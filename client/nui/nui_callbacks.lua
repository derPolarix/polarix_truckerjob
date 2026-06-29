local debug = require("shared.debug")
local client = require("config.client")
local shared = require("shared.debug")

-- Callback um UI wieder zu schließen

RegisterNUICallback('closeNui', function(data, cb)
    SetNuiFocus(false, false)
    print(json.encode(data))
    cb({ ok = true, message = 'NUI closed' })
end)
