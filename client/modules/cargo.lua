local shared = require("config.shared")
local cargo  = require("shared.cargo")
local Locale = require("shared.locale")
local debug  = require("shared.debug")

MissionCargo = { requiredCount = 0, loadedCount = 0, pickupSpawned = false }
MissionPallets = {}       -- slotIndex -> ground entity (both solo and party, same indexing)
ForkliftPallet = { entity = nil, slotIndex = nil }
LoadedPallets = {}        -- solo mode only: 1..maxPallets -> entity on own trailer
TrailerLoadedProps = {}   -- party mode only: trailerEntity -> { [trailerSlot] = entity }, own or teammate's
ForkliftCarriedProps = {} -- party mode only: teammate identifier -> decorative prop on their forklift

function ResetMissionCargo(orderData)
    DespawnMissionPallets()
    DetachPalletFromForklift()
    CleanupMissionPalletsOnTrailer()

    MissionCargo = {
        requiredCount = 0,
        loadedCount = 0,
        pickupSpawned = false,
    }
end

function SpawnMissionPallets(order)
    if MissionCargo.pickupSpawned then return end
    MissionCargo.pickupSpawned = true

    local isParty = DeliveryState.mode == "party"
    local count = isParty and cargo.CalcPalletCount(order.weight_kg) or MissionCargo.requiredCount

    -- Party mode has no per-trip claim anymore; requiredCount is repurposed as "my own
    -- trailer's capacity" so the HUD and the auto-transit check in forklift.lua still work.
    if isParty then
        local ownTrailerModel = GetTrailerModelName()
        local ownConfig = ownTrailerModel and shared.CompatibleTrailers[ownTrailerModel]
        MissionCargo.requiredCount = ownConfig and ownConfig.maxPallets or 0
    end

    local heading = order.pickup_heading or 0.0

    local coordsList = order.pickup_pallet_coords
    if type(coordsList) ~= "table" or #coordsList == 0 then
        local anchor = vector3(order.pickup_x, order.pickup_y, order.pickup_z)
        coordsList = cargo.GenerateGridCoords(anchor, heading, count)
    end

    -- Everyone in the convoy spawns the full deterministic layout, minus whatever the
    -- rest of the party has already taken off the ground - no more per-player claim gate.
    local takenSlots = {}
    if isParty then
        takenSlots = lib.callback.await("polarix_trucker:getPartyGroundState", false) or {}
    end
    debug.DebugPrint(("SpawnMissionPallets: mode=%s count=%s taken="):format(DeliveryState.mode, count), takenSlots)

    local modelHash = GetHashKey(shared.PalletModel)
    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 100 do
        Wait(100)
        timeout = timeout + 1
    end
    if not HasModelLoaded(modelHash) then return end

    for i, pos in ipairs(coordsList) do
        if not takenSlots[i] then
            local pallet = CreateObject(modelHash, pos.x, pos.y, pos.z, false, false, false)
            if pallet and pallet ~= 0 then
                SetEntityHeading(pallet, heading)
                PlaceObjectOnGroundProperly(pallet)
                FreezeEntityPosition(pallet, true)
                SetEntityCollision(pallet, true, true)
                SetEntityInvincible(pallet, true)
                SetEntityProofs(pallet, true, true, true, true, true, true, true, true)
                MissionPallets[i] = pallet
            end
        end
    end

    SetModelAsNoLongerNeeded(modelHash)
end

function DespawnMissionPallets()
    for _, entity in pairs(MissionPallets) do
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

-- Returns entity, slotIndex of the nearest pickable ground pallet (slotIndex is nil in
-- practice only if MissionPallets somehow held a non-numeric key, which never happens).
local function GetPickupCandidatePallet(forklift)
    local forkCoords = GetForkliftBoneCoords(forklift)
    local bestEntity, bestSlot, bestDist = nil, nil, nil

    for slotIndex, entity in pairs(MissionPallets) do
        if entity and DoesEntityExist(entity) then
            local palletCoords = GetEntityCoords(entity)
            local horizontal = #(vector2(forkCoords.x, forkCoords.y) - vector2(palletCoords.x, palletCoords.y))
            local vertical    = palletCoords.z - forkCoords.z

            if horizontal <= 0.7 and vertical >= -0.08 and vertical <= 0.18 then
                local dist = #(forkCoords - palletCoords)
                if not bestDist or dist < bestDist then
                    bestEntity, bestSlot, bestDist = entity, slotIndex, dist
                end
            end
        end
    end

    return bestEntity, bestSlot
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

