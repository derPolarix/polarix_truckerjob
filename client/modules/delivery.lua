DeliveryState = {
    status = "idle", -- idle | awaiting_pickup | delivering
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

function Delivery.Start(orderData)
    DeliveryState.status = "awaiting_pickup"
    DeliveryState.orderData = orderData

    DeliveryState.pickupBlip  = CreateBlip(orderData.pickup_x, orderData.pickup_y, orderData.pickup_z, 1, 2, "Pickup: " .. orderData.pickup_label)
    DeliveryState.dropoffBlip = CreateBlip(orderData.dropoff_x, orderData.dropoff_y, orderData.dropoff_z, 1, 1, "Drop-off: " .. orderData.dropoff_label)

    SetNewWaypoint(orderData.pickup_x, orderData.pickup_y)
    Framework.Notify("Fahre zur Abholstelle: " .. orderData.pickup_label, "info")
end

function Delivery.Cancel()
    ClearBlips()
    DeliveryState.status = "idle"
    DeliveryState.orderData = nil
    TriggerServerEvent("polarix_trucker:failDelivery")
    Framework.Notify("Lieferung abgebrochen.", "error")
end

local PICKUP_RADIUS  = 12.0
local DROPOFF_RADIUS = 12.0
local ZONE_CHECK_MS  = 500

local SPEED_LIMIT_FRAGILE = 25.0 -- m/s ≈ 90 km/h
local SPEED_LIMIT_LIVE    = 20.0 -- m/s ≈ 72 km/h

local isLoading = false
local promptVisible = false

local function IsInTruck()
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh == 0 then return false end
    local cls = GetVehicleClass(veh)
    -- Commercial (Hauler/Packer/Phantom) + Industrial (Flatbed/Mixer) Trucks
    return cls == 20 or cls == 10
end

function Delivery.ShowPickupPrompt()
    if promptVisible then return end
    promptVisible = true
    lib.showTextUI("[E] Cargo aufnehmen", { position = "bottom-center", icon = "box-open" })
end

function Delivery.ShowDropoffPrompt()
    if promptVisible then return end
    promptVisible = true
    lib.showTextUI("[E] Cargo abliefern", { position = "bottom-center", icon = "flag-checkered" })
end

function Delivery.HidePrompt()
    if not promptVisible then return end
    promptVisible = false
    lib.hideTextUI()
end

-- Zone-Check (Proximity-Thread, ersetzt simplen Distanz-Check aus Phase 3)
CreateThread(function()
    while true do
        Wait(ZONE_CHECK_MS)
        if DeliveryState.status ~= "idle" and DeliveryState.orderData then
            local o   = DeliveryState.orderData
            local pos = GetEntityCoords(PlayerPedId())

            if DeliveryState.status == "awaiting_pickup" then
                local dist = #(pos - vector3(o.pickup_x, o.pickup_y, o.pickup_z))
                if dist < PICKUP_RADIUS and not isLoading then
                    Delivery.ShowPickupPrompt()
                else
                    Delivery.HidePrompt()
                end
            elseif DeliveryState.status == "delivering" then
                local dist = #(pos - vector3(o.dropoff_x, o.dropoff_y, o.dropoff_z))
                if dist < DROPOFF_RADIUS and not isLoading then
                    Delivery.ShowDropoffPrompt()
                else
                    Delivery.HidePrompt()
                end
            end
        end
    end
end)

-- Marker-Render-Thread (läuft nur bei aktiver Delivery)
CreateThread(function()
    while true do
        Wait(0)
        if DeliveryState.status == "awaiting_pickup" and DeliveryState.orderData then
            local o = DeliveryState.orderData
            DrawMarker(2, o.pickup_x, o.pickup_y, o.pickup_z, 0, 0, 0, 0, 0, 0, 2.0, 2.0, 1.0, 47, 199, 114, 150, false, true, 2, nil, nil, false)
        elseif DeliveryState.status == "delivering" and DeliveryState.orderData then
            local o = DeliveryState.orderData
            DrawMarker(2, o.dropoff_x, o.dropoff_y, o.dropoff_z, 0, 0, 0, 0, 0, 0, 2.0, 2.0, 1.0, 210, 75, 58, 150, false, true, 2, nil, nil, false)
        else
            Wait(450) -- spart Frames, wenn keine Delivery aktiv ist
        end
    end
end)

-- Key-Handler für E im Nahbereich
CreateThread(function()
    while true do
        Wait(0)
        if IsControlJustReleased(0, 38) then -- E
            if DeliveryState.status == "awaiting_pickup" and promptVisible and not isLoading then
                Delivery.StartLoading()
            elseif DeliveryState.status == "delivering" and promptVisible and not isLoading then
                Delivery.StartUnloading()
            end
        end
    end
end)

-- Ladezeit in Sekunden basierend auf Gewicht
local function CalcLoadingTime(weightKg)
    local base = 8 -- Sekunden
    local perTon = 1.5
    return math.min(base + math.floor(weightKg / 1000) * perTon, 45)
end

function Delivery.StartLoading()
    if not IsInTruck() then
        Framework.Notify("Du musst im Fahrzeug sitzen!", "error")
        return
    end
    isLoading = true
    Delivery.HidePrompt()

    local o = DeliveryState.orderData
    local duration = CalcLoadingTime(o.weight_kg) * 1000 -- ms

    -- Fahrzeug blockieren bis Laden fertig
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    SetVehicleEngineOn(veh, false, true, false)

    local success = lib.progressBar({
        duration = duration,
        label = "Cargo wird geladen: " .. o.name,
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, combat = true },
        anim = { dict = "anim@heists@box_carry@", clip = "idle" },
    })

    SetVehicleEngineOn(veh, true, true, false)
    isLoading = false

    if success then
        DeliveryState.status = "delivering"
        DeliveryState.cargoDamage = 0
        SetNewWaypoint(o.dropoff_x, o.dropoff_y)
        Framework.Notify("Cargo geladen! Fahre nach " .. o.dropoff_label, "success")
        Delivery.HUD.Start()
        Delivery.StartDamageMonitor(veh)
    else
        Framework.Notify("Laden abgebrochen.", "error")
    end
