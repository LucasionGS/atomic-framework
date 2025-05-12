Database:CreateModel(
    "players", 
    {
        "id",
        "steamid64",
        "name",
        "playtime",
        "rank",
        "money",
        "bank",
        "createdAt",
        "lastJoin",
        "lastLeave",
        "kills",
        "deaths",
    },
    {
        "id INT NOT NULL AUTO_INCREMENT",
        "steamid64 VARCHAR(255) NOT NULL UNIQUE",
        "name VARCHAR(255) NOT NULL",
        "playtime INT NOT NULL DEFAULT 0",
        "rank INT NOT NULL DEFAULT 0",
        "money INT NOT NULL DEFAULT 0",
        "bank INT NOT NULL DEFAULT 0",
        "createdAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP",
        "lastJoin DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP",
        "lastLeave DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP",
        "kills int(11) NOT NULL DEFAULT '0'",
        "deaths int(11) NOT NULL DEFAULT '0'",
        "PRIMARY KEY (id)"
    }
)

Database:CreateModel(
    "inventories", 
    {
        "id",
        "steamid64",
        "inventoryId",
        "itemId",
        "slotx",
        "sloty",
        "amount",
        "createdAt"
    },
    {
        "id INT NOT NULL AUTO_INCREMENT",
        "steamid64 VARCHAR(255) NOT NULL",
        "inventoryId INT NOT NULL",
        "itemId VARCHAR(255) NOT NULL",
        "slotx INT NOT NULL",
        "sloty INT NOT NULL",
        "amount INT NOT NULL DEFAULT 1",
        "createdAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP",
        "PRIMARY KEY (id)",
        "FOREIGN KEY (steamid64) REFERENCES players(steamid64)"
    }
)

Database:CreateModel(
    "ranks", 
    {
        "id",
        "index",
        "name",
        "displayName",
        "description",
        "permissions",
        "inherit",
        "createdAt"
    },
    {
        "id INT NOT NULL AUTO_INCREMENT",
        "index INT NOT NULL",
        "name VARCHAR(255) NOT NULL UNIQUE",
        "displayName VARCHAR(255) NOT NULL",
        "description TEXT NOT NULL",
        "permissions TEXT NOT NULL DEFAULT '[]'",
        "inherit INT NOT NULL DEFAULT 0",
        "createdAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP",
        "PRIMARY KEY (id)"
    }
)