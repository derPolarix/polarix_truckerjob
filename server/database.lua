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
        ("UPDATE %s SET level=?, xp=?, skill_points=?, skills=?, total_earnings=?, total_deliveries=?, failed_deliveries=?, equipped_vehicle=?, equipped_trailer=? WHERE identifier=?"):format(T.players),
        { data.level, data.xp, data.skill_points, json.encode(data.skills), data.total_earnings, data.total_deliveries, data.failed_deliveries, data.equipped_vehicle, data.equipped_trailer, identifier }
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

function DB.GetPlayerTrailers(identifier)
    return MySQL.query.await(("SELECT * FROM %s WHERE identifier = ?"):format(T.trailers), { identifier })
end

function DB.InsertTrailer(identifier, trailerSlot, trailerModel)
    return MySQL.insert.await(
        ("INSERT INTO %s (identifier, trailer_slot, trailer_model) VALUES (?,?,?)"):format(T.trailers),
        { identifier, trailerSlot, trailerModel }
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
        ("INSERT INTO %s (id,name,cargo,cargo_type,weight_kg,distance_km,reward_base,xp_base,time_minutes,pickup_label,pickup_city,pickup_x,pickup_y,pickup_z,pickup_heading,pickup_pallet_coords,dropoff_label,dropoff_city,dropoff_x,dropoff_y,dropoff_z,dropoff_heading,comment,tag,tag_color,tag_bg,icon,level_required,requires_hazmat,requires_long_hauler,is_active) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)"):format(T.orders),
        {
            order.id, order.name, order.cargo, order.cargo_type, order.weight_kg, order.distance_km,
            order.reward_base, order.xp_base, order.time_minutes, order.pickup_label, order.pickup_city,
            order.pickup_x, order.pickup_y, order.pickup_z, order.pickup_heading or 0.0,
            json.encode(order.pickup_pallet_coords or {}),
            order.dropoff_label, order.dropoff_city,
            order.dropoff_x, order.dropoff_y, order.dropoff_z, order.dropoff_heading or 0.0,
            order.comment, order.tag, order.tag_color,
            order.tag_bg, order.icon, order.level_required, order.requires_hazmat and 1 or 0,
            order.requires_long_hauler and 1 or 0, 1,
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

function DB.GetLeaderboardGlobal(limit)
    return MySQL.query.await(
        ("SELECT name, level, total_deliveries, total_earnings FROM %s ORDER BY total_deliveries DESC LIMIT ?"):format(T.players),
        { limit or 20 }
    )
end

function DB.GetLeaderboardCompanies(limit)
    return MySQL.query.await(
        ("SELECT name, tag, level, total_deliveries, total_earnings FROM %s ORDER BY total_deliveries DESC LIMIT ?"):format(T.companies),
        { limit or 10 }
    )
end

-- Company queries

function DB.GetMemberByPlayer(identifier)
    return MySQL.single.await(("SELECT * FROM %s WHERE identifier = ?"):format(T.members), { identifier })
end

function DB.GetCompanyById(companyId)
    return MySQL.single.await(("SELECT * FROM %s WHERE id = ?"):format(T.companies), { companyId })
end

function DB.CreateCompany(name, tag, description)
    return MySQL.insert.await(
        ("INSERT INTO %s (name, tag, description) VALUES (?,?,?)"):format(T.companies),
        { name, tag, description }
    )
end

function DB.AddCompanyMember(companyId, identifier, role)
    MySQL.insert.await(
        ("INSERT INTO %s (company_id, identifier, role) VALUES (?,?,?)"):format(T.members),
        { companyId, identifier, role }
    )
end

function DB.GetCompanyMembers(companyId)
    return MySQL.query.await(("SELECT * FROM %s WHERE company_id = ?"):format(T.members), { companyId })
end

function DB.GetCompanyInvitations(companyId)
    return MySQL.query.await(("SELECT * FROM %s WHERE company_id = ?"):format(T.invitations), { companyId })
end

function DB.InsertInvitation(companyId, targetIdentifier, invitedBy)
    MySQL.insert.await(
        ("INSERT IGNORE INTO %s (company_id, target_identifier, invited_by) VALUES (?,?,?)"):format(T.invitations),
        { companyId, targetIdentifier, invitedBy }
    )
end

function DB.DeleteInvitation(companyId, targetIdentifier)
    MySQL.query.await(
        ("DELETE FROM %s WHERE company_id = ? AND target_identifier = ?"):format(T.invitations),
        { companyId, targetIdentifier }
    )
end

function DB.UpdateMemberRole(identifier, companyId, newRole)
    MySQL.update.await(
        ("UPDATE %s SET role=? WHERE identifier=? AND company_id=?"):format(T.members),
        { newRole, identifier, companyId }
    )
end

function DB.DeleteMember(identifier, companyId)
    MySQL.query.await(
        ("DELETE FROM %s WHERE identifier=? AND company_id=?"):format(T.members),
        { identifier, companyId }
    )
end

function DB.UpdateCompanyTreasury(companyId, delta)
    MySQL.update.await(
        ("UPDATE %s SET treasury = treasury + ? WHERE id = ?"):format(T.companies),
        { delta, companyId }
    )
end

function DB.InsertTransaction(companyId, label, amount, isPositive, icon)
    MySQL.insert.await(
        ("INSERT INTO %s (company_id, label, amount, is_positive, icon) VALUES (?,?,?,?,?)"):format(T.transactions),
        { companyId, label, amount, isPositive and 1 or 0, icon }
    )
end

function DB.GetCompanyTransactions(companyId, limit)
    return MySQL.query.await(
        ("SELECT * FROM %s WHERE company_id = ? ORDER BY created_at DESC LIMIT ?"):format(T.transactions),
        { companyId, limit or 20 }
    )
end

function DB.UpdateCompanyStats(companyId, earnings)
    MySQL.update.await(
        ("UPDATE %s SET total_earnings = total_earnings + ?, total_deliveries = total_deliveries + 1 WHERE id = ?"):format(T.companies),
        { earnings, companyId }
    )
end

function DB.UpdateCompanyXP(companyId, amount)
    MySQL.update.await(
        ("UPDATE %s SET xp = xp + ? WHERE id = ?"):format(T.companies),
        { amount, companyId }
    )
end

function DB.UpdateCompanySettings(companyId, name, tag, description, openRecruitment)
    MySQL.update.await(
        ("UPDATE %s SET name=?, tag=?, description=?, open_recruitment=? WHERE id=?"):format(T.companies),
        { name, tag, description, openRecruitment and 1 or 0, companyId }
    )
end

function DB.DeleteCompany(companyId)
    MySQL.query.await(("DELETE FROM %s WHERE company_id = ?"):format(T.members), { companyId })
    MySQL.query.await(("DELETE FROM %s WHERE company_id = ?"):format(T.invitations), { companyId })
    MySQL.query.await(("DELETE FROM %s WHERE company_id = ?"):format(T.transactions), { companyId })
    MySQL.query.await(("DELETE FROM %s WHERE id = ?"):format(T.companies), { companyId })
end

function DB.UpdateMemberStats(identifier, companyId, earnings)
    MySQL.update.await(
        ("UPDATE %s SET deliveries = deliveries + 1, earnings = earnings + ? WHERE identifier = ? AND company_id = ?"):format(T.members),
        { earnings, identifier, companyId }
    )
end

function DB.GetPlayerByName(name)
    return MySQL.single.await(
        ("SELECT identifier, level FROM %s WHERE name = ?"):format(T.players),
        { name }
    )
end

function DB.GetOpenRecruitmentCompanies()
    return MySQL.query.await(
        ("SELECT c.id, c.name, c.tag, c.description, c.level, c.total_deliveries, COUNT(m.id) AS members FROM %s c LEFT JOIN %s m ON m.company_id = c.id WHERE c.open_recruitment = 1 GROUP BY c.id ORDER BY c.total_deliveries DESC"):format(T.companies, T.members),
        {}
    )
end

function LoadDatabaseToCache()
    -- Aktuell kein globaler DB-Cache nötig (Spieler werden pro-Source in PlayerCache gehalten).
end