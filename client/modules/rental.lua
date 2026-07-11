local clientConfig = require("config.client")
local sharedConfig = require("config.shared")
local Locale = require("shared.locale")

LocalRental = {
    vehicleEntity = nil,
    trailerEntity = nil,
}

Rental = {}

local function findFreeSpawnPoint(points)
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

local function spawnModelAt(model, coords)
    local modelHash = GetHashKey(model)
    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 100 do
        Wait(100)
        timeout = timeout + 1
    end
    if not HasModelLoaded(modelHash) then return nil end

    local entity = CreateVehicle(modelHash, coords.x, coords.y, coords.z, coords.w, true, false)
    SetEntityAsMissionEntity(entity, true, true)
    SetModelAsNoLongerNeeded(modelHash)
    return entity
end

-- mode is passed through so rentBundle triggers the right follow-up callback
-- (acceptOrder/startPartyMission) instead of always treating it as solo.
function Rental.OfferInline(orderId, mode)
    SendMessage("showRentalPrompt", {
        orderId = orderId,
        mode = mode or "solo",
        vehicleName = sharedConfig.Rental.VehicleName,
        trailerName = sharedConfig.Rental.TrailerName,
        intervalCost = sharedConfig.Rental.IntervalCost,
        intervalMinutes = sharedConfig.Rental.IntervalMinutes,
    })
end

function Rental.Despawn()
    if LocalRental.trailerEntity and DoesEntityExist(LocalRental.trailerEntity) then
        DeleteEntity(LocalRental.trailerEntity)
    end
    if LocalRental.vehicleEntity and DoesEntityExist(LocalRental.vehicleEntity) then
        DeleteEntity(LocalRental.vehicleEntity)
    end
    LocalRental.vehicleEntity = nil
    LocalRental.trailerEntity = nil
end

RegisterNetEvent("polarix_trucker:rentalStarted", function(vehicleModel, trailerModel)
    Rental.Despawn()

    local vehCoords = findFreeSpawnPoint(clientConfig.VehicleSpawnPoints)
    local vehEntity = spawnModelAt(vehicleModel, vehCoords)
    if not vehEntity then
        Framework.Notify(Locale("notify.failed_load_rental_vehicle"), "error")
        return
    end
    SetVehicleNumberPlateText(vehEntity, "RENTAL")
    LocalRental.vehicleEntity = vehEntity

    local trailerCoords = GetOffsetFromEntityInWorldCoords(vehEntity, 0.0, -12.0, 0.0)
    trailerCoords = vector4(trailerCoords.x, trailerCoords.y, trailerCoords.z, GetEntityHeading(vehEntity))
    local trailerEntity = spawnModelAt(trailerModel, trailerCoords)
    if trailerEntity then
        AttachVehicleToTrailer(vehEntity, trailerEntity, 15.0)
        LocalRental.trailerEntity = trailerEntity
    end

    -- Order matters: enter before giving keys (like Vehicle.Spawn) — some key systems
    -- (qbx_vehiclekeys) bind keys to the currently seated driver.
    if clientConfig.TeleportIntoVehicle then
        TaskWarpPedIntoVehicle(PlayerPedId(), vehEntity, -1)
    end
    Framework.GiveVehicleKeys(vehEntity, "RENTAL")

    Framework.Notify(Locale("notify.rental_vehicle_picked_up_rent"), "success")
end)

RegisterNetEvent("polarix_trucker:rentalCharged", function(amount)
    Framework.Notify(Locale("notify.rent_charged"):format(amount), "info")
end)

RegisterNetEvent("polarix_trucker:rentalEnded", function(reason)
    Rental.Despawn()

    if reason == "returned" then
        Framework.Notify(Locale("notify.rental_returned"), "info")
    else
        Framework.Notify(Locale("notify.rental_vehicle_repossessed"):format(reason), "error")
        -- Server already triggered Orders.Fail for an active delivery — just sync client state here,
        -- don't send failDelivery again.
        if DeliveryState.status ~= "idle" then
            Delivery.HUD.Stop()
            if DeliveryState.pickupBlip then RemoveBlip(DeliveryState.pickupBlip) end
            if DeliveryState.dropoffBlip then RemoveBlip(DeliveryState.dropoffBlip) end
            DeliveryState.pickupBlip = nil
            DeliveryState.dropoffBlip = nil
            DeliveryState.status = "idle"
            DeliveryState.orderData = nil
            DeliveryState.cargoDamage = nil
        end
    end
end)

RegisterCommand("returnrental", function()
    if not LocalRental.vehicleEntity then
        Framework.Notify(Locale("notify.no_active_rental"), "error")
        return
    end
    TriggerServerEvent("polarix_trucker:returnRental")
end, false)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    Rental.Despawn()
end)
