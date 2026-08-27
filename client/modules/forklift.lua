local clientConfig = require("config.client")
local sharedConfig = require("config.shared")
local Locale = require("shared.locale")

ForkliftDockState = {}

Forklift = {}

local function GetTrailerNetId()
    local trailer = GetActiveTrailer()
    if not trailer then return nil end
    if not NetworkGetEntityIsNetworked(trailer) then return nil end
    return NetworkGetNetworkIdFromEntity(trailer)
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

local function GetForkliftInteractionCoords(trailer)
    trailer = trailer or GetActiveTrailer()
    if not trailer then return nil end
    local offset = clientConfig.ForkliftDeployOffset
    return GetOffsetFromEntityInWorldCoords(trailer, offset.x, offset.y, offset.z)
end

local function GetForkliftInteractionRadius()
    if IsPlayerInForklift() then
        return clientConfig.ForkliftInteractionRadiusVehicle
    end
    return clientConfig.ForkliftInteractionRadiusFoot
end

local function IsInForkliftInteractionRangeOf(trailer)
    local coords = GetForkliftInteractionCoords(trailer)
    if not coords then return false end
    return #(GetEntityCoords(PlayerPedId()) - coords) < GetForkliftInteractionRadius()
end

local function IsInForkliftInteractionRange()
    return IsInForkliftInteractionRangeOf(GetActiveTrailer())
end

-- Own trailer first (deploy/stow stay own-trailer-only, but so does loading if you're in
-- range of it); otherwise, in a convoy, any teammate's trailer you can walk/drive up to.
local function FindNearbyLoadTarget()
    local ownTrailer = GetActiveTrailer()
    if ownTrailer and IsInForkliftInteractionRangeOf(ownTrailer) then
        return ownTrailer, nil
    end

    if DeliveryState and DeliveryState.mode == "party" and PartyTrailerNetIds then
        for identifier in pairs(PartyTrailerNetIds) do
            local trailer = GetPartyTrailerEntity(identifier)
            if trailer and IsInForkliftInteractionRangeOf(trailer) then
                return trailer, identifier
            end
        end
    end

    return nil, nil
end

function Forklift.Deploy()
    local netId = GetTrailerNetId()
    if not netId then
        Framework.Notify(Locale("notify.no_trailer_equipped_or_spawned"), "error")
        return
    end

    if IsForkliftDeployed(netId) then
        Framework.Notify(Locale("notify.forklift_already_use"), "error")
        return
    end

    local trailer = GetActiveTrailer()
    if not trailer then return end
    local spawnOffset = clientConfig.ForkliftSpawnOffset
    local coords = GetOffsetFromEntityInWorldCoords(trailer, spawnOffset.x, spawnOffset.y, spawnOffset.z)
    local heading = GetEntityHeading(trailer)

    local modelHash = GetHashKey(sharedConfig.ForkliftModel)
    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 100 do
        Wait(100)
        timeout = timeout + 1
    end
    if not HasModelLoaded(modelHash) then
        Framework.Notify(Locale("notify.failed_load_forklift_model"), "error")
        return
    end

    local ok = lib.progressCircle({
        duration = 3500,
        position = "bottom",
        label = Locale("ui.unloading_forklift"),
        canCancel = true,
        disable = { car = true, move = true, combat = true },
    })

    if not ok then
        SetModelAsNoLongerNeeded(modelHash)
        return
    end

    local forklift = CreateVehicle(modelHash, coords.x, coords.y, coords.z, heading, true, false)
    SetVehicleNumberPlateText(forklift, "FORKLIFT")
    SetEntityAsMissionEntity(forklift, true, true)
    SetModelAsNoLongerNeeded(modelHash)

    -- Forklift drives into the trailer bed to dock/stow; without this its mesh
    -- colliding with the trailer body can knock the trailer's hitch loose.
    SetEntityNoCollisionEntity(forklift, trailer, true)
    SetEntityNoCollisionEntity(trailer, forklift, true)

    SetVehicleDoorsLocked(forklift, 1)
    Framework.GiveVehicleKeys(forklift, "FORKLIFT")

    ForkliftDockState[netId] = { deployed = true, entity = forklift }
    Framework.Notify(Locale("notify.forklift_unloaded"), "success")
    TriggerServerEvent("polarix_trucker:syncForkliftNetId", NetworkGetNetworkIdFromEntity(forklift))
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
        Framework.Notify(Locale("notify.take_pallet_off_forks_first"), "error")
        return
    end

    local ok = lib.progressCircle({
        duration = 3000,
        position = "bottom",
        label = Locale("ui.stowing_forklift"),
        canCancel = true,
        disable = { car = true, move = true, combat = true },
    })

    if not ok then return end

    if not dock.entity or not DoesEntityExist(dock.entity) then
        ForkliftDockState[netId] = nil
        return
    end

    -- Forklift may still have the player inside; deleting it while occupied can
    -- jolt the attached trailer's physical hitch and trip the "trailer detached"
    -- check in delivery.lua's damage monitor.
    local ped = PlayerPedId()
    if GetVehiclePedIsIn(ped, false) == dock.entity then
        SetVehicleDoorsLocked(dock.entity, 0)
        TaskLeaveVehicle(ped, dock.entity, 0)
        local tries = 0
        while GetVehiclePedIsIn(ped, false) == dock.entity and tries < 60 do
            Wait(50)
            tries = tries + 1
        end
        if GetVehiclePedIsIn(ped, false) == dock.entity then
            Framework.Notify(Locale("notify.exit_forklift_first"), "error")
            return
        end
    end

    Wait(1500)
    DeleteEntity(dock.entity)
    ForkliftDockState[netId] = nil
    Framework.Notify(Locale("notify.forklift_stowed"), "success")
    TriggerServerEvent("polarix_trucker:syncForkliftNetId", nil)

    -- Party mode has no per-trip claim, so a small order (fewer pallets than one trailer's
    -- capacity) would never "fill" the trailer - poolRemaining<=0 covers that case too.
    local ownTrailerFull = MissionCargo and MissionCargo.requiredCount and MissionCargo.requiredCount > 0
        and MissionCargo.loadedCount >= MissionCargo.requiredCount
    local poolExhausted = DeliveryState and DeliveryState.mode == "party" and PartyProgress and PartyProgress.poolRemaining <= 0

    if MissionCargo and MissionCargo.loadedCount > 0 and (ownTrailerFull or poolExhausted) then
        if Delivery and Delivery.EnterTransitPhase then
            Delivery.EnterTransitPhase()
        end
    end
