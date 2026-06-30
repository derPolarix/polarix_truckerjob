local debug = require("shared.debug")
local client = require("config.client")
local shared = require("shared.debug")

-- Callback um UI wieder zu schließen

RegisterNUICallback('closeNui', function(data, cb)
    SetNuiFocus(false, false)
    print(json.encode(data))
    cb({ ok = true, message = 'NUI closed' })
end)

RegisterNUICallback('acceptOrder', function(data, cb)
    lib.callback('polarix_trucker:acceptOrder', false, function(success, orderData, err)
        if success then
            Delivery.Start(orderData)
            CloseNui()
        else
            Framework.Notify(err or 'Fehler beim Annehmen.', 'error')
        end
        cb({ ok = success })
    end, data.orderId)
end)
