local Locale = require("shared.locale")

LocalPlayerData = {}

RegisterNetEvent("polarix_trucker:playerUpdate", function(data)
    for k, v in pairs(data) do
        LocalPlayerData[k] = v
    end
end)

RegisterNetEvent("polarix_trucker:levelUp", function(newLevel)
    Framework.Notify(Locale("notify.level_up_now_level"):format(newLevel), "success")
end)

function GetLocalPlayerData()
    return LocalPlayerData
end
