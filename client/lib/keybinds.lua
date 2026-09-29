-- Single entry point for keybinds; default keys come from config/client.lua (Keybinds).
-- Usage: local Keybinds = require("client.lib.keybinds")
local clientConfig = require("config.client")
local Locale = require("shared.locale")

-- Names must stay stable: FiveM stores each player's custom binding under this name.
local BINDS = {
    OpenDepot     = { name = "polarix_trucker_open_depot",     description = "keybind.open_depot" },
    ForkliftDock  = { name = "polarix_trucker_forklift_dock",  description = "keybind.forklift_dock" },
    PalletPickup  = { name = "polarix_trucker_pallet_pickup",  description = "keybind.pallet_pickup" },
    UnloadDropoff = { name = "polarix_trucker_unload_dropoff", description = "keybind.unload_dropoff" },
}

local Keybinds = {}
local registered = {}

function Keybinds.Register(action, onPressed)
    local bind = BINDS[action]
    registered[action] = lib.addKeybind({
        name = bind.name,
        description = Locale(bind.description),
        defaultKey = clientConfig.Keybinds[action],
        onPressed = onPressed,
    })
end

-- Key the player currently has bound, falling back to the config default.
function Keybinds.GetKey(action)
    local keybind = registered[action]
    local key = keybind and keybind:getCurrentKey()
    if not key or key == "" then
        return clientConfig.Keybinds[action]
    end
    return key
end

-- Prompt text like "[E] Load pallet".
function Keybinds.Prompt(action, localeKey)
    return ("[%s] %s"):format(Keybinds.GetKey(action), Locale(localeKey))
end

return Keybinds
