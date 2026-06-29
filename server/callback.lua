local debug = require("shared.debug")
local server = require("config.server")
local shared = require("shared.debug")
local triggerEventHooks = require '@polarix_utils.server.hooks' -- Import triggerEventHooks function from hooks module

-- lib.callback.register('polarix_template:getPlayerJob', function(source, item, metadata, target)
--     local player = exports.qbx_core:GetPlayer(source)
--     return player.PlayerData.job.name
-- end)
