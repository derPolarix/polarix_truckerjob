local config = require("config.shared")

Skills = {}

function Skills.GetSkillDef(skillId)
    for _, branch in ipairs(config.Skills.branches) do
        for _, skill in ipairs(branch.skills) do
            if skill.id == skillId then return skill end
        end
    end
    return nil
end

function Skills.GetBranchesForPlayer(source)
    local result = {}
    for _, branch in ipairs(config.Skills.branches) do
        local branchOut = { name = branch.name, icon = branch.icon, skills = {} }
        for i, skill in ipairs(branch.skills) do
            local acquired    = Player.HasSkill(source, skill.id)
            local prevAcquired = i == 1 or Player.HasSkill(source, branch.skills[i - 1].id)
            local state       = acquired and "acquired" or (prevAcquired and "available" or "locked")
            branchOut.skills[#branchOut.skills + 1] = {
                id       = skill.id,
                name     = skill.name,
                desc     = skill.desc,
                cost     = skill.cost,
                requires = skill.requires,
                state    = state,
            }
        end
        result[#result + 1] = branchOut
    end
    return result
end

function Skills.Unlock(source, skillId)
    local pData = Player.GetData(source)
    if not pData then return false, "Spielerdaten fehlen." end

    if Player.HasSkill(source, skillId) then return false, "Bereits freigeschaltet." end

    local def = Skills.GetSkillDef(skillId)
    if not def then return false, "Skill nicht gefunden." end

    if def.requires and not Player.HasSkill(source, def.requires) then
        return false, "Voraussetzung nicht erfüllt."
    end

    if pData.skill_points < def.cost then
        return false, "Nicht genug Skill-Punkte."
    end

    pData.skill_points = pData.skill_points - def.cost
    table.insert(pData.skills, skillId)
    Player.Save(source)

    TriggerClientEvent("polarix_trucker:skillUnlocked", source, skillId, pData.skill_points)
    return true
end

function Skills.ApplyRewardModifiers(source, baseReward, cargoType, order)
    local reward = baseReward
    local xp     = order.xp_base

    if Player.HasSkill(source, "e2") then
        reward = math.floor(reward * 1.08)
    end

    if cargoType == "heavy" and Player.HasSkill(source, "h4") then
        reward = math.floor(reward * 1.25)
    end

    return reward, xp
end

function Skills.ApplyXPModifiers(source, baseXP)
    local xp = baseXP
    if Player.HasSkill(source, "d4") then
        xp = math.floor(xp * 1.15)
    end
    return xp
end

function Skills.GetFuelModifier(source)
    return Player.HasSkill(source, "e1") and 0.10 or 0.0
end

lib.callback.register("polarix_trucker:unlockSkill", function(source, skillId)
    local success, err = Skills.Unlock(source, skillId)
    if not success then return false, err end
    return true
end)
