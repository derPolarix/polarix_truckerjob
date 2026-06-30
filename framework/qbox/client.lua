return {
    GetPlayerData = function()
        return QBX.PlayerData
    end,

    GetMoney = function()
        return QBX.PlayerData.money.bank
    end,
}
