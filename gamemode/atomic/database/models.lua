Database:CreateModel(
    "players", 
    {
        "id",
        "steamid64",
        "name",
        "playtime",
        "createdAt",
        "lastJoin",
        "lastLeave"
    },
    {
        "id INT NOT NULL AUTO_INCREMENT",
        "steamid64 VARCHAR(255) NOT NULL UNIQUE",
        "name VARCHAR(255) NOT NULL",
        "playtime INT NOT NULL DEFAULT 0",
        "createdAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP",
        "lastJoin DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP",
        "lastLeave DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP",
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