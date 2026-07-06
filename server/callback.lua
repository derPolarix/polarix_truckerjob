local server = require("config.server")
local sharedConfig = require("config.shared")

-- lib.callback.register('polarix_template:getPlayerJob', function(source, item, metadata, target)
--     local player = exports.qbx_core:GetPlayer(source)
--     return player.PlayerData.job.name
-- end)

lib.callback.register("polarix_trucker:openDashboard", function(source)
    local pData = Player.GetData(source)
    if not pData then
        pData = Player.Load(source)
    end
    if not pData then return nil end

    local ownedVehicles = DB.GetPlayerVehicles(pData.identifier)

    local membership = Company.GetMembership(pData.identifier)
    local companyData = nil
    if membership then
        companyData = Company.GetFull(membership.company_id, pData.identifier)
    end

    return {
        player = {
            name              = pData.name,
            level             = pData.level,
            xp                = pData.xp,
            skill_points      = pData.skill_points,
            skills            = pData.skills,
            total_earnings    = pData.total_earnings,
            total_deliveries  = pData.total_deliveries,
            failed_deliveries = pData.failed_deliveries,
            equipped_vehicle  = pData.equipped_vehicle,
            balance           = Framework.GetMoney(source),
        },
        orders        = Orders.GetAvailableForPlayer(source),
        ownedVehicles = ownedVehicles,
        vehicleShop   = server.VehicleShop,
        skillBranches = Skills.GetBranchesForPlayer(source),
        levelTitles   = sharedConfig.LevelTitles,
        xpThresholds  = sharedConfig.XPThresholds,
        company            = companyData,
        myRole             = membership and membership.role or nil,
        leaderboard        = Leaderboard.GetGlobal(),
        companyLeaderboard = Leaderboard.GetCompanies(),
        history            = Leaderboard.GetHistory(source),
    }
end)
