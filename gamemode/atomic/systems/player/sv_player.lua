function ATOMIC:SetPlayerSpeed(ply, multiplier)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    -- ply:SetSlowWalkSpeed(1 * multiplier)
    -- ply:SetWalkSpeed(1 * multiplier)
    -- ply:SetRunSpeed(1 * multiplier)
    print(ply:GetCrouchedWalkSpeed(), ply:GetSlowWalkSpeed(), ply:GetWalkSpeed(), ply:GetRunSpeed())
end

-- Once a player spawns for the first time, Load their data or create them.
hook.Add("PlayerInitialSpawn", "Atomic_PlayerInitialSpawn", function(ply)
    local PlayerModel = Database:Model("players")

    if PlayerModel:RowExists("steamid64", ply:SteamID64()):Wait() then
        ATOMIC:Debug("Player already exists in the database: " .. ply:Nick())

        -- Load player data
        local playerData = PlayerModel:Select("*"):Where({"steamid64 = ?", ply:SteamID64()}):Limit(1):Run(function(playerData)
            if playerData and playerData[1] then
                playerData = playerData[1]
            else 
                playerData = nil
            end
            
            if playerData then
                ply:SetNWString("ATOMIC_Name", playerData.name or ply:Nick())
                
                -- Set default values (these will be overridden by character data once a character is selected)
                ply:SetCash(0)
                ply:SetBank(0)
                
                hook.Run("SV_ATOMIC:OnPlayerDataLoaded", ply, playerData)
            else
                ATOMIC:Error("Failed to load player data for: " .. ply:Nick())
            end
        end)

        return
    end
    
    -- Create new player record
    PlayerModel:Insert(
        {
            steamid64 = ply:SteamID64(),
            name = ply:Nick()
        }
    ):Run(function()
        ATOMIC:Debug("Player inserted: " .. ply:Nick())
        
        -- Set default values
        ply:SetNWString("ATOMIC_Name", ply:Nick())
        ply:SetCash(0)
        ply:SetBank(0)
    end)
end)

-- Setup loadout
hook.Add("PlayerLoadout", "Atomic_PlayerLoadout", function(ply)
    -- If the player doesn't have a character, don't give them weapons
    if not ply:HasCharacter() then
        ply:StripWeapons()
        ply:StripAmmo()
        
        -- Don't allow movement
        ply:Freeze(true)
        
        return true
    end
    
    -- Otherwise, let the job handle the loadout
    local job = ply:GetJob() or ATOMIC.Config.DefaultJob
    ply:SetJob(job)
    
    -- Allow movement
    ply:Freeze(false)
    
    return false
end)

-- Save character data on disconnect
hook.Add("PlayerDisconnected", "Atomic_SavePlayerData", function(ply)
    if ply:HasCharacter() then
        ply:SaveCharacter()
    end
end)

-- Save all character data on server shutdown
hook.Add("ShutDown", "Atomic_SaveAllPlayerData", function()
    ATOMIC:SaveAllCharacters()
end)