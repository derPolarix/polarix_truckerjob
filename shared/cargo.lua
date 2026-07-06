local shared = require("config.shared")

local Cargo = {}

function Cargo.CalcPalletCount(weightKg)
    local count = math.ceil((weightKg or 0) / shared.PalletWeightKg)
    return math.max(1, math.min(count, shared.MaxPalletsPerOrder))
end

function Cargo.GenerateGridCoords(anchor, heading, count)
    local perRow  = 3
    local spacing = 2.2
    local rad     = math.rad(heading or 0.0)
    local rowDir  = vector3(math.cos(rad), math.sin(rad), 0.0)
    local colDir  = vector3(-math.sin(rad), math.cos(rad), 0.0)

    local coords = {}
    for i = 1, count do
        local col = (i - 1) % perRow
        local row = math.floor((i - 1) / perRow)
        local pos = anchor + rowDir * (col * spacing) + colDir * (row * spacing)
        coords[#coords + 1] = { x = pos.x, y = pos.y, z = pos.z }
    end
    return coords
end

return Cargo
