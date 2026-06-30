DeliveryState = {
    status = "idle", -- idle | awaiting_pickup | delivering
    orderData = nil,
    pickupBlip = nil,
    dropoffBlip = nil,
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

function Delivery.ArriveAtPickup()
    if DeliveryState.status ~= "awaiting_pickup" then return end
    DeliveryState.status = "delivering"
    local o = DeliveryState.orderData
    SetNewWaypoint(o.dropoff_x, o.dropoff_y)
    Framework.Notify("Cargo aufgeladen! Fahre nach " .. o.dropoff_label, "success")
end

function Delivery.ArriveAtDropoff()
    if DeliveryState.status ~= "delivering" then return end
    TriggerServerEvent("polarix_trucker:completeDelivery")
end

function Delivery.Cancel()
    ClearBlips()
    DeliveryState.status = "idle"
    DeliveryState.orderData = nil
    TriggerServerEvent("polarix_trucker:failDelivery")
    Framework.Notify("Lieferung abgebrochen.", "error")
end

CreateThread(function()
    while true do
        Wait(1000)
        if DeliveryState.status == "awaiting_pickup" or DeliveryState.status == "delivering" then
            local o = DeliveryState.orderData
            local pCoords = GetEntityCoords(PlayerPedId())
            if DeliveryState.status == "awaiting_pickup" then
                if #(pCoords - vector3(o.pickup_x, o.pickup_y, o.pickup_z)) < 10.0 then
                    Delivery.ArriveAtPickup()
                end
            else
                if #(pCoords - vector3(o.dropoff_x, o.dropoff_y, o.dropoff_z)) < 10.0 then
                    Delivery.ArriveAtDropoff()
                end
            end
        end
    end
end)

RegisterNetEvent("polarix_trucker:deliveryCompleted", function(reward, xp)
    ClearBlips()
    DeliveryState.status = "idle"
    DeliveryState.orderData = nil
    Framework.Notify(("Lieferung abgeschlossen! +$%s, +%s XP"):format(reward, xp), "success")
    SendMessage("deliveryComplete", { reward = reward, xp = xp })
end)
