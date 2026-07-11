-- Locale-Loader (SSOT: locales/*.json) - Importieren mit: local Locale = require("shared.locale")
-- Konvention: der Key ist der Original-Text (Deutsch), wie er im Code stand.
-- locales/de.json bildet Key -> gleicher Text ab, locales/en.json Key -> Übersetzung.

local SharedConfig = require("config.shared")

local cache = {}

local function loadPhrases(lang)
    if cache[lang] then return cache[lang] end

    local raw = LoadResourceFile(GetCurrentResourceName(), ("locales/%s.json"):format(lang))
    local decoded = raw and json.decode(raw) or {}
    cache[lang] = decoded
    return decoded
end

return function(key, ...)
    local phrases = loadPhrases(SharedConfig.Language or "de")
    local phrase = phrases[key] or key

    if select("#", ...) > 0 then
        local ok, formatted = pcall(string.format, phrase, ...)
        if ok then return formatted end
    end

    return phrase
end
