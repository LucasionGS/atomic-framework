DeriveGamemode("sandbox")
ATOMIC = ATOMIC or {} -- Global for Atomic Framework. Important it's initialized early.
AddCSLuaFile("atomic/config.lua")
include("atomic/config.lua")

-- Data folder
GM.DataFolder = "atomrp"

if not file.Exists(GM.DataFolder, "DATA") then
    print("Creating data folder")
    file.CreateDir(GM.DataFolder)
end

---- Shared files -- Also defines ATOMIC global for both client and server
AddCSLuaFile("shared.lua")
include("shared.lua")

---- Client files
AddCSLuaFile("cl_init.lua")

---- Server files
-- Load the database handler.
-- Accessed via Database global for simplified access, SQL global for direct mysqloo access.
include("database/Database.lua")

-- Load the init server logic
include("sv_init.lua")

---- Settings
-- Realistic fall damage
RunConsoleCommand("mp_falldamage", 1)
-- Disable ragdoll spawning
RunConsoleCommand("sbox_maxragdolls", 0)
-- Disable prop spawning
RunConsoleCommand("sbox_maxprops", 0)
-- Disables global voice chat
RunConsoleCommand("sv_alltalk", 0)