DeriveGamemode("sandbox")

GM.Name = ATOMIC.Config.Name
GM.Author = ATOMIC.Config.Author
GM.Sandbox = true

-- Function to add files to the server or client based on their prefix
-- Prefixes: sv_ (server), sh_ (shared), cl_ (client)
-- (Taken from example on Garry's Mod wiki https://wiki.facepunch.com/gmod/Global.include)
function ATOMIC:AddFile( File, directory )
    local function Debug(...)
        if ATOMIC and ATOMIC.Debug then
            ATOMIC:Debug(...)
        else
            MsgC(...)
        end
    end

    local prefix = string.lower( string.Left( File, 3 ) )

    if SERVER and prefix == "sv_" then
        include( ATOMIC.Config.GamemodeFolderName .. "/" .. directory .. File )
        Debug( "[AUTOLOAD] SERVER INCLUDE: " .. File )
    elseif prefix == "sh_" then
        if SERVER then
            AddCSLuaFile( ATOMIC.Config.GamemodeFolderName .. "/" .. directory .. File )
            Debug( "[AUTOLOAD] SHARED ADDCS: " .. File )
        end
        include( ATOMIC.Config.GamemodeFolderName .. "/" .. directory .. File )
        Debug( "[AUTOLOAD] SHARED INCLUDE: " .. File )
    elseif prefix == "cl_" then
        if SERVER then
            AddCSLuaFile( ATOMIC.Config.GamemodeFolderName .. "/" .. directory .. File )
            Debug( "[AUTOLOAD] CLIENT ADDCS: " .. File )
        elseif CLIENT then
            include( ATOMIC.Config.GamemodeFolderName .. "/" .. directory .. File )
            Debug( "[AUTOLOAD] CLIENT INCLUDE: " .. File )
        end
    end
end

-- Function to include a directory and all its files
-- Recursively includes all files in the directory and its subdirectories
-- (Taken from example on Garry's Mod wiki https://wiki.facepunch.com/gmod/Global.include)
function ATOMIC:IncludeDir( directory, prefix )
    local function Debug(...)
        if ATOMIC and ATOMIC.Debug then
            ATOMIC:Debug(...)
        else
            MsgC(...)
        end
    end

    directory = directory .. "/"

    local files, directories = file.Find( ATOMIC.Config.GamemodeFolderName .. "/" .. directory .. "*", "LUA" )

    Debug("Importing " .. ATOMIC.Config.GamemodeFolderName .. "/" .. directory .. "...")

    for _, v in ipairs( files ) do
        if string.EndsWith( v, ".lua" ) then
            if prefix then
                if string.StartWith( v, prefix .. "_" ) then
                    ATOMIC:AddFile( v, directory )
                end
            else
                ATOMIC:AddFile( v, directory )
            end
        end
    end

    for _, v in ipairs( directories ) do
        Debug( "[AUTOLOAD] Directory: " .. v )
        ATOMIC:IncludeDir( directory .. v )
    end
end

-- Handles the sandbox spawn menu (Q menu)
function GM:SpawnMenuOpen()
    -- ATOMIC:Notify(nil, "Atomic Framework: Spawn menu is disabled.")
    -- return false
    return true
end

-- Handles the sandbox C menu
function GM:ContextMenuOpen()
    -- ATOMIC:Notify(nil, "Atomic Framework: Context menu is disabled.")
    -- return false
    return true
end

ATOMIC:IncludeDir("gamemode/atomic/utility")
-- Fonts
ATOMIC:AddFile("cl_fonts.lua", "gamemode/atomic/")
-- Include systems
ATOMIC:AddFile("sh_notifications.lua", "gamemode/atomic/systems/")

-- Attribute system
ATOMIC:AddFile("sh_attributes.lua", "gamemode/atomic/systems/")
ATOMIC:AddFile("sv_attributes.lua", "gamemode/atomic/systems/")
ATOMIC:AddFile("cl_attributes.lua", "gamemode/atomic/systems/")

ATOMIC:IncludeDir("gamemode/atomic/systems/dialog")
ATOMIC:IncludeDir("gamemode/atomic/systems/commands")
ATOMIC:IncludeDir("gamemode/atomic/systems/access")
ATOMIC:IncludeDir("gamemode/atomic/systems/admin")
ATOMIC:IncludeDir("gamemode/atomic/systems/banking")
ATOMIC:IncludeDir("gamemode/atomic/systems/character")
ATOMIC:IncludeDir("gamemode/atomic/systems/drugs")
ATOMIC:IncludeDir("gamemode/atomic/systems/inventory")
ATOMIC:IncludeDir("gamemode/atomic/systems/items")
ATOMIC:IncludeDir("gamemode/atomic/systems/job")
ATOMIC:IncludeDir("gamemode/atomic/systems/npcs")
ATOMIC:IncludeDir("gamemode/atomic/systems/player")
ATOMIC:IncludeDir("gamemode/atomic/systems/properties")
-- Survival system
ATOMIC:IncludeDir("gamemode/atomic/systems/survival")
-- Crafting system
ATOMIC:IncludeDir("gamemode/atomic/systems/crafting")
-- User Interfaces
ATOMIC:IncludeDir("gamemode/atomic/interfaces")
-- Some systems are only loaded when database is ready.
hook.Add("SV_ATOMIC:DatabaseReady", "Atomic_Systems", function()
    -- Items
    ATOMIC:IncludeDir("gamemode/atomic/items")
    ATOMIC:Debug("Loaded " .. #ATOMIC.Items .. " items.")
end)