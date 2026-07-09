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
        elseif err == 'no_vehicle_or_trailer' then
            Rental.OfferInline(data.orderId, 'solo')
        else
            Framework.Notify(err or 'Fehler beim Annehmen.', 'error')
        end
        cb({ ok = success })
    end, data.orderId)
end)

RegisterNUICallback('rentBundle', function(data, cb)
    lib.callback('polarix_trucker:startRental', false, function(success, err)
        if not success then
            Framework.Notify(err or 'Miete fehlgeschlagen.', 'error')
            cb({ ok = false })
            return
        end

        if data.mode == 'party' then
            lib.callback('polarix_trucker:startPartyMission', false, function(ok, startErr)
                if not ok then
                    Framework.Notify(startErr or 'Fehler beim Starten.', 'error')
                end
                cb({ ok = ok })
            end, data.orderId)
        else
            lib.callback('polarix_trucker:acceptOrder', false, function(ok, orderData, acceptErr)
                if ok then
                    Delivery.Start(orderData)
                else
                    Framework.Notify(acceptErr or 'Fehler beim Annehmen.', 'error')
                end
                cb({ ok = ok })
            end, data.orderId)
        end
    end)
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
        if success then
            SendMessage('equippedVehicleSlot', { slot = data.slot })
        else
            Framework.Notify(err or 'Equip fehlgeschlagen.', 'error')
        end
        cb({ ok = success })
    end, data.slot)
end)

RegisterNUICallback('buyTrailer', function(data, cb)
    lib.callback('polarix_trucker:buyTrailer', false, function(success, price, err, ownedTrailers)
        if success then
            Framework.Notify(('Trailer gekauft für $%s!'):format(lib.math.groupdigits(price, ',')), 'success')
            SendMessage('updateOwnedTrailers', {
                ownedTrailers = ownedTrailers,
                equippedSlot  = LocalTrailer.slot,
            })
        else
            Framework.Notify(err or 'Kauf fehlgeschlagen.', 'error')
        end
        cb({ ok = success })
    end, data.slot)
end)

RegisterNUICallback('equipTrailer', function(data, cb)
    lib.callback('polarix_trucker:equipTrailer', false, function(success, err)
        if success then
            SendMessage('equippedTrailerSlot', { slot = data.slot })
        else
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
    end, data.identifier)
end)

RegisterNUICallback('cancelInvite', function(data, cb)
    lib.callback('polarix_trucker:cancelInvite', false, function(success, err)
        if not success then
            Framework.Notify(err or 'Zurückziehen fehlgeschlagen.', 'error')
        end
        cb({ ok = success })
    end, data.identifier)
end)

RegisterNUICallback('getNearbyRecruits', function(_, cb)
    lib.callback('polarix_trucker:getNearbyRecruits', false, function(list)
        cb({ ok = true, list = list or {} })
    end)
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
    end, { name = data.name, tag = data.tag, description = data.description, openRecruitment = data.openRecruitment, taxRate = data.taxRate, minLevel = data.minLevel })
end)

RegisterNUICallback('disbandCompany', function(_, cb)
    lib.callback('polarix_trucker:disbandCompany', false, function(success, err)
        if not success then
            Framework.Notify(err or 'Auflösen fehlgeschlagen.', 'error')
        else
            Framework.Notify('Company aufgelöst.', 'success')
        end
        cb({ ok = success })
    end)
end)

