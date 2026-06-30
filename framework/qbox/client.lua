return {
    GetPlayerData = function()
        return exports.qbx_core:GetPlayerData()
    end,

    GetMoney = function()
        return exports.qbx_core:GetPlayerData().money.bank
    end,
}
