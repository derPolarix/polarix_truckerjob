local debug = require("shared.debug")
local client = require("config.client")
local shared = require("shared.debug")
local Locale = require("shared.locale")

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
            Framework.Notify(err or Locale("notify.failed_accept"), 'error')
        end
        cb({ ok = success })
    end, data.orderId)
end)

RegisterNUICallback('rentBundle', function(data, cb)
    lib.callback('polarix_trucker:startRental', false, function(success, err)
        if not success then
            Framework.Notify(err or Locale("notify.rental_failed"), 'error')
            cb({ ok = false })
            return
        end

        if data.mode == 'party' then
            lib.callback('polarix_trucker:startPartyMission', false, function(ok, startErr)
                if not ok then
                    Framework.Notify(startErr or Locale("notify.failed_start"), 'error')
                end
                cb({ ok = ok })
            end, data.orderId)
        else
            lib.callback('polarix_trucker:acceptOrder', false, function(ok, orderData, acceptErr)
                if ok then
                    Delivery.Start(orderData)
                else
                    Framework.Notify(acceptErr or Locale("notify.failed_accept"), 'error')
                end
                cb({ ok = ok })
            end, data.orderId)
        end
    end)
end)

RegisterNUICallback('buyVehicle', function(data, cb)
    lib.callback('polarix_trucker:buyVehicle', false, function(success, price, err, ownedVehicles)
        if success then
            Framework.Notify(Locale("notify.vehicle_bought"):format(lib.math.groupdigits(price, ',')), 'success')
            SendMessage('updateOwnedVehicles', {
                ownedVehicles = ownedVehicles,
                equippedSlot  = LocalVehicle.slot,
            })
        else
            Framework.Notify(err or Locale("notify.purchase_failed"), 'error')
        end
        cb({ ok = success })
    end, data.slot)
end)

RegisterNUICallback('equipVehicle', function(data, cb)
    lib.callback('polarix_trucker:equipVehicle', false, function(success, err)
        if success then
            SendMessage('equippedVehicleSlot', { slot = data.slot })
        else
            Framework.Notify(err or Locale("notify.failed_equip"), 'error')
        end
        cb({ ok = success })
    end, data.slot)
end)

RegisterNUICallback('buyTrailer', function(data, cb)
    lib.callback('polarix_trucker:buyTrailer', false, function(success, price, err, ownedTrailers)
        if success then
            Framework.Notify(Locale("notify.trailer_bought"):format(lib.math.groupdigits(price, ',')), 'success')
            SendMessage('updateOwnedTrailers', {
                ownedTrailers = ownedTrailers,
                equippedSlot  = LocalTrailer.slot,
            })
        else
            Framework.Notify(err or Locale("notify.purchase_failed"), 'error')
        end
        cb({ ok = success })
    end, data.slot)
end)

RegisterNUICallback('equipTrailer', function(data, cb)
    lib.callback('polarix_trucker:equipTrailer', false, function(success, err)
        if success then
            SendMessage('equippedTrailerSlot', { slot = data.slot })
        else
            Framework.Notify(err or Locale("notify.failed_equip"), 'error')
        end
        cb({ ok = success })
    end, data.slot)
end)

RegisterNUICallback('unlockSkill', function(data, cb)
    lib.callback('polarix_trucker:unlockSkill', false, function(success, err)
        if not success then
            Framework.Notify(err or Locale("notify.failed_unlock_skill"), 'error')
        end
        cb({ ok = success })
    end, data.skillId)
end)

RegisterNUICallback('createCompany', function(data, cb)
    lib.callback('polarix_trucker:createCompany', false, function(success, err)
        if not success then
            Framework.Notify(err or Locale("notify.failed_create"), 'error')
        else
            Framework.Notify(Locale("notify.company_created"), 'success')
        end
        cb({ ok = success })
    end, data.name, data.tag, data.description)
end)

RegisterNUICallback('inviteMember', function(data, cb)
    lib.callback('polarix_trucker:inviteMember', false, function(success, err)
        if not success then
            Framework.Notify(err or Locale("notify.failed_invite"), 'error')
        else
            Framework.Notify(Locale("notify.invite_sent"), 'success')
        end
        cb({ ok = success })
    end, data.identifier)
end)

