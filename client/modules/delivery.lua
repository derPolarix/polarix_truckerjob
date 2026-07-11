local cargo = require("shared.cargo")
local Locale = require("shared.locale")

DeliveryState = {
    status = "idle", -- idle | awaiting_pickup | delivering
    mode = "solo", -- solo | party
    orderData = nil,
    pickupBlip = nil,
    dropoffBlip = nil,
    cargoDamage = nil,
}

Delivery = {}

local function ClearBlips()
    if DeliveryState.pickupBlip then RemoveBlip(DeliveryState.pickupBlip) end
    if DeliveryState.dropoffBlip then RemoveBlip(DeliveryState.dropoffBlip) end
    DeliveryState.pickupBlip = nil
    DeliveryState.dropoffBlip = nil
end

local function CreateBlip(x, y, z, sprite, color, name)
    local blip = AddBlipForCoord(x, y, z)
    SetBlipSprite(blip, sprite)
    SetBlipColour(blip, color)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(name)
    EndTextCommandSetBlipName(blip)
    return blip
end

-- Public wrapper: ClearBlips/DeliveryState are module-local, but party_mission.lua
-- (separate chunk) also needs this full cleanup.
function Delivery.Reset()
    ClearBlips()
    if ResetMissionCargo then ResetMissionCargo(nil) end
    DeliveryState.status = "idle"
    DeliveryState.orderData = nil
    DeliveryState.cargoDamage = nil
end

function Delivery.Start(orderData, mode)
    DeliveryState.status = "awaiting_pickup"
    DeliveryState.mode = mode or "solo"
    DeliveryState.orderData = orderData

    DeliveryState.pickupBlip  = CreateBlip(orderData.pickup_x, orderData.pickup_y, orderData.pickup_z, 1, 2, "Pickup: " .. orderData.pickup_label)
    DeliveryState.dropoffBlip = CreateBlip(orderData.dropoff_x, orderData.dropoff_y, orderData.dropoff_z, 1, 1, "Drop-off: " .. orderData.dropoff_label)

    SetBlipRoute(DeliveryState.pickupBlip, true)
    SetBlipRouteColour(DeliveryState.pickupBlip, 5)

    if ResetMissionCargo then ResetMissionCargo(orderData) end
    Delivery.HUD.Start()

    Framework.Notify(Locale("notify.drive_pickup_point_pallets_total"):format(orderData.pickup_label, cargo.CalcPalletCount(orderData.weight_kg)), "info")
end

-- Solo uses its own order pool, party shares one.
function Delivery.RequestTripClaim()
    local eventName = DeliveryState.mode == "party" and "polarix_trucker:claimPartyPallets" or "polarix_trucker:claimTripPallets"
    return lib.callback.await(eventName, false)
end

function Delivery.Cancel()
    ClearBlips()
    if ResetMissionCargo then ResetMissionCargo(nil) end
    DeliveryState.status = "idle"
    DeliveryState.orderData = nil
    TriggerServerEvent("polarix_trucker:failDelivery")
    Framework.Notify(Locale("notify.delivery_cancelled"), "error")
end

function Delivery.EnterTransitPhase()
    if DeliveryState.status ~= "awaiting_pickup" then return end

    DeliveryState.status = "delivering"
    DeliveryState.cargoDamage = 0

    SetBlipRoute(DeliveryState.pickupBlip, false)
    SetBlipRoute(DeliveryState.dropoffBlip, true)
    SetBlipRouteColour(DeliveryState.dropoffBlip, 5)

    Framework.Notify(Locale("notify.drive_drop_off"):format(DeliveryState.orderData.dropoff_label), "success")

    if LocalVehicle.entity and DoesEntityExist(LocalVehicle.entity) then
        Delivery.StartDamageMonitor(LocalVehicle.entity)
    end
end

local SPEED_LIMIT_FRAGILE = 25.0 -- m/s ≈ 90 km/h
local SPEED_LIMIT_LIVE    = 20.0 -- m/s ≈ 72 km/h

local isUnloading = false

function Delivery.StartUnloading()
    if isUnloading then return end
    if DeliveryState.status ~= "delivering" then return end
    if not IsTrailerParkedCorrectly(DeliveryState.orderData) then
        Framework.Notify(Locale("notify.trailer_not_parked_correctly"), "error")
        return
    end

    isUnloading = true

    local o = DeliveryState.orderData
    local success = lib.progressCircle({
        duration = 8000,
        position = "bottom",
        label = Locale("ui.unloading_cargo"):format(o.name),
        useWhileDead = false,
        canCancel = false,
        disable = { car = true, combat = true },
        anim = { dict = "anim@heists@box_carry@", clip = "idle" },
    })

    isUnloading = false

    if success then
        Delivery.HUD.Stop()
        Delivery.StopDamageMonitor()
        if DeliveryState.mode == "party" then
            TriggerServerEvent("polarix_trucker:completePartyTrip", MissionCargo.loadedCount, DeliveryState.cargoDamage)
        else
            TriggerServerEvent("polarix_trucker:completeTrip", MissionCargo.loadedCount, DeliveryState.cargoDamage)
        end
    end
