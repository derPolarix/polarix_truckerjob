local config = require("config.shared")

Party = {}
Parties = {}             -- partyId -> { leader, members = { [identifier] = { source, name, joinedAt } } }
PlayerParty = {}          -- identifier -> partyId
PendingPartyInvites = {}  -- identifier -> partyId (invite awaiting response)

local nextPartyId = 1

local function broadcastPartyState(partyId)
    local party = Parties[partyId]
    if not party then return end
    local state = Party.BuildState(partyId)
    for _, m in pairs(party.members) do
        if m.source then TriggerClientEvent("polarix_trucker:partyUpdate", m.source, state) end
    end
end

function Party.GetMembership(identifier)
    local partyId = PlayerParty[identifier]
    return partyId and Parties[partyId]
end

function Party.BuildState(partyId)
    local party = Parties[partyId]
    if not party then return nil end
    local members = {}
    for identifier, m in pairs(party.members) do
        members[#members + 1] = { identifier = identifier, name = m.name, isLeader = identifier == party.leader, online = m.source ~= nil }
    end
    return { partyId = partyId, leaderIdentifier = party.leader, members = members, maxSize = config.PartyMaxSize }
end

-- Zentrale Austritts-Logik: von Leave, Kick UND Disconnect genutzt, damit Leader-Transfer/
-- Party-Auflösung/Mission-Fail nicht dreifach implementiert werden.
local function removeMember(partyId, identifier, keepEntryOffline)
    local party = Parties[partyId]
    if not party then return end

    if keepEntryOffline then
        party.members[identifier].source = nil
    else
        party.members[identifier] = nil
        PlayerParty[identifier] = nil
    end

    local onlineCandidates = {}
    for id, m in pairs(party.members) do
        if m.source then onlineCandidates[#onlineCandidates + 1] = id end
    end

    if #onlineCandidates == 0 then
        if PartyMissions and PartyMissions[partyId] and PartyMission then PartyMission.Fail(partyId) end
        for id in pairs(party.members) do PlayerParty[id] = nil end
        Parties[partyId] = nil
        return
    end

    if party.leader == identifier or not party.members[party.leader] then
        party.leader = onlineCandidates[math.random(#onlineCandidates)] -- zufällige Übergabe
    end

    broadcastPartyState(partyId)
end

function Party.Invite(source, targetIdentifier)
    local pData = Player.GetData(source)
    if not pData then return false, "Spielerdaten fehlen." end

    if Party.GetMembership(targetIdentifier) then return false, "Spieler ist bereits in einer Party." end

    local companyMembership = Company.GetMembership(pData.identifier)
    local targetCompany = Company.GetMembership(targetIdentifier)
    if not companyMembership or not targetCompany or companyMembership.company_id ~= targetCompany.company_id then
        return false, "Nur Mitglieder deiner Company können eingeladen werden."
    end

    local myPartyId = PlayerParty[pData.identifier]
    if myPartyId and Parties[myPartyId].leader ~= pData.identifier then
        return false, "Nur der Party-Leader kann einladen."
    end
    if myPartyId and PartyMissions and PartyMissions[myPartyId] then
        return false, "Party-Mission läuft, aktuell keine Einladungen möglich."
    end

    if not myPartyId then
        myPartyId = nextPartyId
        nextPartyId = nextPartyId + 1
        Parties[myPartyId] = { leader = pData.identifier, members = {
            [pData.identifier] = { source = source, name = pData.name, joinedAt = os.time() },
        } }
        PlayerParty[pData.identifier] = myPartyId
    end

    local party = Parties[myPartyId]
    local memberCount = 0
    for _ in pairs(party.members) do memberCount = memberCount + 1 end
    if memberCount >= config.PartyMaxSize then return false, "Party ist voll." end

    local targetSource = Player.GetSourceByIdentifier(targetIdentifier)
    if not targetSource then return false, "Spieler ist nicht online." end

    PendingPartyInvites[targetIdentifier] = myPartyId
    TriggerClientEvent("polarix_trucker:partyInviteReceived", targetSource, myPartyId, pData.name)
    Notifications.Push(targetIdentifier, "party_invite", "Party Invite", ("%s invited you to their party."):format(pData.name), "tabler:users")

    return true, myPartyId
end

function Party.RespondInvite(source, partyId, accept)
    local pData = Player.GetData(source)
    if not pData then return false, "Spielerdaten fehlen." end

    if PendingPartyInvites[pData.identifier] ~= partyId then
        return false, "Einladung ist nicht mehr gültig."
    end
    PendingPartyInvites[pData.identifier] = nil

    if not accept then return true end

    if PlayerParty[pData.identifier] then return false, "Du bist bereits in einer Party." end

    local party = Parties[partyId]
    if not party then return false, "Party existiert nicht mehr." end
    if PartyMissions and PartyMissions[partyId] then
        return false, "Party-Mission läuft, aktuell keine Einladungen möglich."
    end

    local memberCount = 0
    for _ in pairs(party.members) do memberCount = memberCount + 1 end
    if memberCount >= config.PartyMaxSize then return false, "Party ist voll." end

    party.members[pData.identifier] = { source = source, name = pData.name, joinedAt = os.time() }
    PlayerParty[pData.identifier] = partyId
    broadcastPartyState(partyId)
    return true
end

function Party.TransferLeader(source, targetIdentifier)
    local pData = Player.GetData(source)
    local partyId = pData and PlayerParty[pData.identifier]
    local party = partyId and Parties[partyId]
    if not party or party.leader ~= pData.identifier then return false, "Nur der Leader kann übergeben." end
    if not party.members[targetIdentifier] or not party.members[targetIdentifier].source then
        return false, "Zielspieler ist kein Online-Party-Mitglied."
    end
    party.leader = targetIdentifier
    broadcastPartyState(partyId)
    return true
end

function Party.Kick(source, targetIdentifier)
    local pData = Player.GetData(source)
    local partyId = pData and PlayerParty[pData.identifier]
    local party = partyId and Parties[partyId]
    if not party or party.leader ~= pData.identifier then return false, "Nur der Leader kann kicken." end
    if targetIdentifier == pData.identifier then return false, "Kannst dich nicht selbst kicken." end
    if not party.members[targetIdentifier] then return false, "Spieler ist nicht in der Party." end

    local targetSource = party.members[targetIdentifier].source
    if PartyMissions and PartyMissions[partyId] and PartyMission and targetSource then
        PartyMission.HandleMemberDropout(targetSource)
    end

    removeMember(partyId, targetIdentifier, false)
    if targetSource then TriggerClientEvent("polarix_trucker:partyKicked", targetSource) end
    return true
end

function Party.Leave(source)
    local pData = Player.GetData(source)
    local partyId = pData and PlayerParty[pData.identifier]
    if not partyId then return false end
    if PartyMissions and PartyMissions[partyId] and PartyMission then
        PartyMission.HandleMemberDropout(source) -- gibt offenen Claim zurück in den Pool
    end
    removeMember(partyId, pData.identifier, false)
    return true
end

function Party.Disband(source)
    local pData = Player.GetData(source)
    local partyId = pData and PlayerParty[pData.identifier]
    local party = partyId and Parties[partyId]
    if not party or party.leader ~= pData.identifier then return false, "Nur der Leader kann die Party auflösen." end

    if PartyMissions and PartyMissions[partyId] and PartyMission then PartyMission.Fail(partyId) end

    for identifier, m in pairs(party.members) do
        PlayerParty[identifier] = nil
        if m.source and identifier ~= pData.identifier then
            TriggerClientEvent("polarix_trucker:partyDisbanded", m.source)
        end
    end
    Parties[partyId] = nil
    return true
end

Framework.OnPlayerUnload(function(source)
    local pData = Player.GetData(source)
    if not pData then return end
    local partyId = PlayerParty[pData.identifier]
    if not partyId then return end
    if PartyMissions and PartyMissions[partyId] and PartyMission then PartyMission.HandleMemberDropout(source) end
    removeMember(partyId, pData.identifier, true) -- Eintrag bleibt (offline) für möglichen Reconnect
end)

lib.callback.register("polarix_trucker:getPartyState", function(source)
    local pData = Player.GetData(source)
    local partyId = pData and PlayerParty[pData.identifier]
    return partyId and Party.BuildState(partyId) or nil
end)

lib.callback.register("polarix_trucker:getCompanyOnlineMembers", function(source)
    local pData = Player.GetData(source)
    if not pData then return {} end
    local membership = Company.GetMembership(pData.identifier)
    if not membership then return {} end

    local result = {}
    for _, pd in pairs(PlayerCache) do
        if pd.identifier ~= pData.identifier and not Party.GetMembership(pd.identifier) then
            local m = Company.GetMembership(pd.identifier)
            if m and m.company_id == membership.company_id then
                result[#result + 1] = { identifier = pd.identifier, name = pd.name, lvl = pd.level }
            end
        end
    end
    return result
end)

lib.callback.register("polarix_trucker:invitePartyMember", function(source, targetIdentifier) return Party.Invite(source, targetIdentifier) end)
lib.callback.register("polarix_trucker:respondPartyInvite", function(source, partyId, accept) return Party.RespondInvite(source, partyId, accept) end)
lib.callback.register("polarix_trucker:transferPartyLeader", function(source, targetIdentifier) return Party.TransferLeader(source, targetIdentifier) end)
lib.callback.register("polarix_trucker:kickPartyMember", function(source, targetIdentifier) return Party.Kick(source, targetIdentifier) end)
lib.callback.register("polarix_trucker:leaveParty", function(source) return Party.Leave(source) end)
lib.callback.register("polarix_trucker:disbandParty", function(source) return Party.Disband(source) end)
