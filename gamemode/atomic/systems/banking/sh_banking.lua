--[[
    Player convenience functions
]]--
local playerMeta = FindMetaTable("Player")

function playerMeta:GetMoney()
    -- Get the player's current money
    return self:GetNWInt("ATOMIC_Money", 0)
end

function playerMeta:GetBank()
    -- Get the player's current bank balance
    return self:GetNWInt("ATOMIC_Bank", 0)
end