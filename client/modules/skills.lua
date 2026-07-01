LocalSkills = {}

Skills = Skills or {}

-- Initialisiert LocalSkills beim Login und nach playerUpdate (falls skills mitgeschickt)
AddEventHandler("polarix_trucker:playerUpdate", function(data)
    if data.skills then
        LocalSkills = data.skills
    end
end)

AddEventHandler("polarix_trucker:skillUnlocked", function(skillId, newPoints)
    table.insert(LocalSkills, skillId)
    LocalPlayerData.skill_points = newPoints
    Framework.Notify("Skill freigeschaltet!", "success")
end)

function Skills.HasSkill(skillId)
    for _, id in ipairs(LocalSkills) do
        if id == skillId then return true end
    end
    return false
end

-- Steady Hands (h1): -15% Cargo-Schaden
function Skills.GetDamageModifier()
    return Skills.HasSkill("h1") and 0.85 or 1.0
end

-- Fuel Saver (e1): 10% weniger Kraftstoffverbrauch
function Skills.GetFuelModifier()
    return Skills.HasSkill("e1") and 0.10 or 0.0
end

-- Night Owl (d2): keine Handling-Penalty nachts
function Skills.IsNightPenaltyActive()
    if Skills.HasSkill("d2") then return false end
    local hour = GetClockHours()
    return hour >= 22 or hour < 6
end

-- Iron Will (d1): +30 Minuten Fatigue-Timer-Bonus
function Skills.GetFatigueBonus()
    return Skills.HasSkill("d1") and 30 or 0
end
