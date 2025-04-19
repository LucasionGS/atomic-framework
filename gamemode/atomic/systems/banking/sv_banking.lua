--[[
    Player convenience functions
]]--
local playerMeta = FindMetaTable("Player")

function playerMeta:SetCash(amount)
    -- Set the player's money
    self:SetNWInt("ATOMIC_Cash", amount)
end

function playerMeta:AddCash(amount)
    -- Give the player money
    local currentMoney = self:GetCash()
    self:SetCash(currentMoney + amount)
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

--[[
    Banking Transfer Functions
]]--

-- Transfer money from wallet to bank
function playerMeta:DepositMoney(amount)
    if not isnumber(amount) or amount <= 0 then return false, "Invalid amount" end
    if self:GetCash() < amount then return false, "Insufficient funds in wallet" end
    
    self:AddCash(-amount)
    self:AddBank(amount)
    
    hook.Run("ATOMIC_PlayerDeposit", self, amount)
    return true, "Successfully deposited " .. ATOMIC:MoneyToString(amount)
end

-- Transfer money from bank to wallet
function playerMeta:WithdrawMoney(amount)
    if not isnumber(amount) or amount <= 0 then return false, "Invalid amount" end
    if self:GetBank() < amount then return false, "Insufficient funds in bank" end
    
    self:AddBank(-amount)
    self:AddCash(amount)
    
    hook.Run("ATOMIC_PlayerWithdraw", self, amount)
    return true, "Successfully withdrew " .. ATOMIC:MoneyToString(amount)
end

-- Network functions to allow client to request transfers
util.AddNetworkString("ATOMIC_RequestDeposit")
util.AddNetworkString("ATOMIC_RequestWithdraw")
util.AddNetworkString("ATOMIC_BankingResponse")

-- Handle deposit requests from client
net.Receive("ATOMIC_RequestDeposit", function(len, ply)
    local amount = net.ReadInt(32)
    local success, message = ply:DepositMoney(amount)
    
    net.Start("ATOMIC_BankingResponse")
    net.WriteBool(success)
    net.WriteString(message)
    net.Send(ply)
end)

-- Handle withdraw requests from client
net.Receive("ATOMIC_RequestWithdraw", function(len, ply)
    local amount = net.ReadInt(32)
    local success, message = ply:WithdrawMoney(amount)
    
    net.Start("ATOMIC_BankingResponse")
    net.WriteBool(success)
    net.WriteString(message)
    net.Send(ply)
end)