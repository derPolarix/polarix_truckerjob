local ESX

local function getESX()
    ESX = ESX or exports.es_extended:getSharedObject()
    return ESX
end

return {
    GetPlayerData = function()
        return getESX().GetPlayerData()
    end,

    GetMoney = function()
        local playerData = getESX().GetPlayerData()
        for _, account in ipairs(playerData.accounts or {}) do
            if account.name == "bank" then return account.money end
        end
        return 0
    end,
}
