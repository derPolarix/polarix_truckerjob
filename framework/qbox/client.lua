 return {
    GetPlayerData = function()
        return exports.qbx_core:GetPlayerData()
    end,

    GetMoney = function()
        return exports.qbx_core:GetPlayerData().money.bank
    end,

    -- Fahrzeugschlüssel vergeben (qbx_vehiclekeys — server-side API, Bridge via Server-Event)
    GiveVehicleKeys = function(vehicle, _plate)
        if GetResourceState("qbx_vehiclekeys") == "started" then
            TriggerServerEvent("polarix_trucker:giveVehicleKeys", NetworkGetNetworkIdFromEntity(vehicle))
        end
    end,
}
