local config = require("config.shared")
local cargo = require("shared.cargo")
local Locale = require("shared.locale")
local debug = require("shared.debug")

PartyMission = {}
-- partyId -> { orderId, order, totalPallets,
--   slots = { [i] = { state = "carried"|"loaded"|"delivered", identifier?, ownerIdentifier?, trailerSlot? } },
--   contributions = { [identifier] = { damage } } }
PartyMissions = {}

-- oxmysql returns TINYINT(1) as Lua boolean, not integer 1
local function isTruthy(v) return v == 1 or v == true end

local function memberHasGear(memberSource)
    local pData = Player.GetData(memberSource)
    local hasOwnGear = pData and pData.equipped_vehicle and pData.equipped_trailer
    return hasOwnGear or Rental.IsActive(memberSource)
end

function PartyMission.Start(source, orderId)
    local pData = Player.GetData(source)
    if not pData then return false, Locale("error.player_data_missing") end

    local party = Party.GetMembership(pData.identifier)
    if not party then return false, Locale("error.not_convoy") end
    local partyId = PlayerParty[pData.identifier]
    if party.leader ~= pData.identifier then return false, Locale("error.only_leader_can_start") end
    if PartyMissions[partyId] then return false, Locale("error.convoy_mission_already_running") end

    local hasOwnGear = pData.equipped_vehicle and pData.equipped_trailer
    if not hasOwnGear and not Rental.IsActive(source) then return false, "no_vehicle_or_trailer" end

    local order = DB.GetOrderById(orderId)
    if not order or not isTruthy(order.is_active) then return false, Locale("error.order_not_available") end
    if order.level_required > pData.level then return false, Locale("error.level_not_sufficient") end
    if isTruthy(order.requires_hazmat) and not Player.HasSkill(source, "h3") then return false, Locale("error.hazmat_license_required") end
    if isTruthy(order.requires_long_hauler) and not Player.HasSkill(source, "d3") then return false, Locale("error.long_hauler_skill_required") end
    if Orders.CooldownRemaining(order, DB.GetLastCompletedAt(pData.identifier, orderId)) > 0 then
        return false, Locale("error.mission_on_cooldown")
    end
    if type(order.pickup_pallet_coords) == "string" then order.pickup_pallet_coords = json.decode(order.pickup_pallet_coords) end

    local total = cargo.CalcPalletCount(order.weight_kg)
    PartyMissions[partyId] = { orderId = orderId, order = order, totalPallets = total, slots = {}, contributions = {} }

    -- Ungeared members would reach pickup with no way to claim ground pallets and loop
    -- forever - withhold partyMissionStarted and prompt them to rent instead.
    debug.DebugPrint(("PartyMission.Start: partyId=%s orderId=%s totalPallets=%s members="):format(partyId, orderId, total), party.members)

    for _, m in pairs(party.members) do
        if m.source then
            local geared = memberHasGear(m.source)
            debug.DebugPrint(("PartyMission.Start: member src=%s identifier=%s geared=%s -> %s"):format(
                m.source, tostring(m.identifier), tostring(geared), geared and "partyMissionStarted" or "partyMemberNeedsGear"))
            if geared then
                TriggerClientEvent("polarix_trucker:partyMissionStarted", m.source, order, total)
            else
                TriggerClientEvent("polarix_trucker:partyMemberNeedsGear", m.source, orderId)
            end
        end
    end
    return true
end

-- Snapshot of which ground slots are already spoken for, used once by a client when it
-- first spawns pallets so it doesn't render one someone else already picked up.
function PartyMission.GetGroundState(source)
    local pData = Player.GetData(source)
    local partyId = pData and PlayerParty[pData.identifier]
    local mission = partyId and PartyMissions[partyId]
    if not mission then return {} end

    local taken = {}
    for i, slot in pairs(mission.slots) do
        if slot then taken[i] = true end
    end
    return taken
end

-- free -> carried. Physical pickup with the forklift; not a reward claim yet (see
-- LoadPalletOnTrailer), just reserves the ground slot so two members can't grab the same one.
function PartyMission.ClaimGroundPallet(source, slotIndex)
    local pData = Player.GetData(source)
    local partyId = pData and PlayerParty[pData.identifier]
    local mission = partyId and PartyMissions[partyId]
    if not mission then return false end
    if type(slotIndex) ~= "number" or slotIndex < 1 or slotIndex > mission.totalPallets then return false end

    if mission.slots[slotIndex] then
        debug.DebugPrint(("PartyMission.ClaimGroundPallet: src=%s identifier=%s slot=%s already taken (state=%s)"):format(
            source, pData.identifier, slotIndex, mission.slots[slotIndex].state))
        return false
    end

    mission.slots[slotIndex] = { state = "carried", identifier = pData.identifier }
    debug.DebugPrint(("PartyMission.ClaimGroundPallet: src=%s identifier=%s slot=%s -> carried"):format(source, pData.identifier, slotIndex))

    local party = Parties[partyId]
    if party then
        for _, m in pairs(party.members) do
            if m.source and m.source ~= source then
                TriggerClientEvent("polarix_trucker:partyGroundPalletTaken", m.source, slotIndex)
            end
        end
    end
    return true
