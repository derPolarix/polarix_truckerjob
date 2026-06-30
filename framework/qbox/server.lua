return {
    GetPlayerIdentifier = function(source)
        local player = exports.qbx_core:GetPlayer(source)
        return player and player.PlayerData.citizenid or nil
    end,

    GetPlayerName = function(source)
        local player = exports.qbx_core:GetPlayer(source)
        if not player then return "Unknown" end
        local d = player.PlayerData.charinfo
        return d.firstname .. " " .. d.lastname
    end,

    AddMoney = function(source, amount)
        local player = exports.qbx_core:GetPlayer(source)
        if player then player.Functions.AddMoney("bank", amount) end
    end,

    RemoveMoney = function(source, amount)
        local player = exports.qbx_core:GetPlayer(source)
        if player then player.Functions.RemoveMoney("bank", amount) end
    end,

    GetMoney = function(source)
        local player = exports.qbx_core:GetPlayer(source)
        return player and player.PlayerData.money.bank or 0
    end,

    HasJob = function(source, jobName)
        local player = exports.qbx_core:GetPlayer(source)
        return player and player.PlayerData.job.name == jobName or false
    end,

    OnPlayerLoaded = function(callback)
        RegisterNetEvent("QBCore:Server:PlayerLoaded", function(player)
            callback(player.PlayerData.source)
        end)
    end,

    OnPlayerUnload = function(callback)
        RegisterNetEvent("QBCore:Server:OnPlayerUnload", function(source)
            callback(source)
        end)
    end,
}
