local config = require("config.shared")
local Locale = require("shared.locale")

Company = {}

function Company.GetMembership(identifier)
    return DB.GetMemberByPlayer(identifier)
end

function Company.Create(source, name, tag, description)
    local pData = Player.GetData(source)
    if not pData then return false, Locale("error.player_data_missing") end

    if Company.GetMembership(pData.identifier) then
        return false, Locale("error.already_company")
    end

    local companyId = DB.CreateCompany(name, tag, description)
    if not companyId or companyId == 0 then
        return false, Locale("error.name_already_taken")
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
        tax_rate         = company.tax_rate or 0,
        min_level_to_join = company.min_level_to_join or 1,
        founded_at       = company.founded_at,
        members          = enrichedMembers,
        invitations      = enrichedInvites,
        transactions     = transactions,
    }
end

function Company.Invite(source, targetIdentifier)
    local pData = Player.GetData(source)
    if not pData then return false, Locale("error.player_data_missing") end

    local membership = Company.GetMembership(pData.identifier)
    if not membership then return false, Locale("error.not_in_a_company") end
    if membership.role ~= "owner" and membership.role ~= "manager" then
        return false, Locale("error.no_permission")
    end

    local targetRow = DB.GetPlayer(targetIdentifier)
    if not targetRow then return false, Locale("error.player_not_found") end
    if Company.GetMembership(targetIdentifier) then
        return false, Locale("error.player_already_company")
    end

    DB.InsertInvitation(membership.company_id, targetIdentifier, pData.identifier)

    local companyRow = DB.GetCompanyById(membership.company_id)
    local companyName = companyRow and companyRow.name or "Unknown"

    local targetSource = Player.GetSourceByIdentifier(targetIdentifier)
    if targetSource then
        TriggerClientEvent("polarix_trucker:inviteReceived", targetSource,
            membership.company_id, companyName, pData.name, companyRow and companyRow.tax_rate or 0)
    end

    Notifications.Push(targetIdentifier, "company_invite", Locale("push.company_invite"),
        Locale("push.invited"):format(pData.name, companyName), "tabler:mail")

    return true
end

function Company.CancelInvite(source, targetIdentifier)
    local pData = Player.GetData(source)
    if not pData then return false, Locale("error.player_data_missing") end

    local membership = Company.GetMembership(pData.identifier)
    if not membership or (membership.role ~= "owner" and membership.role ~= "manager") then
        return false, Locale("error.no_permission")
    end

    DB.DeleteInvitation(membership.company_id, targetIdentifier)
    return true
end

