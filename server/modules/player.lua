local config = require("config.shared")
local Locale = require("shared.locale")

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
        equipped_trailer   = row.equipped_trailer,
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
        level = data.level, xp = data.xp, skill_points = data.skill_points, skills = data.skills
    })

    -- Ausgerüstetes Fahrzeug zum Client synchronisieren (für /getruck ohne UI-Open)
    if data.equipped_vehicle then
        local vehicles = DB.GetPlayerVehicles(identifier)
        for _, v in ipairs(vehicles) do
            if v.vehicle_slot == data.equipped_vehicle then
                TriggerClientEvent("polarix_trucker:vehicleSync", source, data.equipped_vehicle, v.vehicle_model)
                break
            end
        end
    end

    local trailers = DB.GetPlayerTrailers(identifier)
    if not data.equipped_trailer and #trailers > 0 then
        data.equipped_trailer = trailers[1].trailer_slot
        Player.Save(source)
    end

    if data.equipped_trailer then
        for _, t in ipairs(trailers) do
            if t.trailer_slot == data.equipped_trailer then
                TriggerClientEvent("polarix_trucker:trailerSync", source, data.equipped_trailer, t.trailer_model)
                break
            end
        end
    end

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

function Player.GetSourceByIdentifier(identifier)
    for src, pd in pairs(PlayerCache) do
        if pd.identifier == identifier then return src end
    end
    return nil
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
        Notifications.Push(data.identifier, "level_up", Locale("push.level_up"), Locale("push.reached_level"):format(data.level), "tabler:star")
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
    Orders.CleanupStaleDelivery(source)
end)

Framework.OnPlayerUnload(function(source)
    Player.Save(source)
    PlayerCache[source] = nil
end)
