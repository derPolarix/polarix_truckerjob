local config = require("config.shared")
local cargo = require("shared.cargo")

PartyMission = {}
PartyMissions = {} -- partyId -> { orderId, order, totalPallets, remainingPallets,
                    --              contributions = { [identifier] = { claimed, delivered, damage } } }

-- oxmysql returns TINYINT(1) as Lua boolean, not integer 1
local function isTruthy(v) return v == 1 or v == true end

function PartyMission.Start(source, orderId)
    local pData = Player.GetData(source)
    if not pData then return false, "Spielerdaten fehlen." end

    local party = Party.GetMembership(pData.identifier)
    if not party then return false, "Du bist in keiner Party." end
    local partyId = PlayerParty[pData.identifier]
    if party.leader ~= pData.identifier then return false, "Nur der Leader kann starten." end
    if PartyMissions[partyId] then return false, "Es läuft bereits eine Party-Mission." end

    local hasOwnGear = pData.equipped_vehicle and pData.equipped_trailer
    if not hasOwnGear and not Rental.IsActive(source) then return false, "no_vehicle_or_trailer" end

    local order = DB.GetOrderById(orderId)
    if not order or not isTruthy(order.is_active) then return false, "Auftrag nicht verfügbar." end
    if type(order.pickup_pallet_coords) == "string" then order.pickup_pallet_coords = json.decode(order.pickup_pallet_coords) end

    local total = cargo.CalcPalletCount(order.weight_kg)
    PartyMissions[partyId] = { orderId = orderId, order = order, totalPallets = total, remainingPallets = total, contributions = {} }

    for _, m in pairs(party.members) do
        if m.source then TriggerClientEvent("polarix_trucker:partyMissionStarted", m.source, order, total) end
    end
    return true
end

-- Wie Orders.ClaimTripPallets, aber Pool über die ganze Party geteilt. Nutzt GetActiveMaxPallets
-- (nicht GetEquippedMaxPallets), sonst bekommen Rental-Spieler in der Party nie einen Claim.
function PartyMission.ClaimPallets(source)
    local pData = Player.GetData(source)
    local partyId = pData and PlayerParty[pData.identifier]
    local mission = partyId and PartyMissions[partyId]
    if not mission or mission.remainingPallets <= 0 then return 0 end

    local claim = math.min(Trailers.GetActiveMaxPallets(source) or 0, mission.remainingPallets)
    if claim <= 0 then return 0 end

    mission.remainingPallets = mission.remainingPallets - claim
    local c = mission.contributions[pData.identifier] or { claimed = 0, delivered = 0, damage = 0 }
    c.claimed = c.claimed + claim
    mission.contributions[pData.identifier] = c

    PartyMission.BroadcastProgress(partyId)
    return claim
end

function PartyMission.CompleteTrip(source, tripPalletCount, cargoDamage)
    local pData = Player.GetData(source)
    local partyId = pData and PlayerParty[pData.identifier]
    local mission = partyId and PartyMissions[partyId]
    if not mission then return false, 0 end

    local c = mission.contributions[pData.identifier]
    if not c then return false, mission.remainingPallets end
    c.delivered = c.delivered + tripPalletCount
    c.damage = c.damage + (cargoDamage or 0)

    local deliveredTotal = 0
    for _, contrib in pairs(mission.contributions) do deliveredTotal = deliveredTotal + contrib.delivered end

    PartyMission.BroadcastProgress(partyId)

    if deliveredTotal >= mission.totalPallets then
        PartyMission.Finish(partyId)
        return true, 0
    end
    return false, mission.remainingPallets
end

-- Fahrzeug zerstört / Disconnect / freiwilliges Leave MIT noch nicht abgeliefertem Claim
function PartyMission.HandleMemberDropout(source)
    local pData = Player.GetData(source)
    local partyId = pData and PlayerParty[pData.identifier]
    local mission = partyId and PartyMissions[partyId]
    if not mission then return end
    local c = mission.contributions[pData.identifier]
    if not c then return end
    local unclaimed = c.claimed - c.delivered -- was er noch geladen, aber nicht abgeliefert hatte
    if unclaimed > 0 then
        mission.remainingPallets = mission.remainingPallets + unclaimed
        c.claimed = c.claimed - unclaimed
        PartyMission.BroadcastProgress(partyId)
    end
