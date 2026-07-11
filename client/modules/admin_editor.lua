local shared = require("config.shared")
local cargo  = require("shared.cargo")

AdminEditorGhosts = {}
AdminEditorPreview = { active = false, dropoffX = nil, dropoffY = nil, dropoffZ = nil, dropoffHeading = 0.0 }

RegisterNetEvent("polarix_trucker:openAdminEditor", function(orders)
    SetFocus(true)
    -- ships PalletWeightKg/MaxPalletsPerOrder so web/ can duplicate Cargo.CalcPalletCount without hardcoding them
    SendMessage("openAdminMissions", { orders = orders, palletWeightKg = shared.PalletWeightKg, maxPalletsPerOrder = shared.MaxPalletsPerOrder })
end)

local function spawnGhostPallet(pos, heading)
    local modelHash = GetHashKey(shared.PalletModel)
    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 50 do Wait(50); timeout = timeout + 1 end
    if not HasModelLoaded(modelHash) then return nil end

    local prop = CreateObject(modelHash, pos.x, pos.y, pos.z, false, false, false)
    if prop and prop ~= 0 then
        SetEntityHeading(prop, heading or 0.0)
        PlaceObjectOnGroundProperly(prop)
        FreezeEntityPosition(prop, true)
        SetEntityCollision(prop, false, false)
        SetEntityAlpha(prop, 120, false)
    end
    SetModelAsNoLongerNeeded(modelHash)
    return prop
end

-- called by the NUI once per unconfirmed pallet row in the form
RegisterNUICallback('adminPreviewPallet', function(data, cb)
    local idx = data.index
    if AdminEditorGhosts[idx] and DoesEntityExist(AdminEditorGhosts[idx]) then
        DeleteEntity(AdminEditorGhosts[idx])
    end
    AdminEditorGhosts[idx] = spawnGhostPallet(vector3(data.x, data.y, data.z), data.heading)
    cb({ ok = true })
end)

-- called once the admin confirms a coordinate, removing the ghost
RegisterNUICallback('adminConfirmPallet', function(data, cb)
    local idx = data.index
    if AdminEditorGhosts[idx] and DoesEntityExist(AdminEditorGhosts[idx]) then
        DeleteEntity(AdminEditorGhosts[idx])
    end
    AdminEditorGhosts[idx] = nil
    cb({ ok = true })
end)

RegisterNUICallback('adminClearGhosts', function(_, cb)
    for _, entity in pairs(AdminEditorGhosts) do
        if entity and DoesEntityExist(entity) then DeleteEntity(entity) end
    end
    AdminEditorGhosts = {}
    cb({ ok = true })
end)

RegisterNUICallback('getCurrentPosition', function(_, cb)
    local coords = GetEntityCoords(PlayerPedId())
    local heading = GetEntityHeading(PlayerPedId())
    cb({ x = coords.x, y = coords.y, z = coords.z, heading = heading })
end)

-- uses the exact same function that places the real pickup pallets at runtime
RegisterNUICallback('adminGenerateGrid', function(data, cb)
    local anchor = vector3(data.x, data.y, data.z)
    local coords = cargo.GenerateGridCoords(anchor, data.heading or 0.0, data.count or 1)
    cb({ ok = true, coords = coords })
end)

-- dropoff preview: same pattern as parking.lua's DrawParkingRectangle, minus the green-state branch
RegisterNUICallback('adminSetDropoffPreview', function(data, cb)
    if data.active then
        AdminEditorPreview.active = true
        AdminEditorPreview.dropoffX, AdminEditorPreview.dropoffY, AdminEditorPreview.dropoffZ = data.x, data.y, data.z
        AdminEditorPreview.dropoffHeading = data.heading or 0.0
    else
        AdminEditorPreview.active = false
    end
    cb({ ok = true })
end)

-- reuses DrawOutlineRectangle (from parking.lua), always red since the editor has no "correctly parked" state.
-- trailer footprint fallback (11.0 x 2.6) is fine here since no real trailer is involved.
local function DrawAdminDropoffOutline(preview)
    local center = vector3(preview.dropoffX, preview.dropoffY, preview.dropoffZ - 0.8)
    DrawOutlineRectangle(center, preview.dropoffHeading or 0.0, 11.0, 2.6, false)
end

CreateThread(function()
    while true do
        if AdminEditorPreview.active then
            DrawAdminDropoffOutline(AdminEditorPreview)
            Wait(0)
        else
            Wait(300)
        end
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for _, entity in pairs(AdminEditorGhosts) do
        if entity and DoesEntityExist(entity) then DeleteEntity(entity) end
    end
end)
