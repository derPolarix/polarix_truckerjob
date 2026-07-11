local config = require("config.shared")
local Locale = require("shared.locale")

Rental = {}
RentalState = {} -- source -> { nextChargeAt = <GetGameTimer() ms> }

local INTERVAL_MS = config.Rental.IntervalMinutes * 60 * 1000

function Rental.IsActive(source)
    return RentalState[source] ~= nil
end

function Rental.Start(source)
    if RentalState[source] then return false, Locale("error.rental_already_active") end
    if Framework.GetMoney(source) < config.Rental.IntervalCost then
        return false, Locale("error.not_enough_money_first_installment")
    end

    Framework.RemoveMoney(source, config.Rental.IntervalCost)
    RentalState[source] = { nextChargeAt = GetGameTimer() + INTERVAL_MS }

    TriggerClientEvent("polarix_trucker:rentalStarted", source, config.Rental.VehicleModel, config.Rental.TrailerModel)
    return true
end

function Rental.Return(source)
    if not RentalState[source] then return false end
    RentalState[source] = nil
    TriggerClientEvent("polarix_trucker:rentalEnded", source, "returned")
    return true
end

function Rental.Repossess(source, reason)
    if not RentalState[source] then return end
    RentalState[source] = nil

    if ActiveDeliveries[source] then
        Orders.Fail(source)
    end

    TriggerClientEvent("polarix_trucker:rentalEnded", source, reason)
end

-- Billing thread: charges each active rental at its interval
CreateThread(function()
    while true do
        Wait(15000)
        local now = GetGameTimer()
        for source, state in pairs(RentalState) do
            if now >= state.nextChargeAt then
                if Framework.GetMoney(source) >= config.Rental.IntervalCost then
                    Framework.RemoveMoney(source, config.Rental.IntervalCost)
                    state.nextChargeAt = now + INTERVAL_MS
                    TriggerClientEvent("polarix_trucker:rentalCharged", source, config.Rental.IntervalCost)
                else
                    Rental.Repossess(source, Locale("notify.payment_failed"))
                end
            end
        end
    end
end)

lib.callback.register("polarix_trucker:startRental", function(source)
    return Rental.Start(source)
end)

RegisterNetEvent("polarix_trucker:returnRental", function()
    Rental.Return(source)
end)

-- Avoid orphaned state after logout
Framework.OnPlayerUnload(function(source)
    RentalState[source] = nil
end)
