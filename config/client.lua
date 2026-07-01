-- Importieren mit: local config = require("config.client")
return {
    TruckDepotCoords = vector4(157.8733, -3200.3081, 6.0219, 267.5656),

    -- Jeder Eintrag: vec4 (x, y, z, heading). Spawn wählt zufällig einen freien Punkt.
    VehicleSpawnPoints = {
        vector4(164.6270, -3217.6768, 6.1488, 271.7001),
        vector4(165.2691, -3235.8877, 6.1331, 270.5462),
        vector4(167.6816, -3259.7295, 6.0871, 269.5370),
    },

    -- true = Spieler wird nach dem Spawnen ins Fahrzeug teleportiert
    TeleportIntoVehicle = true,

    DepotBlip = { sprite = 477, color = 5, scale = 0.9, name = "Truck Depot" },
}
