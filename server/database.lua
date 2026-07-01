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

function DB.InsertVehicle(identifier, vehicleSlot, vehicleModel)
    MySQL.insert.await(
        ("INSERT INTO %s (identifier, vehicle_slot, vehicle_model) VALUES (?,?,?)"):format(T.vehicles),
        { identifier, vehicleSlot, vehicleModel }
    )
end

function DB.GetAvailableOrders()
    return MySQL.query.await(("SELECT * FROM %s WHERE is_active = 1"):format(T.orders))
end

function DB.CountOrders()
    return MySQL.scalar.await(("SELECT COUNT(*) FROM %s"):format(T.orders))
end

function DB.GetOrderById(orderId)
    return MySQL.single.await(("SELECT * FROM %s WHERE id = ?"):format(T.orders), { orderId })
end

function DB.InsertOrder(order)
    MySQL.insert.await(
        ("INSERT INTO %s (id,name,cargo,cargo_type,weight_kg,distance_km,reward_base,xp_base,time_minutes,pickup_label,pickup_city,pickup_x,pickup_y,pickup_z,dropoff_label,dropoff_city,dropoff_x,dropoff_y,dropoff_z,comment,tag,tag_color,tag_bg,icon,level_required,requires_hazmat,requires_long_hauler) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)"):format(T.orders),
        {
            order.id, order.name, order.cargo, order.cargo_type, order.weight_kg, order.distance_km,
            order.reward_base, order.xp_base, order.time_minutes, order.pickup_label, order.pickup_city,
            order.pickup_x, order.pickup_y, order.pickup_z, order.dropoff_label, order.dropoff_city,
            order.dropoff_x, order.dropoff_y, order.dropoff_z, order.comment, order.tag, order.tag_color,
            order.tag_bg, order.icon, order.level_required, order.requires_hazmat and 1 or 0,
            order.requires_long_hauler and 1 or 0,
        }
    )
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

function DB.GetActiveDelivery(identifier)
    return MySQL.single.await(
        ("SELECT id FROM %s WHERE identifier = ? AND status = 'active'"):format(T.deliveries),
        { identifier }
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