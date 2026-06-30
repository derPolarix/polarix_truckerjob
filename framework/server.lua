-- Framework adapter - server side (qbox)

function Framework.GetPlayerIdentifier(source)
    local player = exports.qbx_core:GetPlayer(source)
    return player and player.PlayerData.citizenid or nil
end

function Framework.GetPlayerName(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return "Unknown" end
    local d = player.PlayerData.charinfo
    return d.firstname .. " " .. d.lastname
end

function Framework.AddMoney(source, amount)
    local player = exports.qbx_core:GetPlayer(source)
    if player then player.Functions.AddMoney("bank", amount) end
end

function Framework.RemoveMoney(source, amount)
    local player = exports.qbx_core:GetPlayer(source)
    if player then player.Functions.RemoveMoney("bank", amount) end
end

function Framework.GetMoney(source)
    local player = exports.qbx_core:GetPlayer(source)
    return player and player.PlayerData.money.bank or 0
end

function Framework.HasJob(source, jobName)
    local player = exports.qbx_core:GetPlayer(source)
    return player and player.PlayerData.job.name == jobName or false
end
