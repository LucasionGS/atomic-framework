function GM:Initialize()
    print("Atomic Framework: Server initialized.")
end

hook.Add("SV_ATOMIC:DatabaseConnected", "Atomic_SuccessfullyConnected", function()
    print("Atomic Framework: Database connected.")

    -- Database:CreateTable("players", {
    --     "id INT NOT NULL AUTO_INCREMENT",
    --     "steamid64 VARCHAR(255) NOT NULL",
    --     "name VARCHAR(255) NOT NULL",
    --     "playtime INT NOT NULL",
    --     "createdAt DATETIME NOT NULL",
    --     "lastJoin DATETIME NOT NULL",
    --     "lastLeave DATETIME NOT NULL",
    --     "PRIMARY KEY (id)"
    -- })
    Database:CreateQueryInterface():Table("players"):Insert(
        {
            steamid64 = "1234567890",
            name = "Lucasion",
            playtime = 0,
            createdAt = os.date("%Y-%m-%d %H:%M:%S"),
            lastJoin = os.date("%Y-%m-%d %H:%M:%S"),
            lastLeave = os.date("%Y-%m-%d %H:%M:%S")
        },
        {
            steamid64 = "0987654321",
            playtime = 0,
            lastJoin = os.date("%Y-%m-%d %H:%M:%S"),
            createdAt = os.date("%Y-%m-%d %H:%M:%S"),
            name = "Lucasion2",
            lastLeave = os.date("%Y-%m-%d %H:%M:%S")
        }
    ):Run():Wait()

    -- Database:CreateQueryInterface():Table("players"):Select("*"):Where({"steamid64 = ?", "1234567890"}):Run(function(data)
    --     PrintTable(data)
    -- end)
end)

hook.Add("SV_ATOMIC:DatabaseConnectionFailed", "Atomic_FailureConnecting", function(err)
    print("Failed to connect to the MySQL database:")
    print(err)
end)