end

local usingTarget = Target.IsAvailable()
local targetRegisteredFor = nil
local promptVisible = false
local lastLabel = nil

local function GetForkliftDockLabel()
    if GetForkliftPalletPayload and GetForkliftPalletPayload() then
        return Locale("ui.e_load_pallet")
    elseif IsForkliftDeployed(GetTrailerNetId()) then
        return Locale("ui.e_stow_forklift")
    else
        return Locale("ui.e_unload_forklift")
    end
end

local function RunForkliftDockInteraction()
    if GetForkliftPalletPayload and GetForkliftPalletPayload() then
        local trailer, identifier = FindNearbyLoadTarget()
        if trailer then
            TryLoadPalletOnTrailer(trailer, identifier)
        end
    elseif IsForkliftDeployed(GetTrailerNetId()) then
        Forklift.Stow()
    else
        Forklift.Deploy()
    end
end

local loadTargetRegisteredFor = {}

-- Teammate trailers only get the "load pallet" option - deploy/stow/unload stay
-- own-trailer-only since the forklift is docked to your own rig.
local function EnsurePartyLoadTargetRegistered(trailer, identifier)
    if loadTargetRegisteredFor[trailer] then return end
    loadTargetRegisteredFor[trailer] = true

    Target.AddLocalEntity(trailer, {
        {
            name = "trailer_forklift_load_pallet_party",
            icon = "fa-solid fa-pallet",
            label = Locale("ui.load_pallet"),
            distance = clientConfig.ForkliftInteractionRadiusVehicle,
            canInteract = function()
                return IsInForkliftInteractionRangeOf(trailer) and GetForkliftPalletPayload and GetForkliftPalletPayload() ~= nil
            end,
            onSelect = function() TryLoadPalletOnTrailer(trailer, identifier) end,
        },
    })
end

local function EnsureTargetRegistered(trailer)
    if targetRegisteredFor == trailer then return end
    targetRegisteredFor = trailer

    Target.AddLocalEntity(trailer, {
        {
            name = "trailer_forklift_load_pallet",
            icon = "fa-solid fa-pallet",
            label = Locale("ui.load_pallet"),
            distance = clientConfig.ForkliftInteractionRadiusVehicle,
            canInteract = function()
                return IsInForkliftInteractionRange() and GetForkliftPalletPayload and GetForkliftPalletPayload() ~= nil
            end,
            -- Wrapped, not passed bare: target backends call onSelect with their own arg
            -- (e.g. ox_target passes a data table), which would otherwise land in
            -- TryLoadPalletOnTrailer's targetTrailer param and break DoesEntityExist on it.
            onSelect = function() TryLoadPalletOnTrailer() end,
        },
        {
            name = "trailer_forklift_stow",
            icon = "fa-solid fa-warehouse",
            label = Locale("ui.stow_forklift"),
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
            label = Locale("ui.unload_forklift"),
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

        if usingTarget then
            local trailer = GetActiveTrailer()
            if trailer then
                EnsureTargetRegistered(trailer)
            end
            if DeliveryState and DeliveryState.mode == "party" and PartyTrailerNetIds then
                for identifier in pairs(PartyTrailerNetIds) do
                    local teammateTrailer = GetPartyTrailerEntity(identifier)
                    if teammateTrailer then
                        EnsurePartyLoadTargetRegistered(teammateTrailer, identifier)
                    end
                end
            end
        else
            local carrying = GetForkliftPalletPayload and GetForkliftPalletPayload() ~= nil
            local inRange
            if carrying then
                inRange = FindNearbyLoadTarget() ~= nil
            else
                inRange = IsInForkliftInteractionRange()
            end

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
        if not usingTarget and promptVisible then
            RunForkliftDockInteraction()
        end
    end,
})
