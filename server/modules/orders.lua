local cargo = require("shared.cargo")
local config = require("config.server")
local debug = require("shared.debug")
local Locale = require("shared.locale")

Orders = {}
ActiveDeliveries = {} -- source -> { deliveryId, orderId, totalPallets, remainingPallets, claimedPallets, deliveredPallets, cargoDamageTotal, pickup, dropoff, rewardBase }

-- The one place a delivery entry is built (real accept and admin test run alike). pickup/dropoff/
-- rewardBase are kept so the checks on client-reported values need no extra DB read.
function Orders.StartDelivery(source, deliveryId, order, isTest)
    local total = cargo.CalcPalletCount(order.weight_kg)

    ActiveDeliveries[source] = {
        deliveryId = deliveryId, orderId = order.id,
        totalPallets = total, remainingPallets = total, claimedPallets = 0, deliveredPallets = 0, cargoDamageTotal = 0,
        pickup = vector3(order.pickup_x, order.pickup_y, order.pickup_z),
        dropoff = vector3(order.dropoff_x, order.dropoff_y, order.dropoff_z),
        rewardBase = order.reward_base,
        isTest = isTest or nil,
    }
end

-- Position checks run against the server-known ped, never a client-reported coordinate.
function Orders.IsNearZone(source, zone)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return false end

    return #(GetEntityCoords(ped) - zone) <= config.ZoneMaxDistance
end

-- Cargo damage is client-measured; a negative or NaN value would otherwise turn the penalty into
-- a bonus. Anything beyond the order's own reward is irrelevant (the penalty is capped at 30%).
function Orders.SanitizeDamage(value, rewardBase)
    if type(value) ~= "number" or value ~= value or value < 0 then return 0 end

    return math.min(value, rewardBase or value)
end

-- oxmysql returns TINYINT(1) as Lua boolean, not integer 1
local function isTruthy(v) return v == 1 or v == true end

-- oxmysql usually returns TIMESTAMP columns as "YYYY-MM-DD HH:MM:SS" strings, but has been
-- observed returning ISO-ish "YYYY-MM-DDTHH:MM:SS" or a raw epoch number depending on driver
-- config — accept all three instead of assuming one, since a bad type here previously crashed
-- the whole openDashboard callback (":match" called on a non-string) and left players locked
-- out of the NUI entirely.
local function parseTimestamp(ts)
    if type(ts) == "number" then
        return ts > 1e12 and math.floor(ts / 1000) or math.floor(ts)
    end
    if type(ts) ~= "string" then return nil end
    local y, mo, d, h, mi, s = ts:match("(%d+)-(%d+)-(%d+)[T ](%d+):(%d+):(%d+)")
    if not y then return nil end
    return os.time({
        year = tonumber(y) or 1970, month = tonumber(mo) or 1, day = tonumber(d) or 1,
        hour = tonumber(h) or 0, min = tonumber(mi) or 0, sec = tonumber(s) or 0,
    })
end

-- Seconds left before `order` can be accepted again, given the player's last completed
-- delivery timestamp for it (nil = never completed it). 0 = no cooldown / already expired.
-- Exposed on Orders since party_mission.lua's convoy-start path duplicates Orders.Accept's
-- gate checks and needs the same cooldown enforcement.
-- pcall-wrapped: this only feeds a countdown display, never worth crashing dashboard load over.
local function cooldownRemaining(order, lastCompletedAt)
    local cooldown = order.cooldown_seconds or 0
    if cooldown <= 0 then return 0 end
    local ok, completedEpoch = pcall(parseTimestamp, lastCompletedAt)
    if not ok or not completedEpoch then return 0 end
    local remaining = cooldown - (os.time() - completedEpoch)
    return remaining > 0 and remaining or 0
end
Orders.CooldownRemaining = cooldownRemaining

