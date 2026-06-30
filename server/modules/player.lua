local config = require("config.shared")

PlayerCache = {} -- source -> playerData

Player = {}

local function buildPlayerData(identifier, row)
    return {
        identifier         = identifier,
        name               = row.name,
        level              = row.level,
        xp                 = row.xp,
        skill_points       = row.skill_points,
        skills             = json.decode(row.skills) or {},
        total_earnings     = row.total_earnings,
        total_deliveries   = row.total_deliveries,
        failed_deliveries  = row.failed_deliveries,
        equipped_vehicle   = row.equipped_vehicle,
    }
end

function Player.Load(source)
    local identifier = Framework.GetPlayerIdentifier(source)
    if not identifier then return end

    local row = DB.GetPlayer(identifier)
    if not row then
        DB.CreatePlayer(identifier, Framework.GetPlayerName(source))
        row = DB.GetPlayer(identifier)
    end

    local data = buildPlayerData(identifier, row)
    PlayerCache[source] = data

    TriggerClientEvent("polarix_trucker:playerUpdate", source, {
        level = data.level, xp = data.xp, skill_points = data.skill_points
    })

    return data
end

function Player.Save(source)
    local data = PlayerCache[source]
    if not data then return end
    DB.SavePlayer(data.identifier, data)
end

function Player.GetData(source)
    return PlayerCache[source]
end

function Player.AddXP(source, amount)
    local data = PlayerCache[source]
    if not data then return end

    data.xp = data.xp + amount

    local thresholds = config.XPThresholds
    while data.level < #thresholds and data.xp >= thresholds[data.level + 1] do
        data.level = data.level + 1
        data.skill_points = data.skill_points + config.SkillPointsPerLevel
        TriggerClientEvent("polarix_trucker:levelUp", source, data.level)
    end

    TriggerClientEvent("polarix_trucker:playerUpdate", source, {
        level = data.level, xp = data.xp, skill_points = data.skill_points
    })
end

function Player.HasSkill(source, skillId)
    local data = PlayerCache[source]
    if not data then return false end
    for _, id in ipairs(data.skills) do
        if id == skillId then return true end
    end
    return false
end

Framework.OnPlayerLoaded(function(source)
    Player.Load(source)
end)

Framework.OnPlayerUnload(function(source)
    Player.Save(source)
    PlayerCache[source] = nil
end)
