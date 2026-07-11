local shared = require("config.shared")

local function NormalizeHeadingDelta(a, b)
    local diff = (a - b) % 360.0
    if diff > 180.0 then diff = diff - 360.0 end
    return diff
end

function IsTrailerParkedCorrectly(order)
    local trailer = LocalTrailer and LocalTrailer.entity
    if not trailer or not DoesEntityExist(trailer) then return false end

    local target = vector3(order.dropoff_x, order.dropoff_y, order.dropoff_z)
    local trailerPos = GetEntityCoords(trailer)
    local dist = #(vector2(trailerPos.x, trailerPos.y) - vector2(target.x, target.y))

    local headingDiff = math.abs(NormalizeHeadingDelta(GetEntityHeading(trailer), order.dropoff_heading or 0.0))

    return dist <= shared.ParkingTolerance.distance and headingDiff <= shared.ParkingTolerance.heading
end

-- Global (not local): reused by the admin mission editor for dropoff preview.
function DrawOutlineRectangle(center, heading, length, width, correct)
    local rad = math.rad(heading or 0.0)
    local lengthDir = vector3(-math.sin(rad), math.cos(rad), 0.0)
    local widthDir  = vector3(math.cos(rad), math.sin(rad), 0.0)

    local hl, hw = length / 2, width / 2
    local p1 = center + lengthDir * hl + widthDir * hw
    local p2 = center + lengthDir * hl - widthDir * hw
    local p3 = center - lengthDir * hl - widthDir * hw
    local p4 = center - lengthDir * hl + widthDir * hw

    local r, g, b = 210, 75, 58
    if correct then r, g, b = 47, 199, 114 end

    DrawLine(p1.x, p1.y, p1.z, p2.x, p2.y, p2.z, r, g, b, 220)
    DrawLine(p2.x, p2.y, p2.z, p3.x, p3.y, p3.z, r, g, b, 220)
    DrawLine(p3.x, p3.y, p3.z, p4.x, p4.y, p4.z, r, g, b, 220)
    DrawLine(p4.x, p4.y, p4.z, p1.x, p1.y, p1.z, r, g, b, 220)
end

local function DrawParkingRectangle(order, correct)
    local trailerModel = GetTrailerModelName and GetTrailerModelName() or nil
    local trailerConfig = trailerModel and shared.CompatibleTrailers[trailerModel]
    local length = trailerConfig and trailerConfig.length or 11.0
    local width  = trailerConfig and trailerConfig.width or 2.6

    local center = vector3(order.dropoff_x, order.dropoff_y, order.dropoff_z - 0.8)
    DrawOutlineRectangle(center, order.dropoff_heading or 0.0, length, width, correct)
end

CreateThread(function()
    while true do
        if DeliveryState and DeliveryState.status == "delivering" and DeliveryState.orderData then
            local o = DeliveryState.orderData
            local dist = #(GetEntityCoords(PlayerPedId()) - vector3(o.dropoff_x, o.dropoff_y, o.dropoff_z))
            if dist < 25.0 then
                DrawParkingRectangle(o, IsTrailerParkedCorrectly(o))
                Wait(0)
            else
                Wait(500)
            end
        else
            Wait(500)
        end
    end
end)

local promptVisible = false

CreateThread(function()
    while true do
        Wait(200)
        if DeliveryState and DeliveryState.status == "delivering" and DeliveryState.orderData
            and IsTrailerParkedCorrectly(DeliveryState.orderData) then
            if not promptVisible then
                promptVisible = true
                SetHeldAction({
                    name = "Bereit zum Entladen",
                    hint = "Trailer korrekt geparkt",
                    primaryKey = "E",
                    primaryAction = "Entladen",
                })
            end
        elseif promptVisible then
            promptVisible = false
            ClearHeldAction()
        end
    end
end)

lib.addKeybind({
    name = "polarix_trucker_unload_dropoff",
    description = "Cargo entladen (Dropoff)",
    defaultKey = "E",
    onPressed = function()
        if promptVisible then
            Delivery.StartUnloading()
        end
    end,
})
