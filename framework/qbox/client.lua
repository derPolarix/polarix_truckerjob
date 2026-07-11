 return {
    GetPlayerData = function()
        return exports.qbx_core:GetPlayerData()
    end,

    GetMoney = function()
        return exports.qbx_core:GetPlayerData().money.bank
    end,

    -- qbx_vehiclekeys is a server-side API, so bridge via a server event
    GiveVehicleKeys = function(vehicle, _plate)
        if GetResourceState("qbx_vehiclekeys") == "started" then
            TriggerServerEvent("polarix_trucker:giveVehicleKeys", NetworkGetNetworkIdFromEntity(vehicle))
        end
    end,
}
