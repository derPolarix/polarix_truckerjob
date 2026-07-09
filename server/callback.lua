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
    local ownedTrailers = DB.GetPlayerTrailers(pData.identifier)

    local trailerShop = {}
    for _, entry in ipairs(server.TrailerShop) do
        local trailerConfig = sharedConfig.CompatibleTrailers[entry.model]
        trailerShop[#trailerShop + 1] = {
            slot            = entry.slot,
            name            = entry.name,
            model           = entry.model,
            price           = entry.price,
            level_required  = entry.level_required,
            maxPallets      = trailerConfig and trailerConfig.maxPallets or 0,
        }
    end

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
            equipped_trailer  = pData.equipped_trailer,
            balance           = Framework.GetMoney(source),
        },
        orders        = Orders.GetAvailableForPlayer(source),
        ownedVehicles = ownedVehicles,
        vehicleShop   = server.VehicleShop,
        ownedTrailers = ownedTrailers,
        trailerShop   = trailerShop,
        skillBranches = Skills.GetBranchesForPlayer(source),
        levelTitles   = sharedConfig.LevelTitles,
        xpThresholds  = sharedConfig.XPThresholds,
        company            = companyData,
        myRole             = membership and membership.role or nil,
        openCompanies      = (not membership) and DB.GetOpenRecruitmentCompanies() or nil,
        leaderboard        = Leaderboard.GetGlobal(),
        companyLeaderboard = Leaderboard.GetCompanies(),
        history            = Leaderboard.GetHistory(source),
        notifications      = Notifications.GetForPlayer(pData.identifier),
    }
end)
