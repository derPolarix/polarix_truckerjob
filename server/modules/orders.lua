local cargo = require("shared.cargo")
local Locale = require("shared.locale")

Orders = {}
ActiveDeliveries = {} -- source -> { deliveryId, orderId, totalPallets, remainingPallets, deliveredPallets, cargoDamageTotal }

-- oxmysql returns TINYINT(1) as Lua boolean, not integer 1
local function isTruthy(v) return v == 1 or v == true end

function Orders.GetAvailableForPlayer(source)
    local pData = Player.GetData(source)
    if not pData then return {} end

    local filtered = {}
    for _, order in ipairs(DB.GetAvailableOrders()) do
        local visible = true
        if order.level_required > pData.level then visible = false end
        if isTruthy(order.requires_hazmat) and not Player.HasSkill(source, "h3") then visible = false end
        if isTruthy(order.requires_long_hauler) and not Player.HasSkill(source, "d3") then visible = false end
        if visible then filtered[#filtered + 1] = order end
    end
    return filtered
end

function Orders.Accept(source, orderId)
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

    if type(order.pickup_pallet_coords) == "string" then
        order.pickup_pallet_coords = json.decode(order.pickup_pallet_coords)
    end

    local total = cargo.CalcPalletCount(order.weight_kg)
    local deliveryId = DB.InsertDelivery(orderId, pData.identifier)
    ActiveDeliveries[source] = {
        deliveryId = deliveryId, orderId = orderId,
        totalPallets = total, remainingPallets = total, deliveredPallets = 0, cargoDamageTotal = 0,
    }
    return true, order
end

-- Wird beim Betreten der Pickup-Zone aufgerufen: vergibt so viele Paletten wie noch offen
-- sind, gedeckelt durch die aktuell nutzbare Trailer-Kapazität (eigener Trailer oder Rental).
function Orders.ClaimTripPallets(source)
    local delivery = ActiveDeliveries[source]
    if not delivery or delivery.remainingPallets <= 0 then return 0 end

    local claim = math.min(Trailers.GetActiveMaxPallets(source) or 0, delivery.remainingPallets)
    if claim <= 0 then return 0 end

    delivery.remainingPallets = delivery.remainingPallets - claim
    return claim
end

-- Meldet den Abschluss eines Trips. Ist die Order damit komplett geliefert, läuft die volle
-- Reward/XP/Tax-Pipeline (Orders.Finish); sonst kehrt der Spieler zum Pickup zurück.
function Orders.CompleteTrip(source, tripPalletCount, cargoDamage)
    local delivery = ActiveDeliveries[source]
    if not delivery then return false end

    delivery.deliveredPallets = delivery.deliveredPallets + tripPalletCount
    delivery.cargoDamageTotal = delivery.cargoDamageTotal + (cargoDamage or 0)

    if delivery.deliveredPallets >= delivery.totalPallets then
        local _, reward, xp, penalty, taxAmount = Orders.Finish(source)
        return true, reward, xp, penalty, taxAmount
    end
    return false, delivery.remainingPallets
end

-- Vormals "Orders.Complete" — läuft erst, sobald der letzte Trip einer Order geliefert wurde.
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

    -- Cargo-Schaden-Abzug (über alle Trips kumuliert), max 30% vom Reward
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
    if not delivery then return end

    DB.FailDelivery(delivery.deliveryId)

    local pData = Player.GetData(source)
    if pData then
        pData.failed_deliveries = pData.failed_deliveries + 1
        Player.Save(source)
    end
    ActiveDeliveries[source] = nil
end

-- Beim Player-Load: offene Delivery aus vorherigem Disconnect/Server-Restart als abgebrochen markieren
-- (kein echter Fehlschlag, zählt daher nicht als failed_deliveries)
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
    else
        TriggerClientEvent("polarix_trucker:tripSettled", src, a) -- a=remainingPallets
    end
end)

RegisterNetEvent("polarix_trucker:failDelivery", function()
    Orders.Fail(source)
end)
