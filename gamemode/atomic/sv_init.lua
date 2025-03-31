function GM:Initialize()
    print("Atomic Framework: Server initialized.")
end

hook.Add("SV_ATOMIC:DatabaseConnected", "Atomic_SuccessfullyConnected", function()
    print("Atomic Framework: Database connected.")
    for model in pairs(Database.Models) do
        local m = Database:Model(model)
        if not m:TableExists():Wait() then
            print("Creating table for model: " .. model)
            m:CreateTable()
        end
    end
end)


hook.Add("SV_ATOMIC:DatabaseConnectionFailed", "Atomic_FailureConnecting", function(err)
    print("Failed to connect to the MySQL database:")
    print(err)
end)


-- Once a player spawns for the first time, Load their data or create them.
hook.Add("PlayerInitialSpawn", "Atomic_PlayerInitialSpawn", function(ply)
    Database:Model("players"):Insert(
        {
            steamid64 = ply:SteamID64(),
            name = ply:Nick()
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