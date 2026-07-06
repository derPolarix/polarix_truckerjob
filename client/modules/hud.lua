Delivery = Delivery or {}
Delivery.HUD = {}

local hudActive = false

function Delivery.HUD.Start()
    hudActive = true
end

function Delivery.HUD.Stop()
    hudActive = false
end

CreateThread(function()
    while true do
        Wait(250)

        local inForklift = IsPlayerInForklift and IsPlayerInForklift() or false
        local carrying = (GetForkliftPalletPayload and GetForkliftPalletPayload() ~= nil) or false
        local palletsLoaded = (MissionCargo and MissionCargo.loadedCount) or 0
        local palletsRequired = (MissionCargo and MissionCargo.requiredCount) or 0

        if hudActive and DeliveryState and DeliveryState.orderData then
            local o = DeliveryState.orderData
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            local speed = veh ~= 0 and math.floor(GetEntitySpeed(veh) * 3.6) or 0
            local isPickupPhase = DeliveryState.status == "awaiting_pickup"
            local targetCoord = isPickupPhase and vector3(o.pickup_x, o.pickup_y, o.pickup_z) or vector3(o.dropoff_x, o.dropoff_y, o.dropoff_z)
            local dist = math.floor(#(GetEntityCoords(ped) - targetCoord) / 1000 * 10) / 10

            SendMessage("gameHud", {
                visible          = true,
                phase            = isPickupPhase and "pickup" or "delivering",
                cargo            = o.cargo,
                city             = isPickupPhase and o.pickup_city or o.dropoff_city,
                distanceKm       = dist,
                speedKmh         = speed,
                damage           = DeliveryState.cargoDamage or 0,
                palletsLoaded    = palletsLoaded,
                palletsRequired  = palletsRequired,
                inForklift       = inForklift,
                forkliftCarrying = carrying,
                orderName        = o.name,
                pickupLabel      = o.pickup_label,
                dropoffLabel     = o.dropoff_label,
                reward           = o.reward_base,
            })
        elseif inForklift then
            SendMessage("gameHud", {
                visible          = true,
                phase            = nil,
                cargo            = "",
                city             = "",
                distanceKm       = 0,
                speedKmh         = 0,
                damage           = 0,
                palletsLoaded    = palletsLoaded,
                palletsRequired  = palletsRequired,
                inForklift       = true,
                forkliftCarrying = carrying,
            })
        else
            SendMessage("gameHud", { visible = false })
        end
    end
end)
