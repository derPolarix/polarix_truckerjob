-- Data for the "Import Sample Missions" button in the admin mission editor
-- (see server/modules/admin_missions.lua AdminMissions.ImportSampleMissions).
--
-- Values below are the in-game tuned set exported from a live table
-- (internal-docs/sample-missions.json) - coordinates, headings and per-km rates were all set in the
-- editor on a running server, so the routes are drivable and the payouts are the ones that were played.
-- reward_base/xp_base are derived on import by the same helper the editor uses; distance_km matches
-- the straight-line distance between the coordinates, so distance_manual stays off.
return {
    {
        id = "order-al", name = "Alcohols", cargo = "Fragile", cargo_type = "fragile",
        weight_kg = 4300, distance_km = 6.7, distance_manual = false, reward_per_km = 7250, xp_per_km = 0.666667, time_minutes = 165,
        pickup_label = "Paleto Bay Main Street", pickup_city = "Paleto Bay",
        pickup_x = 89.0798, pickup_y = 6334.58, pickup_z = 31.2257,
        dropoff_label = "Mirror Park Boulevard", dropoff_city = "Los Santos",
        dropoff_x = 1178.35, dropoff_y = -315.426, dropoff_z = 69.1783,
        comment = "Handle with care! Fragile and tasty goods inside.",
        tag = "FRAGILE", tag_color = "#b58a05", tag_bg = "rgba(232,180,8,0.16)", icon = "tabler:bottle",
        level_required = 1, requires_hazmat = false, requires_long_hauler = false,
        pickup_heading = 119.954, dropoff_heading = 278.573, cooldown_seconds = 1800,
    },
    {
        id = "order-st", name = "Steel Beams", cargo = "Heavy", cargo_type = "heavy",
        weight_kg = 18000, distance_km = 7.1, distance_manual = false, reward_per_km = 7917, xp_per_km = 0.75, time_minutes = 240,
        pickup_label = "LSIA Freight Yard", pickup_city = "Los Santos",
        pickup_x = -892.514, pickup_y = -2740.97, pickup_z = 13.8285,
        dropoff_label = "Grand Senora Desert Site", dropoff_city = "Grand Senora",
        dropoff_x = 1968.9, dropoff_y = 3751.97, dropoff_z = 32.196,
        comment = "Heavy load — secure properly before transit.",
        tag = "HEAVY", tag_color = "#6b7280", tag_bg = "rgba(107,114,128,0.16)", icon = "tabler:crane",
        level_required = 3, requires_hazmat = false, requires_long_hauler = false,
        pickup_heading = 338.753, dropoff_heading = 211.271, cooldown_seconds = 0,
    },
    {
        id = "order-lv", name = "Livestock", cargo = "Live Animals", cargo_type = "live",
        weight_kg = 3800, distance_km = 7.3, distance_manual = false, reward_per_km = 3867, xp_per_km = 0.4, time_minutes = 210,
        pickup_label = "Grapeseed Farm", pickup_city = "Blaine County",
        pickup_x = 2007.57, pickup_y = 4987.1, pickup_z = 41.3659,
        dropoff_label = "Maze Bank Arena Stockyard", dropoff_city = "Los Santos",
        dropoff_x = -389.538, dropoff_y = -1875.46, dropoff_z = 20.5279,
        comment = "Live animals — drive carefully, no harsh braking.",
        tag = "LIVE", tag_color = "#16a34a", tag_bg = "rgba(22,163,74,0.16)", icon = "tabler:paw",
        level_required = 2, requires_hazmat = false, requires_long_hauler = false,
        pickup_heading = 222.501, dropoff_heading = 303.121, cooldown_seconds = 0,
    },
    {
        id = "order-cr", name = "Crates (Standard)", cargo = "Standard", cargo_type = "standard",
        weight_kg = 2100, distance_km = 1.0, distance_manual = false, reward_per_km = 18000, xp_per_km = 2.0, time_minutes = 90,
        pickup_label = "Pillbox Hill Depot", pickup_city = "Los Santos",
        pickup_x = 505.163, pickup_y = -605.652, pickup_z = 24.7511,
        dropoff_label = "La Mesa Industrial", dropoff_city = "Los Santos",
        dropoff_x = 919.486, dropoff_y = -1563.58, dropoff_z = 30.7582,
        comment = "Standard freight — no special requirements.",
        tag = "STD", tag_color = "#3b82f6", tag_bg = "rgba(59,130,246,0.16)", icon = "tabler:package",
        level_required = 1, requires_hazmat = false, requires_long_hauler = false,
        pickup_heading = 263.288, dropoff_heading = 90.1649, cooldown_seconds = 3600,
    },
}