-- Decorative (unnetworked, local-only) copy of a pallet a teammate is carrying on their
-- forklift - same pattern as AttachDecorativePalletToTrailer below, just for forks.
local function AttachDecorativePalletToForklift(forklift)
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
    if not HasModelLoaded(modelHash) then return nil end

    local prop = CreateObject(modelHash, 0.0, 0.0, 0.0, false, false, false)
    SetModelAsNoLongerNeeded(modelHash)
    if not prop or prop == 0 then return nil end

    AttachEntityToEntity(prop, forklift, boneIndex,
        offset.x, offset.y, offset.z,
        offset.rx, offset.ry, offset.rz,
        false, false, false, false, 2, true)
    SetEntityInvincible(prop, true)
    SetEntityProofs(prop, true, true, true, true, true, true, true, true)
    return prop
end

function DetachPalletFromForklift()
    if ForkliftPallet.entity and DoesEntityExist(ForkliftPallet.entity) then
        DetachEntity(ForkliftPallet.entity, true, true)
        DeleteEntity(ForkliftPallet.entity)
    end
    ForkliftPallet.entity = nil
    ForkliftPallet.slotIndex = nil
end

function GetForkliftPalletPayload()
    return ForkliftPallet.entity
end

function PickupPalletWithForklift(sourcePallet, slotIndex)
    if not IsPlayerInForklift() then
        Framework.Notify(Locale("notify.must_sitting_forklift"), "error")
        return
    end
    if ForkliftPallet.entity then
        Framework.Notify(Locale("notify.already_pallet_forks"), "error")
        return
    end
    if not sourcePallet or not DoesEntityExist(sourcePallet) or not slotIndex then return end

    if DeliveryState.mode == "party" then
        local ok = lib.callback.await("polarix_trucker:claimGroundPallet", false, slotIndex)
        debug.DebugPrint(("PickupPalletWithForklift: party slot=%s claim ok=%s"):format(slotIndex, tostring(ok)))
        if not ok then
            Framework.Notify(Locale("notify.pallet_already_taken"), "error")
            MissionPallets[slotIndex] = nil
            if DoesEntityExist(sourcePallet) then DeleteEntity(sourcePallet) end
            return
        end
    end

    MissionPallets[slotIndex] = nil
    DeleteEntity(sourcePallet)

    ForkliftPallet.slotIndex = slotIndex
    AttachPalletToForklift()
    Framework.Notify(Locale("notify.pallet_picked_up"), "success")
end

local currentPickupCandidate = nil
local currentPickupCandidateSlot = nil
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
            currentPickupCandidate, currentPickupCandidateSlot = nil, nil
            SetForkliftPickupPrompt(false)
        elseif IsPlayerInForklift and IsPlayerInForklift() then
            local forklift = GetPlayerForklift()
            if forklift then
                currentPickupCandidate, currentPickupCandidateSlot = GetPickupCandidatePallet(forklift)
            else
                currentPickupCandidate, currentPickupCandidateSlot = nil, nil
            end
            SetForkliftPickupPrompt(currentPickupCandidate ~= nil)
        else
            currentPickupCandidate, currentPickupCandidateSlot = nil, nil
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
            PickupPalletWithForklift(currentPickupCandidate, currentPickupCandidateSlot)
        end
    end,
})

local function GetTrailerModelNameFor(trailer)
    if not trailer then return nil end
    local modelHash = GetEntityModel(trailer)
    for name, _ in pairs(shared.CompatibleTrailers) do
        if GetHashKey(name) == modelHash then return name end
    end
    return nil
end

function GetTrailerModelName()
    return GetTrailerModelNameFor(GetActiveTrailer())
end

local function GetFreeTrailerSlot(maxPallets)
    for slot = 1, maxPallets do
        if not LoadedPallets[slot] then return slot end
    end
    return nil
end

local palletLoadBusy = false

