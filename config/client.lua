return {
    TruckDepotCoords = vector4(157.8733, -3200.3081, 6.0219, 267.5656),

    -- Spawn picks a random free point from this list.
    VehicleSpawnPoints = {
        vector4(171.9114, -3217.7483, 5.9814, 271.3356),
        vector4(170.4050, -3235.7805, 6.0557, 271.2271),
        vector4(170.2728, -3290.9385, 6.0459, 270.7673),
    },

    TeleportIntoVehicle = true,

    DepotBlip = { sprite = 477, color = 5, scale = 0.9, name = "Truck Depot" },

    ForkliftDeployOffset = { x = 0.0, y = -7.0, z = 0.0 },
    ForkliftSpawnOffset = { x = 0.0, y = -10.5, z = 0.0 },

    ForkliftInteractionRadiusFoot    = 3.0,
    ForkliftInteractionRadiusVehicle = 5.5,

    -- Default keys, using FiveM keyboard names: https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/keyboard/
    -- Players can rebind them in Settings > Key Bindings > FiveM. A default only applies to players who
    -- never had that binding saved, so changing it later won't affect players who already joined.
    Keybinds = {
        OpenDepot     = "E", -- open the job at the depot NPC (only without a target system)
        ForkliftDock  = "E", -- deploy/stow forklift and load pallet at the trailer (only without a target system)
        PalletPickup  = "G", -- pick up a pallet with the forklift
        UnloadDropoff = "E", -- unload cargo once the trailer is parked at the dropoff
    },
}
