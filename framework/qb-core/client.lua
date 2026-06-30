local QBCore

local function getQBCore()
    QBCore = QBCore or exports["qb-core"]:GetCoreObject()
    return QBCore
end

return {
    GetPlayerData = function()
        return getQBCore().Functions.GetPlayerData()
    end,

    GetMoney = function()
        return getQBCore().Functions.GetPlayerData().money.bank
    end,
}
