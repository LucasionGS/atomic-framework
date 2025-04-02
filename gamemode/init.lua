ATOMIC = ATOMIC or {} -- Global for Atomic Framework. Important it's initialized early.
-- Load config
AddCSLuaFile("config/sh_config.lua")
include("config/sh_config.lua")
include("atomic/init.lua")

--[[
  DO NOT EDIT ABOVE THIS LINE UNLESS YOU KNOW WHAT YOU'RE DOING.

  Gamemode specific code should be placed in in separate files in the gamemode folder, and included here below.
  This is to ensure that the gamemode can be easily updated without overwriting your changes.
]]