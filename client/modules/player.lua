LocalPlayerData = {}

RegisterNetEvent("polarix_trucker:playerUpdate", function(data)
    for k, v in pairs(data) do
        LocalPlayerData[k] = v
    end
end)

RegisterNetEvent("polarix_trucker:levelUp", function(newLevel)
    Framework.Notify(("Level Up! Du bist jetzt Level %s"):format(newLevel), "success")
end)

function GetLocalPlayerData()
    return LocalPlayerData
end
