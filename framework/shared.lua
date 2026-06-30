-- Framework adapter - shared (client + server)
-- Loaded before all other scripts. Defines framework-agnostic globals.
-- Active framework is set in config/shared.lua -> Framework (e.g. "qbox", "qb-core", "esx")
local config = require("config.shared")

Framework = {}

local ok, provider = pcall(require, "framework." .. config.Framework .. ".shared")
if not ok then
    error(("[polarix_trucker] Unbekanntes Framework in config/shared.lua: %s"):format(tostring(config.Framework)))
end

for fnName, fn in pairs(provider) do
    Framework[fnName] = fn
end
