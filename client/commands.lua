local debug = require("shared.debug")
local client = require("config.client")
local shared = require("shared.debug")

-- Leerer Befehl zum kopieren
-- Source: Der ausführende Spieler
-- Args: Argumente als Tabelle
-- RawCommand: Der vollständige Befehl als String

-- RegisterCommand('template', function(source, args, rawCommand)

-- end, false)

-- Showcase command to send a message to the NUI Template to open it or update text

RegisterCommand('openNui', function()
    OpenNui()
end, false)

RegisterCommand('sendmsg', function()
    --Öffne Nui falls nicht offen
    OpenNui()
    -- Sende Nachricht an Nui
   SendMessage('updateMessage', {
        message = 'Hallo von der Client Seite!'
    })
end, false)

-- Test-Command: UI mit echten Daten öffnen (entspricht NPC-Interaktion)
RegisterCommand('truckerui', function()
    lib.callback('polarix_trucker:openDashboard', false, function(data)
        if not data then
            Framework.Notify('Keine Spielerdaten verfügbar.', 'error')
            return
        end
        OpenNui()
        SendMessage('openNui', data)
    end)
end, false)