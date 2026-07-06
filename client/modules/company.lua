AddEventHandler("polarix_trucker:inviteReceived", function(companyId, companyName, inviterName, taxRate)
    local msg = inviterName .. " hat dich zu [" .. companyName .. "] eingeladen. Öffne /truckerui zum Annehmen."
    if taxRate and taxRate > 0 then
        msg = msg .. (" (Abgabe: %d%%)"):format(taxRate)
    end
    Framework.Notify(msg, "info", 10000)
end)

AddEventHandler("polarix_trucker:companyDisbanded", function()
    Framework.Notify("Deine Company wurde aufgelöst.", "error", 8000)
end)
