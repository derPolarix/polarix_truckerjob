local clientConfig = require("config.client")

LocalVehicle = {
    entity = nil,
    slot   = nil,
    model  = nil,
}

Vehicle = {}

function Vehicle.Spawn()
    if not LocalVehicle.model then
        Framework.Notify("Kein Fahrzeug ausgewählt.", "error")
        return
    end

    Vehicle.Despawn()

    local coords    = clientConfig.VehicleSpawnCoords
    local modelHash = GetHashKey(LocalVehicle.model)

    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 100 do
        Wait(100)
        timeout = timeout + 1
    end
    if not HasModelLoaded(modelHash) then
        Framework.Notify("Fahrzeugmodell konnte nicht geladen werden.", "error")
        return
    end

    local veh = CreateVehicle(modelHash, coords.x, coords.y, coords.z, coords.w, true, false)
    SetVehicleNumberPlateText(veh, "TRUCKER")
    SetEntityAsMissionEntity(veh, true, true)
    SetModelAsNoLongerNeeded(modelHash)

    TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
    Framework.GiveVehicleKeys(veh, "TRUCKER")

    LocalVehicle.entity = veh
    Framework.Notify("Fahrzeug abgeholt!", "success")
end

function Vehicle.Despawn()
    if LocalVehicle.entity and DoesEntityExist(LocalVehicle.entity) then
        DeleteEntity(LocalVehicle.entity)
    end
    LocalVehicle.entity = nil
end

-- Ausgerüstetes Fahrzeug wechseln (nach Equip-Aktion in der UI — Player ist am Depot → direkt spawnen)
RegisterNetEvent("polarix_trucker:vehicleEquipped", function(vehicleSlot, vehicleModel)
    LocalVehicle.slot  = vehicleSlot
    LocalVehicle.model = vehicleModel
    Vehicle.Spawn()
end)

-- Fahrzeug-Sync beim Login (wenn equipped_vehicle bereits in DB gesetzt war)
RegisterNetEvent("polarix_trucker:vehicleSync", function(vehicleSlot, vehicleModel)
    LocalVehicle.slot  = vehicleSlot
    LocalVehicle.model = vehicleModel
end)

-- Fahrzeug am Depot abholen
RegisterCommand("getruck", function()
    if not LocalVehicle.slot then
        Framework.Notify("Kein Fahrzeug ausgewählt.", "error")
        return
    end
    local depotPos  = clientConfig.TruckDepotCoords
    local playerPos = GetEntityCoords(PlayerPedId())
    if #(playerPos - vector3(depotPos.x, depotPos.y, depotPos.z)) > 30.0 then
        Framework.Notify("Du musst am Depot sein, um dein Fahrzeug abzuholen.", "error")
        return
    end
    Vehicle.Spawn()
end, false)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    Vehicle.Despawn()
end)
