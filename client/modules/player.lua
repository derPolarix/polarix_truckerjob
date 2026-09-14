local Locale = require("shared.locale")
local Money = require("shared.currency")

LocalPlayerData = {}

RegisterNetEvent("polarix_trucker:playerUpdate", function(data)
    for k, v in pairs(data) do
        LocalPlayerData[k] = v
    end
end)

RegisterNetEvent("polarix_trucker:levelUp", function(newLevel)
    Framework.Notify(Locale("notify.level_up_now_level"):format(newLevel), "success")
end)

RegisterNetEvent("polarix_trucker:driverIncomePaid", function(amount)
    Framework.Notify(Locale("notify.driver_income_paid"):format(Money(amount)), "info")
end)

function GetLocalPlayerData()
    return LocalPlayerData
end
