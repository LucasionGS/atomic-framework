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
        "`id` INT NOT NULL AUTO_INCREMENT",
        "`steamid64` VARCHAR(255) NOT NULL UNIQUE",
        "`name` VARCHAR(255) NOT NULL",
        "`playtime` INT NOT NULL DEFAULT 0",
        "`rank` INT NOT NULL DEFAULT 0",
        "`money` INT NOT NULL DEFAULT 0",
        "`bank` INT NOT NULL DEFAULT 0",
        "`createdAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP",
        "`lastJoin` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP",
        "`lastLeave` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP",
        "`kills` int(11) NOT NULL DEFAULT '0'",
        "`deaths` int(11) NOT NULL DEFAULT '0'",
        "PRIMARY KEY (`id`)"
    }
)

Database:CreateModel(
    "characters", 
    {
        "id",
        "steamid64",
        "firstname",
        "lastname",
        "model",
        "skin",
        "bodygroups",
        "job",
        "money",
        "bank",
        "inventory",
        "position_x",
        "position_y",
        "position_z",
        "health",
        "armor",
        "active",
        "created_at",
        "last_used"
    },
    {
        "`id` INT NOT NULL AUTO_INCREMENT",
        "`steamid64` VARCHAR(255) NOT NULL",
        "`firstname` VARCHAR(32) NOT NULL",
        "`lastname` VARCHAR(32) NOT NULL",
        "`model` VARCHAR(255) NOT NULL",
        "`skin` INT NOT NULL DEFAULT 0",
        "`bodygroups` TEXT NOT NULL DEFAULT '{}'",
        "`job` VARCHAR(64) NOT NULL DEFAULT 'citizen'",
        "`money` INT NOT NULL DEFAULT 0",
        "`bank` INT NOT NULL DEFAULT 0",
        "`inventory` TEXT NOT NULL DEFAULT '{}'",
        "`position_x` FLOAT NOT NULL DEFAULT 0",
        "`position_y` FLOAT NOT NULL DEFAULT 0",
        "`position_z` FLOAT NOT NULL DEFAULT 0",
        "`health` INT NOT NULL DEFAULT 100",
        "`armor` INT NOT NULL DEFAULT 0",
        "`active` BOOLEAN NOT NULL DEFAULT 0",
        "`created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP",
        "`last_used` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP",
        "PRIMARY KEY (`id`)",
        "FOREIGN KEY (`steamid64`) REFERENCES players(`steamid64`) ON DELETE CASCADE ON UPDATE CASCADE"
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
        "`id` INT NOT NULL AUTO_INCREMENT",
        "`steamid64` VARCHAR(255) NOT NULL",
        "`inventoryId` INT NOT NULL",
        "`itemId` VARCHAR(255) NOT NULL",
        "`slotx` INT NOT NULL",
        "`sloty` INT NOT NULL",
        "`amount` INT NOT NULL DEFAULT 1",
        "`createdAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP",
        "PRIMARY KEY (`id`)",
        "FOREIGN KEY (`steamid64`) REFERENCES players(`steamid64`) ON DELETE CASCADE ON UPDATE CASCADE"
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
        "color",
        "createdAt"
    },
    {
        "`id` INT NOT NULL AUTO_INCREMENT",
        "`index` INT NOT NULL",
        "`name` VARCHAR(255) NOT NULL UNIQUE",
        "`displayName` VARCHAR(255) NOT NULL",
        "`description` TEXT NOT NULL DEFAULT ''",
        "`permissions` TEXT NOT NULL DEFAULT '[]'",
        "`inherit` INT NOT NULL DEFAULT 0",
        "`color` VARCHAR(32) NOT NULL DEFAULT '#FFFFFF'",
        "`createdAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP",
        "PRIMARY KEY (`id`)"
    }
)

Database:CreateModel(
    "attributes", 
    {
        "id",
        "characterId",
        "type",
        "attribute",
        "value",
        "xp",
        "createdAt"
    },
    {
        "`id` INT NOT NULL AUTO_INCREMENT",
        "`characterId` INT NOT NULL",
        "`type` VARCHAR(32) NOT NULL",
        "`attribute` VARCHAR(64) NOT NULL",
        "`value` INT NOT NULL DEFAULT 0",
        "`xp` INT NOT NULL DEFAULT 0",
        "`createdAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP",
        "PRIMARY KEY (`id`)",
        "FOREIGN KEY (`characterId`) REFERENCES characters(`id`) ON DELETE CASCADE ON UPDATE CASCADE"
    }
)