RegisterNUICallback('cancelInvite', function(data, cb)
    lib.callback('polarix_trucker:cancelInvite', false, function(success, err)
        if not success then
            Framework.Notify(err or Locale("notify.failed_withdraw"), 'error')
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
            Framework.Notify(err or Locale("notify.error"), 'error')
        end
        cb({ ok = success })
    end, data.companyId, data.accept)
end)

RegisterNUICallback('kickMember', function(data, cb)
    lib.callback('polarix_trucker:kickMember', false, function(success, err)
        if not success then
            Framework.Notify(err or Locale("notify.failed_kick"), 'error')
        else
            Framework.Notify(Locale("notify.member_removed"), 'success')
        end
        cb({ ok = success })
    end, data.identifier)
end)

RegisterNUICallback('changeRole', function(data, cb)
    lib.callback('polarix_trucker:changeRole', false, function(success, err)
        if not success then
            Framework.Notify(err or Locale("notify.failed_change_role"), 'error')
        else
            Framework.Notify(Locale("notify.role_changed"), 'success')
        end
        cb({ ok = success })
    end, data.identifier, data.role)
end)

RegisterNUICallback('saveCompanySettings', function(data, cb)
    lib.callback('polarix_trucker:saveCompanySettings', false, function(success, err)
        if not success then
            Framework.Notify(err or Locale("notify.failed_save"), 'error')
        else
            Framework.Notify(Locale("notify.settings_saved"), 'success')
        end
        cb({ ok = success })
    end, { name = data.name, tag = data.tag, description = data.description, openRecruitment = data.openRecruitment, taxRate = data.taxRate, minLevel = data.minLevel })
end)

RegisterNUICallback('disbandCompany', function(_, cb)
    lib.callback('polarix_trucker:disbandCompany', false, function(success, err)
        if not success then
            Framework.Notify(err or Locale("notify.failed_disband"), 'error')
        else
            Framework.Notify(Locale("notify.company_disband_confirmed"), 'success')
        end
        cb({ ok = success })
    end)
end)

RegisterNUICallback('leaveCompany', function(_, cb)
    lib.callback('polarix_trucker:leaveCompany', false, function(success, err)
        if not success then
            Framework.Notify(err or Locale("notify.failed_leave"), 'error')
        else
            Framework.Notify(Locale("notify.left_company"), 'success')
        end
        cb({ ok = success })
    end)
end)

RegisterNUICallback('depositBank', function(data, cb)
    lib.callback('polarix_trucker:depositBank', false, function(success, err)
        if not success then
            Framework.Notify(err or Locale("notify.deposit_failed"), 'error')
        else
            Framework.Notify(Locale("notify.deposited"):format(lib.math.groupdigits(data.amount, ',')), 'success')
        end
        cb({ ok = success })
    end, data.amount)
end)

RegisterNUICallback('withdrawBank', function(data, cb)
    lib.callback('polarix_trucker:withdrawBank', false, function(success, err)
        if not success then
            Framework.Notify(err or Locale("notify.withdrawal_failed"), 'error')
        else
            Framework.Notify(Locale("notify.withdrawn"):format(lib.math.groupdigits(data.amount, ',')), 'success')
        end
        cb({ ok = success })
    end, data.amount)
end)

RegisterNUICallback('requestJoin', function(data, cb)
    lib.callback('polarix_trucker:requestJoin', false, function(success, err)
        if not success then
            Framework.Notify(err or Locale("notify.failed_join"), 'error')
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
            Framework.Notify(err or Locale("notify.failed_invite"), 'error')
        else
            Framework.Notify(Locale("notify.convoy_invite_sent"), 'success')
        end
        cb({ ok = success })
    end, data.identifier)
end)

RegisterNUICallback('respondPartyInvite', function(data, cb)
    lib.callback('polarix_trucker:respondPartyInvite', false, function(success, err)
        if not success then
            Framework.Notify(err or Locale("notify.error"), 'error')
        end
        cb({ ok = success })
    end, data.partyId, data.accept)
end)

