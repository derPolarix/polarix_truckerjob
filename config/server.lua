-- Importieren mit: local config = require("config.server")
return {
    -- TEMPORÄR: Initiale Aufträge bis Admin-Menü existiert.
    -- ZIEL: Alle Aufträge ausschliesslich via Admin-Menü verwalten, diese Config entfernen.
    SeedOrders = {
        {
            id = "order-al", name = "Alcohols", cargo = "Fragile", cargo_type = "fragile",
            weight_kg = 4300, distance_km = 6.0, reward_base = 43500, xp_base = 4, time_minutes = 165,
            pickup_label = "Paleto Bay Main Street", pickup_city = "Paleto Bay",
            pickup_x = -105.0, pickup_y = 6474.0, pickup_z = 31.0,
            dropoff_label = "Mirror Park Boulevard", dropoff_city = "Los Santos",
            dropoff_x = 1185.0, dropoff_y = -321.0, dropoff_z = 69.0,
            comment = "Handle with care! Fragile goods inside.",
            tag = "FRAGILE", tag_color = "#b58a05", tag_bg = "rgba(232,180,8,0.16)", icon = "tabler:bottle",
            level_required = 1, requires_hazmat = false, requires_long_hauler = false,
            pickup_heading = 0.0, dropoff_heading = 0.0,
        },
        {
            id = "order-st", name = "Steel Beams", cargo = "Heavy", cargo_type = "heavy",
            weight_kg = 18000, distance_km = 12.0, reward_base = 95000, xp_base = 9, time_minutes = 240,
            pickup_label = "LSIA Freight Yard", pickup_city = "Los Santos",
            pickup_x = -1055.0, pickup_y = -2663.0, pickup_z = 13.0,
            dropoff_label = "Grand Senora Desert Site", dropoff_city = "Grand Senora",
            dropoff_x = 1960.0, dropoff_y = 3760.0, dropoff_z = 32.0,
            comment = "Heavy load — secure properly before transit.",
            tag = "HEAVY", tag_color = "#6b7280", tag_bg = "rgba(107,114,128,0.16)", icon = "tabler:crane",
            level_required = 3, requires_hazmat = false, requires_long_hauler = false,
            pickup_heading = 0.0, dropoff_heading = 0.0,
        },
        {
            id = "order-ch", name = "Chemical Drums", cargo = "Hazmat", cargo_type = "hazmat",
            weight_kg = 6200, distance_km = 8.5, reward_base = 72000, xp_base = 7, time_minutes = 195,
            pickup_label = "Elysian Island Port", pickup_city = "Los Santos",
            pickup_x = 476.0, pickup_y = -3000.0, pickup_z = 6.0,
            dropoff_label = "Route 68 Processing Plant", dropoff_city = "Blaine County",
            dropoff_x = 762.0, dropoff_y = 2930.0, dropoff_z = 40.0,
            comment = "Hazardous materials — licensed drivers only.",
            tag = "HAZMAT", tag_color = "#dc2626", tag_bg = "rgba(220,38,38,0.16)", icon = "tabler:biohazard",
            level_required = 1, requires_hazmat = true, requires_long_hauler = false,
            pickup_heading = 0.0, dropoff_heading = 0.0,
        },
        {
            id = "order-lv", name = "Livestock", cargo = "Live Animals", cargo_type = "live",
            weight_kg = 3800, distance_km = 15.0, reward_base = 58000, xp_base = 6, time_minutes = 210,
            pickup_label = "Grapeseed Farm", pickup_city = "Blaine County",
            pickup_x = 1705.0, pickup_y = 4870.0, pickup_z = 42.0,
            dropoff_label = "Maze Bank Arena Stockyard", dropoff_city = "Los Santos",
            dropoff_x = -310.0, dropoff_y = -1800.0, dropoff_z = 24.0,
            comment = "Live animals — drive carefully, no harsh braking.",
            tag = "LIVE", tag_color = "#16a34a", tag_bg = "rgba(22,163,74,0.16)", icon = "tabler:paw",
            level_required = 2, requires_hazmat = false, requires_long_hauler = false,
            pickup_heading = 0.0, dropoff_heading = 0.0,
        },
        {
            id = "order-cr", name = "Crates (Standard)", cargo = "Standard", cargo_type = "standard",
            weight_kg = 2100, distance_km = 3.5, reward_base = 18000, xp_base = 2, time_minutes = 90,
            pickup_label = "Pillbox Hill Depot", pickup_city = "Los Santos",
            pickup_x = 205.0, pickup_y = -810.0, pickup_z = 31.0,
            dropoff_label = "La Mesa Industrial", dropoff_city = "Los Santos",
            dropoff_x = 919.4861, dropoff_y = -1563.5834, dropoff_z = 30.7582,
            comment = "Standard freight — no special requirements.",
            tag = "STD", tag_color = "#3b82f6", tag_bg = "rgba(59,130,246,0.16)", icon = "tabler:package",
            level_required = 1, requires_hazmat = false, requires_long_hauler = false,
            pickup_heading = 0.0, dropoff_heading = 90.1649,
        },
    },

    VehicleShop = {
        { slot = "volvo-fh16",    name = "Volvo FH16 Globetrotter", model = "hauler",   cls = "Heavy Duty", speed = 125, cap_kg = 30000, fuel_l = 700, price = 680000,  level_required = 1  },
        { slot = "kenworth-w900", name = "Kenworth W900",           model = "packer",   cls = "Long-haul",  speed = 135, cap_kg = 26000, fuel_l = 750, price = 540000,  level_required = 1  },
        { slot = "scania-r730",   name = "Scania R730 V8",          model = "phantom",  cls = "Premium",    speed = 150, cap_kg = 28000, fuel_l = 800, price = 1250000, level_required = 10 },
        { slot = "freightliner",  name = "Freightliner Cascadia",   model = "hauler2",  cls = "Long-haul",  speed = 130, cap_kg = 27000, fuel_l = 720, price = 610000,  level_required = 1  },
    },

    TrailerShop = {
        { slot = "flatbed-std",   name = "Flatbed Standard",   model = "trailers2", price = 180000, level_required = 1 },
        { slot = "container-std", name = "Container Standard", model = "trailers",  price = 220000, level_required = 3 },
    },
}
