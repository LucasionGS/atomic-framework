-- File: sh_properties.lua
-- This file contains the shared property system for the Atomic framework

-- Table to store all registered properties
ATOMIC.Properties = ATOMIC.Properties or {}
ATOMIC.PropertyGroups = ATOMIC.PropertyGroups or {}

-- Format of a property:
--[[
    {
        id = "unique_id",                      -- Unique identifier for the property
        name = "Property Name",                -- Display name of the property
        description = "Property Description",   -- Description of the property
        price = 50000,                         -- Price to purchase the property
        type = "house",                        -- Type of property (house, business, etc.)
        doors = {                              -- Array of doors that belong to this property
            {
                map = "map_name",              -- Map name
                index = 123                    -- Door entity index
            }
        },
        spawnPos = Vector(0, 0, 0),            -- Spawn position inside the property
        spawnAng = Angle(0, 0, 0),             -- Spawn angle inside the property
        group = "downtown",                    -- Property group (optional)
        owner = nil,                           -- Owner of the property (player object)
        ownerSteamID = nil,                    -- SteamID of the owner
        coowners = {},                         -- Table of co-owners (SteamIDs)
        inventory = {},                        -- Storage inventory
        flags = {                              -- Special flags (optional)
            forSale = true,                    -- Whether the property is for sale
            raidable = false,                  -- Whether the property can be raided
            protected = false,                 -- Whether the property is protected
        }
    }
]]--

-- Register a new property
function ATOMIC:RegisterProperty(id, data)
    if not id then
        ATOMIC:Error("Property ID is missing!")
        return
    end
    
    -- Set default values
    data.id = id
    data.name = data.name or "Unnamed Property"
    data.description = data.description or ""
    data.price = data.price or 50000
    data.type = data.type or "house"
    data.doors = data.doors or {}
    data.spawnPos = data.spawnPos or Vector(0, 0, 0)
    data.spawnAng = data.spawnAng or Angle(0, 0, 0)
    data.group = data.group or "default"
    data.owner = nil
    data.ownerSteamID = nil
    data.coowners = {}
    data.inventory = {}
    data.flags = data.flags or {
        forSale = true,
        raidable = false,
        protected = false
    }
    
    -- Register the property group if it doesn't exist
    if not ATOMIC.PropertyGroups[data.group] then
        ATOMIC.PropertyGroups[data.group] = {
            name = data.group,
            properties = {}
        }
    end
    
    -- Add the property to its group
    table.insert(ATOMIC.PropertyGroups[data.group].properties, id)
    
    -- Add the property to the global table
    ATOMIC.Properties[id] = data
    
    return data
end

-- Get a property by ID
function ATOMIC:GetProperty(id)
    return ATOMIC.Properties[id]
end

-- Get properties by group
function ATOMIC:GetPropertiesByGroup(group)
    local properties = {}
    
    if ATOMIC.PropertyGroups[group] then
        for _, propId in ipairs(ATOMIC.PropertyGroups[group].properties) do
            table.insert(properties, ATOMIC.Properties[propId])
        end
    end
    
    return properties
end

-- Get all properties
function ATOMIC:GetAllProperties()
    return ATOMIC.Properties
end

-- Get all property groups
function ATOMIC:GetAllPropertyGroups()
    return ATOMIC.PropertyGroups
end

-- Check if a player owns a property
function ATOMIC:PlayerOwnsProperty(ply, propertyId)
    local property = ATOMIC:GetProperty(propertyId)
    
    if not property then return false end
    
    local steamID = ply:SteamID64()
    
    -- Check if player is the owner
    if property.ownerSteamID == steamID then
        return true
    end
    
    -- Check if player is a co-owner
    for _, coownerID in ipairs(property.coowners) do
        if coownerID == steamID then
            return true
        end
    end
    
    return false
end

-- Get all properties owned by a player
function ATOMIC:GetPropertiesOwnedByPlayer(ply)
    local steamID = ply:SteamID64()
    local properties = {}
    
    for id, property in pairs(ATOMIC.Properties) do
        if property.ownerSteamID == steamID then
            table.insert(properties, property)
        end
    end
    
    return properties