-- Scannt online Spieler in Reichweite (kein Username-Feld vorhanden — Company-Namen können
-- doppelt vergeben sein, daher Auswahl per Nähe statt Texteingabe).
function Company.GetNearbyRecruits(source)
    local pData = Player.GetData(source)
    if not pData then return {} end

    local membership = Company.GetMembership(pData.identifier)
    if not membership or (membership.role ~= "owner" and membership.role ~= "manager") then
        return {}
    end

    local originCoords = GetEntityCoords(GetPlayerPed(source))
    local radius = config.CompanyInviteRadius or 15.0

    local nearby = {}
    for src, pd in pairs(PlayerCache) do
        if src ~= source and not Company.GetMembership(pd.identifier) then
            local targetPed = GetPlayerPed(src)
            if targetPed ~= 0 then
                local dist = #(originCoords - GetEntityCoords(targetPed))
                if dist <= radius then
                    nearby[#nearby + 1] = { identifier = pd.identifier, name = pd.name, lvl = pd.level }
                end
            end
        end
    end
    return nearby
end

function Company.GetIncomingInvites(identifier)
    local rows = DB.GetInvitationsForPlayer(identifier)
    local result = {}
    for _, r in ipairs(rows) do
        local inviter = DB.GetPlayer(r.invited_by)
        result[#result + 1] = {
            companyId   = r.company_id,
            companyName = r.company_name,
            companyTag  = r.company_tag,
            invitedBy   = inviter and inviter.name or "Unknown",
            created_at  = r.created_at,
        }
    end
    return result
end

function Company.RespondInvite(source, companyId, accept)
    local pData = Player.GetData(source)
    if not pData then return false, Locale("error.player_data_missing") end

    DB.DeleteInvitation(companyId, pData.identifier)

    if accept then
        if Company.GetMembership(pData.identifier) then
            return false, Locale("error.already_company")
        end
        DB.AddCompanyMember(companyId, pData.identifier, "recruit")
        Company.NotifyOwnerMemberJoined(companyId, pData.name)
    end
    return true
end

function Company.NotifyOwnerMemberJoined(companyId, memberName)
    local owner = DB.GetCompanyOwner(companyId)
    if owner then
        Notifications.Push(owner.identifier, "member_joined", Locale("push.new_member"),
            Locale("push.joined_company"):format(memberName), "tabler:user-plus")
    end
end

function Company.ChangeRole(source, targetIdentifier, newRole)
    local pData = Player.GetData(source)
    if not pData then return false, Locale("error.player_data_missing") end

    local membership = Company.GetMembership(pData.identifier)
    if not membership or membership.role ~= "owner" then
        return false, Locale("error.no_permission")
    end
    if targetIdentifier == pData.identifier then
        return false, Locale("error.cannot_change_own_role")
    end

    DB.UpdateMemberRole(targetIdentifier, membership.company_id, newRole)
    return true
end

function Company.KickMember(source, targetIdentifier)
    local pData = Player.GetData(source)
    if not pData then return false, Locale("error.player_data_missing") end

    local membership = Company.GetMembership(pData.identifier)
    if not membership or (membership.role ~= "owner" and membership.role ~= "manager") then
        return false, Locale("error.no_permission")
    end
    if targetIdentifier == pData.identifier then
        return false, Locale("error.cannot_kick_yourself")
    end

    DB.DeleteMember(targetIdentifier, membership.company_id)
    return true
end

function Company.SaveSettings(source, settings)
    local pData = Player.GetData(source)
    if not pData then return false, Locale("error.player_data_missing") end

    local membership = Company.GetMembership(pData.identifier)
    if not membership or membership.role ~= "owner" then
        return false, Locale("error.no_permission")
    end

    local taxRate = tonumber(settings.taxRate) or 0
    taxRate = math.floor(math.max(0, math.min(25, taxRate)))

    local maxLevel = #config.XPThresholds
    local minLevel = tonumber(settings.minLevel) or 1
    minLevel = math.floor(math.max(1, math.min(maxLevel, minLevel)))

    DB.UpdateCompanySettings(
        membership.company_id,
        settings.name, settings.tag, settings.description, settings.openRecruitment, taxRate, minLevel
    )
    return true
end

function Company.Disband(source)
    local pData = Player.GetData(source)
    if not pData then return false, Locale("error.player_data_missing") end

    local membership = Company.GetMembership(pData.identifier)
    if not membership or membership.role ~= "owner" then
        return false, Locale("error.no_permission")
    end

    local companyId = membership.company_id
    local members = DB.GetCompanyMembers(companyId)

    DB.DeleteCompany(companyId)

    for _, m in ipairs(members) do
        if m.identifier ~= pData.identifier then
            local memberSource = Player.GetSourceByIdentifier(m.identifier)
            if memberSource then
                TriggerClientEvent("polarix_trucker:companyDisbanded", memberSource)
            end
        end
    end

    return true
end

function Company.Leave(source)
    local pData = Player.GetData(source)
    if not pData then return false, Locale("error.player_data_missing") end

    local membership = Company.GetMembership(pData.identifier)
    if not membership then return false, Locale("error.not_in_a_company") end
    if membership.role == "owner" then
        return false, Locale("error.as_owner_must_disband_company")
    end

    local owner = DB.GetCompanyOwner(membership.company_id)
    DB.DeleteMember(pData.identifier, membership.company_id)
    if owner then
        Notifications.Push(owner.identifier, "member_left", Locale("push.member_left"),
            Locale("push.left_company"):format(pData.name), "tabler:user-minus")
    end
    return true
end

function Company.AddXP(companyId, amount)
    local company = DB.GetCompanyById(companyId)
    if not company then return end

    local newXp = company.xp + amount
    local newLevel = company.level
    local thresholds = config.CompanyXPThresholds
    while newLevel < #thresholds and newXp >= thresholds[newLevel + 1] do
        newLevel = newLevel + 1
    end

    DB.UpdateCompanyXP(companyId, amount)

    if newLevel > company.level then
        DB.SetCompanyLevel(companyId, newLevel)
        for _, m in ipairs(DB.GetCompanyMembers(companyId)) do
            Notifications.Push(m.identifier, "company_level_up", Locale("push.company_level_up"),
                Locale("push.company_reached_level"):format(newLevel), "tabler:building")
        end
    end
end

-- Zieht die Company-Abgabe (Steuer) vom Reward ab und bucht sie in die Kasse/Historie.
-- Gibt den Netto-Reward und den abgezogenen Betrag zurück.
function Company.ApplyTax(source, reward)
    local pData = Player.GetData(source)
    if not pData then return reward, 0 end

    local membership = Company.GetMembership(pData.identifier)
    if not membership then return reward, 0 end

    local company = DB.GetCompanyById(membership.company_id)
    local taxRate = company and (company.tax_rate or 0) or 0
    if taxRate <= 0 then return reward, 0 end

    local taxAmount = math.floor(reward * taxRate / 100)
    if taxAmount <= 0 then return reward, 0 end

    DB.UpdateCompanyTreasury(membership.company_id, taxAmount)
    DB.InsertTransaction(
        membership.company_id,
        ("Abgabe von %s (%d%%)"):format(pData.name, taxRate),
        taxAmount, true, "tabler:receipt-tax"
    )

    return reward - taxAmount, taxAmount
end

function Company.OnDeliveryComplete(source, reward)
    local pData = Player.GetData(source)
    if not pData then return end

    local membership = Company.GetMembership(pData.identifier)
    if not membership then return end

    DB.UpdateCompanyStats(membership.company_id, reward)
    DB.UpdateMemberStats(pData.identifier, membership.company_id, reward)
    Company.AddXP(membership.company_id, 10)
    Leaderboard.CheckCompanyTop3(membership.company_id)
end

-- Callbacks

lib.callback.register("polarix_trucker:createCompany", function(source, name, tag, description)
    local success, result = Company.Create(source, name, tag, description)
    if not success then return false, result end
    return true
end)

lib.callback.register("polarix_trucker:inviteMember", function(source, targetIdentifier)
    return Company.Invite(source, targetIdentifier)
end)

lib.callback.register("polarix_trucker:cancelInvite", function(source, targetIdentifier)
    return Company.CancelInvite(source, targetIdentifier)
end)

lib.callback.register("polarix_trucker:getNearbyRecruits", function(source)
    return Company.GetNearbyRecruits(source)
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

lib.callback.register("polarix_trucker:disbandCompany", function(source)
    return Company.Disband(source)
end)

lib.callback.register("polarix_trucker:leaveCompany", function(source)
    return Company.Leave(source)
end)

function Company.RequestJoin(source, companyId)
    local pData = Player.GetData(source)
    if not pData then return false, Locale("error.player_data_missing") end

    if Company.GetMembership(pData.identifier) then
        return false, Locale("error.already_company")
    end

    local company = DB.GetCompanyById(companyId)
    if not company then return false, Locale("error.company_not_found") end

    local isOpen = company.open_recruitment == 1 or company.open_recruitment == true
    if not isOpen then return false, Locale("error.company_not_accepting_applications") end

    local minLevel = company.min_level_to_join or 1
    if pData.level < minLevel then
        return false, Locale("error.minimum_level_required"):format(minLevel)
    end

    DB.AddCompanyMember(companyId, pData.identifier, "recruit")
    Company.NotifyOwnerMemberJoined(companyId, pData.name)
    return true
end

lib.callback.register("polarix_trucker:requestJoin", function(source, companyId)
    return Company.RequestJoin(source, companyId)
end)
