local debug = require("shared.debug")
local server = require("config.server")
local shared = require("shared.debug")


RegisterCommand('truckeraddxp', function(source, args)
    local amount = tonumber(args[1])
    if not amount or amount <= 0 then
        print("[truckeraddxp] Verwendung: /truckeraddxp <menge>")
        return
    end
    if not Player.GetData(source) then
        Player.Load(source)
    end
    if not Player.GetData(source) then
        print("[truckeraddxp] Spielerdaten nicht geladen.")
        return
    end
    Player.AddXP(source, amount)
    print(("[truckeraddxp] +%d XP an source %d vergeben."):format(amount, source))
end, true)  -- true = nur Admins (ace permission)

RegisterCommand('debugprintserver', function()
    Wait(1000) --Warte eine Sekunde, damit die Ausgabe im richtigen Reihenfolge erscheint
    debug.DebugPrint("Dies ist ein Debug Print Test von commands.lua!")
    Wait(1000)
    debug.DebugPrint("Das ist eine"," weitere Zeile mit", "mehreren", "Argumenten.")
    Wait(1000)
    debug.DebugPrint("Das ist eine Zeile", {key = "value", number = 42, bool = true})
    Wait(1000)
    debug.DebugPrint({nested = {table = {with = {multiple = "levels"}}}})
    Wait(1000)
    debug.DebugPrint(nil)
    Wait(1000)
    debug.DebugPrint(12345)
    Wait(1000)
    debug.DebugPrint(true)
    Wait(1000)
end, false)