RegisterNUICallback('kickPartyMember', function(data, cb)
    lib.callback('polarix_trucker:kickPartyMember', false, function(success, err)
        if not success then
            Framework.Notify(err or Locale("notify.failed_kick"), 'error')
        else
            Framework.Notify(Locale("notify.member_removed"), 'success')
        end
        cb({ ok = success })
    end, data.identifier)
end)

RegisterNUICallback('leaveParty', function(_, cb)
    lib.callback('polarix_trucker:leaveParty', false, function(success, err)
        if not success then
            Framework.Notify(err or Locale("notify.failed_leave"), 'error')
        end
        cb({ ok = success })
    end)
end)

RegisterNUICallback('disbandParty', function(_, cb)
    lib.callback('polarix_trucker:disbandParty', false, function(success, err)
        if not success then
            Framework.Notify(err or Locale("notify.failed_disband"), 'error')
        else
            Framework.Notify(Locale("notify.convoy_disband_confirmed"), 'success')
        end
        cb({ ok = success })
    end)
end)

RegisterNUICallback('transferPartyLeader', function(data, cb)
    lib.callback('polarix_trucker:transferPartyLeader', false, function(success, err)
        if not success then
            Framework.Notify(err or Locale("notify.failed_hand_over"), 'error')
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
                Framework.Notify(err or Locale("notify.failed_start"), 'error')
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

-- Admin mission editor: pure server forwarders — each server callback re-checks Framework.IsAdmin itself.

RegisterNUICallback('adminListOrders', function(_, cb)
    lib.callback('polarix_trucker:adminListOrders', false, function(orders)
        cb({ ok = true, orders = orders or {} })
    end)
end)

RegisterNUICallback('adminCreateOrder', function(data, cb)
    lib.callback('polarix_trucker:adminCreateOrder', false, function(success, result)
        if not success then
            Framework.Notify(result or Locale("notify.failed_create"), 'error')
        end
        cb({ ok = success, orderId = success and result or nil, err = not success and result or nil })
    end, data.order)
end)

RegisterNUICallback('adminUpdateOrder', function(data, cb)
    lib.callback('polarix_trucker:adminUpdateOrder', false, function(success, err)
        if not success then
            Framework.Notify(err or Locale("notify.failed_save"), 'error')
        end
        cb({ ok = success, err = not success and err or nil })
    end, data.orderId, data.order)
end)

RegisterNUICallback('adminSetOrderActive', function(data, cb)
    lib.callback('polarix_trucker:adminSetOrderActive', false, function(success, err)
        if not success then
            Framework.Notify(err or Locale("notify.error"), 'error')
        end
        cb({ ok = success })
    end, data.orderId, data.isActive)
end)

RegisterNUICallback('adminDeleteOrder', function(data, cb)
    lib.callback('polarix_trucker:adminDeleteOrder', false, function(success, err)
        if not success then
            Framework.Notify(err or Locale("notify.failed_delete"), 'error')
        end
        cb({ ok = success, err = not success and err or nil })
    end, data.orderId)
end)

RegisterNUICallback('adminForceDeleteOrder', function(data, cb)
    lib.callback('polarix_trucker:adminForceDeleteOrder', false, function(success, err)
        if not success then
            Framework.Notify(err or Locale("notify.failed_delete"), 'error')
        end
        cb({ ok = success, err = not success and err or nil })
    end, data.orderId)
end)

RegisterNUICallback('adminCloneOrder', function(data, cb)
    lib.callback('polarix_trucker:adminCloneOrder', false, function(success, result)
        if not success then
            Framework.Notify(result or Locale("notify.failed_duplicate"), 'error')
        end
        cb({ ok = success, order = success and result or nil })
    end, data.orderId)
end)

RegisterNUICallback('adminImportSampleMissions', function(_, cb)
    lib.callback('polarix_trucker:adminImportSampleMissions', false, function(success)
        cb({ ok = success })
    end)
end)

-- A successful test run starts the delivery immediately for the admin (same path as acceptOrder).
RegisterNUICallback('adminTestRunOrder', function(data, cb)
    lib.callback('polarix_trucker:adminTestRunOrder', false, function(success, result)
        if success then
            Delivery.Start(result)
        else
            Framework.Notify(result or Locale("notify.test_failed"), 'error')
        end
        cb({ ok = success })
    end, data.orderId)
end)
