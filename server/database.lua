local debug = require("shared.debug")
local server = require("config.server")
local shared = require("shared.debug")


function LoadDatabaseToCache()
    -- Example function to load data from the database into a cache
    -- local result = MySQL.query.await("SELECT * FROM " .. server.database_table)

    -- for _, row in ipairs(result) do
    --     LocalCache.table[row.COLUMNNAME] = row
    -- end
    -- return true
end