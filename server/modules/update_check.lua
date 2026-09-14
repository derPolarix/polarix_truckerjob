-- Checks GitHub Releases for a newer polarix_truckerjob version on resource
-- start and warns in the server console if the running copy is outdated.
local config = require("config.shared")
local debug = require("shared.debug")

local REPO_OWNER = "derPolarix"
local REPO_NAME = "polarix_truckerjob"
local RELEASES_API = ("https://api.github.com/repos/%s/%s/releases/latest"):format(REPO_OWNER, REPO_NAME)
local RELEASES_PAGE = ("https://github.com/%s/%s/releases"):format(REPO_OWNER, REPO_NAME)

local function parseVersion(version)
    local parts = {}
    for part in tostring(version):gmatch("%d+") do
        parts[#parts + 1] = tonumber(part)
    end
    return parts
end

local function isNewer(remote, current)
    for i = 1, math.max(#remote, #current) do
        local r, c = remote[i] or 0, current[i] or 0
        if r ~= c then return r > c end
    end
    return false
end

if config.CheckForUpdates == false then return end

-- Deferred: PerformHttpRequest issued while the resource is still loading can be
-- dropped before its callback is ever scheduled.
CreateThread(function()
    local resourceName = GetCurrentResourceName()
    local currentVersion = GetResourceMetadata(resourceName, "version", 0) or "0.0.0"

    PerformHttpRequest(RELEASES_API, function(statusCode, body)
        if statusCode ~= 200 then
            debug.Warn(("Update check failed: HTTP %s (%s)"):format(tostring(statusCode), RELEASES_API))
            if body and body ~= "" then
                debug.DebugPrint(("Update check response body: %s"):format(body))
            end
            return
        end

        if not body or body == "" then
            debug.Warn("Update check failed: empty response body")
            return
        end

        local ok, data = pcall(json.decode, body)
        if not ok or type(data) ~= "table" or not data.tag_name then
            debug.Warn("Update check failed: could not read tag_name from the GitHub response")
            return
        end

        local remoteVersion = data.tag_name
        debug.DebugPrint(("Update check: running v%s, latest release %s"):format(currentVersion, remoteVersion))

        if not isNewer(parseVersion(remoteVersion), parseVersion(currentVersion)) then
            return
        end

        debug.Warn(("Update available: v%s -> %s"):format(currentVersion, remoteVersion))
        debug.Warn(("Please update, download the latest release here: %s"):format(RELEASES_PAGE))
    end, "GET", "", { ["User-Agent"] = REPO_NAME })
end)
