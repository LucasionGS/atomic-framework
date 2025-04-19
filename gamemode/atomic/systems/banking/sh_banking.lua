--[[
    Player convenience functions
]]--
local playerMeta = FindMetaTable("Player")

-- Get the player's current money
function playerMeta:GetCash()
    return self:GetNWInt("ATOMIC_Cash", 0)
end

-- Get the player's current bank balance
function playerMeta:GetBank()
    return self:GetNWInt("ATOMIC_Bank", 0)
end


-- Convert the money value to a string with the currency symbol
function ATOMIC:MoneyToString(money)
    return ATOMIC.Config.CurrencySymbol .. string.Comma(money)
end

-- Convert the money value to a string with the currency symbol
function ATOMIC:MoneyToLongString(money)
    return string.Comma(money) .. " " .. (money == 1 and ATOMIC.Config.CurrencyName or ATOMIC.Config.CurrencyPlural)
end