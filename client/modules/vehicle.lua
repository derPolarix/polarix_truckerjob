local clientConfig = require("config.client")
local Locale = require("shared.locale")

LocalVehicle = {
    entity = nil,
    slot   = nil,
    model  = nil,
}

Vehicle = {}

-- Wählt zufällig einen freien Spawn-Punkt (kein Fahrzeug innerhalb von 6 Einheiten).
-- Fallback: erster Punkt der gemischten Liste wenn alle belegt.
local function findFreeSpawnPoint()
    local points = clientConfig.VehicleSpawnPoints
    -- Fisher-Yates shuffle auf Kopie
    local candidates = {}
    for i = 1, #points do candidates[i] = points[i] end
    for i = #candidates, 2, -1 do
        local j = math.random(i)
        candidates[i], candidates[j] = candidates[j], candidates[i]
    end

    local vehicles = GetGamePool("CVehicle")
    for _, point in ipairs(candidates) do
        local free = true
        for _, veh in ipairs(vehicles) do
            local pos = GetEntityCoords(veh)
            if #(pos - vector3(point.x, point.y, point.z)) < 6.0 then
                free = false
                break
            end
        end
        if free then return point end
    end
    return candidates[1]
end

function Vehicle.Spawn()
    if not LocalVehicle.model then
        Framework.Notify(Locale("notify.no_vehicle_selected"), "error")
        return
    end

    Vehicle.Despawn()

    local coords    = findFreeSpawnPoint()
    local modelHash = GetHashKey(LocalVehicle.model)

    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 100 do
        Wait(100)
        timeout = timeout + 1
    end
    if not HasModelLoaded(modelHash) then
        Framework.Notify(Locale("notify.failed_load_vehicle_model"), "error")
        return
    end

    local veh = CreateVehicle(modelHash, coords.x, coords.y, coords.z, coords.w, true, false)
    SetVehicleNumberPlateText(veh, "TRUCKER")
    SetEntityAsMissionEntity(veh, true, true)
    SetModelAsNoLongerNeeded(modelHash)

    if clientConfig.TeleportIntoVehicle then
        TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
    end
    Framework.GiveVehicleKeys(veh, "TRUCKER")

    LocalVehicle.entity = veh
    Framework.Notify(Locale("notify.vehicle_picked_up"), "success")
    SendMessage("vehicleSpawnState", { slot = LocalVehicle.slot, spawned = true })
end

function Vehicle.Despawn()
    if LocalVehicle.entity and DoesEntityExist(LocalVehicle.entity) then
        DeleteEntity(LocalVehicle.entity)
    end
    LocalVehicle.entity = nil
    SendMessage("vehicleSpawnState", { slot = LocalVehicle.slot, spawned = false })
end

CreateThread(function()
    Wait(500)
    SendMessage("vehicleSpawnState", { slot = nil, spawned = false })
end)

-- Ausgerüstetes Fahrzeug wechseln (nach Equip-Aktion in der UI — Player ist am Depot → direkt spawnen)
RegisterNetEvent("polarix_trucker:vehicleEquipped", function(vehicleSlot, vehicleModel)
    LocalVehicle.slot  = vehicleSlot
    LocalVehicle.model = vehicleModel
    Vehicle.Spawn()

    if LocalTrailer.model then
        Trailer.Spawn()
    end
end)

-- Fahrzeug-Sync beim Login (wenn equipped_vehicle bereits in DB gesetzt war)
RegisterNetEvent("polarix_trucker:vehicleSync", function(vehicleSlot, vehicleModel)
    LocalVehicle.slot  = vehicleSlot
    LocalVehicle.model = vehicleModel
end)

-- Fahrzeug am Depot abholen
RegisterCommand("getruck", function()
    if not LocalVehicle.slot then
        Framework.Notify(Locale("notify.no_vehicle_selected"), "error")
        return
    end
    local depotPos  = clientConfig.TruckDepotCoords
    local playerPos = GetEntityCoords(PlayerPedId())
    if #(playerPos - vector3(depotPos.x, depotPos.y, depotPos.z)) > 30.0 then
        Framework.Notify(Locale("notify.must_depot_pick_up_vehicle"), "error")
        return
    end
    Vehicle.Spawn()

    if LocalTrailer.model then
        Trailer.Spawn()
    else
        Framework.Notify(Locale("notify.no_trailer_equipped"), "error")
    end
end, false)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    Vehicle.Despawn()
end)
