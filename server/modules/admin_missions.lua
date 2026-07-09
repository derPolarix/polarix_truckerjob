local cargo = require("shared.cargo")

AdminMissions = {}

local function requireAdmin(source)
    if not Framework.IsAdmin(source) then return false, "Keine Berechtigung." end
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
    DB.InsertOrder(order) -- setzt is_active = 1 fest (bestehende Signatur, siehe database.lua)
    DB.SetOrderCreatedBy(order.id, pData and pData.identifier)
    DB.UpdateOrder(order.id, order, pData and pData.identifier) -- vergibt zusätzlich updated_by
    return true, order.id
end

function AdminMissions.Update(source, orderId, order)
    local ok, err = requireAdmin(source)
    if not ok then return false, err end
    if not DB.OrderIdExists(orderId) then return false, "Mission existiert nicht." end

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
        return false, "Mission hat Lieferhistorie — nur deaktivieren, nicht löschen."
    end
    DB.DeleteOrderHard(orderId)
    return true
end

function AdminMissions.Clone(source, orderId)
    local ok, err = requireAdmin(source)
    if not ok then return false, err end
    local order = DB.GetOrderById(orderId)
    if not order then return false, "Mission nicht gefunden." end
    if type(order.pickup_pallet_coords) == "string" then order.pickup_pallet_coords = json.decode(order.pickup_pallet_coords) end
    order.id = nil
    order.name = order.name .. " (Kopie)"
    return true, order -- Client bekommt vorausgefülltes Formular, speichert separat via Create
end

-- Reiner Test-Button für Admins (QA), kein "Zuweisen"-Feature — startet die Mission nur für den
-- aufrufenden Admin selbst, umgeht Gates, damit neue Missionen sofort durchgespielt werden können.
function AdminMissions.TestRun(source, orderId)
    local ok, err = requireAdmin(source)
    if not ok then return false, err end
    -- Bewusst KEIN Level/Hazmat/Long-Hauler-Gate — reiner Test-Button für Admins
    local order = DB.GetOrderById(orderId)
    if not order or not order.is_active then return false, "Mission nicht verfügbar." end
    if ActiveDeliveries[source] then return false, "Du hast bereits eine aktive Lieferung." end
    if type(order.pickup_pallet_coords) == "string" then order.pickup_pallet_coords = json.decode(order.pickup_pallet_coords) end

    local pData = Player.GetData(source)
    local total = cargo.CalcPalletCount(order.weight_kg)
    local deliveryId = DB.InsertDelivery(orderId, pData.identifier)
    ActiveDeliveries[source] = { deliveryId = deliveryId, orderId = orderId, totalPallets = total, remainingPallets = total, deliveredPallets = 0, cargoDamageTotal = 0 }
    return true, order
end

-- Web-Formular braucht pickup_pallet_coords als Array (nicht JSON-String) sowie delivery_count
-- pro Order, um den Löschen-Button gaten zu können (siehe admin-mission-editor-plan.md Phase D).
-- Global (nicht local), da server/commands.lua (/truckeradmin, initiales Öffnen) dieselbe
-- Aufbereitung braucht wie der lib.callback für den späteren "adminListOrders"-Refetch —
-- sonst bekäme das Formular beim ersten Öffnen JSON-Strings statt Arrays.
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
lib.callback.register("polarix_trucker:adminCloneOrder", function(source, orderId) return AdminMissions.Clone(source, orderId) end)
lib.callback.register("polarix_trucker:adminTestRunOrder", function(source, orderId) return AdminMissions.TestRun(source, orderId) end)