end

-- Monitors vehicle health + speed for fragile/live cargo damage
function Delivery.StartDamageMonitor(veh)
    local o = DeliveryState.orderData
    local isSensitive = o.cargo_type == "fragile" or o.cargo_type == "live"
    local speedLimit = o.cargo_type == "live" and SPEED_LIMIT_LIVE or SPEED_LIMIT_FRAGILE
    local prevHealth = GetVehicleBodyHealth(veh)

    CreateThread(function()
        while DeliveryState.status == "delivering" do
            Wait(2000)
            if not DoesEntityExist(veh) then
                Delivery.ForceFailure(Locale("notify.vehicle_destroyed"))
                break
            end

            local engineHealth = GetVehicleEngineHealth(veh)
            if engineHealth < 100.0 then
                Delivery.ForceFailure(Locale("notify.vehicle_too_badly_damaged"))
                break
            end

            local trailerEntity = GetActiveTrailer()
            if trailerEntity then
                if not DoesEntityExist(trailerEntity) then
                    Delivery.ForceFailure(Locale("notify.trailer_destroyed"))
                    break
                elseif GetVehicleTrailerVehicle(veh) ~= trailerEntity then
                    Delivery.ForceFailure(Locale("notify.trailer_detached"))
                    break
                end
            end

            if isSensitive then
                local speed = GetEntitySpeed(veh)
                if speed > speedLimit then
                    local excess = speed - speedLimit
                    local rawDamage = math.floor(excess * 50)
                    local modifier = Skills.GetDamageModifier()
                    local damage = math.floor(rawDamage * modifier)
                    DeliveryState.cargoDamage = DeliveryState.cargoDamage + damage

                    if DeliveryState.cargoDamage > 500 then
                        Framework.Notify(Locale("notify.cargo_taking_damage_slow_down"), "error")
                    end

                    local maxDamage = DeliveryState.orderData.reward_base * 0.30
                    if DeliveryState.cargoDamage >= maxDamage then
                        Delivery.ForceFailure(Locale("notify.cargo_too_badly_damaged"))
                        break
                    end
                end
            end

            local currentHealth = GetVehicleBodyHealth(veh)
            if prevHealth - currentHealth > 150 and isSensitive then
                DeliveryState.cargoDamage = DeliveryState.cargoDamage + 200
            end
            prevHealth = currentHealth
        end
    end)
end

function Delivery.StopDamageMonitor()
    -- no-op: the monitor thread exits on its own once status leaves "delivering"
end

function Delivery.ForceFailure(reason)
    if DeliveryState.status == "idle" then return end
    Delivery.HUD.Stop()
    ClearBlips()
    if ResetMissionCargo then ResetMissionCargo(nil) end
    DeliveryState.status = "idle"
    DeliveryState.orderData = nil
    DeliveryState.cargoDamage = nil
    TriggerServerEvent("polarix_trucker:failDelivery")
    Framework.Notify(Locale("notify.delivery_failed"):format(reason), "error")
end

RegisterNetEvent("polarix_trucker:deliveryCompleted", function(reward, xp, damagePenalty, companyTax)
    Delivery.Reset()

    local msg = Locale("notify.delivery_completed_xp"):format(reward, xp)
    if damagePenalty and damagePenalty > 0 then
        msg = msg .. Locale("notify.damage_deduction"):format(damagePenalty)
    end
    if companyTax and companyTax > 0 then
        msg = msg .. Locale("notify.company_tax"):format(companyTax)
    end
    Framework.Notify(msg, "success")
    SendMessage("deliveryComplete", { reward = reward, xp = xp })
end)

-- Trip delivered but order pool not empty yet — head back to pickup for the next trip
RegisterNetEvent("polarix_trucker:tripSettled", function(remainingPallets)
    DeliveryState.status = "awaiting_pickup"
    SetBlipRoute(DeliveryState.dropoffBlip, false)
    SetBlipRoute(DeliveryState.pickupBlip, true)
    SetBlipRouteColour(DeliveryState.pickupBlip, 5)
    Framework.Notify(Locale("notify.trip_delivered_pallets_left_pool"):format(remainingPallets), "info")
end)

RegisterNetEvent("polarix_trucker:staleFailed", function()
    Framework.Notify(Locale("notify.last_delivery_marked_as_cancelled"), "info")
end)

-- Disconnect/resource stop during an active delivery auto-fails it on next join (server-side CleanupStaleDelivery)
AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    if DeliveryState.status ~= "idle" then
        TriggerServerEvent("polarix_trucker:failDelivery")
    end
end)
