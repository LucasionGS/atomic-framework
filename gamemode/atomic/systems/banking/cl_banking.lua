--[[
    ATOMIC Banking Interface
    Allows players to transfer money between their wallet and bank account
]]--

-- Variables to prevent spam clicking
local lastClick = 0

-- Create notification system for banking messages
local bankingNotifications = {}

local function AddBankingNotification(message, isError)
    local notification = {
        message = message,
        color = isError and ATOMIC.Config.Colors.Error or ATOMIC.Config.Colors.Success,
        time = CurTime(),
        alpha = 255
    }
    
    table.insert(bankingNotifications, notification)
    
    -- Remove old notifications
    if #bankingNotifications > 5 then
        table.remove(bankingNotifications, 1)
    end
end

-- Handle responses from the server
net.Receive("ATOMIC_BankingResponse", function()
    local success = net.ReadBool()
    local message = net.ReadString()
    
    AddBankingNotification(message, not success)
    
    -- Refresh the dialog if it's open
    if success then
        timer.Simple(0.1, function()
            BankDialog(LocalPlayer())
        end)
    end
end)

-- Function to create a withdraw option
local function MakeWithdraw(amount, bank)
    return {
        text = "Withdraw " .. ATOMIC:MoneyToString(amount),
        click = function()
            if CurTime() < lastClick + 0.5 then return false end
            lastClick = CurTime()
            
            net.Start("ATOMIC_RequestWithdraw")
            net.WriteInt(amount, 32)
            net.SendToServer()
            
            -- If shift is held, reopen the withdraw dialog with updated amount
            if input.IsKeyDown(KEY_LSHIFT) then
                timer.Simple(0.2, function()
                    Withdraw(LocalPlayer(), bank - amount)
                end)
            end
        end,
        nosound = true
    }
end

-- Function to create a deposit option
local function MakeDeposit(amount, money, bank)
    return {
        text = "Deposit " .. ATOMIC:MoneyToString(amount),
        click = function()
            if CurTime() < lastClick + 0.5 then return false end
            lastClick = CurTime()
            
            net.Start("ATOMIC_RequestDeposit")
            net.WriteInt(amount, 32)
            net.SendToServer()
            
            -- If shift is held, reopen the deposit dialog with updated amount
            if input.IsKeyDown(KEY_LSHIFT) then
                timer.Simple(0.2, function()
                    Deposit(LocalPlayer(), money - amount, bank + amount)
                end)
            end
        end,
        nosound = true
    }
end

-- Function to open the withdraw dialog
function Withdraw(ply, bank)
    bank = bank or ply:GetBank()
    
    local options = {}
    
    -- Generate withdraw options for different amounts
    for i = 2, 7 do
        local amount = 10 ^ i
        if bank >= amount * 0.5 then
            table.insert(options, MakeWithdraw(amount * 0.5, bank))
        end
        if bank >= amount then
            table.insert(options, MakeWithdraw(amount, bank))
        end
    end
    
    -- Add options for half and all of bank balance
    if bank > 0 and bank < 10000000 then
        if bank > 1 then
            table.insert(options, MakeWithdraw(math.floor(bank / 2), bank))
        end
        table.insert(options, MakeWithdraw(bank, bank))
    end
    
    -- Add back button
    table.insert(options, {
        text = "<Back",
        click = function()
            BankDialog(ply)
        end,
        color = ATOMIC.Config.Colors.Error,
        hoverColor = Color(255, 0, 0)
    })
    
    ATOMIC:Dialog(
        "Balance: " .. ATOMIC:MoneyToString(bank),
        "Withdraw money from your bank account.\n\nHow much do you want to withdraw?",
        options
    )
end

-- Function to open the deposit dialog
function Deposit(ply, money, bank)
    money = money or ply:GetCash()
    bank = bank or ply:GetBank()
    
    local options = {}
    
    -- Generate deposit options for different amounts
    for i = 2, 7 do
        local amount = 10 ^ i
        if money >= amount * 0.5 then
            table.insert(options, MakeDeposit(amount * 0.5, money, bank))
        end
        if money >= amount then
            table.insert(options, MakeDeposit(amount, money, bank))
        end
    end
    
    -- Add options for half and all of wallet
    if money > 0 and money < 10000000 then
        if money > 1 then
            table.insert(options, MakeDeposit(math.floor(money / 2), money, bank))
        end
        table.insert(options, MakeDeposit(money, money, bank))
    end
    
    -- Add back button
    table.insert(options, {
        text = "<Back",
        click = function()
            BankDialog(ply)
        end,
        color = ATOMIC.Config.Colors.Error,
        hoverColor = Color(255, 0, 0)
    })
    
    ATOMIC:Dialog(
        "Balance: " .. ATOMIC:MoneyToString(bank),
        "Deposit money into your bank account.\n\nHow much do you want to deposit?",
        options
    )
end

-- Main banking dialog function
function BankDialog(ply)
    local firstname = ply:GetNWString("char_firstname", "")
    local lastname = ply:GetNWString("char_lastname", "")
    local money = ply:GetCash()
    local bank = ply:GetBank()
    
    local name = firstname .. " " .. lastname
    if firstname == "" and lastname == "" then
        name = ply:Nick()
    end
    
    local options = {}
    
    -- Deposit option
    table.insert(options, {
        text = "Deposit",
        click = function()
            Deposit(ply)
        end
    })
    
    -- Withdraw option
    table.insert(options, {
        text = "Withdraw",
        click = function()
            Withdraw(ply)
        end
    })
    
    -- Exit option
    table.insert(options, {
        text = "Exit",
        click = function() end,
        color = ATOMIC.Config.Colors.Error,
        hoverColor = Color(255, 0, 0)
    })
    
    ATOMIC:Dialog(
        "Balance: " .. ATOMIC:MoneyToString(bank),
        "Welcome " .. name .. ".\n\nWhat do you want to do? You have " .. ATOMIC:MoneyToString(money) .. " in your pocket.",
        options
    )
end

-- Function to open the banking interface (entry point)
function ATOMIC:OpenBankingInterface()
    BankDialog(LocalPlayer())
end

-- Register console command to open the banking interface
concommand.Add("atomic_banking", function()
    ATOMIC:OpenBankingInterface()
end)

-- Add banking command to F4 menu (this assumes you have an F4 menu)
hook.Add("ATOMIC_PopulateF4Menu", "ATOMIC_AddBankingButton", function(menu)
    if not IsValid(menu) then return end
    
    -- Add banking button to F4 menu
    local bankingBtn = menu:AddButton("Banking", "Open the banking interface")
    bankingBtn.DoClick = function()
        ATOMIC:OpenBankingInterface()
    end
end)

-- Create a test keybind (Remove in production)
hook.Add("PlayerButtonDown", "ATOMIC_BankingKeybind", function(ply, button)
    if button == KEY_B then
        ATOMIC:OpenBankingInterface()
    end
end)