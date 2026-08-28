-- Loads the active framework's client provider (config/shared.lua -> Framework)
local config = require("config.shared")

local ok, provider = pcall(require, "framework." .. config.Framework .. ".client")
if not ok then
    error(("^1[ERROR]^7 Unbekanntes Framework in config/shared.lua: %s"):format(tostring(config.Framework)))
end

-- ox_lib is always available, no per-framework branching needed
function Framework.Notify(message, notifType, duration)
    lib.notify({ title = "Trucker", description = message, type = notifType or "info", duration = duration or 4000 })
end

for fnName, fn in pairs(provider) do
    Framework[fnName] = fn
end
