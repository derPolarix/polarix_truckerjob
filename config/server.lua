return {
    AdminPermission = "admin", -- qbx_core/qb-core permission/group name for Framework.IsAdmin
    AdminGroups = { "admin", "superadmin" }, -- esx: allowed groups for Framework.IsAdmin
    AdminAceSuffix = "trucker_admin", -- fallback ACE if the framework export is missing: command.trucker_admin

    VehicleShop = {
        { slot = "volvo-fh16",    name = "Jobuilt Hauler",          model = "hauler",   cls = "Heavy Duty", speed = 125, cap_kg = 30000, fuel_l = 700, price = 680000,  level_required = 1  },
        { slot = "kenworth-w900", name = "MTL Packer",              model = "packer",   cls = "Long-haul",  speed = 135, cap_kg = 26000, fuel_l = 750, price = 540000,  level_required = 1  },
        { slot = "scania-r730",   name = "Jobuilt Phantom",         model = "phantom",  cls = "Premium",    speed = 150, cap_kg = 28000, fuel_l = 800, price = 1250000, level_required = 10 },
    },

    TrailerShop = {
        { slot = "flatbed-box",       name = "Trailer Box Variant",       model = "trailers2",   price = 180000, level_required = 1 },
        { slot = "flatbed-container", name = "Trailer Container Variant", model = "docktrailer", price = 200000, level_required = 3 },

    },

    -- Passives Einkommen: Fahrer-Slots. price = einmaliger Kaufpreis, income = Auszahlung
    -- pro DriverIncomeIntervalMinutes (fix, unabhängig von Aktivität).
    -- WERTE SIND PLATZHALTER — noch zu balancen.
    DriverSlots = {
        { slot = "driver_0", level_required = 1,  price = 5000,   income = 50   },
        { slot = "driver_1", level_required = 2,  price = 15000,  income = 120  },
        { slot = "driver_2", level_required = 3,  price = 30000,  income = 220  },
        { slot = "driver_3", level_required = 4,  price = 55000,  income = 380  },
        { slot = "driver_4", level_required = 5,  price = 90000,  income = 600  },
        { slot = "driver_5", level_required = 6,  price = 135000, income = 850  },
        { slot = "driver_6", level_required = 7,  price = 190000, income = 1150 },
        { slot = "driver_7", level_required = 9,  price = 260000, income = 1550 },
        { slot = "driver_8", level_required = 11, price = 350000, income = 2000 },
    },
    -- Intervall in Minuten, in dem jeder angestellte Fahrer sein `income` auszahlt.
    DriverIncomeIntervalMinutes = 10,
}
