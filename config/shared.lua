-- Importieren mit: local config = require("config.shared")
return {
    Framework = "qbox",
    Debug = false,
    PrintDebug = true,

    -- Sprache für locales/<Language>.json (SSOT für alle User-facing Texte, Lua + NUI).
    Language = "de",

    -- name/desc sind locales/*.json-Keys, nicht Anzeigetexte — aufgelöst via Locale() in
    -- server/modules/skills.lua (Skills.GetBranchesForPlayer), damit die NUI bereits übersetzten Text bekommt.
    Skills = {
        branches = {
            { name = "skill.hauling", icon = "tabler:truck", skills = {
                { id = "h1", name = "skill.steady_hands",   desc = "skill.reduces_cargo_damage_by_15",       cost = 1, requires = nil,  effects = { cargo_damage_reduction = 0.15 } },
                { id = "h2", name = "skill.heavy_hauler",   desc = "skill.unlocks_orders_over_20_000",       cost = 2, requires = "h1", effects = { max_weight_unlock = 20000 } },
                { id = "h3", name = "skill.hazmat_license", desc = "skill.unlocks_hazmat_orders",            cost = 2, requires = "h2", effects = { unlock_hazmat = true } },
                { id = "h4", name = "skill.master_hauler",  desc = "skill.25_reward_heavy_orders",           cost = 3, requires = "h3", effects = { heavy_reward_bonus = 0.25 } },
            }},
            { name = "skill.economy", icon = "tabler:coin", skills = {
                { id = "e1", name = "skill.fuel_saver",  desc = "skill.10_less_fuel_consumption",            cost = 1, requires = nil,  effects = { fuel_modifier = 0.10 } },
                { id = "e2", name = "skill.negotiator",  desc = "skill.8_all_payouts",                       cost = 2, requires = "e1", effects = { payout_bonus = 0.08 } },
                { id = "e3", name = "skill.bulk_deals",  desc = "skill.25_discount_vehicle_purchases",       cost = 2, requires = "e2", effects = { vehicle_discount = 0.25 } },
                { id = "e4", name = "skill.tycoon",      desc = "skill.20_company_dividends",                cost = 3, requires = "e3", effects = { dividend_bonus = 0.20 } },
            }},
            { name = "skill.endurance", icon = "tabler:bolt", skills = {
                { id = "d1", name = "skill.iron_will",    desc = "skill.30_minutes_fatigue_timer",           cost = 1, requires = nil,  effects = { fatigue_bonus_minutes = 30 } },
                { id = "d2", name = "skill.night_owl",    desc = "skill.no_night_penalty_while_driving",     cost = 2, requires = "d1", effects = { night_penalty_immune = true } },
                { id = "d3", name = "skill.long_hauler",  desc = "skill.unlocks_long_haul_orders",           cost = 2, requires = "d2", effects = { unlock_long_routes = true } },
                { id = "d4", name = "skill.unstoppable",  desc = "skill.15_xp_all_deliveries",                cost = 3, requires = "d3", effects = { xp_bonus = 0.15 } },
            }},
        }
    },

    -- Index = Level (Level 1 = Index 1, kein Threshold; Level 2 benötigt 200 XP, usw.)
    XPThresholds = { 0, 200, 500, 1000, 1800, 2800, 4200, 6000, 8500, 12000, 16000 },
    SkillPointsPerLevel = 2,

    -- Gleiche Konvention wie XPThresholds, aber für Company-Level (Company.AddXP).
    CompanyXPThresholds = { 0, 500, 1200, 2200, 3600, 5500, 8000, 11000, 15000, 20000 },
    -- Einträge sind locales/*.json-Keys (siehe Skills-Kommentar oben), aufgelöst in server/callback.lua.
    LevelTitles = {
        "skill.rookie", "skill.apprentice", "skill.driver", "skill.pro_driver", "skill.senior_driver",
        "skill.expert", "skill.road_master", "skill.elite", "skill.legend", "skill.grand_champion", "skill.titan"
    },

    PalletWeightKg     = 1000,
    MaxPalletsPerOrder = 10,

    ParkingTolerance = {
        distance = 1.5,
        heading  = 12.0,
    },

    -- Radius (m) für "nearby recruits" beim Company-Invite — kein Username-System vorhanden,
    -- daher Auswahl über online Spieler in Reichweite statt Namenseingabe.
    CompanyInviteRadius = 15.0,

    PartyMaxSize = 5,

    PartyRewardMultiplier = {
        cash = 1.10, -- +10% Cash bei Party-Missionen
        xp   = 1.15, -- +15% XP bei Party-Missionen
    },

    ForkliftModel         = "forklift",
    ForkliftAttachBone    = "forks_attach",
    ForkliftAttachOffset  = { x = 0.0, y = 0.0, z = 0.05, rx = 0.0, ry = 0.0, rz = 0.0 },
    ForkliftDropMaxHeight = 0.12,

    PalletModel = "sm3d_prop_pallet_1",

    -- Feste Rental-Kombo für Spieler ohne eigenes Fahrzeug/Trailer, mit laufenden Kosten.
    -- In config/shared.lua statt config/server.lua, da Client (Rental-Dialog, Spawn) und Server
    -- (Billing) beide Zugriff brauchen — config/server.lua wird nur server-seitig geladen.
    Rental = {
        VehicleModel = "hauler",
        VehicleName  = "Rental Truck",
        TrailerModel = "trailers2",
        TrailerName  = "Rental Trailer",
        IntervalMinutes = 5,
        IntervalCost    = 500,
    },

    CompatibleTrailers = {
        ["trailers2"] = {
            maxPallets = 8,
            length = 10.5, width = 2.6,
            attachOffsets = {
                { x = -0.55, y =  3.6, z = 0.85, rx = 0.0, ry = 0.0, rz = 0.0 },
                { x =  0.55, y =  3.6, z = 0.85, rx = 0.0, ry = 0.0, rz = 0.0 },
                { x = -0.55, y =  1.2, z = 0.85, rx = 0.0, ry = 0.0, rz = 0.0 },
                { x =  0.55, y =  1.2, z = 0.85, rx = 0.0, ry = 0.0, rz = 0.0 },
                { x = -0.55, y = -1.2, z = 0.85, rx = 0.0, ry = 0.0, rz = 0.0 },
                { x =  0.55, y = -1.2, z = 0.85, rx = 0.0, ry = 0.0, rz = 0.0 },
                { x = -0.55, y = -3.6, z = 0.85, rx = 0.0, ry = 0.0, rz = 0.0 },
                { x =  0.55, y = -3.6, z = 0.85, rx = 0.0, ry = 0.0, rz = 0.0 },
            },
        },
        ["docktrailer"] = {
            maxPallets = 4,
            length = 11.0, width = 2.6,
            attachOffsets = {
                { x = 0.0, y =  3.0, z = 1.9, rx = 0.0, ry = 0.0, rz = 0.0 },
                { x = 0.0, y =  1.0, z = 1.9, rx = 0.0, ry = 0.0, rz = 0.0 },
                { x = 0.0, y = -1.0, z = 1.9, rx = 0.0, ry = 0.0, rz = 0.0 },
                { x = 0.0, y = -3.0, z = 1.9, rx = 0.0, ry = 0.0, rz = 0.0 },
            },
        },
    },
}
