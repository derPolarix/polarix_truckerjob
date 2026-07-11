return {
    Framework = "qbox",
    Debug = false,
    PrintDebug = true,

    -- language for locales/<Language>.json, the SSOT for all user-facing text
    Language = "de",

    -- name/desc are locales/*.json keys, not display text — resolved via Locale()
    -- in Skills.GetBranchesForPlayer
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

    -- index = level (index 1 = level 1, no threshold)
    XPThresholds = { 0, 200, 500, 1000, 1800, 2800, 4200, 6000, 8500, 12000, 16000 },
    SkillPointsPerLevel = 2,

    -- same convention as XPThresholds, but for company level (Company.AddXP)
    CompanyXPThresholds = { 0, 500, 1200, 2200, 3600, 5500, 8000, 11000, 15000, 20000 },
    -- locales/*.json keys, resolved in server/callback.lua
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

    -- "nearby recruits" radius (m) for company invite — no username system, so pick
    -- from online players in range instead of typing a name
    CompanyInviteRadius = 15.0,

    PartyMaxSize = 5,

    PartyRewardMultiplier = {
        cash = 1.10,
        xp   = 1.15,
    },

    ForkliftModel         = "forklift",
    ForkliftAttachBone    = "forks_attach",
    ForkliftAttachOffset  = { x = 0.0, y = 0.0, z = 0.05, rx = 0.0, ry = 0.0, rz = 0.0 },
    ForkliftDropMaxHeight = 0.12,

    PalletModel = "sm3d_prop_pallet_1",

    -- Fixed rental combo for players without their own vehicle/trailer. Lives here
    -- (not config/server.lua) because both client (dialog, spawn) and server (billing) need it.
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
