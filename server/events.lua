local debug = require("shared.debug")
local server = require("config.server")
local shared = require("shared.debug")
local sharedConfig = require("config.shared")

local KEY_POLL_MS = 200
local KEY_POLL_ATTEMPTS = 15

-- Only the vehicles this job spawns for a player ever get keys: shop trucks, the rental truck
-- and the forklift (trailers are unkeyed).
local keyModels = nil
local function isKeyModel(modelHash)
    if not keyModels then
        keyModels = {
            [GetHashKey(sharedConfig.Rental.VehicleModel)] = true,
            [GetHashKey(sharedConfig.ForkliftModel)] = true,
        }
        for _, vehicle in ipairs(server.VehicleShop) do
            keyModels[GetHashKey(vehicle.model)] = true
        end
    end

    return keyModels[modelHash] == true
end

-- Bridge: the client sends the netId of a vehicle it just spawned and the server hands out keys
-- via the framework adapter. The netId is client-supplied, so the entity must be one of this
-- job's models and owned by the caller; a fresh entity is polled for a few seconds until it has
-- reached the server.
RegisterNetEvent("polarix_trucker:giveVehicleKeys", function(vehicleNetId)
    local src = source
    if not Framework.GiveVehicleKeys or type(vehicleNetId) ~= "number" then return end

    for attempt = 1, KEY_POLL_ATTEMPTS do
        local entity = NetworkGetEntityFromNetworkId(vehicleNetId)
        if entity and entity ~= 0 and DoesEntityExist(entity) and GetEntityType(entity) == 2
            and isKeyModel(GetEntityModel(entity)) and NetworkGetEntityOwner(entity) == src then
            Framework.GiveVehicleKeys(src, vehicleNetId)
            return
        end

        if attempt < KEY_POLL_ATTEMPTS then Wait(KEY_POLL_MS) end
    end

    debug.Warn(("giveVehicleKeys: refused keys for netId %s to source %s"):format(tostring(vehicleNetId), src))
end)