function Orders.GetAvailableForPlayer(source)
    local pData = Player.GetData(source)
    if not pData then return {} end

    local ok, result = pcall(DB.GetLastCompletedByOrder, pData.identifier)
    local lastCompletedByOrder = ok and result or {}

    local filtered = {}
    for _, order in ipairs(DB.GetAvailableOrders()) do
        local visible = true
        if order.level_required > pData.level then visible = false end
        if isTruthy(order.requires_hazmat) and not Player.HasSkill(source, "h3") then visible = false end
        if isTruthy(order.requires_long_hauler) and not Player.HasSkill(source, "d3") then visible = false end
        if visible then
            order.cooldown_remaining = cooldownRemaining(order, lastCompletedByOrder[order.id])
            filtered[#filtered + 1] = order
        end
    end
    return filtered
end

-- Accept yields on DB awaits between its active-delivery check and the insert, so two concurrent
-- calls from one player would both pass it and open two deliveries.
local accepting = {}

local function accept(source, orderId)
    if ActiveDeliveries[source] then return false, Locale("error.already_active_delivery") end

    local pData = Player.GetData(source)
    if not pData then return false, Locale("error.player_data_not_found") end

    local hasOwnGear = pData.equipped_vehicle and pData.equipped_trailer
    if not hasOwnGear and not Rental.IsActive(source) then
        return false, "no_vehicle_or_trailer"
    end

    local order = DB.GetOrderById(orderId)
    if not order or not isTruthy(order.is_active) then return false, Locale("error.order_not_available") end
    if order.level_required > pData.level then return false, Locale("error.level_not_sufficient") end
    if isTruthy(order.requires_hazmat) and not Player.HasSkill(source, "h3") then return false, Locale("error.hazmat_license_required") end
    if isTruthy(order.requires_long_hauler) and not Player.HasSkill(source, "d3") then return false, Locale("error.long_hauler_skill_required") end
    if cooldownRemaining(order, DB.GetLastCompletedAt(pData.identifier, orderId)) > 0 then
        return false, Locale("error.mission_on_cooldown")
    end

    if type(order.pickup_pallet_coords) == "string" then
        order.pickup_pallet_coords = json.decode(order.pickup_pallet_coords)
    end

    local deliveryId = DB.InsertDelivery(orderId, pData.identifier)
    Orders.StartDelivery(source, deliveryId, order)
    return true, order
end

function Orders.Accept(source, orderId)
    if accepting[source] then return false, Locale("error.already_active_delivery") end

    accepting[source] = true
    local ok, success, result = pcall(accept, source, orderId)
    accepting[source] = nil

    if not ok then error(success, 0) end
    return success, result
end

-- Called on entering the pickup zone: claims as many pallets as still open, capped by
-- the currently usable trailer capacity (own trailer or rental).
function Orders.ClaimTripPallets(source)
    local delivery = ActiveDeliveries[source]
    if not delivery or delivery.finishing or delivery.remainingPallets <= 0 then return 0 end
    if not Orders.IsNearZone(source, delivery.pickup) then return 0 end

    -- remainingPallets is read after the capacity lookup (it may yield on the DB) so concurrent
    -- claims cannot both take the same pallets.
    local claim = math.min(Trailers.GetActiveMaxPallets(source) or 0, delivery.remainingPallets)
    if claim <= 0 then return 0 end

    delivery.remainingPallets = delivery.remainingPallets - claim
    delivery.claimedPallets = delivery.claimedPallets + claim
    return claim
end

-- Reports a trip's completion. If that finishes the order, the full reward/XP/tax
-- pipeline runs (Orders.Finish); otherwise the player heads back to pickup.
function Orders.CompleteTrip(source, tripPalletCount, cargoDamage)
    local delivery = ActiveDeliveries[source]
    if not delivery or delivery.finishing then return false end

    if not Orders.IsNearZone(source, delivery.dropoff) then
        debug.Warn(("Orders.CompleteTrip: rejected trip report from outside the drop-off for source %s"):format(source))
        return false
    end

    -- The client only says how many pallets it carried; the server credits at most what it handed
    -- out for this trip in ClaimTripPallets.
    if type(tripPalletCount) ~= "number" or tripPalletCount < 1 or tripPalletCount ~= math.floor(tripPalletCount) then
        return false
    end

    local count = math.min(tripPalletCount, delivery.claimedPallets)
    if count < 1 then return false end

    delivery.claimedPallets = delivery.claimedPallets - count
    delivery.deliveredPallets = delivery.deliveredPallets + count
    delivery.cargoDamageTotal = delivery.cargoDamageTotal + Orders.SanitizeDamage(cargoDamage, delivery.rewardBase)

    if delivery.deliveredPallets >= delivery.totalPallets then
        -- Finish yields on DB awaits before it clears the delivery; without this a second
        -- completeTrip would run the payout again.
        delivery.finishing = true
        local _, reward, xp, penalty, taxAmount = Orders.Finish(source)
        return true, reward, xp, penalty, taxAmount
    end
    return false, delivery.remainingPallets
end

-- Runs only once the last trip of an order has been delivered.
function Orders.Finish(source)
    local delivery = ActiveDeliveries[source]
    if not delivery then return false end

    local order = DB.GetOrderById(delivery.orderId)
    if not order then
        ActiveDeliveries[source] = nil
        return false
    end

    local reward, xp = Skills.ApplyRewardModifiers(source, order.reward_base, order.cargo_type, order)
    xp = Skills.ApplyXPModifiers(source, xp)

    -- cargo damage deduction (accumulated across all trips), capped at 30% of reward
    local damagePercent = math.min(delivery.cargoDamageTotal / order.reward_base, 0.30)
    local penalty = math.floor(reward * damagePercent)
    reward = reward - penalty

    local taxAmount
    reward, taxAmount = Company.ApplyTax(source, reward)

    Framework.AddMoney(source, reward)
    Player.AddXP(source, xp)

    local pData = Player.GetData(source)
    pData.total_earnings = pData.total_earnings + reward
    pData.total_deliveries = pData.total_deliveries + 1
    Player.Save(source)
    Company.OnDeliveryComplete(source, reward)

    DB.CompleteDelivery(delivery.deliveryId, reward, xp)
    ActiveDeliveries[source] = nil

    return true, reward, xp, penalty, taxAmount
end

function Orders.Fail(source)
    local delivery = ActiveDeliveries[source]
    if not delivery or delivery.finishing then return end

    DB.FailDelivery(delivery.deliveryId)

    local pData = Player.GetData(source)
    if pData then
        pData.failed_deliveries = pData.failed_deliveries + 1
        Player.Save(source)
    end
    ActiveDeliveries[source] = nil
end

-- On player load: mark a delivery left open by a previous disconnect/restart as abandoned
-- (not a real failure, so it doesn't count toward failed_deliveries)
function Orders.CleanupStaleDelivery(source)
    local pData = Player.GetData(source)
    if not pData then return end

    local stale = DB.GetActiveDelivery(pData.identifier)
    if not stale then return end

    DB.AbandonDelivery(stale.id)
    TriggerClientEvent("polarix_trucker:staleFailed", source)
end

lib.callback.register("polarix_trucker:acceptOrder", function(source, orderId)
    local success, result = Orders.Accept(source, orderId)
    if not success then return false, nil, result end
    return true, result
end)

lib.callback.register("polarix_trucker:claimTripPallets", function(source)
    return Orders.ClaimTripPallets(source)
end)

RegisterNetEvent("polarix_trucker:completeTrip", function(tripPalletCount, cargoDamage)
    local src = source
    local finished, a, b, c, d = Orders.CompleteTrip(src, tripPalletCount, cargoDamage)
    if finished then
        TriggerClientEvent("polarix_trucker:deliveryCompleted", src, a, b, c, d) -- a=reward, b=xp, c=penalty, d=tax
    elseif a ~= nil then
        TriggerClientEvent("polarix_trucker:tripSettled", src, a) -- a=remainingPallets
    end
end)

RegisterNetEvent("polarix_trucker:failDelivery", function()
    Orders.Fail(source)
end)