local function TryLoadPalletOnTrailerSolo()
    if not ForkliftPallet.entity or not DoesEntityExist(ForkliftPallet.entity) then return end
    local trailer = GetActiveTrailer()
    if not trailer then return end

    local trailerModel = GetTrailerModelName()
    local trailerConfig = trailerModel and shared.CompatibleTrailers[trailerModel]
    if not trailerConfig then
        Framework.Notify(Locale("notify.trailer_does_not_support_pallets"), "error")
        return
    end

    local slot = GetFreeTrailerSlot(trailerConfig.maxPallets)
    if not slot then
        Framework.Notify(Locale("notify.trailer_full"), "error")
        return
    end

    palletLoadBusy = true

    local ok = lib.progressCircle({
        duration = 4000,
        position = "bottom",
        label = Locale("ui.loading_pallet"),
        canCancel = true,
        disable = { car = true, move = true, combat = true },
    })

    if not ok then
        palletLoadBusy = false
        return
    end

    if not ForkliftPallet.entity or not DoesEntityExist(ForkliftPallet.entity) then
        palletLoadBusy = false
        return
    end
    if LoadedPallets[slot] then
        palletLoadBusy = false
        return
    end

    local offset = trailerConfig.attachOffsets[slot]
    if not offset then
        Framework.Notify(Locale("notify.slot_offset_missing_not_calibrated"), "error")
        palletLoadBusy = false
        return
    end

    local prop = ForkliftPallet.entity
    DetachEntity(prop, true, true)
    AttachEntityToEntity(prop, trailer, 0,
        offset.x, offset.y, offset.z,
        offset.rx, offset.ry, offset.rz,
        false, false, false, false, 2, true)

    SetEntityCollision(prop, true, true)
    SetEntityNoCollisionEntity(prop, trailer, true)
    for otherSlot, otherEntity in pairs(LoadedPallets) do
        if otherSlot ~= slot and otherEntity and DoesEntityExist(otherEntity) then
            SetEntityNoCollisionEntity(prop, otherEntity, true)
            SetEntityNoCollisionEntity(otherEntity, prop, true)
        end
    end

    LoadedPallets[slot] = prop
    ForkliftPallet.entity = nil
    ForkliftPallet.slotIndex = nil

    MissionCargo.loadedCount = MissionCargo.loadedCount + 1

    if MissionCargo.loadedCount >= MissionCargo.requiredCount then
        Framework.Notify(Locale("notify.all_pallets_loaded_stow_forklift"), "success")
    else
        Framework.Notify(Locale("notify.pallet_loaded"):format(MissionCargo.loadedCount, MissionCargo.requiredCount), "success")
    end

    palletLoadBusy = false
end

-- Attaches a decorative (unnetworked, local-only) prop for a pallet another party member
-- physically loaded - every client that can see the target trailer renders its own copy at
-- the same deterministic offset, so no entity networking is needed to keep cargo in sync.
local function AttachDecorativePalletToTrailer(trailer, trailerSlot, trailerConfig)
    local offset = trailerConfig.attachOffsets[trailerSlot]
    if not offset then return nil end

    local modelHash = GetHashKey(shared.PalletModel)
    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 50 do
        Wait(50)
        timeout = timeout + 1
    end
    if not HasModelLoaded(modelHash) then return nil end

    local prop = CreateObject(modelHash, 0.0, 0.0, 0.0, false, false, false)
    SetModelAsNoLongerNeeded(modelHash)
    if not prop or prop == 0 then return nil end

    AttachEntityToEntity(prop, trailer, 0,
        offset.x, offset.y, offset.z,
        offset.rx, offset.ry, offset.rz,
        false, false, false, false, 2, true)
    SetEntityInvincible(prop, true)
    SetEntityCollision(prop, true, true)
    SetEntityNoCollisionEntity(prop, trailer, true)
    SetEntityProofs(prop, true, true, true, true, true, true, true, true)
    return prop
end

local function RegisterTrailerLoadedProp(trailer, trailerSlot, prop)
    local owned = TrailerLoadedProps[trailer]
    if not owned then
        owned = {}
        TrailerLoadedProps[trailer] = owned
    end
    for _, otherEntity in pairs(owned) do
        if otherEntity and DoesEntityExist(otherEntity) then
            SetEntityNoCollisionEntity(prop, otherEntity, true)
            SetEntityNoCollisionEntity(otherEntity, prop, true)
        end
    end
    owned[trailerSlot] = prop
