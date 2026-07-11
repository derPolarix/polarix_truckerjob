local Locale = require("shared.locale")

Bank = {}

function Bank.Deposit(source, amount)
    local pData = Player.GetData(source)
    if not pData then return false, Locale("error.player_data_missing") end

    local membership = Company.GetMembership(pData.identifier)
    if not membership then return false, Locale("error.no_company_membership") end

    if type(amount) ~= "number" or amount <= 0 then return false, Locale("error.invalid_amount") end
    if Framework.GetMoney(source) < amount then return false, Locale("error.not_enough_money") end

    Framework.RemoveMoney(source, amount)
    DB.UpdateCompanyTreasury(membership.company_id, amount)
    DB.InsertTransaction(membership.company_id, "Einzahlung von " .. pData.name, amount, true, "tabler:arrow-down-left")
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

    if type(amount) ~= "number" or amount <= 0 then return false, Locale("error.invalid_amount") end

    local company = DB.GetCompanyById(membership.company_id)
    if not company or company.treasury < amount then
        return false, Locale("error.not_enough_money_company_account")
    end

    DB.UpdateCompanyTreasury(membership.company_id, -amount)
    Framework.AddMoney(source, amount)
    DB.InsertTransaction(membership.company_id, "Auszahlung an " .. pData.name, amount, false, "tabler:arrow-up-right")
    return true
end

lib.callback.register("polarix_trucker:depositBank", function(source, amount)
    return Bank.Deposit(source, amount)
end)

lib.callback.register("polarix_trucker:withdrawBank", function(source, amount)
    return Bank.Withdraw(source, amount)
end)
