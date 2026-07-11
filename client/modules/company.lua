local Locale = require("shared.locale")

AddEventHandler("polarix_trucker:inviteReceived", function(companyId, companyName, inviterName, taxRate)
    local msg = Locale("notify.invited_open_truckerui_accept"):format(inviterName, companyName)
    if taxRate and taxRate > 0 then
        msg = msg .. Locale("notify.tax"):format(taxRate)
    end
    Framework.Notify(msg, "info", 10000)
end)

AddEventHandler("polarix_trucker:companyDisbanded", function()
    Framework.Notify(Locale("notify.your_company_was_disbanded"), "error", 8000)
end)
