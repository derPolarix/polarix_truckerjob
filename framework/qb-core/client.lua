local QBCore

local function getQBCore()
    QBCore = QBCore or exports["qb-core"]:GetCoreObject()
    return QBCore
end

return {
    GetPlayerData = function()
        return getQBCore().Functions.GetPlayerData()
    end,

    GetMoney = function()
        return getQBCore().Functions.GetPlayerData().money.bank
    end,

    -- Fahrzeugschlüssel vergeben (qb-vehiclekeys Key-System)
    GiveVehicleKeys = function(_vehicle, plate)
        if GetResourceState("qb-vehiclekeys") == "started" then
            TriggerEvent("vehiclekeys:client:SetOwner", plate)
        end
    end,
}
