local clientConfig = require("config.client")

LocalTrailer = {
    entity = nil,
    slot   = nil,
    model  = nil,
}

Trailer = {}

local function findFreeTrailerSpawnPoint()
    local points = clientConfig.TrailerSpawnPoints
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

function Trailer.Spawn()
    if not LocalTrailer.model then return end

    Trailer.Despawn()

    local coords    = findFreeTrailerSpawnPoint()
    local modelHash = GetHashKey(LocalTrailer.model)

    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 100 do
        Wait(100)
        timeout = timeout + 1
    end
    if not HasModelLoaded(modelHash) then
        Framework.Notify("Trailer-Modell konnte nicht geladen werden.", "error")
        return
    end

    local trailer = CreateVehicle(modelHash, coords.x, coords.y, coords.z, coords.w, true, false)
    SetEntityAsMissionEntity(trailer, true, true)
    SetModelAsNoLongerNeeded(modelHash)
    LocalTrailer.entity = trailer

    if LocalVehicle.entity and DoesEntityExist(LocalVehicle.entity) then
        AttachVehicleToTrailer(LocalVehicle.entity, trailer, 15.0)
    end

    SendMessage("trailerSpawnState", { slot = LocalTrailer.slot, spawned = true })
end

function Trailer.Despawn()
    if LocalTrailer.entity and DoesEntityExist(LocalTrailer.entity) then
        if NetworkGetEntityIsNetworked(LocalTrailer.entity) then
            local netId = NetworkGetNetworkIdFromEntity(LocalTrailer.entity)
            if ForkliftDockState and ForkliftDockState[netId] then
                local dock = ForkliftDockState[netId]
                if dock.entity and DoesEntityExist(dock.entity) then
                    DeleteEntity(dock.entity)
                end
                ForkliftDockState[netId] = nil
            end
        end

        if CleanupMissionPalletsOnTrailer then
            CleanupMissionPalletsOnTrailer()
        end

        DeleteEntity(LocalTrailer.entity)
    end
    LocalTrailer.entity = nil
    SendMessage("trailerSpawnState", { slot = LocalTrailer.slot, spawned = false })
end

RegisterNetEvent("polarix_trucker:trailerEquipped", function(trailerSlot, trailerModel)
    LocalTrailer.slot  = trailerSlot
    LocalTrailer.model = trailerModel
    Trailer.Spawn()
end)

RegisterNetEvent("polarix_trucker:trailerSync", function(trailerSlot, trailerModel)
    LocalTrailer.slot  = trailerSlot
    LocalTrailer.model = trailerModel
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    Trailer.Despawn()
end)

CreateThread(function()
    Wait(500)
    SendMessage("trailerSpawnState", { slot = nil, spawned = false })
end)
