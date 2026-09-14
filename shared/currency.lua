-- Money formatter (SSOT: Config.Currency); usage: local Money = require("shared.currency")
-- Turns a number into the display string every notify and NUI value uses, so the
-- symbol and its position are decided in exactly one place.

local SharedConfig = require("config.shared")

local DEFAULT_SYMBOL   = "$"
local DEFAULT_POSITION = "prefix"

return function(amount)
    local config   = SharedConfig.Currency or {}
    local symbol   = config.symbol or DEFAULT_SYMBOL
    local position = config.position or DEFAULT_POSITION
    local grouped  = lib.math.groupdigits(math.floor(tonumber(amount) or 0), ',')

    -- suffix currencies are conventionally written with a space, prefix ones without
    if position == "suffix" then
        return grouped .. " " .. symbol
    end

    return symbol .. grouped
end
