local Locale = require("shared.locale")

Bank = {}

local function isValidAmount(amount)
    return type(amount) == "number" and amount == amount and amount > 0 and amount < math.huge
end

function Bank.Deposit(source, amount)
    local pData = Player.GetData(source)
    if not pData then return false, Locale("error.player_data_missing") end

    local membership = Company.GetMembership(pData.identifier)
    if not membership then return false, Locale("error.no_company_membership") end

    if not isValidAmount(amount) then return false, Locale("error.invalid_amount") end
    if Framework.GetMoney(source) < amount then return false, Locale("error.not_enough_money") end

    Framework.RemoveMoney(source, amount)
    DB.UpdateCompanyTreasury(membership.company_id, amount)
    DB.InsertTransaction(membership.company_id, "Einzahlung von " .. pData.name, amount, true, "tabler:arrow-down-left",
        "deposit", { name = pData.name })
    return true
end

function Bank.Withdraw(source, amount)
    local pData = Player.GetData(source)
    if not pData then return false, Locale("error.player_data_missing") end

    local membership = Company.GetMembership(pData.identifier)
    if not membership then return false, Locale("error.no_company_membership") end
    if membership.role ~= "owner" and membership.role ~= "manager" then
        return false, Locale("error.no_permission")
    end

    if not isValidAmount(amount) then return false, Locale("error.invalid_amount") end

    if not DB.DebitCompanyTreasury(membership.company_id, amount) then
        return false, Locale("error.not_enough_money_company_account")
    end

    Framework.AddMoney(source, amount)
    DB.InsertTransaction(membership.company_id, "Auszahlung an " .. pData.name, amount, false, "tabler:arrow-up-right",
        "withdrawal", { name = pData.name })
    return true
end

lib.callback.register("polarix_trucker:depositBank", function(source, amount)
    return Bank.Deposit(source, amount)
end)

lib.callback.register("polarix_trucker:withdrawBank", function(source, amount)
    return Bank.Withdraw(source, amount)
end)
