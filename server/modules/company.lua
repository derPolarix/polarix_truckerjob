Company = {}

function Company.GetMembership(identifier)
    return DB.GetMemberByPlayer(identifier)
end

function Company.Create(source, name, tag, description)
    local pData = Player.GetData(source)
    if not pData then return false, "Spielerdaten fehlen." end

    if Company.GetMembership(pData.identifier) then
        return false, "Du bist bereits in einer Company."
    end

    local companyId = DB.CreateCompany(name, tag, description)
    if not companyId or companyId == 0 then
        return false, "Name bereits vergeben."
    end

    DB.AddCompanyMember(companyId, pData.identifier, "owner")
    return true, companyId
end

function Company.GetFull(companyId, selfIdentifier)
    local company = DB.GetCompanyById(companyId)
    if not company then return nil end

    local members = DB.GetCompanyMembers(companyId)
    local enrichedMembers = {}
    for _, m in ipairs(members) do
        local pRow = DB.GetPlayer(m.identifier)
        local isOnline = false
        for _, pd in pairs(PlayerCache) do
            if pd.identifier == m.identifier then
                isOnline = true
                break
            end
        end
        enrichedMembers[#enrichedMembers + 1] = {
            identifier = m.identifier,
            name       = pRow and pRow.name or "Unknown",
            role       = m.role,
            deliveries = m.deliveries,
            earned     = m.earnings,
            lvl        = pRow and pRow.level or 1,
            isOnline   = isOnline,
            isYou      = selfIdentifier == m.identifier,
        }
    end

    local invitations = DB.GetCompanyInvitations(companyId)
    local enrichedInvites = {}
    for _, inv in ipairs(invitations) do
        local pRow = DB.GetPlayer(inv.target_identifier)
        enrichedInvites[#enrichedInvites + 1] = {
            identifier = inv.target_identifier,
            name       = pRow and pRow.name or "Unknown",
            lvl        = pRow and pRow.level or 1,
            created_at = inv.created_at,
        }
    end

    local transactions = DB.GetCompanyTransactions(companyId, 20)

    return {
        id               = company.id,
        name             = company.name,
        tag              = company.tag,
        description      = company.description,
        level            = company.level,
        xp               = company.xp,
        treasury         = company.treasury,
        total_earnings   = company.total_earnings,
        total_deliveries = company.total_deliveries,
        open_recruitment = company.open_recruitment,
        founded_at       = company.founded_at,
        members          = enrichedMembers,
        invitations      = enrichedInvites,
        transactions     = transactions,
    }
end

function Company.Invite(source, targetName)
    local pData = Player.GetData(source)
    if not pData then return false, "Spielerdaten fehlen." end

    local membership = Company.GetMembership(pData.identifier)
    if not membership then return false, "Du bist in keiner Company." end
    if membership.role ~= "owner" and membership.role ~= "manager" then
        return false, "Keine Berechtigung."
    end

    local targetRow = DB.GetPlayerByName(targetName)
    if not targetRow then return false, "Spieler nicht gefunden." end
    if Company.GetMembership(targetRow.identifier) then
        return false, "Spieler ist bereits in einer Company."
    end

    DB.InsertInvitation(membership.company_id, targetRow.identifier, pData.identifier)

    for src, pd in pairs(PlayerCache) do
        if pd.identifier == targetRow.identifier then
            local companyRow = DB.GetCompanyById(membership.company_id)
            TriggerClientEvent("polarix_trucker:inviteReceived", src,
                membership.company_id, companyRow and companyRow.name or "Unknown", pData.name)
            break
        end
    end

    return true
end

function Company.RespondInvite(source, companyId, accept)
    local pData = Player.GetData(source)
    if not pData then return false, "Spielerdaten fehlen." end

    DB.DeleteInvitation(companyId, pData.identifier)

    if accept then
        if Company.GetMembership(pData.identifier) then
            return false, "Du bist bereits in einer Company."
        end
        DB.AddCompanyMember(companyId, pData.identifier, "recruit")
    end
    return true
end

function Company.ChangeRole(source, targetIdentifier, newRole)
    local pData = Player.GetData(source)
    if not pData then return false, "Spielerdaten fehlen." end

    local membership = Company.GetMembership(pData.identifier)
    if not membership or membership.role ~= "owner" then
        return false, "Keine Berechtigung."
    end
    if targetIdentifier == pData.identifier then
        return false, "Eigene Rolle kann nicht geändert werden."
    end

    DB.UpdateMemberRole(targetIdentifier, membership.company_id, newRole)
    return true
end

function Company.KickMember(source, targetIdentifier)
    local pData = Player.GetData(source)
    if not pData then return false, "Spielerdaten fehlen." end

    local membership = Company.GetMembership(pData.identifier)
    if not membership or (membership.role ~= "owner" and membership.role ~= "manager") then
        return false, "Keine Berechtigung."
    end
    if targetIdentifier == pData.identifier then
        return false, "Kannst dich nicht selbst kicken."
    end

    DB.DeleteMember(targetIdentifier, membership.company_id)
    return true
end

function Company.SaveSettings(source, settings)
    local pData = Player.GetData(source)
    if not pData then return false, "Spielerdaten fehlen." end

    local membership = Company.GetMembership(pData.identifier)
    if not membership or membership.role ~= "owner" then
        return false, "Keine Berechtigung."
    end

    DB.UpdateCompanySettings(
        membership.company_id,
        settings.name, settings.tag, settings.description, settings.openRecruitment
    )
    return true
end

function Company.AddXP(companyId, amount)
    DB.UpdateCompanyXP(companyId, amount)
end

function Company.OnDeliveryComplete(source, reward)
    local pData = Player.GetData(source)
    if not pData then return end

    local membership = Company.GetMembership(pData.identifier)
    if not membership then return end

    DB.UpdateCompanyStats(membership.company_id, reward)
    DB.UpdateMemberStats(pData.identifier, membership.company_id, reward)
    Company.AddXP(membership.company_id, 10)
end

-- Callbacks

lib.callback.register("polarix_trucker:createCompany", function(source, name, tag, description)
    local success, result = Company.Create(source, name, tag, description)
    if not success then return false, result end
    return true
end)

lib.callback.register("polarix_trucker:inviteMember", function(source, targetName)
    return Company.Invite(source, targetName)
end)

lib.callback.register("polarix_trucker:respondInvite", function(source, companyId, accept)
    return Company.RespondInvite(source, companyId, accept)
end)

lib.callback.register("polarix_trucker:kickMember", function(source, targetIdentifier)
    return Company.KickMember(source, targetIdentifier)
end)

lib.callback.register("polarix_trucker:changeRole", function(source, targetIdentifier, newRole)
    return Company.ChangeRole(source, targetIdentifier, newRole)
end)

lib.callback.register("polarix_trucker:saveCompanySettings", function(source, settings)
    return Company.SaveSettings(source, settings)
end)
