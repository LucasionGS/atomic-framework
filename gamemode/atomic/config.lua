AddCSLuaFile("../config/config.lua")
include("../config/config.lua")

-- Process configuration
ATOMIC.Config = ATOMIC.Config or {}
ATOMIC.Config.GamemodeFolderName = ATOMIC.Config.GamemodeFolderName or nil

if ATOMIC.Config.GamemodeFolderName == nil then
    print("ERROR: Gamemode folder name not set. Please set ATOMIC.Config.GamemodeFolderName in config/config.lua.")
end

ATOMIC.Config.DataFolder = ATOMIC.Config.DataFolder or ATOMIC.Config.GamemodeFolderName or nil

if ATOMIC.Config.DataFolder == nil then
    print("ERROR: Data folder not set. Please set ATOMIC.Config.DataFolder in config/config.lua.")
end