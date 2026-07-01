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

RegisterNUICallback('unlockSkill', function(data, cb)
    lib.callback('polarix_trucker:unlockSkill', false, function(success, err)
        if not success then
            Framework.Notify(err or 'Skill-Freischaltung fehlgeschlagen.', 'error')
        end
        cb({ ok = success })
    end, data.skillId)
end)

RegisterNUICallback('createCompany', function(data, cb)
    lib.callback('polarix_trucker:createCompany', false, function(success, err)
        if not success then
            Framework.Notify(err or 'Erstellen fehlgeschlagen.', 'error')
        else
            Framework.Notify('Company erstellt!', 'success')
        end
        cb({ ok = success })
    end, data.name, data.tag, data.description)
end)

RegisterNUICallback('inviteMember', function(data, cb)
    lib.callback('polarix_trucker:inviteMember', false, function(success, err)
        if not success then
            Framework.Notify(err or 'Einladung fehlgeschlagen.', 'error')
        else
            Framework.Notify('Einladung gesendet!', 'success')
        end
        cb({ ok = success })
    end, data.name)
end)

RegisterNUICallback('respondInvite', function(data, cb)
    lib.callback('polarix_trucker:respondInvite', false, function(success, err)
        if not success then
            Framework.Notify(err or 'Fehler.', 'error')
        end
        cb({ ok = success })
    end, data.companyId, data.accept)
end)

RegisterNUICallback('kickMember', function(data, cb)
    lib.callback('polarix_trucker:kickMember', false, function(success, err)
        if not success then
            Framework.Notify(err or 'Kick fehlgeschlagen.', 'error')
        else
            Framework.Notify('Mitglied entfernt.', 'success')
        end
        cb({ ok = success })
    end, data.identifier)
end)

RegisterNUICallback('changeRole', function(data, cb)
    lib.callback('polarix_trucker:changeRole', false, function(success, err)
        if not success then
            Framework.Notify(err or 'Rolle konnte nicht geändert werden.', 'error')
        else
            Framework.Notify('Rolle geändert.', 'success')
        end
        cb({ ok = success })
    end, data.identifier, data.role)
end)

RegisterNUICallback('saveCompanySettings', function(data, cb)
    lib.callback('polarix_trucker:saveCompanySettings', false, function(success, err)
        if not success then
            Framework.Notify(err or 'Speichern fehlgeschlagen.', 'error')
        else
            Framework.Notify('Einstellungen gespeichert.', 'success')
        end
        cb({ ok = success })
    end, { name = data.name, tag = data.tag, description = data.description, openRecruitment = data.openRecruitment })
end)

RegisterNUICallback('depositBank', function(data, cb)
    lib.callback('polarix_trucker:depositBank', false, function(success, err)
        if not success then
            Framework.Notify(err or 'Einzahlung fehlgeschlagen.', 'error')
        else
            Framework.Notify(('$%s eingezahlt.'):format(lib.math.groupdigits(data.amount, ',')), 'success')
        end
        cb({ ok = success })
    end, data.amount)
end)

RegisterNUICallback('withdrawBank', function(data, cb)
    lib.callback('polarix_trucker:withdrawBank', false, function(success, err)
        if not success then
            Framework.Notify(err or 'Auszahlung fehlgeschlagen.', 'error')
        else
            Framework.Notify(('$%s ausgezahlt.'):format(lib.math.groupdigits(data.amount, ',')), 'success')
        end
        cb({ ok = success })
    end, data.amount)
end)
