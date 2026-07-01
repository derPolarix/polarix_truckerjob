local config = require("config.server")

Vehicles = {}

function Vehicles.GetOwned(identifier)
    return DB.GetPlayerVehicles(identifier)
end

function Vehicles.Buy(source, vehicleSlot)
    local pData = Player.GetData(source)
    if not pData then return false, "Spielerdaten fehlen." end

    local shopEntry = nil
    for _, v in ipairs(config.VehicleShop) do
        if v.slot == vehicleSlot then shopEntry = v; break end
    end
    if not shopEntry then return false, "Fahrzeug nicht gefunden." end

    if pData.level < shopEntry.level_required then
        return false, ("Level %d erforderlich."):format(shopEntry.level_required)
    end

    local owned = DB.GetPlayerVehicles(pData.identifier)
    for _, v in ipairs(owned) do
        if v.vehicle_slot == vehicleSlot then return false, "Bereits besessen." end
    end

    -- Bulk Deals Skill: 25% Rabatt
    local price = shopEntry.price
    if Player.HasSkill(source, "e3") then
        price = math.floor(price * 0.75)
    end

    if Framework.GetMoney(source) < price then return false, "Nicht genug Geld." end
    Framework.RemoveMoney(source, price)

    DB.InsertVehicle(pData.identifier, vehicleSlot, shopEntry.model)
    return true, price
end

function Vehicles.Equip(source, vehicleSlot)
    local pData = Player.GetData(source)
    if not pData then return false, "Spielerdaten fehlen." end

    local owned = DB.GetPlayerVehicles(pData.identifier)
    local vehicleModel = nil
    for _, v in ipairs(owned) do
        if v.vehicle_slot == vehicleSlot then
            vehicleModel = v.vehicle_model
            break
        end
    end
    if not vehicleModel then return false, "Fahrzeug nicht besessen." end

    pData.equipped_vehicle = vehicleSlot
    Player.Save(source)
    TriggerClientEvent("polarix_trucker:vehicleEquipped", source, vehicleSlot, vehicleModel)
    return true
end

lib.callback.register("polarix_trucker:buyVehicle", function(source, vehicleSlot)
    local success, result = Vehicles.Buy(source, vehicleSlot)
    if not success then return false, nil, result end

    local pData = Player.GetData(source)
    local owned = DB.GetPlayerVehicles(pData.identifier)
    return true, result, nil, owned
end)

lib.callback.register("polarix_trucker:equipVehicle", function(source, vehicleSlot)
    local success, err = Vehicles.Equip(source, vehicleSlot)
    if not success then return false, err end
    return true
end)
