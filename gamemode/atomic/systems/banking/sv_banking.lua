--[[
    Player convenience functions
]]--
local playerMeta = FindMetaTable("Player")

function playerMeta:SetMoney(amount)
    -- Set the player's money
    self:SetNWInt("ATOMIC_Money", amount)
end

function playerMeta:AddMoney(amount)
    -- Give the player money
    local currentMoney = self:GetMoney()
    self:SetMoney(currentMoney + amount)
end

function playerMeta:SetBank(amount)
    -- Set the player's bank balance
    self:SetNWInt("ATOMIC_Bank", amount)
end

function playerMeta:AddBank(amount)
    -- Give the player money
    local currentBank = self:GetBank()
    self:SetBank(currentBank + amount)
end