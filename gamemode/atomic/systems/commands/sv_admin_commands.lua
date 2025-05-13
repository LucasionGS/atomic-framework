-- File: sv_admin_commands.lua
-- This file contains administrative commands for the Atomic framework

-- Administrative commands
ATOMIC:AddCommand("noclip", function(ply, args)
    -- Toggle noclip
    if not ply:GetNWBool("ATOMIC_Noclip", false) then
        ply:SetMoveType(MOVETYPE_NOCLIP)
        ply:SetNWBool("ATOMIC_Noclip", true)
        ATOMIC:Notify(ply, "Noclip enabled.")
    else
        ply:SetMoveType(MOVETYPE_WALK)
        ply:SetNWBool("ATOMIC_Noclip", false)
        ATOMIC:Notify(ply, "Noclip disabled.")
    end
end, { rank = "admin" })

ATOMIC:AddCommand("teleport", function(ply, args)
    -- Teleport to position
    local target = ATOMIC:FindPlayer(args[2])
    if target then
        ply:SetPos(target:GetPos() + Vector(0, 0, 10))
        ATOMIC:Notify(ply, "Teleported to " .. target:Nick())
        ATOMIC:Log("Admin", ply, "teleported to " .. target:Nick())
    else
        ATOMIC:NotifyError(ply, "Player not found.")
    end
end, { rank = "admin" })

ATOMIC:AddCommand("bring", function(ply, args)
    -- Bring player to you
    local target = ATOMIC:FindPlayer(args[2])
    if target then
        target:SetPos(ply:GetPos() + ply:GetForward() * 100)
        ATOMIC:Notify(ply, "Brought " .. target:Nick() .. " to you.")
        ATOMIC:Notify(target, "You were teleported to " .. ply:Nick())
        ATOMIC:Log("Admin", ply, "brought " .. target:Nick() .. " to them")
    else
        ATOMIC:NotifyError(ply, "Player not found.")
    end
end, { rank = "admin" })

ATOMIC:AddCommand("pos", function(ply, args)
    -- Get current position
    local pos = ply:GetPos()
    local ang = ply:GetAngles()
    local posStr = string.format("setpos %.6f %.6f %.6f;setang %.6f %.6f %.6f", pos.x, pos.y, pos.z, ang.p, ang.y, ang.r)
    ply:ChatPrint("Position: " .. posStr)
    
    -- Copy to clipboard if possible
    if args[2] and args[2] == "copy" then
        ply:ConCommand("connect_clipboard \"" .. posStr .. "\"")
        ATOMIC:Notify(ply, "Position copied to clipboard.")
    end
end, { rank = "admin" })

ATOMIC:AddCommand("goto", function(ply, args)
    -- Go to position
    if #args < 4 then
        ATOMIC:NotifyError(ply, "Usage: /goto <x> <y> <z>")
        return
    end
    
    local x = tonumber(args[2])
    local y = tonumber(args[3])
    local z = tonumber(args[4])
    
    if not x or not y or not z then
        ATOMIC:NotifyError(ply, "Invalid coordinates.")
        return
    end
    
    ply:SetPos(Vector(x, y, z))
    ATOMIC:Notify(ply, "Teleported to " .. x .. ", " .. y .. ", " .. z)
    ATOMIC:Log("Admin", ply, "teleported to " .. x .. ", " .. y .. ", " .. z)
end, { rank = "admin" })

ATOMIC:AddCommand("giveitem", function(ply, args)
    -- Give item to player
    if #args < 3 then
        ATOMIC:NotifyError(ply, "Usage: /giveitem <player/self> <item> [amount]")
        return
    end
    
    local target
    if args[2] == "self" then
        target = ply
    else
        target = ATOMIC:FindPlayer(args[2])
    end
    
    if not target then
        ATOMIC:NotifyError(ply, "Player not found.")
        return
    end
    
    local item = args[3]
    local amount = tonumber(args[4]) or 1
    
    -- TODO: Implement item system and integrate this command with it
    ATOMIC:Notify(ply, "Gave " .. amount .. " " .. item .. " to " .. target:Nick())
    ATOMIC:Log("Admin", ply, "gave " .. amount .. " " .. item .. " to " .. target:Nick())
end, { rank = "admin" })

ATOMIC:AddCommand("revive", function(ply, args)
    -- Revive player
    local target
    if args[2] then
        target = ATOMIC:FindPlayer(args[2])
    else
        target = ply
    end
    
    if not target then
        ATOMIC:NotifyError(ply, "Player not found.")
        return
    end
    
    if not target:Alive() then
        target:Spawn()
        ATOMIC:Notify(ply, "Revived " .. target:Nick())
        ATOMIC:Notify(target, "You were revived by " .. ply:Nick())
        ATOMIC:Log("Admin", ply, "revived " .. target:Nick())
    else
        ATOMIC:NotifyError(ply, target:Nick() .. " is already alive.")
    end
end, { rank = "admin" })

ATOMIC:AddCommand("setjob", function(ply, args)
    -- Set player's job
    if #args < 3 then
        ATOMIC:NotifyError(ply, "Usage: /setjob <player> <job>")
        return
    end
    
    local target = ATOMIC:FindPlayer(args[2])
    if not target then
        ATOMIC:NotifyError(ply, "Player not found.")
        return
    end
    
    local job = args[3]
    if not ATOMIC.Jobs[job] then
        ATOMIC:NotifyError(ply, "Job not found.")
        return
    end
    
    target:SetJob(job)
    ATOMIC:Notify(ply, "Set " .. target:Nick() .. "'s job to " .. ATOMIC.Jobs[job].Name)
    ATOMIC:Notify(target, "Your job was set to " .. ATOMIC.Jobs[job].Name .. " by " .. ply:Nick())
    ATOMIC:Log("Admin", ply, "set " .. target:Nick() .. "'s job to " .. job)
end, { rank = "admin" })

ATOMIC:AddCommand("setwallet", function(ply, args)
    if #args < 3 then
        ATOMIC:NotifyError(ply, "Usage: /setwallet <player> <amount>")
        return
    end
    
    local target = ATOMIC:FindPlayer(args[2])
    if not target then
        ATOMIC:NotifyError(ply, "Player not found.")
        return
    end
    
    local amount = tonumber(args[3])
    if not amount then
        ATOMIC:NotifyError(ply, "Invalid amount.")
        return
    end
    
    target:SetCash(amount)
    ATOMIC:Notify(ply, "Set " .. target:Nick() .. "'s wallet to " .. amount)
    ATOMIC:Notify(target, "Your wallet was set to " .. amount .. " by " .. ply:Nick())
    ATOMIC:Log("Admin", ply, "set " .. target:Nick() .. "'s wallet to " .. amount)
end, { rank = "admin" })

ATOMIC:AddCommand("setbank", function(ply, args)
    if #args < 3 then
        ATOMIC:NotifyError(ply, "Usage: /setbank <player> <amount>")
        return
    end
    
    local target = ATOMIC:FindPlayer(args[2])
    if not target then
        ATOMIC:NotifyError(ply, "Player not found.")
        return
    end
    
    local amount = tonumber(args[3])
    if not amount then
        ATOMIC:NotifyError(ply, "Invalid amount.")
        return
    end
    
    target:SetBank(amount)
    ATOMIC:Notify(ply, "Set " .. target:Nick() .. "'s bank to " .. amount)
    ATOMIC:Notify(target, "Your bank was set to " .. amount .. " by " .. ply:Nick())
    ATOMIC:Log("Admin", ply, "set " .. target:Nick() .. "'s bank to " .. amount)
end, { rank = "admin" })