end

-- targetIdentifier is nil for "my own trailer" - the server fills in the caller's own
-- identity in that case, so the client never needs to know its own identifier.
local function TryLoadPalletOnTrailerParty(targetTrailer, targetIdentifier)
    if not ForkliftPallet.entity or not DoesEntityExist(ForkliftPallet.entity) or not ForkliftPallet.slotIndex then return end
    if not targetTrailer or not DoesEntityExist(targetTrailer) then return end

    local trailerModel = GetTrailerModelNameFor(targetTrailer)
    local trailerConfig = trailerModel and shared.CompatibleTrailers[trailerModel]
    if not trailerConfig then
        Framework.Notify(Locale("notify.trailer_does_not_support_pallets"), "error")
        return
    end

    palletLoadBusy = true

    local ok = lib.progressCircle({
        duration = 4000,
        position = "bottom",
        label = Locale("ui.loading_pallet"),
        canCancel = true,
        disable = { car = true, move = true, combat = true },
    })

    if not ok then
        palletLoadBusy = false
        return
    end
    if not ForkliftPallet.entity or not DoesEntityExist(ForkliftPallet.entity) or not ForkliftPallet.slotIndex then
        palletLoadBusy = false
        return
    end

    local slotIndex = ForkliftPallet.slotIndex
    local success, trailerSlot, maxPallets = lib.callback.await("polarix_trucker:loadPalletOnTrailer", false, slotIndex, targetIdentifier)
    debug.DebugPrint(("TryLoadPalletOnTrailerParty: slot=%s target=%s -> success=%s trailerSlot=%s max=%s"):format(
        slotIndex, tostring(targetIdentifier), tostring(success), tostring(trailerSlot), tostring(maxPallets)))

    if not success then
        Framework.Notify(Locale("notify.trailer_full"), "error")
        palletLoadBusy = false
        return
    end

    local offset = trailerConfig.attachOffsets[trailerSlot]
    if offset then
        local prop = ForkliftPallet.entity
        DetachEntity(prop, true, true)
        AttachEntityToEntity(prop, targetTrailer, 0,
            offset.x, offset.y, offset.z,
            offset.rx, offset.ry, offset.rz,
            false, false, false, false, 2, true)
        SetEntityCollision(prop, true, true)
        SetEntityNoCollisionEntity(prop, targetTrailer, true)
        RegisterTrailerLoadedProp(targetTrailer, trailerSlot, prop)
    end

    ForkliftPallet.entity = nil
    ForkliftPallet.slotIndex = nil

    if targetIdentifier then
        Framework.Notify(Locale("notify.pallet_loaded_for"):format(trailerSlot, maxPallets or 0), "success")
    else
        Framework.Notify(Locale("notify.pallet_loaded"):format(trailerSlot, maxPallets or 0), "success")
    end

    palletLoadBusy = false
end

-- targetTrailer/targetIdentifier let forklift.lua point this at a teammate's trailer;
-- omit both to load onto the player's own active trailer (own-trailer party loads also
-- go through the party path so the server tracks who delivers what).
function TryLoadPalletOnTrailer(targetTrailer, targetIdentifier)
    if palletLoadBusy then return end
    if DeliveryState.mode == "party" then
        TryLoadPalletOnTrailerParty(targetTrailer or GetActiveTrailer(), targetIdentifier)
    else
        TryLoadPalletOnTrailerSolo()
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

    for _, slots in pairs(TrailerLoadedProps) do
        for _, entity in pairs(slots) do
            if entity and DoesEntityExist(entity) then
                DetachEntity(entity, true, true)
                DeleteEntity(entity)
            end
        end
    end
    TrailerLoadedProps = {}

    for _, entity in pairs(ForkliftCarriedProps) do
        if entity and DoesEntityExist(entity) then
            DetachEntity(entity, true, true)
            DeleteEntity(entity)
        end
    end
    ForkliftCarriedProps = {}
end

