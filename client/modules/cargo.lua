local shared = require("config.shared")
local cargo  = require("shared.cargo")

MissionCargo = { requiredCount = 0, loadedCount = 0, pickupSpawned = false }
MissionPallets = {}
ForkliftPallet = { entity = nil }
LoadedPallets = {}

function ResetMissionCargo(orderData)
    DespawnMissionPallets()
    DetachPalletFromForklift()
    CleanupMissionPalletsOnTrailer()

    MissionCargo = {
        requiredCount = orderData and cargo.CalcPalletCount(orderData.weight_kg) or 0,
        loadedCount = 0,
        pickupSpawned = false,
    }
end

function SpawnMissionPallets(order)
    if MissionCargo.pickupSpawned then return end
    MissionCargo.pickupSpawned = true

    local heading = order.pickup_heading or 0.0
    local count   = MissionCargo.requiredCount

    local coordsList = order.pickup_pallet_coords
    if type(coordsList) ~= "table" or #coordsList == 0 then
        local anchor = vector3(order.pickup_x, order.pickup_y, order.pickup_z)
        coordsList = cargo.GenerateGridCoords(anchor, heading, count)
    end

    local modelHash = GetHashKey(shared.PalletModel)
    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 100 do
        Wait(100)
        timeout = timeout + 1
    end
    if not HasModelLoaded(modelHash) then return end

    for _, pos in ipairs(coordsList) do
        local pallet = CreateObject(modelHash, pos.x, pos.y, pos.z, false, false, false)
        if pallet and pallet ~= 0 then
            SetEntityHeading(pallet, heading)
            PlaceObjectOnGroundProperly(pallet)
            FreezeEntityPosition(pallet, true)
            SetEntityCollision(pallet, true, true)
            SetEntityInvincible(pallet, true)
            SetEntityProofs(pallet, true, true, true, true, true, true, true, true)
            MissionPallets[#MissionPallets + 1] = pallet
        end
    end

    SetModelAsNoLongerNeeded(modelHash)
end

function DespawnMissionPallets()
    for _, entity in ipairs(MissionPallets) do
        if entity and DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
    end
    MissionPallets = {}
    MissionCargo.pickupSpawned = false
end

local function GetForkliftBoneCoords(forklift)
    local boneIndex = GetEntityBoneIndexByName(forklift, shared.ForkliftAttachBone)
    if boneIndex == -1 then
        return GetEntityCoords(forklift)
    end
    return GetWorldPositionOfEntityBone(forklift, boneIndex)
end

local function GetPickupCandidatePallet(forklift)
    local forkCoords = GetForkliftBoneCoords(forklift)
    local best, bestDist = nil, nil

    for _, entity in ipairs(MissionPallets) do
        if entity and DoesEntityExist(entity) then
            local palletCoords = GetEntityCoords(entity)
            local horizontal = #(vector2(forkCoords.x, forkCoords.y) - vector2(palletCoords.x, palletCoords.y))
            local vertical    = palletCoords.z - forkCoords.z

            if horizontal <= 0.7 and vertical >= -0.08 and vertical <= 0.18 then
                local dist = #(forkCoords - palletCoords)
                if not bestDist or dist < bestDist then
                    best, bestDist = entity, dist
                end
            end
        end
    end

    return best
end

function AttachPalletToForklift()
    local forklift = GetPlayerForklift()
    if not forklift then return end

    local offset = shared.ForkliftAttachOffset
    local boneIndex = GetEntityBoneIndexByName(forklift, shared.ForkliftAttachBone)
    if boneIndex == -1 then boneIndex = 0 end

    local modelHash = GetHashKey(shared.PalletModel)
    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 50 do
        Wait(50)
        timeout = timeout + 1
    end
    if not HasModelLoaded(modelHash) then return end

    local prop = CreateObject(modelHash, 0.0, 0.0, 0.0, false, false, false)
    if not prop or prop == 0 then return end

    AttachEntityToEntity(prop, forklift, boneIndex,
        offset.x, offset.y, offset.z,
        offset.rx, offset.ry, offset.rz,
        false, false, false, false, 2, true)

    SetEntityInvincible(prop, true)
    SetEntityProofs(prop, true, true, true, true, true, true, true, true)

    SetModelAsNoLongerNeeded(modelHash)
    ForkliftPallet.entity = prop
end

function DetachPalletFromForklift()
    if ForkliftPallet.entity and DoesEntityExist(ForkliftPallet.entity) then
        DetachEntity(ForkliftPallet.entity, true, true)
        DeleteEntity(ForkliftPallet.entity)
    end
    ForkliftPallet.entity = nil
end

function GetForkliftPalletPayload()
    return ForkliftPallet.entity
end

function PickupPalletWithForklift(sourcePallet)
    if not IsPlayerInForklift() then
        Framework.Notify("Du musst in einem Gabelstapler sitzen.", "error")
        return
    end
    if ForkliftPallet.entity then
        Framework.Notify("Du hast bereits eine Palette auf der Gabel.", "error")
        return
    end
    if not sourcePallet or not DoesEntityExist(sourcePallet) then return end

    for i, entity in ipairs(MissionPallets) do
        if entity == sourcePallet then
            table.remove(MissionPallets, i)
            break
        end
    end
    DeleteEntity(sourcePallet)

    AttachPalletToForklift()
    Framework.Notify("Palette aufgenommen.", "success")
end

local currentPickupCandidate = nil
local currentPrompt = nil

local function SetForkliftPickupPrompt(visible)
    if visible == currentPrompt then return end
    currentPrompt = visible

    if not visible then
        ClearHeldAction()
        return
    end

    SetHeldAction({
        name = "Palette bereit",
        hint = "Gabel unter der Palette",
        primaryKey = "G",
        primaryAction = "Aufheben",
    })
end

CreateThread(function()
    while true do
        Wait(300)
        if ForkliftPallet.entity and DoesEntityExist(ForkliftPallet.entity) then
            currentPickupCandidate = nil
            SetForkliftPickupPrompt(false)
        elseif IsPlayerInForklift and IsPlayerInForklift() then
            local forklift = GetPlayerForklift()
            currentPickupCandidate = forklift and GetPickupCandidatePallet(forklift) or nil
            SetForkliftPickupPrompt(currentPickupCandidate ~= nil)
        else
            currentPickupCandidate = nil
            SetForkliftPickupPrompt(false)
        end
    end
end)

lib.addKeybind({
    name = "polarix_trucker_pallet_pickup",
    description = "Palette aufnehmen",
    defaultKey = "G",
    onPressed = function()
        if currentPickupCandidate then
            PickupPalletWithForklift(currentPickupCandidate)
        end
    end,
})

function GetTrailerModelName()
    if not LocalTrailer.entity or not DoesEntityExist(LocalTrailer.entity) then return nil end
    local modelHash = GetEntityModel(LocalTrailer.entity)
    for name, _ in pairs(shared.CompatibleTrailers) do
        if GetHashKey(name) == modelHash then return name end
    end
    return nil
end

local function GetFreeTrailerSlot(maxPallets)
    for slot = 1, maxPallets do
        if not LoadedPallets[slot] then return slot end
    end
    return nil
end

function TryLoadPalletOnTrailer()
    if not ForkliftPallet.entity or not DoesEntityExist(ForkliftPallet.entity) then return end
    if not LocalTrailer.entity or not DoesEntityExist(LocalTrailer.entity) then return end

    local trailerModel = GetTrailerModelName()
    local trailerConfig = trailerModel and shared.CompatibleTrailers[trailerModel]
    if not trailerConfig then
        Framework.Notify("Dieser Trailer unterstützt keine Paletten.", "error")
        return
    end

    local slot = GetFreeTrailerSlot(trailerConfig.maxPallets)
    if not slot then
        Framework.Notify("Trailer ist voll.", "error")
        return
    end

    local ok = lib.progressBar({
        duration = 4000,
        label = "Palette wird verladen...",
        canCancel = true,
        disable = { car = true, move = true, combat = true },
    })

    if not ok then return end

    if not ForkliftPallet.entity or not DoesEntityExist(ForkliftPallet.entity) then return end
    if LoadedPallets[slot] then return end

    local offset = trailerConfig.attachOffsets[slot]
    if not offset then
        Framework.Notify("Slot-Offset für diesen Trailer fehlt (nicht kalibriert).", "error")
        return
    end

    local prop = ForkliftPallet.entity
    DetachEntity(prop, true, true)
    AttachEntityToEntity(prop, LocalTrailer.entity, 0,
        offset.x, offset.y, offset.z,
        offset.rx, offset.ry, offset.rz,
        false, false, false, false, 2, true)

    SetEntityCollision(prop, true, true)
    SetEntityNoCollisionEntity(prop, LocalTrailer.entity, true)
    for otherSlot, otherEntity in pairs(LoadedPallets) do
        if otherSlot ~= slot and otherEntity and DoesEntityExist(otherEntity) then
            SetEntityNoCollisionEntity(prop, otherEntity, true)
            SetEntityNoCollisionEntity(otherEntity, prop, true)
        end
    end

    LoadedPallets[slot] = prop
    ForkliftPallet.entity = nil

    MissionCargo.loadedCount = MissionCargo.loadedCount + 1

    if MissionCargo.loadedCount >= MissionCargo.requiredCount then
        Framework.Notify("Alle Paletten geladen! Verstaue den Gabelstapler am Trailer.", "success")
    else
        Framework.Notify(("Palette geladen (%d/%d)."):format(MissionCargo.loadedCount, MissionCargo.requiredCount), "success")
    end
end

function CleanupMissionPalletsOnTrailer()
    for slot, entity in pairs(LoadedPallets) do
        if entity and DoesEntityExist(entity) then
            DetachEntity(entity, true, true)
            DeleteEntity(entity)
        end
    end
    LoadedPallets = {}
end

CreateThread(function()
    while true do
        Wait(1000)
        if DeliveryState and DeliveryState.status == "awaiting_pickup" and DeliveryState.orderData then
            local o = DeliveryState.orderData
            local dist = #(GetEntityCoords(PlayerPedId()) - vector3(o.pickup_x, o.pickup_y, o.pickup_z))
            if dist < 40.0 and not MissionCargo.pickupSpawned then
                SpawnMissionPallets(o)
            elseif dist >= 40.0 and MissionCargo.pickupSpawned then
                DespawnMissionPallets()
            end
        elseif MissionCargo.pickupSpawned then
            DespawnMissionPallets()
        end
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    ClearHeldAction()
    DespawnMissionPallets()
    DetachPalletFromForklift()
    CleanupMissionPalletsOnTrailer()
end)
