-- File: sv_player_commands.lua
-- This file contains player commands for the Atomic framework

-- Player commands
ATOMIC:AddCommand("me", function(ply, args)
    -- Roleplay action
    if #args < 2 then
        ATOMIC:NotifyError(ply, "Usage: /me <action>")
        return
    end
    
    local action = table.concat(args, " ", 2)
    local playerName = ply:GetNWString("ATOMIC_Name", ply:Nick())
    local message = "* " .. playerName .. " " .. action
    
    -- Send to nearby players (proximity emote)
    local radius = ATOMIC.Config.ChatRadius or 600
    for _, v in ipairs(player.GetAll()) do
        if v:GetPos():Distance(ply:GetPos()) <= radius then
            v:ChatPrint(message)
        end
    end
end, { requireDuty = false })

ATOMIC:AddCommand("ooc", function(ply, args)
    -- Out of character chat
    if #args < 2 then
        ATOMIC:NotifyError(ply, "Usage: /ooc <message>")
        return
    end
    
    local message = table.concat(args, " ", 2)
    local playerName = ply:Nick()
    local fullMessage = "(OOC) " .. playerName .. ": " .. message
    
    -- Send to all players
    for _, v in ipairs(player.GetAll()) do
        v:ChatPrint(fullMessage)
    end
end, { requireDuty = false })

ATOMIC:AddCommand("roll", function(ply, args)
    -- Roll a dice
    local max = tonumber(args[2]) or 100
    local result = math.random(1, max)
    
    local playerName = ply:GetNWString("ATOMIC_Name", ply:Nick())
    local message = "* " .. playerName .. " rolled " .. result .. " out of " .. max
    
    -- Send to nearby players
    local radius = ATOMIC.Config.ChatRadius or 600
    for _, v in ipairs(player.GetAll()) do
        if v:GetPos():Distance(ply:GetPos()) <= radius then
            v:ChatPrint(message)
        end
    end
end, { requireDuty = false })

ATOMIC:AddCommand("help", function(ply, args)
    -- Show available commands
    local commands = {}
    local playerRank = ply:GetNWString("ATOMIC_Rank", "user")
    
    for cmd, data in pairs(ATOMIC.Commands) do
        if not data.rank or ATOMIC:IsRankEqualOrHigher(playerRank, data.rank) then
            table.insert(commands, cmd)
        end
    end
    
    table.sort(commands)
    
    ply:ChatPrint("Available commands:")
    for _, cmd in ipairs(commands) do
        ply:ChatPrint("/" .. cmd)
    end
end, { requireDuty = false })

ATOMIC:AddCommand("job", function(ply, args)
    -- Apply for a job
    if #args < 2 then
        ATOMIC:NotifyError(ply, "Usage: /job <job>")
        return
    end
    
    local job = args[2]
    if not ATOMIC.Jobs[job] then
        local availableJobs = {}
        for jobId, _ in pairs(ATOMIC.Jobs) do
            table.insert(availableJobs, jobId)
        end
        
        ATOMIC:NotifyError(ply, "Job not found. Available jobs: " .. table.concat(availableJobs, ", "))
        return
    end
    
    ply:RequestJob(job)
end, { requireDuty = false })

ATOMIC:AddCommand("bank", function(ply, args)
    -- Open bank interface
    if SERVER then
        net.Start("ATOMIC:OpenBankMenu")
        net.Send(ply)
        ATOMIC:Log("Banking", ply, "opened bank menu")
    end
end, { requireDuty = false })

ATOMIC:AddCommand("y", function(ply, args)
    -- Yell (longer distance)
    if #args < 2 then
        ATOMIC:NotifyError(ply, "Usage: /y <message>")
        return
    end
    
    local message = table.concat(args, " ", 2)
    local playerName = ply:GetNWString("ATOMIC_Name", ply:Nick())
    local fullMessage = playerName .. " yells: " .. message
    
    -- Send to nearby players with extended radius
    local radius = (ATOMIC.Config.ChatRadius or 600) * 1.5
    for _, v in ipairs(player.GetAll()) do
        if v:GetPos():Distance(ply:GetPos()) <= radius then
            v:ChatPrint(fullMessage)
        end
    end
end, { requireDuty = false })

ATOMIC:AddCommand("w", function(ply, args)
    -- Whisper (shorter distance)
    if #args < 2 then
        ATOMIC:NotifyError(ply, "Usage: /w <message>")
        return
    end
    
    local message = table.concat(args, " ", 2)
    local playerName = ply:GetNWString("ATOMIC_Name", ply:Nick())
    local fullMessage = playerName .. " whispers: " .. message
    
    -- Send to nearby players with reduced radius
    local radius = (ATOMIC.Config.ChatRadius or 600) * 0.5
    for _, v in ipairs(player.GetAll()) do
        if v:GetPos():Distance(ply:GetPos()) <= radius then
            v:ChatPrint(fullMessage)
        end
    end
end, { requireDuty = false })

ATOMIC:AddCommand("inventory", function(ply, args)
    -- Open inventory
    if SERVER then
        net.Start("ATOMIC:OpenInventory")
        net.Send(ply)
        ATOMIC:Log("Inventory", ply, "opened inventory")
    end
end, { requireDuty = false })

-- Alias commands
ATOMIC:AddCommand("say", "ooc")     -- '/say' is the same as '/ooc'
ATOMIC:AddCommand("//", "ooc")      -- '//' is the same as '/ooc'
ATOMIC:AddCommand("whisper", "w")   -- '/whisper' is the same as '/w'
ATOMIC:AddCommand("yell", "y")      -- '/yell' is the same as '/y'
ATOMIC:AddCommand("inv", "inventory") -- '/inv' is the same as '/inventory'
