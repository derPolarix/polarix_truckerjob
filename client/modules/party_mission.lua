-- Dünner Glue-Layer: setzt nur DeliveryState.mode = "party" und startet den in Phase B
-- generalisierten Trip-Loop. Party-spezifisches (Reward pro Mitglied, Gesamt-Fortschritt, Fail)
-- wird hier behandelt, nicht in delivery.lua.

PartyProgress = { totalPallets = 0, claimedTotal = 0, deliveredTotal = 0 }

RegisterNetEvent("polarix_trucker:partyMissionStarted", function(order, totalPallets)
    PartyProgress = { totalPallets = totalPallets, claimedTotal = 0, deliveredTotal = 0 }
    Delivery.Start(order, "party")
end)

RegisterNetEvent("polarix_trucker:partyMissionProgress", function(progress)
    PartyProgress.totalPallets = progress.totalPallets
    PartyProgress.claimedTotal = progress.claimedTotal
    PartyProgress.deliveredTotal = progress.deliveredTotal
    SendMessage("partyMissionProgress", progress) -- Party-Dropdown/HUD zeigt totalPallets/claimedTotal/deliveredTotal
end)

RegisterNetEvent("polarix_trucker:partyTripSettled", function(reward, xp, penalty, tax)
    local msg = ("Party-Lieferung abgerechnet! +$%s, +%s XP"):format(reward, xp)
    if penalty and penalty > 0 then
        msg = msg .. (" (-%s Schaden-Abzug)"):format(penalty)
    end
    if tax and tax > 0 then
        msg = msg .. (" (-$%s Company-Abgabe)"):format(tax)
    end
    Framework.Notify(msg, "success")
    SendMessage("deliveryComplete", { reward = reward, xp = xp })
end)

RegisterNetEvent("polarix_trucker:partyMissionFinished", function()
    Delivery.Reset()
    PartyProgress = { totalPallets = 0, claimedTotal = 0, deliveredTotal = 0 }
    SendMessage("partyMissionFinished", {})
end)
