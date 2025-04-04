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

    --[[
        Job configuration
    ]]--

    -- The default job for players when they first spawn. This should be a valid job identifier.
    DefaultJob = "citizen",
}