-- Called when a trip delivers but the mission isn't fully done yet (order needs more than
-- one trailer-load) - the trailer is physically empty again at the dropoff, so whatever was
-- visually still attached (mine, or what reconcile rendered for others watching me) has to
-- go, and loadedCount resets for the next trip.
function ClearOwnTrailerPallets()
    for slot, entity in pairs(LoadedPallets) do
        if entity and DoesEntityExist(entity) then
            DetachEntity(entity, true, true)
            DeleteEntity(entity)
        end
    end
    LoadedPallets = {}

    local ownTrailer = GetActiveTrailer()
    if ownTrailer and TrailerLoadedProps[ownTrailer] then
        for _, entity in pairs(TrailerLoadedProps[ownTrailer]) do
            if entity and DoesEntityExist(entity) then
                DetachEntity(entity, true, true)
                DeleteEntity(entity)
            end
        end
        TrailerLoadedProps[ownTrailer] = nil
    end

    MissionCargo.loadedCount = 0
end

-- Someone (possibly us) picked a ground pallet up - remove our local copy of that slot too
-- so nobody else can grab "the same" one.
RegisterNetEvent("polarix_trucker:partyGroundPalletTaken", function(slotIndex)
    local entity = MissionPallets[slotIndex]
    if entity and DoesEntityExist(entity) then
        DeleteEntity(entity)
    end
    MissionPallets[slotIndex] = nil
end)

-- A carried pallet reopened (dropout) - respawn it on the ground if we're still spawned in.
RegisterNetEvent("polarix_trucker:partyGroundPalletFreed", function(slotIndex)
    if not MissionCargo.pickupSpawned or MissionPallets[slotIndex] then return end
    if not (DeliveryState and DeliveryState.orderData) then return end

    local o = DeliveryState.orderData
    local heading = o.pickup_heading or 0.0
    local coordsList = o.pickup_pallet_coords
    if type(coordsList) ~= "table" or #coordsList == 0 then
        local anchor = vector3(o.pickup_x, o.pickup_y, o.pickup_z)
        coordsList = cargo.GenerateGridCoords(anchor, heading, cargo.CalcPalletCount(o.weight_kg))
    end
    local pos = coordsList[slotIndex]
    if not pos then return end

    local modelHash = GetHashKey(shared.PalletModel)
    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 100 do
        Wait(100)
        timeout = timeout + 1
    end
    if not HasModelLoaded(modelHash) then return end

    local pallet = CreateObject(modelHash, pos.x, pos.y, pos.z, false, false, false)
    SetModelAsNoLongerNeeded(modelHash)
    if pallet and pallet ~= 0 then
        SetEntityHeading(pallet, heading)
        PlaceObjectOnGroundProperly(pallet)
        FreezeEntityPosition(pallet, true)
        SetEntityCollision(pallet, true, true)
        SetEntityInvincible(pallet, true)
        SetEntityProofs(pallet, true, true, true, true, true, true, true, true)
        MissionPallets[slotIndex] = pallet
    end
end)

-- A pallet was loaded onto ownerIdentifier's trailer. Only the instant, correctness-critical
-- bits happen here (own loadedCount, ground cleanup) - decorative rendering for teammates is
-- the periodic reconcile loop's job below, so a client that missed this event (trailer not
-- streamed in yet) still catches up, and delivered pallets get cleaned up the same way.
RegisterNetEvent("polarix_trucker:partyPalletLoaded", function(slotIndex, ownerIdentifier, trailerSlot, isLoader, isOwner)
    local ground = MissionPallets[slotIndex]
    if ground and DoesEntityExist(ground) then
        DeleteEntity(ground)
    end
    MissionPallets[slotIndex] = nil

    if isOwner then
        MissionCargo.loadedCount = MissionCargo.loadedCount + 1
    end
end)

