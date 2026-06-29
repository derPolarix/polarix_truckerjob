local debug = require("shared.debug")
local server = require("config.server")
local shared = require("shared.debug")
local triggerEventHooks = require '@polarix_utils.server.hooks' -- Import triggerEventHooks function from hooks module

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end

    -- Create a database table onResourceStart

    -- MySQL.query.await([[
    --     CREATE TABLE IF NOT EXISTS ]] .. server.database_table .. [[ (
    --        COLUMNNAME TEXT
    --     )
    -- ]])

    -- Am Ende alles in Cacheladen
    LoadDatabaseToCache()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
end)

-- Hier ist ein Beispiel wie ein Hook registriert werden kann, um bei einem Event "polarix_template:server:hookExample" eine Bedingung zu prüfen
-- und ggf. die Ausführung zu stoppen vom Event. Aus QBX Core kopiert und in eigenen Utils verbaut.

-- exports.polarix_utils:registerHook('template:checkCondition', function(payload)
--   -- payload contains everything passed into triggerEventHooks, which will depend on the resource to document
--   if payload.myNumber == 10 then
--     return true -- Continue as normal
--   else
--     return false -- Stop execution
--   end
-- end)

-- RegisterNetEvent('polarix_template:server:hookExample', function(data)
--     local src = source
--     local Player = QBX.GetPlayer(src)
--     if not triggerEventHooks('template:checkCondition', {source = src, myNumber = 10}) then return end -- Example of using triggerEventHooks
-- end)
