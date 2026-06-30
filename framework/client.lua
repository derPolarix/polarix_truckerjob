-- Framework adapter - client side (qbox)

function Framework.Notify(message, notifType, duration)
    lib.notify({ title = "Trucker", description = message, type = notifType or "info", duration = duration or 4000 })
end

function Framework.GetPlayerData()
    return QBX.PlayerData
end

function Framework.GetMoney()
    return QBX.PlayerData.money.bank
end
