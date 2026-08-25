local Locale = require("shared.locale")
local sharedConfig = require("config.shared")

LocalTrailer = {
    entity = nil,
    slot   = nil,
    model  = nil,
}

Trailer = {}

-- Trailer in play can come from either an owned trailer (LocalTrailer) or an
-- active rental (LocalRental) — callers that need "whatever trailer the player
-- currently has" should go through this instead of reading LocalTrailer.entity directly.
function GetActiveTrailer()
    if LocalTrailer.entity and DoesEntityExist(LocalTrailer.entity) then
        return LocalTrailer.entity
    end
    if LocalRental and LocalRental.trailerEntity and DoesEntityExist(LocalRental.trailerEntity) then
        return LocalRental.trailerEntity
    end
    return nil
end

-- Spawn point is derived from the vehicle since AttachVehicleToTrailer immediately
-- snaps the trailer to the hitch anyway — it's never parked standalone.
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
        Framework.Notify(Locale("notify.failed_load_trailer_model"), "error")
        return
    end

    local trailer = CreateVehicle(modelHash, coords.x, coords.y, coords.z, heading, true, false)
    SetEntityAsMissionEntity(trailer, true, true)
    SetModelAsNoLongerNeeded(modelHash)

    LocalTrailer.entity = trailer

    AttachVehicleToTrailer(LocalVehicle.entity, trailer, 15.0)

    -- Must run after attach — the game re-rolls trailer livery at hitch time,
    -- so setting it before attach gets silently overwritten.
    local trailerConfig = sharedConfig.CompatibleTrailers[LocalTrailer.model]
    if trailerConfig and trailerConfig.livery then
        SetVehicleLivery(trailer, trailerConfig.livery)
    end

    -- extras is an enable-list: ids in it are forced on, everything else forced off.
    -- SetVehicleExtra no-ops for extra ids the model doesn't have, so 0-20 safely covers any trailer.
    if trailerConfig and trailerConfig.extras then
        local enabledExtras = {}
        for _, extraId in ipairs(trailerConfig.extras) do
            enabledExtras[extraId] = true
        end
        for extraId = 0, 20 do
            SetVehicleExtra(trailer, extraId, not enabledExtras[extraId])
        end
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

-- UI-triggered "Park trailer" action — same mid-delivery guard as Vehicle.Park().
function Trailer.Park()
    if DeliveryState.status ~= "idle" then
        Framework.Notify(Locale("notify.cannot_park_during_delivery"), "error")
        return false
    end
    Trailer.Despawn()
    Framework.Notify(Locale("notify.trailer_parked"), "success")
    return true
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
