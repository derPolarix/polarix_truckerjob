local Locale = require("shared.locale")

RegisterNetEvent("polarix_trucker:partyUpdate", function(state)
    SendMessage("partyUpdate", state)
end)

RegisterNetEvent("polarix_trucker:partyInviteReceived", function(partyId, fromName)
    SendMessage("partyInviteReceived", { partyId = partyId, fromName = fromName })
end)

RegisterNetEvent("polarix_trucker:partyKicked", function()
    Framework.Notify(Locale("notify.removed_from_convoy"), "error")
    SendMessage("partyUpdate", nil)
end)

RegisterNetEvent("polarix_trucker:partyDisbanded", function()
    Framework.Notify(Locale("notify.convoy_was_disbanded"), "info")
    SendMessage("partyUpdate", nil)
end)
