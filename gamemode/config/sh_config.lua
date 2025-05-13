--[[
    Shared configuration for the gamemode.
    This is where you define the details of your gamemode, along with customizable settings used throughout the gamemode.

    DO NOT include sensitive information in this file, as it is shared with clients.
]]--
ATOMIC.Config = {
    -- The name of the gamemode. Used for GM.Name
    Name = "Atomic Framework",
    -- The author of the gamemode. Used for GM.Author
    Author = "Lucasion",
    -- The folder name of the gamemode. This should match the name of the folder in the gamemodes/ directory.
    GamemodeFolderName = "atomic",
    -- The data folder for the gamemode. Used for Server Data Folder (Default is GamemodeFolderName)
    DataFolder = nil,
    -- The column name used for the primary key in the database tables. Used for querying and updating rows.
    DatabasePrimaryKey = "id",
    -- Debug mode. If true, will print debug information to the console.
    Debug = true,

    -- Chat radius for proximity chat (in units)
    ChatRadius = 600,
    
    -- Name change price
    NameChangePrice = 25000,
    
    -- Organization creation price
    OrganizationPrice = 50000,
    
    -- Salary interval (in seconds)
    SalaryInterval = 300,
    
    -- Admin salary
    AdminSalary = 500,
    
    -- Vehicle test duration (in seconds)
    VehicleTestDuration = 60,
    
    -- Player base speeds
    PlayerBaseWalkSpeed = 150,
    PlayerBaseRunSpeed = 250,
    PlayerBaseCrouchSpeed = 0.3,
    PlayerBaseJumpPower = 175,
    
    -- Character system settings
    MaxCharacters = 5,             -- Maximum number of characters per player
    StartingMoney = 1000,          -- Starting money for new characters
    StartingBank = 0,              -- Starting bank balance for new characters
    
    -- Ranks in order from lowest to highest
    Ranks = {
        "user",
        "silver",
        "gold",
        "diamond",
        "prism",
        "admin",
        "superadmin",
        "headadmin",
        "developer"
    },
    
    -- Display names for ranks
    RankNames = {
        user = "User",
        silver = "Silver",
        gold = "Gold",
        diamond = "Diamond",
        prism = "Prism",
        admin = "Admin",
        superadmin = "Super Admin",
        headadmin = "Head Admin",
        developer = "Developer"
    },
    
    -- Vehicle system settings
    VehicleFuelConsumption = 0.1,  -- Fuel consumption rate
    VehicleMaxFuel = 100,          -- Default maximum fuel capacity
    VehicleBaseHealth = 1000,      -- Default maximum vehicle health
    
    -- NPC system settings
    NPCDefaultHealth = 100,        -- Default health for NPCs
    
    -- Property system settings
    PropertyBaseTax = 50,          -- Base property tax rate
    PropertyTaxInterval = 3600,    -- Property tax interval in seconds (1 hour)
    
    -- Position system settings
    GarageSpawnDistance = 300,     -- Maximum distance to spawn a vehicle from a garage
    BankATMRadius = 100,           -- Radius in which players can interact with bank ATMs
    
    -- Inventory system settings
    DefaultInventorySize = 20,     -- Default inventory size
    DefaultStorageSize = 50,       -- Default storage size
    MaxItemStack = 99,             -- Maximum stack size for stackable items
    
    -- Buddy system settings
    MaxBuddies = 50,               -- Maximum number of buddies a player can have
    
    -- Organization system settings
    MaxOrganizationMembers = 25,   -- Maximum number of members in an organization
    OrganizationRanks = {          -- Default organization ranks
        "Owner",
        "Co-Owner",
        "Officer",
        "Member",
        "Recruit"
    },
    
    -- Attribute system settings
    AttributeSystem = true,        -- Enable/disable the attribute system
    AttributeResetCost = 5000,     -- Cost to reset attributes
    AttributeXPMultiplier = 1.0,   -- Global XP gain multiplier
    AttributeEffectMultiplier = 1.0, -- Global attribute effect multiplier
    AttributeLevelCap = 100,       -- Maximum level for attributes
    AttributeSkillChance = 0.3,    -- Base chance to gain skill XP from related actions

    -- Spawn whitelist - These are the only entities that can be spawned by non-admins
    SpawnableProps = {
        "models/props/de_inferno/potted_plant1.mdl",
        "models/props_c17/oildrum001.mdl",
        "models/props_junk/wood_crate001a.mdl",
        "models/props_c17/bench01a.mdl",
        "models/props_c17/furniturechair001a.mdl",
        "models/props_c17/furnituretable002a.mdl",
        "models/props_c17/furnitureshelf001a.mdl",
        "models/props_c17/furnituredrawer001a.mdl",
    },
    
    --[[
        Job configuration
    ]]--

    -- The default job for players when they first spawn. This should be a valid job identifier.
    DefaultJob = "citizen",
}
