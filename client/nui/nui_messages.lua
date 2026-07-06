local debug = require("shared.debug")
local client = require("config.client")
local shared = require("shared.debug")


-- Callback um UI wieder zu schließen
function SetFocus(state)
    SetNuiFocus(state, state)
end

function OpenNui()
    SetFocus(true)
    SendNUIMessage({
        action = 'openNui'
    })
end

function CloseNui()
    SetFocus(false)
    SendNUIMessage({
        action = 'closeNui'
    })
end

function SendMessage(action, data)
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