RegisterNUICallback('leaveCompany', function(_, cb)
    lib.callback('polarix_trucker:leaveCompany', false, function(success, err)
        if not success then
            Framework.Notify(err or 'Verlassen fehlgeschlagen.', 'error')
        else
            Framework.Notify('Company verlassen.', 'success')
        end
        cb({ ok = success })
    end)
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

RegisterNUICallback('requestJoin', function(data, cb)
    lib.callback('polarix_trucker:requestJoin', false, function(success, err)
        if not success then
            Framework.Notify(err or 'Beitreten fehlgeschlagen.', 'error')
        end
        cb({ ok = success })
    end, data.companyId)
end)

RegisterNUICallback('markNotificationRead', function(data, cb)
    lib.callback('polarix_trucker:markNotificationRead', false, function(success)
        cb({ ok = success })
    end, data.id)
end)

RegisterNUICallback('markAllNotificationsRead', function(_, cb)
    lib.callback('polarix_trucker:markAllNotificationsRead', false, function(success)
        cb({ ok = success })
    end)
end)

RegisterNUICallback('getPartyState', function(_, cb)
    lib.callback('polarix_trucker:getPartyState', false, function(state)
        cb({ ok = true, state = state })
    end)
end)

RegisterNUICallback('getCompanyOnlineMembers', function(_, cb)
    lib.callback('polarix_trucker:getCompanyOnlineMembers', false, function(list)
        cb({ ok = true, list = list or {} })
    end)
end)

RegisterNUICallback('invitePartyMember', function(data, cb)
    lib.callback('polarix_trucker:invitePartyMember', false, function(success, err)
        if not success then
            Framework.Notify(err or 'Einladung fehlgeschlagen.', 'error')
        else
            Framework.Notify('Convoy-Einladung gesendet!', 'success')
        end
        cb({ ok = success })
    end, data.identifier)
end)

RegisterNUICallback('respondPartyInvite', function(data, cb)
    lib.callback('polarix_trucker:respondPartyInvite', false, function(success, err)
        if not success then
            Framework.Notify(err or 'Fehler.', 'error')
        end
        cb({ ok = success })
    end, data.partyId, data.accept)
end)

RegisterNUICallback('kickPartyMember', function(data, cb)
    lib.callback('polarix_trucker:kickPartyMember', false, function(success, err)
        if not success then
            Framework.Notify(err or 'Kick fehlgeschlagen.', 'error')
        else
            Framework.Notify('Mitglied entfernt.', 'success')
        end
        cb({ ok = success })
    end, data.identifier)
end)

RegisterNUICallback('leaveParty', function(_, cb)
    lib.callback('polarix_trucker:leaveParty', false, function(success, err)
        if not success then
            Framework.Notify(err or 'Verlassen fehlgeschlagen.', 'error')
        end
        cb({ ok = success })
    end)
end)

RegisterNUICallback('disbandParty', function(_, cb)
    lib.callback('polarix_trucker:disbandParty', false, function(success, err)
        if not success then
            Framework.Notify(err or 'Auflösen fehlgeschlagen.', 'error')
        else
            Framework.Notify('Convoy aufgelöst.', 'success')
        end
        cb({ ok = success })
    end)
end)

RegisterNUICallback('transferPartyLeader', function(data, cb)
    lib.callback('polarix_trucker:transferPartyLeader', false, function(success, err)
        if not success then
            Framework.Notify(err or 'Übergabe fehlgeschlagen.', 'error')
        end
        cb({ ok = success })
    end, data.identifier)
end)

RegisterNUICallback('startPartyMission', function(data, cb)
    lib.callback('polarix_trucker:startPartyMission', false, function(success, err)
        if not success then
            if err == 'no_vehicle_or_trailer' then
                Rental.OfferInline(data.orderId, 'party')
            else
                Framework.Notify(err or 'Fehler beim Starten.', 'error')
            end
        end
        cb({ ok = success })
    end, data.orderId)
end)

RegisterNUICallback('refetchDashboard', function(_, cb)
    lib.callback('polarix_trucker:openDashboard', false, function(dashboardData)
        if dashboardData then
            SendNUIMessage({ action = "openNui", data = dashboardData })
        end
        cb({ ok = dashboardData ~= nil })
    end)
end)

-- Admin-Mission-Editor: reine Server-Forwarder, jeder Server-Callback prüft Framework.IsAdmin
-- selbst erneut (siehe admin-mission-editor-plan.md, Phase B). Namen sind server-seitig final.

RegisterNUICallback('adminListOrders', function(_, cb)
    lib.callback('polarix_trucker:adminListOrders', false, function(orders)
        cb({ ok = true, orders = orders or {} })
    end)
end)

RegisterNUICallback('adminCreateOrder', function(data, cb)
    lib.callback('polarix_trucker:adminCreateOrder', false, function(success, result)
        if not success then
            Framework.Notify(result or 'Erstellen fehlgeschlagen.', 'error')
        end
        cb({ ok = success, orderId = success and result or nil, err = not success and result or nil })
    end, data.order)
end)

RegisterNUICallback('adminUpdateOrder', function(data, cb)
    lib.callback('polarix_trucker:adminUpdateOrder', false, function(success, err)
        if not success then
            Framework.Notify(err or 'Speichern fehlgeschlagen.', 'error')
        end
        cb({ ok = success, err = not success and err or nil })
    end, data.orderId, data.order)
end)

RegisterNUICallback('adminSetOrderActive', function(data, cb)
    lib.callback('polarix_trucker:adminSetOrderActive', false, function(success, err)
        if not success then
            Framework.Notify(err or 'Fehler.', 'error')
        end
        cb({ ok = success })
    end, data.orderId, data.isActive)
end)

RegisterNUICallback('adminDeleteOrder', function(data, cb)
    lib.callback('polarix_trucker:adminDeleteOrder', false, function(success, err)
        if not success then
            Framework.Notify(err or 'Löschen fehlgeschlagen.', 'error')
        end
        cb({ ok = success, err = not success and err or nil })
    end, data.orderId)
end)

RegisterNUICallback('adminCloneOrder', function(data, cb)
    lib.callback('polarix_trucker:adminCloneOrder', false, function(success, result)
        if not success then
            Framework.Notify(result or 'Duplizieren fehlgeschlagen.', 'error')
        end
        cb({ ok = success, order = success and result or nil })
    end, data.orderId)
end)

-- Erfolgreicher Test startet die Lieferung sofort für den Admin (gleicher Pfad wie acceptOrder).
-- Web schließt das Admin-Fenster danach selbst (persistantStore.closeNui()).
RegisterNUICallback('adminTestRunOrder', function(data, cb)
    lib.callback('polarix_trucker:adminTestRunOrder', false, function(success, result)
        if success then
            Delivery.Start(result)
        else
            Framework.Notify(result or 'Test fehlgeschlagen.', 'error')
        end
        cb({ ok = success })
    end, data.orderId)
end)
