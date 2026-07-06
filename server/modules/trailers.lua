local config = require("config.server")
local sharedConfig = require("config.shared")

Trailers = {}

function Trailers.GetOwned(identifier)
    return DB.GetPlayerTrailers(identifier)
end

function Trailers.Buy(source, trailerSlot)
    local pData = Player.GetData(source)
    if not pData then return false, "Spielerdaten fehlen." end

    local shopEntry = nil
    for _, t in ipairs(config.TrailerShop) do
        if t.slot == trailerSlot then shopEntry = t; break end
    end
    if not shopEntry then return false, "Trailer nicht gefunden." end

    if pData.level < shopEntry.level_required then
        return false, ("Level %d erforderlich."):format(shopEntry.level_required)
    end

    local owned = DB.GetPlayerTrailers(pData.identifier)
    for _, t in ipairs(owned) do
        if t.trailer_slot == trailerSlot then return false, "Bereits besessen." end
    end

    local price = shopEntry.price
    if Player.HasSkill(source, "e3") then
        price = math.floor(price * 0.75)
    end

    if Framework.GetMoney(source) < price then return false, "Nicht genug Geld." end
    Framework.RemoveMoney(source, price)

    DB.InsertTrailer(pData.identifier, trailerSlot, shopEntry.model)
    return true, price
end

function Trailers.Equip(source, trailerSlot)
    local pData = Player.GetData(source)
    if not pData then return false, "Spielerdaten fehlen." end

    local owned = DB.GetPlayerTrailers(pData.identifier)
    local trailerModel = nil
    for _, t in ipairs(owned) do
        if t.trailer_slot == trailerSlot then
            trailerModel = t.trailer_model
            break
        end
    end
    if not trailerModel then return false, "Trailer nicht besessen." end

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
