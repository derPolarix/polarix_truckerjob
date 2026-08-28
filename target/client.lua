-- Loads the active target system's client provider (config/shared.lua -> Target)
local config = require("config.shared")

Target = {}

local ok, provider = pcall(require, "target." .. config.Target .. ".client")
if not ok then
    error(("^1[ERROR]^7 Unbekanntes Target-System in config/shared.lua: %s"):format(tostring(config.Target)))
end

for fnName, fn in pairs(provider) do
    Target[fnName] = fn
end
