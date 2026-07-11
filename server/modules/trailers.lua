local config = require("config.server")
local sharedConfig = require("config.shared")
local Locale = require("shared.locale")

Trailers = {}

function Trailers.GetOwned(identifier)
    return DB.GetPlayerTrailers(identifier)
end

function Trailers.Buy(source, trailerSlot)
    local pData = Player.GetData(source)
    if not pData then return false, Locale("error.player_data_missing") end

    local shopEntry = nil
    for _, t in ipairs(config.TrailerShop) do
        if t.slot == trailerSlot then shopEntry = t; break end
    end
    if not shopEntry then return false, Locale("error.trailer_not_found") end

    if pData.level < shopEntry.level_required then
        return false, Locale("error.level_required"):format(shopEntry.level_required)
    end

    local owned = DB.GetPlayerTrailers(pData.identifier)
    for _, t in ipairs(owned) do
        if t.trailer_slot == trailerSlot then return false, Locale("error.already_owned") end
    end

    local price = shopEntry.price
    if Player.HasSkill(source, "e3") then
        price = math.floor(price * 0.75)
    end

    if Framework.GetMoney(source) < price then return false, Locale("error.not_enough_money") end
    Framework.RemoveMoney(source, price)

    DB.InsertTrailer(pData.identifier, trailerSlot, shopEntry.model)

    if not pData.equipped_trailer then
        pData.equipped_trailer = trailerSlot
        Player.Save(source)
        TriggerClientEvent("polarix_trucker:trailerSync", source, trailerSlot, shopEntry.model)
    end

    return true, price
end

function Trailers.Equip(source, trailerSlot)
    local pData = Player.GetData(source)
    if not pData then return false, Locale("error.player_data_missing") end

    local owned = DB.GetPlayerTrailers(pData.identifier)
    local trailerModel = nil
    for _, t in ipairs(owned) do
        if t.trailer_slot == trailerSlot then
            trailerModel = t.trailer_model
            break
        end
    end
    if not trailerModel then return false, Locale("error.trailer_not_owned") end

    pData.equipped_trailer = trailerSlot
    Player.Save(source)
    TriggerClientEvent("polarix_trucker:trailerEquipped", source, trailerSlot, trailerModel)
    return true
end

function Trailers.GetEquippedMaxPallets(source)
    local pData = Player.GetData(source)
    if not pData or not pData.equipped_trailer then return nil end

    local owned = DB.GetPlayerTrailers(pData.identifier)
    for _, t in ipairs(owned) do
        if t.trailer_slot == pData.equipped_trailer then
            local trailerConfig = sharedConfig.CompatibleTrailers[t.trailer_model]
            return trailerConfig and trailerConfig.maxPallets or nil
        end
    end
    return nil
end

-- Like GetEquippedMaxPallets but also covers the fixed rental capacity
-- (rental doesn't set equipped_trailer, see Orders.Accept hasOwnGear/Rental.IsActive branch).
function Trailers.GetActiveMaxPallets(source)
    if Rental.IsActive(source) then
        local trailerConfig = sharedConfig.CompatibleTrailers[sharedConfig.Rental.TrailerModel]
        return trailerConfig and trailerConfig.maxPallets or nil
    end
    return Trailers.GetEquippedMaxPallets(source)
end

lib.callback.register("polarix_trucker:buyTrailer", function(source, trailerSlot)
    local success, result = Trailers.Buy(source, trailerSlot)
    if not success then return false, nil, result end

    local pData = Player.GetData(source)
    local owned = DB.GetPlayerTrailers(pData.identifier)
    return true, result, nil, owned
end)

lib.callback.register("polarix_trucker:equipTrailer", function(source, trailerSlot)
    local success, err = Trailers.Equip(source, trailerSlot)
    if not success then return false, err end
    return true
end)
