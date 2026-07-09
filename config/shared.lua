-- Importieren mit: local config = require("config.shared")
return {
    Framework = "qbox",
    Debug = false,
    PrintDebug = true,

    Skills = {
        branches = {
            { name = "Hauling", icon = "tabler:truck", skills = {
                { id = "h1", name = "Steady Hands",   desc = "Reduziert Cargo-Schaden um 15%.",          cost = 1, requires = nil,  effects = { cargo_damage_reduction = 0.15 } },
                { id = "h2", name = "Heavy Hauler",   desc = "Ermöglicht Aufträge über 20.000 kg.",       cost = 2, requires = "h1", effects = { max_weight_unlock = 20000 } },
                { id = "h3", name = "Hazmat License", desc = "Schaltet Gefahrgut-Aufträge frei.",         cost = 2, requires = "h2", effects = { unlock_hazmat = true } },
                { id = "h4", name = "Master Hauler",  desc = "+25% Reward auf Heavy-Aufträge.",           cost = 3, requires = "h3", effects = { heavy_reward_bonus = 0.25 } },
            }},
            { name = "Economy", icon = "tabler:coin", skills = {
                { id = "e1", name = "Fuel Saver",  desc = "10% weniger Kraftstoffverbrauch.",             cost = 1, requires = nil,  effects = { fuel_modifier = 0.10 } },
                { id = "e2", name = "Negotiator",  desc = "+8% auf alle Auszahlungen.",                   cost = 2, requires = "e1", effects = { payout_bonus = 0.08 } },
                { id = "e3", name = "Bulk Deals",  desc = "25% Rabatt beim Fahrzeugkauf.",                cost = 2, requires = "e2", effects = { vehicle_discount = 0.25 } },
                { id = "e4", name = "Tycoon",      desc = "+20% Company-Dividenden.",                     cost = 3, requires = "e3", effects = { dividend_bonus = 0.20 } },
            }},
            { name = "Endurance", icon = "tabler:bolt", skills = {
                { id = "d1", name = "Iron Will",    desc = "+30 Minuten Fatigue-Timer.",                  cost = 1, requires = nil,  effects = { fatigue_bonus_minutes = 30 } },
                { id = "d2", name = "Night Owl",    desc = "Keine Nacht-Penalty beim Fahren.",            cost = 2, requires = "d1", effects = { night_penalty_immune = true } },
                { id = "d3", name = "Long Hauler",  desc = "Schaltet Langstrecken-Aufträge frei.",        cost = 2, requires = "d2", effects = { unlock_long_routes = true } },
                { id = "d4", name = "Unstoppable",  desc = "+15% XP auf alle Lieferungen.",               cost = 3, requires = "d3", effects = { xp_bonus = 0.15 } },
            }},
        }
    },

    -- Index = Level (Level 1 = Index 1, kein Threshold; Level 2 benötigt 200 XP, usw.)
    XPThresholds = { 0, 200, 500, 1000, 1800, 2800, 4200, 6000, 8500, 12000, 16000 },
    SkillPointsPerLevel = 2,

    -- Gleiche Konvention wie XPThresholds, aber für Company-Level (Company.AddXP).
    CompanyXPThresholds = { 0, 500, 1200, 2200, 3600, 5500, 8000, 11000, 15000, 20000 },
    LevelTitles = {
        "Rookie", "Apprentice", "Driver", "Pro Driver", "Senior Driver",
        "Expert", "Road Master", "Elite", "Legend", "Grand Champion", "Titan"
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
        ["trailers"] = {
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