end

-- carried -> loaded. This is the actual reward claim, and the target trailer can belong to
-- any online party member (not just the caller) - that's the whole point of the rewrite.
function PartyMission.LoadPalletOnTrailer(source, slotIndex, targetIdentifier)
    local pData = Player.GetData(source)
    local partyId = pData and PlayerParty[pData.identifier]
    local mission = partyId and PartyMissions[partyId]
    local party = partyId and Parties[partyId]
    if not mission or not party then return false end

    local slot = mission.slots[slotIndex]
    if not slot or slot.state ~= "carried" or slot.identifier ~= pData.identifier then
        debug.DebugPrint(("PartyMission.LoadPalletOnTrailer: src=%s identifier=%s slot=%s invalid state (%s)"):format(
            source, pData.identifier, tostring(slotIndex), slot and slot.state or "free"))
        return false
    end

    -- nil targetIdentifier means "load onto my own trailer" - the client never needs to
    -- know its own identifier, the caller's own identity is the default target.
    targetIdentifier = targetIdentifier or pData.identifier

    local targetMember = party.members[targetIdentifier]
    local targetSource = targetMember and targetMember.source
    if not targetSource then return false end

    local maxPallets = Trailers.GetActiveMaxPallets(targetSource) or 0
    local loadedForTarget = 0
    for _, s in pairs(mission.slots) do
        if s and s.state == "loaded" and s.ownerIdentifier == targetIdentifier then
            loadedForTarget = loadedForTarget + 1
        end
    end
    if loadedForTarget >= maxPallets then
        debug.DebugPrint(("PartyMission.LoadPalletOnTrailer: src=%s target=%s trailer full (%s/%s)"):format(
            source, targetIdentifier, loadedForTarget, maxPallets))
        return false, "trailer_full"
    end

    local trailerSlot = loadedForTarget + 1
    slot.state = "loaded"
    slot.ownerIdentifier = targetIdentifier
    slot.trailerSlot = trailerSlot
    slot.identifier = nil

    debug.DebugPrint(("PartyMission.LoadPalletOnTrailer: src=%s identifier=%s slot=%s -> loaded owner=%s trailerSlot=%s"):format(
        source, pData.identifier, slotIndex, targetIdentifier, trailerSlot))

    for identifier, m in pairs(party.members) do
        if m.source then
            TriggerClientEvent("polarix_trucker:partyPalletLoaded", m.source, slotIndex, targetIdentifier, trailerSlot,
                m.source == source, identifier == targetIdentifier)
        end
    end

    PartyMission.BroadcastProgress(partyId)
    return true, trailerSlot, maxPallets
end

-- Called after an ungeared member rents/equips a trailer; joins them onto the mission
-- the rest of the party already started.
function PartyMission.ConfirmMemberReady(source)
    local pData = Player.GetData(source)
    local partyId = pData and PlayerParty[pData.identifier]
    local mission = partyId and PartyMissions[partyId]
    if not mission then return false, Locale("error.convoy_mission_not_active") end
    if not memberHasGear(source) then return false, "no_vehicle_or_trailer" end

    TriggerClientEvent("polarix_trucker:partyMissionStarted", source, mission.order, mission.totalPallets)
    return true
end

function PartyMission.CompleteTrip(source, cargoDamage, clientReportedCount)
    local pData = Player.GetData(source)
    local partyId = pData and PlayerParty[pData.identifier]
    local mission = partyId and PartyMissions[partyId]
    if not mission then return false, 0 end

    local deliveredThisTrip = 0
    for _, s in pairs(mission.slots) do
        if s and s.state == "loaded" and s.ownerIdentifier == pData.identifier then
            s.state = "delivered"
            deliveredThisTrip = deliveredThisTrip + 1
        end
    end

    local c = mission.contributions[pData.identifier] or { damage = 0 }
    c.damage = c.damage + (cargoDamage or 0)
    mission.contributions[pData.identifier] = c

    local deliveredTotal, freeCount = 0, 0
    for i = 1, mission.totalPallets do
        local s = mission.slots[i]
        if not s then freeCount = freeCount + 1
        elseif s.state == "delivered" then deliveredTotal = deliveredTotal + 1 end
    end

    debug.DebugPrint(("PartyMission.CompleteTrip: src=%s identifier=%s deliveredThisTrip=%s (clientReported=%s) deliveredTotal=%s/%s"):format(
        source, pData.identifier, deliveredThisTrip, tostring(clientReportedCount), deliveredTotal, mission.totalPallets))

    PartyMission.BroadcastProgress(partyId)

    if deliveredTotal >= mission.totalPallets then
        PartyMission.Finish(partyId)
        return true, 0
    end
    return false, freeCount
end

