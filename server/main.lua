local debug = require("shared.debug")
local server = require("config.server")
local shared = require("shared.debug")
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
