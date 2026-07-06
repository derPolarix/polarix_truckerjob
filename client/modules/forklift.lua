local clientConfig = require("config.client")
local sharedConfig = require("config.shared")

ForkliftDockState = {}

Forklift = {}

local function GetTrailerNetId()
    if not LocalTrailer.entity or not DoesEntityExist(LocalTrailer.entity) then return nil end
    if not NetworkGetEntityIsNetworked(LocalTrailer.entity) then return nil end
    return NetworkGetNetworkIdFromEntity(LocalTrailer.entity)
end

local function IsForkliftDeployed(netId)
    local dock = netId and ForkliftDockState[netId]
    return dock ~= nil and dock.deployed and dock.entity and DoesEntityExist(dock.entity)
end

function IsPlayerInForklift()
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh == 0 then return false end
    return GetEntityModel(veh) == GetHashKey(sharedConfig.ForkliftModel)
end

function GetPlayerForklift()
    if not IsPlayerInForklift() then return nil end
    return GetVehiclePedIsIn(PlayerPedId(), false)
end

CreateThread(function()
    while true do
        Wait(100)
        local forklift = GetPlayerForklift()
        if forklift and not GetIsVehicleEngineRunning(forklift) then
            SetVehicleEngineOn(forklift, true, true, false)
        end
    end
end)

local function GetForkliftInteractionCoords()
    if not LocalTrailer.entity or not DoesEntityExist(LocalTrailer.entity) then return nil end
    local offset = clientConfig.ForkliftDeployOffset
    return GetOffsetFromEntityInWorldCoords(LocalTrailer.entity, offset.x, offset.y, offset.z)
end

local function GetForkliftInteractionRadius()
    if IsPlayerInForklift() then
        return clientConfig.ForkliftInteractionRadiusVehicle
    end
    return clientConfig.ForkliftInteractionRadiusFoot
end

local function IsInForkliftInteractionRange()
    local coords = GetForkliftInteractionCoords()
    if not coords then return false end
    return #(GetEntityCoords(PlayerPedId()) - coords) < GetForkliftInteractionRadius()
end

function Forklift.Deploy()
    local netId = GetTrailerNetId()
    if not netId then
        Framework.Notify("Kein Trailer ausgerüstet oder gespawnt.", "error")
        return
    end

    if IsForkliftDeployed(netId) then
        Framework.Notify("Gabelstapler bereits im Einsatz.", "error")
        return
    end

    if not GetForkliftInteractionCoords() then return end
    local spawnOffset = clientConfig.ForkliftSpawnOffset
    local coords = GetOffsetFromEntityInWorldCoords(LocalTrailer.entity, spawnOffset.x, spawnOffset.y, spawnOffset.z)
    local heading = GetEntityHeading(LocalTrailer.entity)

    local modelHash = GetHashKey(sharedConfig.ForkliftModel)
    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 100 do
        Wait(100)
        timeout = timeout + 1
    end
    if not HasModelLoaded(modelHash) then
        Framework.Notify("Gabelstapler-Modell konnte nicht geladen werden.", "error")
        return
    end

    local forklift = CreateVehicle(modelHash, coords.x, coords.y, coords.z, heading, true, false)
    SetVehicleNumberPlateText(forklift, "FORKLIFT")
    SetEntityAsMissionEntity(forklift, true, true)
    SetModelAsNoLongerNeeded(modelHash)

    SetVehicleDoorsLocked(forklift, 1)
    Framework.GiveVehicleKeys(forklift, "FORKLIFT")

    ForkliftDockState[netId] = { deployed = true, entity = forklift }
    Framework.Notify("Gabelstapler ausgeladen.", "success")
end

