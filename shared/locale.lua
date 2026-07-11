-- Locale loader (SSOT: locales/*.json); usage: local Locale = require("shared.locale")
-- Convention: key = original German text as it appeared in code; de.json maps key->same text, en.json maps key->translation.

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