end

function PartyMission.BroadcastProgress(partyId)
    local mission = PartyMissions[partyId]
    local party = Parties[partyId]
    if not mission or not party then return end

    local deliveredTotal, claimedTotal = 0, 0
    for _, c in pairs(mission.contributions) do
        deliveredTotal = deliveredTotal + c.delivered
        claimedTotal = claimedTotal + c.claimed
    end

    local payload = { totalPallets = mission.totalPallets, claimedTotal = claimedTotal, deliveredTotal = deliveredTotal }
    for _, m in pairs(party.members) do
        if m.source then TriggerClientEvent("polarix_trucker:partyMissionProgress", m.source, payload) end
    end
end

function PartyMission.Finish(partyId)
    local mission = PartyMissions[partyId]
    local party = Parties[partyId]
    if not mission or not party then return end

    for identifier, contrib in pairs(mission.contributions) do
        if contrib.delivered > 0 then
            local memberSource = party.members[identifier] and party.members[identifier].source
            if memberSource then
                local share = contrib.delivered / mission.totalPallets
                local baseReward = math.floor(mission.order.reward_base * share)

                local reward, xp = Skills.ApplyRewardModifiers(memberSource, baseReward, mission.order.cargo_type, mission.order)
                xp = Skills.ApplyXPModifiers(memberSource, xp)

                -- Party-Bonus-Multiplier (config-gesteuert, on top der Skill-Modifier)
                reward = math.floor(reward * (config.PartyRewardMultiplier and config.PartyRewardMultiplier.cash or 1.0))
                xp = math.floor(xp * (config.PartyRewardMultiplier and config.PartyRewardMultiplier.xp or 1.0))

                local damagePercent = math.min(contrib.damage / math.max(baseReward, 1), 0.30)
                local penalty = math.floor(reward * damagePercent)
                reward = reward - penalty

                local taxAmount
                reward, taxAmount = Company.ApplyTax(memberSource, reward)

                Framework.AddMoney(memberSource, reward)
                Player.AddXP(memberSource, xp)

                local pData = Player.GetData(memberSource)
                pData.total_earnings = pData.total_earnings + reward
                pData.total_deliveries = pData.total_deliveries + 1
                Player.Save(memberSource)
                Company.OnDeliveryComplete(memberSource, reward)

                TriggerClientEvent("polarix_trucker:partyTripSettled", memberSource, reward, xp, penalty, taxAmount)
            end
        end
    end

    for _, m in pairs(party.members) do
        if m.source then TriggerClientEvent("polarix_trucker:partyMissionFinished", m.source) end
    end
    PartyMissions[partyId] = nil
end

-- Aufgerufen von Party.removeMember, wenn nach einem Austritt 0 Online-Mitglieder übrig sind
function PartyMission.Fail(partyId)
    local mission = PartyMissions[partyId]
    local party = Parties[partyId]
    if not mission then return end
    if party then
        for identifier in pairs(party.members) do
            Notifications.Push(identifier, "party_mission_failed", "Party-Mission fehlgeschlagen",
                "Alle Mitglieder haben die Party verlassen — die Mission wurde abgebrochen, kein Reward.", "tabler:alert-triangle")
        end
    end
    PartyMissions[partyId] = nil
end

lib.callback.register("polarix_trucker:startPartyMission", function(source, orderId) return PartyMission.Start(source, orderId) end)
lib.callback.register("polarix_trucker:claimPartyPallets", function(source) return PartyMission.ClaimPallets(source) end)

RegisterNetEvent("polarix_trucker:completePartyTrip", function(tripPalletCount, cargoDamage)
    local finished, remaining = PartyMission.CompleteTrip(source, tripPalletCount, cargoDamage)
    if not finished then TriggerClientEvent("polarix_trucker:tripSettled", source, remaining) end
    -- bei finished=true kommt "partyMissionFinished" bereits per Broadcast aus Finish() an ALLE,
    -- inkl. des Spielers, der gerade den letzten Trip geliefert hat
end)
