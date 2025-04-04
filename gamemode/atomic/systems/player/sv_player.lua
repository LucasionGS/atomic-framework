-- Once a player spawns for the first time, Load their data or create them.
hook.Add("PlayerInitialSpawn", "Atomic_PlayerInitialSpawn", function(ply)
    local PlayerModel = Database:Model("players")

    if PlayerModel:RowExists("steamid64", ply:SteamID64()):Wait() then
        print("Player already exists in the database: " .. ply:Nick())
        return
    end
    
    PlayerModel:Insert(
        {
            steamid64 = ply:SteamID64(),
            name = ""
        }
    ):Run(function()
        print("Player inserted: " .. ply:Nick())
    end)
end)

-- Setup loadout
hook.Add("PlayerLoadout", "Atomic_PlayerLoadout", function(ply)
    ply:Give("weapon_physgun")
    ply:Give("gmod_tool")

    return false
end)