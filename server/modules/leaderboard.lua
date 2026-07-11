local Locale = require("shared.locale")

Leaderboard = {}

-- companyId -> true while notified for current top-3 streak; cleared once rank drops out.
-- Resets on resource restart (a company already in top 3 may get re-notified once) — acceptable.
local companyTop3Notified = {}

function Leaderboard.CheckCompanyTop3(companyId)
    local rank = DB.GetCompanyRank(companyId)
    if not rank then return end

    if rank <= 3 then
        if companyTop3Notified[companyId] then return end
        companyTop3Notified[companyId] = true

        local owner = DB.GetCompanyOwner(companyId)
        if not owner then return end

        local place = rank == 1 and "1st" or (rank == 2 and "2nd" or "3rd")
        Notifications.Push(owner.identifier, "leaderboard_top3", Locale("push.top_3"),
            Locale("push.company_reached_place_leaderboard"):format(place), "tabler:trophy")
    else
        companyTop3Notified[companyId] = nil
    end
end

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