end

if SERVER then
    -- Save properties to file
    function ATOMIC:SaveProperties()
        local map = game.GetMap()
        
        -- Deep copy properties to avoid saving player entities
        local propertiesCopy = {}
        
        for id, property in pairs(ATOMIC.Properties) do
            local propertyCopy = table.Copy(property)
            propertyCopy.owner = nil -- Don't save the player entity
            propertiesCopy[id] = propertyCopy
        end
        
        file.Write(ATOMIC.Config.DataFolder .. "/properties_" .. map .. ".json", util.TableToJSON(propertiesCopy))
        ATOMIC:Print("Saved properties to file.")
    end
    
    -- Load properties from file
    function ATOMIC:LoadProperties()
        local map = game.GetMap()
        
        if file.Exists(ATOMIC.Config.DataFolder .. "/properties_" .. map .. ".json", "DATA") then
            ATOMIC.Properties = util.JSONToTable(file.Read(ATOMIC.Config.DataFolder .. "/properties_" .. map .. ".json", "DATA"))
            
            -- Rebuild property groups
            ATOMIC.PropertyGroups = {}
            
            for id, property in pairs(ATOMIC.Properties) do
                local group = property.group or "default"
                
                if not ATOMIC.PropertyGroups[group] then
                    ATOMIC.PropertyGroups[group] = {
                        name = group,
                        properties = {}
                    }
                end
                
                table.insert(ATOMIC.PropertyGroups[group].properties, id)
            end
            
            ATOMIC:Print("Loaded properties from file.")
        end
    end
    
    -- Send properties to players
    function ATOMIC:SendPropertiesToPlayers(plys)
        net.Start("ATOMIC:SendProperties")
        net.WriteTable(ATOMIC.Properties)
        net.WriteTable(ATOMIC.PropertyGroups)
        net.Send(plys)
    end
    
    -- Update door ownership based on properties
    function ATOMIC:UpdateDoorOwnership()
        for id, property in pairs(ATOMIC.Properties) do
            if property.owner and IsValid(property.owner) then
                for _, door in ipairs(property.doors) do
                    local doorEnt = ents.GetMapCreatedEntity(door.index)
                    
                    if IsValid(doorEnt) then
                        -- Set the door as owned
                        doorEnt:SetNWBool("ATOMIC_Owned", true)
                        doorEnt:SetNWString("ATOMIC_OwnerSteamID", property.ownerSteamID)
                        doorEnt:SetNWString("ATOMIC_PropertyID", id)
                        
                        -- Set door title
                        doorEnt:SetNWString("ATOMIC_DoorTitle", property.name)
                    end
                end
            else
                for _, door in ipairs(property.doors) do
                    local doorEnt = ents.GetMapCreatedEntity(door.index)
                    
                    if IsValid(doorEnt) then
                        -- Reset door ownership
                        doorEnt:SetNWBool("ATOMIC_Owned", false)
                        doorEnt:SetNWString("ATOMIC_OwnerSteamID", "")
                        doorEnt:SetNWString("ATOMIC_PropertyID", "")
                        doorEnt:SetNWString("ATOMIC_DoorTitle", "")
                    end
                end
            end
        end
    end
    
    -- Buy a property
    function ATOMIC:BuyProperty(ply, propertyId)
        local property = ATOMIC:GetProperty(propertyId)
        
        if not property then
            ATOMIC:NotifyError(ply, "This property doesn't exist.")
            return false
        end
        
        if not property.flags.forSale then
            ATOMIC:NotifyError(ply, "This property is not for sale.")
            return false
        end
        
        if property.owner then
            ATOMIC:NotifyError(ply, "This property is already owned.")
            return false
        end
        
        -- Check if player can afford the property
        if ply:GetBank() < property.price then
            ATOMIC:NotifyError(ply, "You can't afford this property.")
            return false
        end
        
        -- Take money from player
        ply:RemoveBank(property.price)
        
        -- Set ownership
        property.owner = ply
        property.ownerSteamID = ply:SteamID64()
        property.flags.forSale = false
        
        -- Update door ownership
        ATOMIC:UpdateDoorOwnership()
        
        -- Save properties
        ATOMIC:SaveProperties()
        
        -- Send properties to all players
        ATOMIC:SendPropertiesToPlayers(player.GetAll())
        
        -- Notify player
        ATOMIC:Notify(ply, "You purchased " .. property.name .. " for $" .. property.price)
        
        return true
    end
    
    -- Sell a property
    function ATOMIC:SellProperty(ply, propertyId)
        local property = ATOMIC:GetProperty(propertyId)
        
        if not property then
            ATOMIC:NotifyError(ply, "This property doesn't exist.")
            return false
        end
        
        if not ATOMIC:PlayerOwnsProperty(ply, propertyId) then
            ATOMIC:NotifyError(ply, "You don't own this property.")
            return false
        end
        
        -- Calculate sell price (75% of purchase price)
        local sellPrice = math.floor(property.price * 0.75)
        
        -- Give money to player
        ply:AddBank(sellPrice)
        
        -- Reset ownership
        property.owner = nil
        property.ownerSteamID = nil
        property.coowners = {}
        property.flags.forSale = true
        
        -- Clear inventory (optional)
        property.inventory = {}
        
        -- Update door ownership
        ATOMIC:UpdateDoorOwnership()
        
        -- Save properties
        ATOMIC:SaveProperties()
        
        -- Send properties to all players
        ATOMIC:SendPropertiesToPlayers(player.GetAll())
        
        -- Notify player
        ATOMIC:Notify(ply, "You sold " .. property.name .. " for $" .. sellPrice)
        
        return true
    end
    
    -- Add a co-owner to a property
    function ATOMIC:AddCoOwner(ply, propertyId, coOwnerPly)
        local property = ATOMIC:GetProperty(propertyId)
        
        if not property then
            ATOMIC:NotifyError(ply, "This property doesn't exist.")
            return false
        end
        
        if not property.ownerSteamID == ply:SteamID64() then
            ATOMIC:NotifyError(ply, "You don't own this property.")
            return false
        end
        
        local coOwnerSteamID = coOwnerPly:SteamID64()
        
        -- Check if already a co-owner
        for _, id in ipairs(property.coowners) do
            if id == coOwnerSteamID then
                ATOMIC:NotifyError(ply, coOwnerPly:Nick() .. " is already a co-owner.")
                return false
            end
        end
        
        -- Add as co-owner
        table.insert(property.coowners, coOwnerSteamID)
        
        -- Save properties
        ATOMIC:SaveProperties()
        
        -- Notify players
        ATOMIC:Notify(ply, "You added " .. coOwnerPly:Nick() .. " as a co-owner of " .. property.name)
        ATOMIC:Notify(coOwnerPly, "You are now a co-owner of " .. property.name)
        
        return true
    end
    
    -- Remove a co-owner from a property
    function ATOMIC:RemoveCoOwner(ply, propertyId, coOwnerSteamID)
        local property = ATOMIC:GetProperty(propertyId)
        
        if not property then
            ATOMIC:NotifyError(ply, "This property doesn't exist.")
            return false
        end
        
        if not property.ownerSteamID == ply:SteamID64() then
            ATOMIC:NotifyError(ply, "You don't own this property.")
            return false
        end
        
        -- Find and remove co-owner
        for i, id in ipairs(property.coowners) do
            if id == coOwnerSteamID then
                table.remove(property.coowners, i)
                
                -- Save properties
                ATOMIC:SaveProperties()
                
                -- Notify player
                ATOMIC:Notify(ply, "You removed a co-owner from " .. property.name)
                
                -- Notify co-owner if online
                local coOwner = player.GetBySteamID64(coOwnerSteamID)
                if IsValid(coOwner) then
                    ATOMIC:Notify(coOwner, "You are no longer a co-owner of " .. property.name)
                end
                
                return true
            end
        end
        
        ATOMIC:NotifyError(ply, "This player is not a co-owner.")
        return false
    end
    
    -- Load properties when the server starts
    hook.Add("InitPostEntity", "ATOMIC:LoadProperties", function()
        ATOMIC:LoadProperties()
        
        -- Update door ownership after a brief delay
        timer.Simple(2, function()
            ATOMIC:UpdateDoorOwnership()
        end)
    end)
    
    -- Network strings for property management
    util.AddNetworkString("ATOMIC:SendProperties")
    util.AddNetworkString("ATOMIC:BuyProperty")
    util.AddNetworkString("ATOMIC:SellProperty")
    util.AddNetworkString("ATOMIC:AddCoOwner")
    util.AddNetworkString("ATOMIC:RemoveCoOwner")
    util.AddNetworkString("ATOMIC:RequestProperties")
    
    -- Handle property buying
    net.Receive("ATOMIC:BuyProperty", function(len, ply)
        local propertyId = net.ReadString()
        ATOMIC:BuyProperty(ply, propertyId)
    end)
    
    -- Handle property selling
    net.Receive("ATOMIC:SellProperty", function(len, ply)
        local propertyId = net.ReadString()
        ATOMIC:SellProperty(ply, propertyId)
    end)
    
    -- Handle co-owner adding
    net.Receive("ATOMIC:AddCoOwner", function(len, ply)
        local propertyId = net.ReadString()
        local coOwnerSteamID = net.ReadString()
        local coOwner = player.GetBySteamID64(coOwnerSteamID)
        
        if IsValid(coOwner) then
            ATOMIC:AddCoOwner(ply, propertyId, coOwner)
        else
            ATOMIC:NotifyError(ply, "Player not found.")
        end
    end)
    
    -- Handle co-owner removal
    net.Receive("ATOMIC:RemoveCoOwner", function(len, ply)
        local propertyId = net.ReadString()
        local coOwnerSteamID = net.ReadString()
        ATOMIC:RemoveCoOwner(ply, propertyId, coOwnerSteamID)
    end)
    
    -- Handle property request
    net.Receive("ATOMIC:RequestProperties", function(len, ply)
        ATOMIC:SendPropertiesToPlayers(ply)
    end)
    
