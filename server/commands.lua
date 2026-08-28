local debug = require("shared.debug")

RegisterCommand('truckeradmin', function(source)
    if source == 0 then return end -- Konsole hat kein UI
    if not Framework.IsAdmin(source) then
        debug.Warn(("Nicht-Admin %d versuchte /truckeradmin"):format(source))
        return
    end
    local orders = AdminMissions.ListForWeb()
    TriggerClientEvent("polarix_trucker:openAdminEditor", source, orders)
end, false)