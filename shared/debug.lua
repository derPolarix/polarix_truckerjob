-- Erweitertes Debug Modul für formatierte Konsolenausgaben
-- Importieren mit: local debug = require("shared.debug")

local SharedConfig = require("config.shared")
local prefix = "^2[" .. GetCurrentResourceName() .. "]^7 "
local suffix = "^7"

local function printPrefixed(message)
    message = tostring(message)

    -- Print each line with a prefix so multi-line table dumps stay readable.
    for line in (message .. "\n"):gmatch("(.-)\n") do
        print(prefix .. line .. suffix)
    end
end

local function tryEncodeTable(value)
    if type(value) ~= "table" then return nil end
    if not json or type(json.encode) ~= "function" then return nil end

    local ok, encoded = pcall(json.encode, value, { indent = true })
    if ok and type(encoded) == "string" then
        return encoded
    end

    return nil
end

local function stringify(value, visited, depth)
    local valueType = type(value)

    if valueType == "string" then
        return value
    end

    if valueType == "number" or valueType == "boolean" or valueType == "nil" then
        return tostring(value)
    end

    if valueType ~= "table" then
        return tostring(value)
    end

    visited = visited or {}
    if visited[value] then
        return "<circular>"
    end

    depth = depth or 4
    if depth <= 0 then
        return "<max-depth>"
    end

    local encoded = tryEncodeTable(value)
    if encoded then
        return encoded
    end

    visited[value] = true

    local parts = {}
    local nextDepth = depth - 1

    -- Best-effort: show arrays as [a, b, c] and maps as {k=v, ...}
    local isArray = true
    local n = #value
    for k, _ in pairs(value) do
        if type(k) ~= "number" or k % 1 ~= 0 or k < 1 or k > n then
            isArray = false
            break
        end
    end

    if isArray and n > 0 then
        for i = 1, n do
            parts[#parts + 1] = stringify(value[i], visited, nextDepth)
        end
        visited[value] = nil
        return "[" .. table.concat(parts, ", ") .. "]"
    end

    for k, v in pairs(value) do
        parts[#parts + 1] = stringify(k, visited, nextDepth) .. "=" .. stringify(v, visited, nextDepth)
    end

    visited[value] = nil
    return "{" .. table.concat(parts, ", ") .. "}"
end

return {
    DebugPrint = function(...)
        
        if not SharedConfig.PrintDebug then return end

        local argCount = select("#", ...)
        if argCount == 0 then
            printPrefixed("")
            return
        end

        local out = {}
        for i = 1, argCount do
            out[#out + 1] = stringify(select(i, ...), nil, 4)
        end

        printPrefixed(table.concat(out, " "))
    end

}
