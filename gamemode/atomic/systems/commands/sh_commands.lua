-- File: sh_commands.lua
-- This file contains the shared command system for the Atomic framework
-- Commands are registered with ATOMIC:AddCommand and can be called via chat

-- Commands table
ATOMIC.Commands = ATOMIC.Commands or {}

-- Command function
function ATOMIC:AddCommand(name, func, opts)
    opts = opts or {}

    if opts.requireDuty == nil then opts.requireDuty = true end
    
    if type(func) == "string" then
        -- Alias - Must be a valid command already
        ATOMIC.Commands[name] = ATOMIC.Commands[func]
    else
        -- Command
        ATOMIC.Commands[name] = {
            func = func,
            rank = opts.rank or nil,
            requireDuty = opts.requireDuty, -- Require player to be on duty if it is admin or above
        }
    end
end

if SERVER then
    -- Call a command by name
    function ATOMIC:CallCommand(name, ply, ...)
        local args = {...}
        table.insert(args, 1, name)
        local cmd = ATOMIC.Commands[name]
        if cmd then
            -- Check if the player has the required rank
            if cmd.rank ~= nil then
                if not ATOMIC:IsRankEqualOrHigher(ply:GetNWString("ATOMIC_Rank", "user"), cmd.rank) then
                    ATOMIC:NotifyError(ply, "You don't have permission to use this command.")
                    return
                end
                
                -- Check if the player is on duty (if required)
                if cmd.requireDuty and not ply:GetNWBool("ATOMIC_OnDuty", false) then
                    ATOMIC:NotifyError(ply, "You need to be on duty to use this command.")
                    return
                end
            end
            
            -- Execute the command
            cmd.func(ply, args)
        end
    end
    
    -- Handle chat commands
    hook.Add("PlayerSay", "ATOMIC_ChatCommands", function(ply, text, teamChat)
        local args = string.Explode(" ", text)
        local cmd = string.lower(string.sub(args[1], 2)) -- Remove the / or !
        
        if string.StartWith(args[1], "/") or string.StartWith(args[1], "!") then
            if ATOMIC.Commands[cmd] then
                ATOMIC:CallCommand(cmd, ply, unpack(args))
                return "" -- Hide the command
            end
        end
    end)
end
