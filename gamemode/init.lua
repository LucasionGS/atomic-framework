DeriveGamemode("sandbox")
ATOMIC = ATOMIC or {} -- Global for Atomic Framework. Important it's initialized early.

-- Load config
AddCSLuaFile("config/config.lua")
include("config/config.lua")
-- Process config
AddCSLuaFile("atomic/config.lua")
include("atomic/config.lua")

-- Data folder

if not file.Exists(ATOMIC.Config.DataFolder, "DATA") then
    print("Creating data folder")
    file.CreateDir(ATOMIC.Config.DataFolder)
end

---- Shared files -- Also defines ATOMIC global for both client and server
AddCSLuaFile("shared.lua")
include("shared.lua")

---- Server files
-- Load the database handler.
-- Accessed via Database global for simplified access, SQL global for direct mysqloo access.
include("atomic/database/Database.lua")

-- Load the init server logic
include("sv_init.lua")

---- Client files
AddCSLuaFile("cl_init.lua")

---- Settings
-- Realistic fall damage
RunConsoleCommand("mp_falldamage", 1)
-- Disable ragdoll spawning
RunConsoleCommand("sbox_maxragdolls", 0)
-- Disable prop spawning
RunConsoleCommand("sbox_maxprops", 0)
-- Disables global voice chat
RunConsoleCommand("sv_alltalk", 0)