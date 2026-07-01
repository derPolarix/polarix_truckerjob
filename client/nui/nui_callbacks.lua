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

RegisterNUICallback('buyVehicle', function(data, cb)
    lib.callback('polarix_trucker:buyVehicle', false, function(success, price, err, ownedVehicles)
        if success then
            Framework.Notify(('Fahrzeug gekauft für $%s!'):format(lib.math.groupdigits(price, ',')), 'success')
            SendMessage('updateOwnedVehicles', {
                ownedVehicles = ownedVehicles,
                equippedSlot  = LocalVehicle.slot,
            })
        else
            Framework.Notify(err or 'Kauf fehlgeschlagen.', 'error')
        end
        cb({ ok = success })
    end, data.slot)
end)

RegisterNUICallback('equipVehicle', function(data, cb)
    lib.callback('polarix_trucker:equipVehicle', false, function(success, err)
        if not success then
            Framework.Notify(err or 'Equip fehlgeschlagen.', 'error')
        end
        cb({ ok = success })
    end, data.slot)
end)
