local debug = require("shared.debug")
local client = require("config.client")
local shared = require("shared.debug")
local sharedConfig = require("config.shared")


-- Callback um UI wieder zu schließen
function SetFocus(state)
    SetNuiFocus(state, state)
end

function OpenNui()
    SetFocus(true)
    SendNUIMessage({
        action = 'openNui',
        data = { language = sharedConfig.Language }
    })
end

function CloseNui()
    SetFocus(false)
    SendNUIMessage({
        action = 'closeNui'
    })
end

-- every NUI message carries the current language so App.vue can keep vue-i18n
-- in sync with Config.Language regardless of which message opens/updates the UI
function SendMessage(action, data)
    data = data or {}
    data.language = sharedConfig.Language
    SendNUIMessage({
        action = action,
        data = data
    })
end

function SetHeldAction(actionData)
    SendNUIMessage({
        action = 'setHeldAction',
        data = actionData,
    })
end

function ClearHeldAction()
    SendNUIMessage({
        action = 'clearHeldAction',
    })
end