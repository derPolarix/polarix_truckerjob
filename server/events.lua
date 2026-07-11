local debug = require("shared.debug")
local server = require("config.server")
local shared = require("shared.debug")

-- Bridge: Client sendet Fahrzeug-NetID nach Spawn → Server gibt Keys via Framework-Adapter
RegisterNetEvent("polarix_trucker:giveVehicleKeys", function(vehicleNetId)
    if Framework.GiveVehicleKeys then
        Framework.GiveVehicleKeys(source, vehicleNetId)
    end
end)
