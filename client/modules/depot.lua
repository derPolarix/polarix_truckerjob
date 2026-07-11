local clientConfig = require("config.client")
local Locale = require("shared.locale")

local depotNpc = nil

local function openDashboard()
    lib.callback("polarix_trucker:openDashboard", false, function(data)
        if not data then
            Framework.Notify(Locale("notify.failed_load_data"), "error")
            return
        end
        SetFocus(true)
        SendMessage("openNui", data)
    end)
end

local function spawnDepotNpc()
    local coords = clientConfig.TruckDepotCoords
    local model = GetHashKey("s_m_m_trucker_01")

    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    if not HasModelLoaded(model) then return nil end

    local ped = CreatePed(4, model, coords.x, coords.y, coords.z - 1.0, coords.w, false, true)
    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedDiesWhenInjured(ped, false)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    TaskStartScenarioInPlace(ped, "WORLD_HUMAN_CLIPBOARD", 0, true)
    SetModelAsNoLongerNeeded(model)

    depotNpc = ped
    return ped
end

local function setupBlip()
    local cfg = clientConfig.DepotBlip
    local coords = clientConfig.TruckDepotCoords
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, cfg.sprite)
    SetBlipColour(blip, cfg.color)
    SetBlipScale(blip, cfg.scale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(cfg.name)
    EndTextCommandSetBlipName(blip)
end

local function setupTarget(ped)
    if GetResourceState("ox_target") == "started" then
        exports.ox_target:addLocalEntity(ped, {
            {
                icon = "fa-solid fa-truck",
                label = Locale("ui.open_trucker_job"),
                onSelect = openDashboard,
            }
        })
        return
    end

    -- Fallback when ox_target isn't available: 3D marker + TextUI + E key
    local coords = clientConfig.TruckDepotCoords
    local npcPos = vector3(coords.x, coords.y, coords.z)
    local promptVisible = false
    local INTERACT_DIST = 2.5

    CreateThread(function()
        while DoesEntityExist(ped) do
            Wait(500)
            local dist = #(GetEntityCoords(PlayerPedId()) - npcPos)
            if dist < INTERACT_DIST and not promptVisible then
                promptVisible = true
                lib.showTextUI(Locale("ui.e_open_trucker_job"), { position = "top-center", icon = "truck" })
            elseif dist >= INTERACT_DIST and promptVisible then
                promptVisible = false
                lib.hideTextUI()
            end
        end
        if promptVisible then lib.hideTextUI() end
    end)

    CreateThread(function()
        while DoesEntityExist(ped) do
            Wait(0)
            local dist = #(GetEntityCoords(PlayerPedId()) - npcPos)

            if dist < 15.0 then
                DrawMarker(2, npcPos.x, npcPos.y, npcPos.z, 0, 0, 0, 0, 0, 0,
                    0.8, 0.8, 0.4, 232, 180, 8, 150, false, true, 2, false, "", "", false)
            end

            if promptVisible and IsControlJustReleased(0, 38) then -- E
                openDashboard()
            end
        end
    end)
end

CreateThread(function()
    Wait(500)
    setupBlip()
    local ped = spawnDepotNpc()
    if ped then setupTarget(ped) end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    if depotNpc and DoesEntityExist(depotNpc) then
        DeleteEntity(depotNpc)
        depotNpc = nil
    end
end)
