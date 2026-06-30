local config = require("config.server")

Orders = {}
ActiveDeliveries = {} -- source -> { deliveryId, orderId }

-- TEMPORÄR: Seed initiale Orders aus Config wenn Tabelle leer.
-- ZIEL: Orders ausschliesslich via Admin-Menü verwalten, dieser Seed entfällt dann.
function Orders.SeedIfEmpty()
    if (DB.CountOrders() or 0) > 0 then return end
    for _, order in ipairs(config.SeedOrders or {}) do
        DB.InsertOrder(order)
    end
end

function Orders.GetAvailableForPlayer(source)
    local pData = Player.GetData(source)
    if not pData then return {} end

    local filtered = {}
    for _, order in ipairs(DB.GetAvailableOrders()) do
        local visible = true
        if order.level_required > pData.level then visible = false end
        if order.requires_hazmat == 1 and not Player.HasSkill(source, "h3") then visible = false end
        if order.requires_long_hauler == 1 and not Player.HasSkill(source, "d3") then visible = false end
        if visible then filtered[#filtered + 1] = order end
    end
    return filtered
end

function Orders.Accept(source, orderId)
    if ActiveDeliveries[source] then return false, "Du hast bereits eine aktive Lieferung." end

    local pData = Player.GetData(source)
    if not pData then return false, "Spielerdaten nicht gefunden." end

    local order = DB.GetOrderById(orderId)
    if not order or order.is_active ~= 1 then return false, "Auftrag nicht verfügbar." end
    if order.level_required > pData.level then return false, "Level nicht ausreichend." end
    if order.requires_hazmat == 1 and not Player.HasSkill(source, "h3") then return false, "Hazmat-Lizenz erforderlich." end
    if order.requires_long_hauler == 1 and not Player.HasSkill(source, "d3") then return false, "Long-Hauler-Skill erforderlich." end

    local deliveryId = DB.InsertDelivery(orderId, pData.identifier)
    ActiveDeliveries[source] = { deliveryId = deliveryId, orderId = orderId }
    return true, order
end

function Orders.Complete(source, cargoDamage)
    local delivery = ActiveDeliveries[source]
    if not delivery then return false end

    local order = DB.GetOrderById(delivery.orderId)
    if not order then
        ActiveDeliveries[source] = nil
        return false
    end

    local reward, xp = order.reward_base, order.xp_base

    -- Cargo-Schaden-Abzug, max 30% vom Reward
    local damagePercent = math.min((cargoDamage or 0) / order.reward_base, 0.30)
    local penalty = math.floor(reward * damagePercent)
    reward = reward - penalty

    Framework.AddMoney(source, reward)
    Player.AddXP(source, xp)

    local pData = Player.GetData(source)
    pData.total_earnings = pData.total_earnings + reward
    pData.total_deliveries = pData.total_deliveries + 1
    Player.Save(source)

    DB.CompleteDelivery(delivery.deliveryId, reward, xp)
    ActiveDeliveries[source] = nil

    return true, reward, xp, penalty
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

-- Beim Player-Load: offene Delivery aus vorherigem Disconnect als fehlgeschlagen markieren
function Orders.CleanupStaleDelivery(source)
    local pData = Player.GetData(source)
    if not pData then return end

    local stale = DB.GetActiveDelivery(pData.identifier)
    if not stale then return end

    DB.FailDelivery(stale.id)
    pData.failed_deliveries = pData.failed_deliveries + 1
    Player.Save(source)
    TriggerClientEvent("polarix_trucker:staleFailed", source)
end

lib.callback.register("polarix_trucker:acceptOrder", function(source, orderId)
    local success, result = Orders.Accept(source, orderId)
    if not success then return false, nil, result end
    return true, result
end)

RegisterNetEvent("polarix_trucker:completeDelivery", function(cargoDamage)
    local src = source
    local success, reward, xp, penalty = Orders.Complete(src, cargoDamage)
    if success then
        TriggerClientEvent("polarix_trucker:deliveryCompleted", src, reward, xp, penalty)
    end
end)

RegisterNetEvent("polarix_trucker:failDelivery", function()
    Orders.Fail(source)
end)
