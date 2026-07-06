AddEventHandler("polarix_trucker:inviteReceived", function(companyId, companyName, inviterName)
    Framework.Notify(
        inviterName .. " hat dich zu [" .. companyName .. "] eingeladen. Öffne /truckerui zum Annehmen.",
        "info",
        10000
    )
end)

AddEventHandler("polarix_trucker:companyDisbanded", function()
    Framework.Notify("Deine Company wurde aufgelöst.", "error", 8000)
end)