else -- CLIENT
    -- Request properties from the server
    function ATOMIC:RequestProperties()
        net.Start("ATOMIC:RequestProperties")
        net.SendToServer()
    end
    
    -- Buy a property
    function ATOMIC:BuyProperty(propertyId)
        net.Start("ATOMIC:BuyProperty")
        net.WriteString(propertyId)
        net.SendToServer()
    end
    
    -- Sell a property
    function ATOMIC:SellProperty(propertyId)
        net.Start("ATOMIC:SellProperty")
        net.WriteString(propertyId)
        net.SendToServer()
    end
    
    -- Add a co-owner to a property
    function ATOMIC:AddCoOwner(propertyId, coOwnerSteamID)
        net.Start("ATOMIC:AddCoOwner")
        net.WriteString(propertyId)
        net.WriteString(coOwnerSteamID)
        net.SendToServer()
    end
    
    -- Remove a co-owner from a property
    function ATOMIC:RemoveCoOwner(propertyId, coOwnerSteamID)
        net.Start("ATOMIC:RemoveCoOwner")
        net.WriteString(propertyId)
        net.WriteString(coOwnerSteamID)
        net.SendToServer()
    end
    
    -- Receive properties from the server
    net.Receive("ATOMIC:SendProperties", function()
        ATOMIC.Properties = net.ReadTable()
        ATOMIC.PropertyGroups = net.ReadTable()
        
        -- Call callback if properties were received
        hook.Run("ATOMIC:PropertiesUpdated")
    end)
    
    -- Request properties when the client initializes
    hook.Add("InitPostEntity", "ATOMIC:RequestProperties", function()
        timer.Simple(2, function()
            ATOMIC:RequestProperties()
        end)
    end)
end
