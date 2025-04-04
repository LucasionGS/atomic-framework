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
    "items", 
    {
        "id",
        "identifierName", -- Optional - Used for identification in memory by a string name - Nullable (Example: "item_hamburger")
        "name",
        "description",

        -- Used for inventory management and how much space it takes up.
        "itemWidth",
        "itemHeight",

        -- Attributes
        "weight",
        "data", -- Optional - Stores dynamic JSON data about the item. (Example: "health" for food items)

        -- Scripting
        "type", -- Used to determine the type of item. (Example: "food", "weapon", "tool", "misc")
                -- Items has default behavior based on their type. Overrides can be made in the item's script.
        "script", -- Optional - Assigned the name of a SERVERSIDE function to be called when the item is used. (Parameters: player, inventoryItem)

        "createdAt",
    },
    {
        "id INT NOT NULL AUTO_INCREMENT",
        "identifierName VARCHAR(255)",
        "name VARCHAR(255) NOT NULL",
        "description TEXT NOT NULL",
        "itemWidth INT NOT NULL DEFAULT 1",
        "itemHeight INT NOT NULL DEFAULT 1",
        "weight INT NOT NULL",
        "data TEXT",
        "type VARCHAR(255) NOT NULL DEFAULT 'misc'",
        "script VARCHAR(255)",
        "createdAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP",
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
        "itemId INT NOT NULL",
        "slotx INT NOT NULL",
        "sloty INT NOT NULL",
        "amount INT NOT NULL DEFAULT 1",
        "createdAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP",
        "PRIMARY KEY (id)",
        "FOREIGN KEY (steamid64) REFERENCES players(steamid64)",
        "FOREIGN KEY (itemId) REFERENCES items(id)"
    }
)

Database:CreateModel(
    "ranks", 
    {
        "id",
        "name",
        "description",
        "permissions",
        "inherit",
        "createdAt"
    },
    {
        "id INT NOT NULL AUTO_INCREMENT",
        "name VARCHAR(255) NOT NULL UNIQUE",
        "description TEXT NOT NULL",
        "permissions TEXT NOT NULL DEFAULT '[]'",
        "inherit INT NOT NULL DEFAULT 0",
        "createdAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP",
        "PRIMARY KEY (id)"
    }
)