end

function Delivery.StartUnloading()
    if not IsInTruck() then
        Framework.Notify("Du musst im Fahrzeug sitzen!", "error")
        return
    end
    isLoading = true
    Delivery.HidePrompt()

    local o = DeliveryState.orderData

    local success = lib.progressBar({
        duration = 8000,
        label = "Cargo wird entladen: " .. o.name,
        useWhileDead = false,
        canCancel = false,
        disable = { car = true, combat = true },
        anim = { dict = "anim@heists@box_carry@", clip = "idle" },
    })

    isLoading = false

    if success then
        Delivery.HUD.Stop()
        Delivery.StopDamageMonitor()
        TriggerServerEvent("polarix_trucker:completeDelivery", DeliveryState.cargoDamage)
    end
end

-- Cargo-Schaden-System: überwacht Fahrzeug-Gesundheit + Geschwindigkeit für fragile/live Cargo
function Delivery.StartDamageMonitor(veh)
    local o = DeliveryState.orderData
    local isSensitive = o.cargo_type == "fragile" or o.cargo_type == "live"
    local speedLimit = o.cargo_type == "live" and SPEED_LIMIT_LIVE or SPEED_LIMIT_FRAGILE
    local prevHealth = GetVehicleBodyHealth(veh)

    CreateThread(function()
        while DeliveryState.status == "delivering" do
            Wait(2000)
            if not DoesEntityExist(veh) then
                Delivery.ForceFailure("Fahrzeug zerstört!")
                break
            end

            local engineHealth = GetVehicleEngineHealth(veh)
            if engineHealth < 100.0 then
                Delivery.ForceFailure("Fahrzeug zu stark beschädigt!")
                break
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
                        Framework.Notify("Cargo wird beschädigt! Langsamer fahren!", "error")
                    end

                    local maxDamage = DeliveryState.orderData.reward_base * 0.30
                    if DeliveryState.cargoDamage >= maxDamage then
                        Delivery.ForceFailure("Cargo zu stark beschädigt!")
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
    -- Thread endet selbständig, sobald DeliveryState.status nicht mehr "delivering" ist
end

function Delivery.ForceFailure(reason)
    if DeliveryState.status == "idle" then return end
    Delivery.HUD.Stop()
    Delivery.HidePrompt()
    ClearBlips()
    DeliveryState.status = "idle"
    DeliveryState.orderData = nil
    DeliveryState.cargoDamage = nil
    TriggerServerEvent("polarix_trucker:failDelivery")
    Framework.Notify("Lieferung fehlgeschlagen: " .. reason, "error")
end

RegisterNetEvent("polarix_trucker:deliveryCompleted", function(reward, xp, damagePenalty)
    ClearBlips()
    DeliveryState.status = "idle"
    DeliveryState.orderData = nil
    DeliveryState.cargoDamage = nil

    local msg = ("Lieferung abgeschlossen! +$%s, +%s XP"):format(reward, xp)
    if damagePenalty and damagePenalty > 0 then
        msg = msg .. (" (-%s Schaden-Abzug)"):format(damagePenalty)
    end
    Framework.Notify(msg, "success")
    SendMessage("deliveryComplete", { reward = reward, xp = xp })
end)

RegisterNetEvent("polarix_trucker:staleFailed", function()
    Framework.Notify("Deine letzte Lieferung wurde als fehlgeschlagen markiert (Disconnect).", "error")
end)

-- Disconnect/Resource-Stop während aktiver Delivery → beim nächsten Join auto-fail (server-seitig via CleanupStaleDelivery)
AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    if DeliveryState.status ~= "idle" then
        TriggerServerEvent("polarix_trucker:failDelivery")
    end
end)