-- Vehicle destroyed / disconnect / voluntary leave. Anything the player was physically
-- carrying, or had loaded on their own trailer but not yet delivered, goes back to the
-- ground pool for the rest of the party to pick up again.
function PartyMission.HandleMemberDropout(source)
    local pData = Player.GetData(source)
    local partyId = pData and PlayerParty[pData.identifier]
    local mission = partyId and PartyMissions[partyId]
    local party = partyId and Parties[partyId]
    if not mission then return end

    local freed = {}
    for i = 1, mission.totalPallets do
        local s = mission.slots[i]
        if s and ((s.state == "carried" and s.identifier == pData.identifier)
            or (s.state == "loaded" and s.ownerIdentifier == pData.identifier)) then
            mission.slots[i] = nil
            freed[#freed + 1] = i
        end
    end

    if #freed == 0 then return end

    debug.DebugPrint(("PartyMission.HandleMemberDropout: identifier=%s freed slots="):format(pData.identifier), freed)

    if party then
        for _, m in pairs(party.members) do
            if m.source then
                for _, slotIndex in ipairs(freed) do
                    TriggerClientEvent("polarix_trucker:partyGroundPalletFreed", m.source, slotIndex)
                end
            end
        end
    end
    PartyMission.BroadcastProgress(partyId)
end

function PartyMission.BroadcastProgress(partyId)
    local mission = PartyMissions[partyId]
    local party = Parties[partyId]
    if not mission or not party then return end

    local carried, loaded, delivered = 0, 0, 0
    for i = 1, mission.totalPallets do
        local s = mission.slots[i]
        if s then
            if s.state == "carried" then carried = carried + 1
            elseif s.state == "loaded" then loaded = loaded + 1
            elseif s.state == "delivered" then delivered = delivered + 1
            end
        end
    end
    local poolRemaining = mission.totalPallets - carried - loaded - delivered

    local payload = {
        totalPallets = mission.totalPallets,
        claimedTotal = carried + loaded + delivered,
        deliveredTotal = delivered,
        poolRemaining = poolRemaining,
    }
    for _, m in pairs(party.members) do
        if m.source then TriggerClientEvent("polarix_trucker:partyMissionProgress", m.source, payload) end
    end
end

function PartyMission.Finish(partyId)
    local mission = PartyMissions[partyId]
    local party = Parties[partyId]
    if not mission or not party then return end

    local deliveredByOwner = {}
    for _, s in pairs(mission.slots) do
        if s and s.state == "delivered" then
            deliveredByOwner[s.ownerIdentifier] = (deliveredByOwner[s.ownerIdentifier] or 0) + 1
        end
    end

    for identifier, deliveredCount in pairs(deliveredByOwner) do
        local memberSource = party.members[identifier] and party.members[identifier].source
        if memberSource then
            local share = deliveredCount / mission.totalPallets
            local baseReward = math.floor(mission.order.reward_base * share)
            local damage = (mission.contributions[identifier] and mission.contributions[identifier].damage) or 0

            local reward, xp = Skills.ApplyRewardModifiers(memberSource, baseReward, mission.order.cargo_type, mission.order)
            xp = Skills.ApplyXPModifiers(memberSource, xp)

            -- party bonus multiplier (config-driven, applied on top of skill modifiers)
            reward = math.floor(reward * (config.PartyRewardMultiplier and config.PartyRewardMultiplier.cash or 1.0))
            xp = math.floor(xp * (config.PartyRewardMultiplier and config.PartyRewardMultiplier.xp or 1.0))

            local damagePercent = math.min(damage / math.max(baseReward, 1), 0.30)
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

    for _, m in pairs(party.members) do
        if m.source then TriggerClientEvent("polarix_trucker:partyMissionFinished", m.source) end
    end
    PartyMissions[partyId] = nil
end

-- called from Party.removeMember when a leave drops the party to 0 online members
function PartyMission.Fail(partyId)
    local mission = PartyMissions[partyId]
    local party = Parties[partyId]
    if not mission then return end
    if party then
        for identifier in pairs(party.members) do
            Notifications.Push(identifier, "party_mission_failed", Locale("push.convoy_mission_failed"),
                Locale("push.all_members_left_convoy_mission"), "tabler:alert-triangle")
        end
    end
    PartyMissions[partyId] = nil
end

lib.callback.register("polarix_trucker:startPartyMission", function(source, orderId) return PartyMission.Start(source, orderId) end)
lib.callback.register("polarix_trucker:getPartyGroundState", function(source) return PartyMission.GetGroundState(source) end)
lib.callback.register("polarix_trucker:claimGroundPallet", function(source, slotIndex) return PartyMission.ClaimGroundPallet(source, slotIndex) end)
lib.callback.register("polarix_trucker:loadPalletOnTrailer", function(source, slotIndex, targetIdentifier) return PartyMission.LoadPalletOnTrailer(source, slotIndex, targetIdentifier) end)
lib.callback.register("polarix_trucker:confirmPartyMemberReady", function(source) return PartyMission.ConfirmMemberReady(source) end)

RegisterNetEvent("polarix_trucker:completePartyTrip", function(clientReportedCount, cargoDamage)
    local finished, remaining = PartyMission.CompleteTrip(source, cargoDamage, clientReportedCount)
    if not finished then TriggerClientEvent("polarix_trucker:tripSettled", source, remaining) end
    -- on finished=true, "partyMissionFinished" already reaches everyone via Finish()'s broadcast,
    -- including the player who just delivered the last trip
end)
