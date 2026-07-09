LocalTrailer = {
    entity = nil,
    slot   = nil,
    model  = nil,
}

Trailer = {}

-- Trailer wird immer zusammen mit dem Fahrzeug geparkt (nie alleine) — Spawn-Punkt ergibt sich
-- direkt aus der Fahrzeugposition, da AttachVehicleToTrailer ihn ohnehin sofort an die Anhängerkupplung snappt.
function Trailer.Spawn()
    if not LocalTrailer.model then return end
    if not (LocalVehicle.entity and DoesEntityExist(LocalVehicle.entity)) then return end

    Trailer.Despawn()

    local coords    = GetOffsetFromEntityInWorldCoords(LocalVehicle.entity, 0.0, -12.0, 0.0)
    local heading   = GetEntityHeading(LocalVehicle.entity)
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

    local trailer = CreateVehicle(modelHash, coords.x, coords.y, coords.z, heading, true, false)
    SetEntityAsMissionEntity(trailer, true, true)
    SetModelAsNoLongerNeeded(modelHash)
    LocalTrailer.entity = trailer

    AttachVehicleToTrailer(LocalVehicle.entity, trailer, 15.0)

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
