local server = require("config.server")
local sharedConfig = require("config.shared")
local Locale = require("shared.locale")
local debug = require("shared.debug")

local function localizeList(keys)
    local out = {}
    for i, key in ipairs(keys) do out[i] = Locale(key) end
    return out
end

local function buildDashboardData(source, pData)
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
        language = sharedConfig.Language,
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
        driverSlots      = server.DriverSlots,
        ownedDriverSlots = DB.GetPlayerDriverSlots(pData.identifier),
        driverIncomeIntervalMinutes = server.DriverIncomeIntervalMinutes,
        levelTitles   = localizeList(sharedConfig.LevelTitles),
        xpThresholds  = sharedConfig.XPThresholds,
        company            = companyData,
        myRole             = membership and membership.role or nil,
        openCompanies      = (not membership) and DB.GetOpenRecruitmentCompanies() or nil,
        incomingInvites    = (not membership) and Company.GetIncomingInvites(pData.identifier) or nil,
        leaderboard        = Leaderboard.GetGlobal(),
        companyLeaderboard = Leaderboard.GetCompanies(),
        history            = Leaderboard.GetHistory(source),
        notifications      = Notifications.GetForPlayer(pData.identifier),
        party              = Party.BuildState(PlayerParty[pData.identifier]),
        partyRewardMultiplier = sharedConfig.PartyRewardMultiplier,
    }
end

lib.callback.register("polarix_trucker:openDashboard", function(source)
    local pData = Player.GetData(source)
    if not pData then
        pData = Player.Load(source)
    end
    if not pData then
        debug.DebugPrint(("openDashboard: no player data for source %s — Player.Load failed, see Player.Load log above"):format(source))
        return nil
    end

    local ok, result = xpcall(buildDashboardData, tostring, source, pData)
    if not ok then
        debug.DebugPrint(("openDashboard: error building dashboard data for %s: %s"):format(pData.identifier, tostring(result)))
        return nil
    end

    return result
end)
