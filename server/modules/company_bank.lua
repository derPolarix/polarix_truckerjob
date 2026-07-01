Bank = {}

function Bank.Deposit(source, amount)
    local pData = Player.GetData(source)
    if not pData then return false, "Spielerdaten fehlen." end

    local membership = Company.GetMembership(pData.identifier)
    if not membership then return false, "Nicht in einer Company." end

    if type(amount) ~= "number" or amount <= 0 then return false, "Ungültiger Betrag." end
    if Framework.GetMoney(source) < amount then return false, "Nicht genug Geld." end

    Framework.RemoveMoney(source, amount)
    DB.UpdateCompanyTreasury(membership.company_id, amount)
    DB.InsertTransaction(membership.company_id, "Einzahlung von " .. pData.name, amount, true, "tabler:arrow-down-left")
    return true
end

function Bank.Withdraw(source, amount)
    local pData = Player.GetData(source)
    if not pData then return false, "Spielerdaten fehlen." end

    local membership = Company.GetMembership(pData.identifier)
    if not membership then return false, "Nicht in einer Company." end
    if membership.role ~= "owner" and membership.role ~= "manager" then
        return false, "Keine Berechtigung."
    end

    if type(amount) ~= "number" or amount <= 0 then return false, "Ungültiger Betrag." end

    local company = DB.GetCompanyById(membership.company_id)
    if not company or company.treasury < amount then
        return false, "Nicht genug Geld in der Kasse."
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
