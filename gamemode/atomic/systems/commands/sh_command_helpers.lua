-- File: sh_command_helpers.lua
-- Shared helper functions for the Atomic command system

-- Function to find a player by name or part of name
function ATOMIC:FindPlayer(nameOrId)
    if not nameOrId then return nil end
    
    -- Check if it's a player object already
    if type(nameOrId) == "Player" then
        return nameOrId
    end
    
    -- Convert to string
    nameOrId = tostring(nameOrId):lower()
    
    -- Check if it's a steamid
    if string.match(nameOrId, "^steam_%d:%d:%d+$") then
        for _, ply in ipairs(player.GetAll()) do
            if ply:SteamID():lower() == nameOrId then
                return ply
            end
        end
    end
    
    -- Check if it's a steamid64
    if string.match(nameOrId, "^7656119%d+$") then
        for _, ply in ipairs(player.GetAll()) do
            if ply:SteamID64() == nameOrId then
                return ply
            end
        end
    end
    
    -- Check by partial name match
    local matchingPlayers = {}
    for _, ply in ipairs(player.GetAll()) do
        if string.find(string.lower(ply:Nick()), nameOrId) then
            table.insert(matchingPlayers, ply)
        end
    end
    
    -- Return the result based on matches
    if #matchingPlayers == 1 then
        return matchingPlayers[1] -- Exact match
    elseif #matchingPlayers > 1 then
        return matchingPlayers -- Multiple matches
    end
    
    return nil -- No matches
end

-- Function to get command arguments in a more structured way
function ATOMIC:GetCommandArgs(args, argTypes)
    -- Parse the args array into named parameters based on argTypes
    local parsedArgs = {}
    
    for i, argInfo in ipairs(argTypes) do
        local argValue = args[i + 1] -- +1 because args[1] is the command name
        
        -- Skip if no value and not required
        if not argValue and not argInfo.required then
            continue
        end
        
        -- Convert the value to the right type
        if argInfo.type == "number" then
            argValue = tonumber(argValue)
        elseif argInfo.type == "boolean" then
            argValue = (argValue == "true" or argValue == "1" or argValue == "yes")
        elseif argInfo.type == "player" then
            argValue = ATOMIC:FindPlayer(argValue)
        end
        
        -- Store the value
        parsedArgs[argInfo.name] = argValue
    end
    
    return parsedArgs
end

-- Register common command aliases
hook.Add("Initialize", "ATOMIC:RegisterCommandAliases", function()
    -- Money related
    ATOMIC:AddCommand("setmoney", "setcharactermoney")
    ATOMIC:AddCommand("money", "setcharactermoney")
    ATOMIC:AddCommand("setbank", "setcharacterbank")
    ATOMIC:AddCommand("bank", "setcharacterbank")
    
    -- Spawn related
    ATOMIC:AddCommand("add_spawn", "addspawn")
    ATOMIC:AddCommand("list_spawns", "listspawns")
    ATOMIC:AddCommand("goto_spawn", "gotopoint")
end)
