local clientConfig = require("config.client")
local sharedConfig = require("config.shared")

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

-- Öffnet den Rental-Bestätigungsdialog in der NUI (siehe App.vue "showRentalPrompt" + RentalPromptModal.vue).
-- Bestätigung/Ablehnung läuft vollständig über NUI-Callbacks (nui_callbacks.lua "rentBundle").
function Rental.OfferInline(orderId)
    SendMessage("showRentalPrompt", {
        orderId = orderId,
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
        Framework.Notify("Rental-Fahrzeug konnte nicht geladen werden.", "error")
        return
    end
    SetVehicleNumberPlateText(vehEntity, "RENTAL")
    Framework.GiveVehicleKeys(vehEntity, "RENTAL")
    LocalRental.vehicleEntity = vehEntity

    local trailerCoords = findFreeSpawnPoint(clientConfig.TrailerSpawnPoints)
    local trailerEntity = spawnModelAt(trailerModel, trailerCoords)
    if trailerEntity then
        AttachVehicleToTrailer(vehEntity, trailerEntity, 15.0)
        LocalRental.trailerEntity = trailerEntity
    end

    if clientConfig.TeleportIntoVehicle then
        TaskWarpPedIntoVehicle(PlayerPedId(), vehEntity, -1)
    end

    Framework.Notify("Rental-Fahrzeug abgeholt! Es wird laufend Miete abgebucht.", "success")
end)

RegisterNetEvent("polarix_trucker:rentalCharged", function(amount)
    Framework.Notify(("Miete abgebucht: $%s"):format(amount), "info")
end)

RegisterNetEvent("polarix_trucker:rentalEnded", function(reason)
    Rental.Despawn()

    if reason == "returned" then
        Framework.Notify("Rental zurückgegeben.", "info")
    else
        Framework.Notify("Dein Mietfahrzeug wurde eingezogen: " .. reason, "error")
        -- Server hat bei aktiver Delivery bereits Orders.Fail ausgelöst — hier nur Client-State nachziehen,
        -- ohne erneut failDelivery zu senden.
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
        Framework.Notify("Kein aktives Rental.", "error")
        return
    end
    TriggerServerEvent("polarix_trucker:returnRental")
end, false)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    Rental.Despawn()
end)
