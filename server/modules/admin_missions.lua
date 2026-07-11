local cargo = require("shared.cargo")
local Locale = require("shared.locale")
local sampleMissions = require("server.sample_missions")

AdminMissions = {}

local function requireAdmin(source)
    if not Framework.IsAdmin(source) then return false, Locale("error.no_permission") end
    return true
end

local function slugify(name)
    local base = (name or "order"):lower():gsub("[^%w]+", "-"):gsub("^-+", ""):gsub("-+$", "")
    if base == "" then base = "order" end
    local candidate = base
    local suffix = 0
    while DB.OrderIdExists(candidate) do
        suffix = suffix + 1
        candidate = ("%s-%d"):format(base, suffix)
    end
    return candidate
end

function AdminMissions.Create(source, order)
    local ok, err = requireAdmin(source)
    if not ok then return false, err end

    local pData = Player.GetData(source)
    order.id = slugify(order.name)
    order.pickup_pallet_coords = order.pickup_pallet_coords or {}
    DB.InsertOrder(order) -- forces is_active = 1
    DB.SetOrderCreatedBy(order.id, pData and pData.identifier)
    DB.UpdateOrder(order.id, order, pData and pData.identifier) -- also sets updated_by
    return true, order.id
end

function AdminMissions.Update(source, orderId, order)
    local ok, err = requireAdmin(source)
    if not ok then return false, err end
    if not DB.OrderIdExists(orderId) then return false, Locale("error.mission_does_not_exist") end

    local pData = Player.GetData(source)
    DB.UpdateOrder(orderId, order, pData and pData.identifier)
    return true
end

function AdminMissions.SetActive(source, orderId, isActive)
    local ok, err = requireAdmin(source)
    if not ok then return false, err end
    local pData = Player.GetData(source)
    DB.SetOrderActive(orderId, isActive, pData and pData.identifier)
    return true
end

function AdminMissions.Delete(source, orderId)
    local ok, err = requireAdmin(source)
    if not ok then return false, err end
    if DB.CountDeliveriesForOrder(orderId) > 0 then
        return false, Locale("error.mission_delivery_history_deactivate_only")
    end
    DB.DeleteOrderHard(orderId)
    return true
end

-- Deliberately bypasses the delivery-history lock, deletes deliveries rows too.
-- Only reachable via the "Force Delete" confirm dialog in the web UI.
function AdminMissions.ForceDelete(source, orderId)
    local ok, err = requireAdmin(source)
    if not ok then return false, err end
    DB.DeleteDeliveriesForOrder(orderId)
    DB.DeleteOrderHard(orderId)
    return true
end

function AdminMissions.Clone(source, orderId)
    local ok, err = requireAdmin(source)
    if not ok then return false, err end
    local order = DB.GetOrderById(orderId)
    if not order then return false, Locale("error.mission_not_found") end
    if type(order.pickup_pallet_coords) == "string" then order.pickup_pallet_coords = json.decode(order.pickup_pallet_coords) end
    order.id = nil
    order.name = order.name .. " (Kopie)"
    return true, order -- caller re-submits via Create to persist
end

local function shallowCopy(t)
    local copy = {}
    for k, v in pairs(t) do copy[k] = v end
    return copy
end

-- Sample IDs are static (order-lv, ...); after delete+reimport, orphaned deliveries rows
-- under the same ID would still block a hard delete, so check those too, not just existing orders.
local function freshSampleId(baseId)
    local candidate = baseId
    local suffix = 0
    while DB.OrderIdExists(candidate) or DB.CountDeliveriesForOrder(candidate) > 0 do
        suffix = suffix + 1
        candidate = ("%s-%d"):format(baseId, suffix)
    end
    return candidate
end

-- Only allowed while no orders exist — no merge/overwrite case to handle.
function AdminMissions.ImportSampleMissions(source)
    local ok, err = requireAdmin(source)
    if not ok then return false, err end
    if (DB.CountOrders() or 0) > 0 then return false end

    for _, sample in ipairs(sampleMissions) do
        local order = shallowCopy(sample)
        order.id = freshSampleId(order.id)
        local anchor = vector3(order.pickup_x, order.pickup_y, order.pickup_z)
        local count = cargo.CalcPalletCount(order.weight_kg)
        order.pickup_pallet_coords = cargo.GenerateGridCoords(anchor, order.pickup_heading, count)
        DB.InsertOrder(order)
    end
    return true
end

-- QA-only test button: starts the mission for the calling admin, bypasses level/hazmat/long-hauler gates.
function AdminMissions.TestRun(source, orderId)
    local ok, err = requireAdmin(source)
    if not ok then return false, err end
    local order = DB.GetOrderById(orderId)
    if not order or not order.is_active then return false, Locale("error.mission_not_available") end
    if ActiveDeliveries[source] then return false, Locale("error.already_active_delivery") end
    if type(order.pickup_pallet_coords) == "string" then order.pickup_pallet_coords = json.decode(order.pickup_pallet_coords) end

    local pData = Player.GetData(source)
    local total = cargo.CalcPalletCount(order.weight_kg)
    local deliveryId = DB.InsertDelivery(orderId, pData.identifier)
    ActiveDeliveries[source] = { deliveryId = deliveryId, orderId = orderId, totalPallets = total, remainingPallets = total, deliveredPallets = 0, cargoDamageTotal = 0 }
    return true, order
end

-- Global, not local: server/commands.lua needs the same array/delivery_count shaping
-- as the adminListOrders callback.
function AdminMissions.ListForWeb()
    local orders = DB.GetAllOrdersAdmin()
    for _, order in ipairs(orders) do
        if type(order.pickup_pallet_coords) == "string" then order.pickup_pallet_coords = json.decode(order.pickup_pallet_coords) end
        order.delivery_count = DB.CountDeliveriesForOrder(order.id) or 0
    end
    return orders
end

lib.callback.register("polarix_trucker:adminListOrders", function(source)
    if not Framework.IsAdmin(source) then return {} end
    return AdminMissions.ListForWeb()
end)

lib.callback.register("polarix_trucker:adminCreateOrder", function(source, order) return AdminMissions.Create(source, order) end)
lib.callback.register("polarix_trucker:adminUpdateOrder", function(source, orderId, order) return AdminMissions.Update(source, orderId, order) end)
lib.callback.register("polarix_trucker:adminSetOrderActive", function(source, orderId, isActive) return AdminMissions.SetActive(source, orderId, isActive) end)
lib.callback.register("polarix_trucker:adminDeleteOrder", function(source, orderId) return AdminMissions.Delete(source, orderId) end)
lib.callback.register("polarix_trucker:adminForceDeleteOrder", function(source, orderId) return AdminMissions.ForceDelete(source, orderId) end)
lib.callback.register("polarix_trucker:adminCloneOrder", function(source, orderId) return AdminMissions.Clone(source, orderId) end)
lib.callback.register("polarix_trucker:adminTestRunOrder", function(source, orderId) return AdminMissions.TestRun(source, orderId) end)
lib.callback.register("polarix_trucker:adminImportSampleMissions", function(source) return AdminMissions.ImportSampleMissions(source) end)