-- Adds any trailer prop that should exist locally but doesn't yet, removes any that
-- exists locally but shouldn't anymore (delivered, or the mission ended). wanted maps
-- trailer entity -> set of trailerSlot indices that should currently be visible there.
local function ReconcileTrailerProps(wanted)
    for trailer, slots in pairs(wanted) do
        local trailerModel = GetTrailerModelNameFor(trailer)
        local trailerConfig = trailerModel and shared.CompatibleTrailers[trailerModel]
        if trailerConfig then
            local owned = TrailerLoadedProps[trailer]
            for trailerSlot in pairs(slots) do
                local existing = owned and owned[trailerSlot]
                if not (existing and DoesEntityExist(existing)) then
                    local prop = AttachDecorativePalletToTrailer(trailer, trailerSlot, trailerConfig)
                    if prop then
                        RegisterTrailerLoadedProp(trailer, trailerSlot, prop)
                    end
                end
            end
        end
    end

    for trailer, slots in pairs(TrailerLoadedProps) do
        local wantedSlots = wanted[trailer]
        for trailerSlot, entity in pairs(slots) do
            if not (wantedSlots and wantedSlots[trailerSlot]) then
                if entity and DoesEntityExist(entity) then
                    DetachEntity(entity, true, true)
                    DeleteEntity(entity)
                end
                slots[trailerSlot] = nil
            end
        end
    end
end

local function ReconcileForkliftProps(teammateCarried, forkliftNetIds)
    for identifier in pairs(teammateCarried) do
        local existing = ForkliftCarriedProps[identifier]
        if not (existing and DoesEntityExist(existing)) then
            local netId = forkliftNetIds[identifier]
            local forklift = netId and NetworkGetEntityFromNetworkId(netId)
            if forklift and forklift ~= 0 and DoesEntityExist(forklift) then
                local prop = AttachDecorativePalletToForklift(forklift)
                if prop then
                    ForkliftCarriedProps[identifier] = prop
                end
            end
        end
    end

    for identifier, entity in pairs(ForkliftCarriedProps) do
        if not teammateCarried[identifier] then
            if entity and DoesEntityExist(entity) then
                DetachEntity(entity, true, true)
                DeleteEntity(entity)
            end
            ForkliftCarriedProps[identifier] = nil
        end
    end
end

-- Self-healing sync for everything a teammate might be doing with cargo (see the
-- getPartyCargoState doc comment server-side for why this replaced pure event-push):
-- catches clients that missed a load event (trailer not streamed in yet), and cleans up
-- decorative props for pallets that have since been delivered.
CreateThread(function()
    while true do
        Wait(3000)
        if DeliveryState and DeliveryState.mode == "party" and DeliveryState.status ~= "idle" then
            local state = lib.callback.await("polarix_trucker:getPartyCargoState", false)
            if state then
                local wanted = {}
                local ownTrailer = GetActiveTrailer()
                if ownTrailer and next(state.ownLoaded) then
                    wanted[ownTrailer] = state.ownLoaded
                end
                for identifier, slots in pairs(state.teammateLoaded or {}) do
                    local trailer = GetPartyTrailerEntity(identifier)
                    if trailer then wanted[trailer] = slots end
                end
                ReconcileTrailerProps(wanted)
                ReconcileForkliftProps(state.teammateCarried or {}, state.forkliftNetIds or {})
            end
        elseif next(TrailerLoadedProps) or next(ForkliftCarriedProps) then
            -- mission ended/left while props existed - CleanupMissionPalletsOnTrailer
            -- normally handles this, but a stale table here would leak entities forever.
            ReconcileTrailerProps({})
            ReconcileForkliftProps({}, {})
        end
    end
end)

CreateThread(function()
    while true do
        Wait(1000)
        if DeliveryState and DeliveryState.status == "awaiting_pickup" and DeliveryState.orderData then
            local o = DeliveryState.orderData
            local dist = #(GetEntityCoords(PlayerPedId()) - vector3(o.pickup_x, o.pickup_y, o.pickup_z))
            if dist < 40.0 and not MissionCargo.pickupSpawned then
                if DeliveryState.mode == "party" then
                    -- Shared pool: every member just sees what's left, no per-player claim.
                    SpawnMissionPallets(o)
                else
                    local claim = Delivery.RequestTripClaim()
                    debug.DebugPrint(("SpawnMissionPallets poll: mode=solo dist=%.1f claim=%s"):format(dist, tostring(claim)))
                    if claim > 0 then
                        MissionCargo.requiredCount = claim
                        MissionCargo.loadedCount = 0
                        SpawnMissionPallets(o)
                    else
                        Framework.Notify(Locale("notify.no_pallets_left_pool"), "info")
                    end
                end
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
