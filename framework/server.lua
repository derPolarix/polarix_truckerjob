-- Framework adapter - server side
-- Loads the active framework's server provider (config/shared.lua -> Framework)
local config = require("config.shared")

local ok, provider = pcall(require, "framework." .. config.Framework .. ".server")
if not ok then
    error(("[polarix_trucker] Unbekanntes Framework in config/shared.lua: %s"):format(tostring(config.Framework)))
end

for fnName, fn in pairs(provider) do
    Framework[fnName] = fn
end
