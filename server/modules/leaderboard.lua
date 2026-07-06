Leaderboard = {}

function Leaderboard.GetGlobal()
    return DB.GetLeaderboardGlobal(20)
end

function Leaderboard.GetCompanies()
    return DB.GetLeaderboardCompanies(10)
end

function Leaderboard.GetHistory(source)
    local pData = Player.GetData(source)
    if not pData then return {} end
    return DB.GetDeliveryHistory(pData.identifier, 30)
end
