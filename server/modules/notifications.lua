Notifications = {}

function Notifications.Push(identifier, notifType, title, message, icon)
    local id = DB.InsertNotification(identifier, notifType, title, message, icon)
    DB.PruneNotifications(identifier)

    local targetSource = Player.GetSourceByIdentifier(identifier)
    if targetSource then
        TriggerClientEvent("polarix_trucker:notification", targetSource, {
            id = id,
            type = notifType,
            title = title,
            message = message,
            icon = icon,
            is_read = false,
            created_at = os.date("%Y-%m-%d %H:%M:%S"),
        })
    end

    return id
end

function Notifications.GetForPlayer(identifier)
    return DB.GetNotifications(identifier, 50)
end

function Notifications.MarkRead(source, notificationId)
    local pData = Player.GetData(source)
    if not pData then return false end
    DB.MarkNotificationRead(notificationId, pData.identifier)
    return true
end

function Notifications.MarkAllRead(source)
    local pData = Player.GetData(source)
    if not pData then return false end
    DB.MarkAllNotificationsRead(pData.identifier)
    return true
end

lib.callback.register("polarix_trucker:markNotificationRead", function(source, notificationId)
    return Notifications.MarkRead(source, notificationId)
end)

lib.callback.register("polarix_trucker:markAllNotificationsRead", function(source)
    return Notifications.MarkAllRead(source)
end)
