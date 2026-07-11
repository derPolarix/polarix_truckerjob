local debug = require("shared.debug")
local client = require("config.client")
local shared = require("shared.debug")
local Locale = require("shared.locale")

RegisterCommand('openNui', function()
    OpenNui()
end, false)

RegisterCommand('sendmsg', function()
    OpenNui()
   SendMessage('updateMessage', {
        message = 'Hallo von der Client Seite!'
    })
end, false)

-- test command: instantly loads all remaining pallets onto the trailer
RegisterCommand('autoloadpallets', function()
    AutoLoadAllPallets()
end, false)

RegisterCommand('truckerui', function()
    lib.callback('polarix_trucker:openDashboard', false, function(data)
        if not data then
            Framework.Notify(Locale("notify.no_player_data_available"), 'error')
            return
        end
        OpenNui()
        SendMessage('openNui', data)
    end)
end, false)