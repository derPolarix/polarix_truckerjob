Delivery = Delivery or {}
Delivery.HUD = {}

local hudActive = false

function Delivery.HUD.Start()
    hudActive = true
    CreateThread(function()
        while hudActive do
            Wait(0)
            local o = DeliveryState.orderData
            if not o then break end

            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            local speed = veh ~= 0 and math.floor(GetEntitySpeed(veh) * 3.6) or 0
            local dropCoord = vector3(o.dropoff_x, o.dropoff_y, o.dropoff_z)
            local dist = math.floor(#(GetEntityCoords(ped) - dropCoord) / 1000 * 10) / 10

            DrawRect(0.5, 0.965, 0.38, 0.048, 22, 38, 45, 210)

            local statusText = DeliveryState.status == "awaiting_pickup" and "PICKUP" or "DELIVERING"
            SetTextFont(4); SetTextScale(0.0, 0.28); SetTextColour(232, 180, 8, 255)
            SetTextEntry("STRING"); AddTextComponentString(statusText)
            DrawText(0.325, 0.950)

            SetTextFont(4); SetTextScale(0.0, 0.26); SetTextColour(200, 210, 220, 255)
            SetTextEntry("STRING"); AddTextComponentString(o.cargo .. " -> " .. o.dropoff_city)
            DrawText(0.375, 0.963)

            SetTextFont(4); SetTextScale(0.0, 0.26); SetTextColour(200, 210, 220, 255)
            SetTextEntry("STRING"); AddTextComponentString(dist .. " km · " .. speed .. " km/h")
            DrawText(0.375, 0.974)

            if DeliveryState.cargoDamage and DeliveryState.cargoDamage > 0 then
                local dmgColor = DeliveryState.cargoDamage > 500 and { 210, 75, 58, 255 } or { 232, 180, 8, 255 }
                SetTextFont(4); SetTextScale(0.0, 0.26)
                SetTextColour(dmgColor[1], dmgColor[2], dmgColor[3], dmgColor[4])
                SetTextEntry("STRING"); AddTextComponentString("DMG: " .. DeliveryState.cargoDamage)
                DrawText(0.615, 0.963)
            end
        end
    end)
end

function Delivery.HUD.Stop()
    hudActive = false
end
