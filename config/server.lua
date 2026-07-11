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
        { slot = "flatbed-std",   name = "Trailer Box Variant",   model = "trailers2", price = 180000, level_required = 1 },
        { slot = "flatbed-std",   name = "Trailer Container Variant",   model = "docktrailer", price = 200000, level_required = 3 },

    },
}
