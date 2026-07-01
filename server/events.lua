local debug = require("shared.debug")
local server = require("config.server")
local shared = require("shared.debug")

-- Bridge: Client sendet Fahrzeug-NetID nach Spawn → Server gibt Keys via Framework-Adapter
RegisterNetEvent("polarix_trucker:giveVehicleKeys", function(vehicleNetId)
    if Framework.GiveVehicleKeys then
        Framework.GiveVehicleKeys(source, vehicleNetId)
    end
end)


-- RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
-- end)

-- AddEventHandler('qbx_core:client:playerLoggedOut', function()
-- end)

-- AddEventHandler('QBCore:Client:OnJobUpdate', function(job)
-- end)

-- AddEventHandler('QBCore:Client:OnGangUpdate', function(gang)
-- end)