function Forklift.Stow()
    local netId = GetTrailerNetId()
    local dock = netId and ForkliftDockState[netId]
    if not dock or not dock.deployed then return end

    if not dock.entity or not DoesEntityExist(dock.entity) then
        ForkliftDockState[netId] = nil
        return
    end

    if GetForkliftPalletPayload and GetForkliftPalletPayload() then
        Framework.Notify("Erst die Palette von der Gabel nehmen.", "error")
        return
    end

    local dist = #(GetEntityCoords(dock.entity) - GetEntityCoords(LocalTrailer.entity))
    if dist > 10.0 then
        Framework.Notify("Bring den Gabelstapler näher zum Trailer.", "error")
        return
    end

    DeleteEntity(dock.entity)
    ForkliftDockState[netId] = nil
    Framework.Notify("Gabelstapler verstaut.", "success")

    if MissionCargo and MissionCargo.requiredCount and MissionCargo.loadedCount >= MissionCargo.requiredCount then
        if Delivery and Delivery.EnterTransitPhase then
            Delivery.EnterTransitPhase()
        end
    end
end

local usingOxTarget = GetResourceState("ox_target") == "started"
local targetRegisteredFor = nil
local promptVisible = false
local lastLabel = nil

local function GetForkliftDockLabel()
    if GetForkliftPalletPayload and GetForkliftPalletPayload() then
        return "[E] Palette einladen"
    elseif IsForkliftDeployed(GetTrailerNetId()) then
        return "[E] Gabelstapler verstauen"
    else
        return "[E] Gabelstapler ausladen"
    end
end

local function RunForkliftDockInteraction()
    if GetForkliftPalletPayload and GetForkliftPalletPayload() then
        TryLoadPalletOnTrailer()
    elseif IsForkliftDeployed(GetTrailerNetId()) then
        Forklift.Stow()
    else
        Forklift.Deploy()
    end
end

local function EnsureOxTargetRegistered(trailer)
    if targetRegisteredFor == trailer then return end
    targetRegisteredFor = trailer

    exports.ox_target:addLocalEntity(trailer, {
        {
            name = "trailer_forklift_load_pallet",
            icon = "fa-solid fa-pallet",
            label = "Palette einladen",
            distance = clientConfig.ForkliftInteractionRadiusVehicle,
            canInteract = function()
                return IsInForkliftInteractionRange() and GetForkliftPalletPayload and GetForkliftPalletPayload() ~= nil
            end,
            onSelect = TryLoadPalletOnTrailer,
        },
        {
            name = "trailer_forklift_stow",
            icon = "fa-solid fa-warehouse",
            label = "Gabelstapler verstauen",
            distance = clientConfig.ForkliftInteractionRadiusVehicle,
            canInteract = function()
                return IsInForkliftInteractionRange()
                    and not (GetForkliftPalletPayload and GetForkliftPalletPayload() ~= nil)
                    and IsForkliftDeployed(GetTrailerNetId())
            end,
            onSelect = Forklift.Stow,
        },
        {
            name = "trailer_forklift_deploy",
            icon = "fa-solid fa-truck-loading",
            label = "Gabelstapler ausladen",
            distance = clientConfig.ForkliftInteractionRadiusVehicle,
            canInteract = function()
                return IsInForkliftInteractionRange()
                    and not (GetForkliftPalletPayload and GetForkliftPalletPayload() ~= nil)
                    and not IsForkliftDeployed(GetTrailerNetId())
            end,
            onSelect = Forklift.Deploy,
        },
    })
end

CreateThread(function()
    while true do
        Wait(500)

        if usingOxTarget then
            if LocalTrailer.entity and DoesEntityExist(LocalTrailer.entity) then
                EnsureOxTargetRegistered(LocalTrailer.entity)
            end
        else
            local inRange = IsInForkliftInteractionRange()

            if inRange then
                local label = GetForkliftDockLabel()
                if not promptVisible or label ~= lastLabel then
                    if promptVisible then lib.hideTextUI() end
                    lib.showTextUI(label, { position = "bottom-center", icon = "dolly" })
                    promptVisible = true
                    lastLabel = label
                end
            elseif promptVisible then
                lib.hideTextUI()
                promptVisible = false
                lastLabel = nil
            end
        end
    end
end)

lib.addKeybind({
    name = "polarix_trucker_forklift_dock",
    description = "Gabelstapler / Palette (am Trailer)",
    defaultKey = "E",
    onPressed = function()
        if not usingOxTarget and promptVisible then
            RunForkliftDockInteraction()
        end
    end,
})
