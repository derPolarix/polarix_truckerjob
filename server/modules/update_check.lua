-- Checks GitHub Releases for a newer polarix_truckerjob version on resource
-- start and warns in the server console if the running copy is outdated.
local config = require("config.shared")

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

local resourceName = GetCurrentResourceName()
local currentVersion = GetResourceMetadata(resourceName, "version", 0) or "0.0.0"

PerformHttpRequest(RELEASES_API, function(statusCode, body)
    if statusCode ~= 200 or not body then
        return
    end

    local ok, data = pcall(json.decode, body)
    if not ok or type(data) ~= "table" or not data.tag_name then
        return
    end

    local remoteVersion = data.tag_name
    if not isNewer(parseVersion(remoteVersion), parseVersion(currentVersion)) then
        return
    end

    print(("^3[%s] Update available: v%s -> %s^7"):format(resourceName, currentVersion, remoteVersion))
    print(("^3[%s] Please update, download the latest release here: %s^7"):format(resourceName, RELEASES_PAGE))
end, "GET", "", { ["User-Agent"] = REPO_NAME })
