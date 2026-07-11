-- Thin glue layer: sets DeliveryState.mode = "party" and starts the shared trip loop.
-- Party-specific bits (per-member reward, overall progress, fail) are handled here, not in delivery.lua.

local Locale = require("shared.locale")

PartyProgress = { totalPallets = 0, claimedTotal = 0, deliveredTotal = 0 }

RegisterNetEvent("polarix_trucker:partyMissionStarted", function(order, totalPallets)
    PartyProgress = { totalPallets = totalPallets, claimedTotal = 0, deliveredTotal = 0 }
    Delivery.Start(order, "party")
end)

RegisterNetEvent("polarix_trucker:partyMissionProgress", function(progress)
    PartyProgress.totalPallets = progress.totalPallets
    PartyProgress.claimedTotal = progress.claimedTotal
    PartyProgress.deliveredTotal = progress.deliveredTotal
    SendMessage("partyMissionProgress", progress)
end)

RegisterNetEvent("polarix_trucker:partyTripSettled", function(reward, xp, penalty, tax)
    local msg = Locale("notify.convoy_delivery_settled_xp"):format(reward, xp)
    if penalty and penalty > 0 then
        msg = msg .. Locale("notify.damage_deduction"):format(penalty)
    end
    if tax and tax > 0 then
        msg = msg .. Locale("notify.company_tax"):format(tax)
    end
    Framework.Notify(msg, "success")
    SendMessage("deliveryComplete", { reward = reward, xp = xp })
end)

RegisterNetEvent("polarix_trucker:partyMissionFinished", function()
    Delivery.Reset()
    PartyProgress = { totalPallets = 0, claimedTotal = 0, deliveredTotal = 0 }
    SendMessage("partyMissionFinished", {})
end)
