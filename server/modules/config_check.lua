-- Validates config/shared.lua's Framework/Target against the values the
-- resource actually ships adapters for, and prints a clear server console
-- error if either is misconfigured.
local config = require("config.shared")

local ALLOWED_FRAMEWORKS = { qbox = true, ["qb-core"] = true, esx = true }
local ALLOWED_TARGETS    = { ox_target = true, ["qb-target"] = true, sleepless_interact = true, none = true }

local function listKeys(t)
    local keys = {}
    for k in pairs(t) do keys[#keys + 1] = k end
    table.sort(keys)
    return table.concat(keys, ", ")
end

if not ALLOWED_FRAMEWORKS[config.Framework] then
    print(("^1[polarix_trucker] Invalid Framework \"%s\" in config/shared.lua — allowed values: %s^7")
        :format(tostring(config.Framework), listKeys(ALLOWED_FRAMEWORKS)))
end

if not ALLOWED_TARGETS[config.Target] then
    print(("^1[polarix_trucker] Invalid Target \"%s\" in config/shared.lua — allowed values: %s^7")
        :format(tostring(config.Target), listKeys(ALLOWED_TARGETS)))
end
