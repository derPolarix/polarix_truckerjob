local T = require("server.constants")

DB = {}

function DB.GetPlayer(identifier)
    return MySQL.single.await(("SELECT * FROM %s WHERE identifier = ?"):format(T.players), { identifier })
end

function DB.CreatePlayer(identifier, name)
    MySQL.insert.await(
        ("INSERT INTO %s (identifier, name) VALUES (?, ?)"):format(T.players),
        { identifier, name }
    )
end

function DB.SavePlayer(identifier, data)
    MySQL.update.await(
        ("UPDATE %s SET level=?, xp=?, skill_points=?, skills=?, total_earnings=?, total_deliveries=?, failed_deliveries=?, equipped_vehicle=? WHERE identifier=?"):format(T.players),
        { data.level, data.xp, data.skill_points, json.encode(data.skills), data.total_earnings, data.total_deliveries, data.failed_deliveries, data.equipped_vehicle, identifier }
    )
end

function DB.GetPlayerVehicles(identifier)
    return MySQL.query.await(("SELECT * FROM %s WHERE identifier = ?"):format(T.vehicles), { identifier })
end

function DB.GetAvailableOrders()
    return MySQL.query.await(("SELECT * FROM %s WHERE is_active = 1"):format(T.orders))
end

function DB.InsertDelivery(orderId, identifier)
    return MySQL.insert.await(
        ("INSERT INTO %s (order_id, identifier) VALUES (?, ?)"):format(T.deliveries),
        { orderId, identifier }
    )
end

function DB.CompleteDelivery(deliveryId, rewardPaid, xpPaid)
    MySQL.update.await(
        ("UPDATE %s SET status='completed', reward_paid=?, xp_paid=?, completed_at=NOW() WHERE id=?"):format(T.deliveries),
        { rewardPaid, xpPaid, deliveryId }
    )
end

function DB.FailDelivery(deliveryId)
    MySQL.update.await(
        ("UPDATE %s SET status='failed', completed_at=NOW() WHERE id=?"):format(T.deliveries),
        { deliveryId }
    )
end

function DB.GetDeliveryHistory(identifier, limit)
    return MySQL.query.await(
        ("SELECT d.*, o.name, o.pickup_city, o.dropoff_city FROM %s d LEFT JOIN %s o ON d.order_id = o.id WHERE d.identifier = ? ORDER BY d.started_at DESC LIMIT ?"):format(T.deliveries, T.orders),
        { identifier, limit or 20 }
    )
end

function LoadDatabaseToCache()
    -- Aktuell kein globaler DB-Cache nötig (Spieler werden pro-Source in PlayerCache gehalten).
end