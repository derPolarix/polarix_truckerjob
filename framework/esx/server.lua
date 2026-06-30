local ESX

local function getESX()
    ESX = ESX or exports.es_extended:getSharedObject()
    return ESX
end

return {
    GetPlayerIdentifier = function(source)
        local xPlayer = getESX().GetPlayerFromId(source)
        return xPlayer and xPlayer.identifier or nil
    end,

    GetPlayerName = function(source)
        local xPlayer = getESX().GetPlayerFromId(source)
        return xPlayer and xPlayer.getName() or "Unknown"
    end,

    AddMoney = function(source, amount)
        local xPlayer = getESX().GetPlayerFromId(source)
        if xPlayer then xPlayer.addAccountMoney("bank", amount) end
    end,

    RemoveMoney = function(source, amount)
        local xPlayer = getESX().GetPlayerFromId(source)
        if xPlayer then xPlayer.removeAccountMoney("bank", amount) end
    end,

    GetMoney = function(source)
        local xPlayer = getESX().GetPlayerFromId(source)
        if not xPlayer then return 0 end
        local account = xPlayer.getAccount("bank")
        return account and account.money or 0
    end,

    HasJob = function(source, jobName)
        local xPlayer = getESX().GetPlayerFromId(source)
        return xPlayer and xPlayer.job.name == jobName or false
    end,
}
