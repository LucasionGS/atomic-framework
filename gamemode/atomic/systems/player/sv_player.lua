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
        print("Player already exists in the database: " .. ply:Nick())

        -- Load player data
        local playerData = PlayerModel:Select("*"):Where({"steamid64 = ?", ply:SteamID64()}):Limit(1):Run(function(playerData)
            if playerData and playerData[1] then
                playerData = playerData[1]
            else 
                playerData = nil
            end
            if playerData then
                ply:SetNWString("ATOMIC_Name", playerData.name or ply:Nick())
                ply:SetMoney(playerData.money or 0)
                ply:SetBank(playerData.bank or 0)

                -- Set the player's job
                ply:SetJob(ATOMIC.Config.DefaultJob)
                hook.Run("SV_ATOMIC:OnPlayerDataLoaded", ply, playerData)
            else
                print("Failed to load player data for: " .. ply:Nick())
            end
        end)

        return
    end
    
    PlayerModel:Insert(
        {
            steamid64 = ply:SteamID64(),
            name = ""
        }
    ):Run(function()
        print("Player inserted: " .. ply:Nick())
        -- Set the player's data
        ply:SetNWString("ATOMIC_Name", "")
    end)
end)

-- Setup loadout
hook.Add("PlayerLoadout", "Atomic_PlayerLoadout", function(ply)
    print("JOBS:", ply:GetJob(), ATOMIC.Config.DefaultJob)
    ply:SetJob(ply:GetJob() or ATOMIC.Config.DefaultJob)
    return false
end)