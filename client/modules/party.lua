RegisterNetEvent("polarix_trucker:partyUpdate", function(state)
    SendMessage("partyUpdate", state)
end)

RegisterNetEvent("polarix_trucker:partyInviteReceived", function(partyId, fromName)
    SendMessage("partyInviteReceived", { partyId = partyId, fromName = fromName })
end)

RegisterNetEvent("polarix_trucker:partyKicked", function()
    Framework.Notify("Du wurdest aus der Party entfernt.", "error")
    SendMessage("partyUpdate", nil)
end)

RegisterNetEvent("polarix_trucker:partyDisbanded", function()
    Framework.Notify("Die Party wurde aufgelöst.", "info")
    SendMessage("partyUpdate", nil)
end)
