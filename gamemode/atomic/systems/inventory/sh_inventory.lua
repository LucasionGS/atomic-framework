-- File: sh_inventory.lua
-- This file contains the shared inventory system for the Atomic framework

-- Table to store all registered items
ATOMIC.Items = ATOMIC.Items or {}

--[[
    Item Definition:
    {
        Name = "Item Name",
        Model = "models/path/to/model.mdl",
        Type = "item", -- "item", "weapon", "material", "food", etc.
        Weight = 1, -- How much inventory space it takes up
        Description = "Item description", -- Optional
        MaxStack = 10, -- How many can stack together in one slot (default 1)
        OnUse = function(ply) -- Function to call when used
            -- Do something when used
            return true -- Return true to consume the item, false to keep it
        end,
        OnDrop = function(ply, item, amount) -- Function to call when dropped
            -- Do something when dropped
        end,
        OnPickup = function(ply, item, amount) -- Function to call when picked up
            -- Do something when picked up
        end
    }
]]--

-- Register a new item
function ATOMIC:RegisterItem(data)
    -- Validate required fields
    local id = data.id
    local name = data.name
    local itemType = data.type or data.category
    
    -- Standardize key naming (support both lowercase and uppercase keys)
    if not id then
        ATOMIC:Error("Item registration failed: Missing ID")
        return
    end
    
    if not name then
        ATOMIC:Error("Item " .. id .. " is missing a name!")
        return
    end
    
    if not itemType then
        ATOMIC:Error("Item " .. id .. " is missing a type or category!")
        return
    end
    
    -- Create a standardized version of the item
    local standardItem = {
        id = id,
        name = name,
        type = itemType,
        description = data.description or data.Description or "",
        model = data.model or data.Model or "models/props_junk/garbage_bag001a.mdl",
        weight = data.weight or data.Weight or 1,
        maxStack = data.maxStack or data.MaxStack or 1,
        price = data.price or data.Price or 0,
        __key = id -- Store the original key for reference
    }
    
    -- Copy any other properties
    for k, v in pairs(data) do
        if standardItem[k] == nil then
            standardItem[k] = v
        end
    end
    
    -- Copy callback functions
    if data.OnUse then standardItem.OnUse = data.OnUse end
    if data.OnDrop then standardItem.OnDrop = data.OnDrop end
    if data.OnPickup then standardItem.OnPickup = data.OnPickup end
    
    -- Register the item
    ATOMIC.Items[id] = standardItem
    
    return standardItem
end

-- Get an item by ID
function ATOMIC:GetItem(id)
    return ATOMIC.Items[id]
end

-- Get an item property with case-insensitive keys
function ATOMIC:GetItemProperty(item, key)
    if not item then return nil end
    
    -- Try the exact key first
    if item[key] ~= nil then
        return item[key]
    end
    
    -- Try lowercase version
    local lkey = string.lower(key)
    for k, v in pairs(item) do
        if string.lower(k) == lkey then
            return v
        end
    end
    
    return nil
end

-- Get all items
function ATOMIC:GetAllItems()
    return ATOMIC.Items
end

-- Get items by type
function ATOMIC:GetItemsByType(itemType)
    local items = {}
    
    for id, item in pairs(ATOMIC.Items) do
        local type = item.type or item.Type or item.category or item.Category
        if type == itemType then
            items[id] = item
        end
    end
    
    return items
end

-- Define default inventory functions
local meta = FindMetaTable("Player")

-- Add an item to a player's inventory
function meta:AddItem(itemId, amount)
    amount = amount or 1
    
    if SERVER then
        local item = ATOMIC:GetItem(itemId)
        
        if not item then
            ATOMIC:Error("Tried to add non-existent item: " .. itemId)
            return false
        end
        
        -- Get the player's inventory
        self:GetInventory(function(inventory)
            -- Check if the player already has this item and it can be stacked
            for slot, invItem in pairs(inventory) do
                local maxStack = item.maxStack or item.MaxStack or 1
                if invItem.id == itemId and invItem.amount < maxStack then
                    -- Stack with existing item
                    local canStack = maxStack - invItem.amount
                    local toStack = math.min(amount, canStack)
                    
                    inventory[slot].amount = inventory[slot].amount + toStack
                    amount = amount - toStack
                    
                    if amount <= 0 then
                        -- All items have been added
                        self:SaveInventory(inventory)
                        
                        -- Call the OnPickup function if defined
                        if item.OnPickup then
                            item.OnPickup(self, item, amount)
                        end
                        
                        return true
                    end
                end
            end
            
            -- Find an empty slot for the remaining items
            local firstEmptySlot = nil
            
            for i = 1, self:GetMaxInventorySlots() do
                if not inventory[tostring(i)] then
                    firstEmptySlot = tostring(i)
                    break
                end
            end
            
            if not firstEmptySlot then
                ATOMIC:NotifyError(self, "Your inventory is full!")
                return false
            end
            
            -- Add the item to the empty slot
            inventory[firstEmptySlot] = {
                id = itemId,
                amount = math.min(amount, item.maxStack or item.MaxStack or 1)
            }
            
            -- If there are still items left, recursively add them
            local remainingAmount = amount - (item.maxStack or item.MaxStack or 1)
            
            if remainingAmount > 0 then
                -- Save the current inventory first
                self:SaveInventory(inventory)
                
                -- Then add the remaining items
                return self:AddItem(itemId, remainingAmount)
            else
                -- Save the inventory
                self:SaveInventory(inventory)
                
                -- Call the OnPickup function if defined
                if item.OnPickup then
                    item.OnPickup(self, item, amount)
                end
                
                return true
            end
        end)
    else
        net.Start("ATOMIC:AddItem")
        net.WriteString(itemId)
        net.WriteUInt(amount, 16)
        net.SendToServer()
    end
end

-- Remove an item from a player's inventory
function meta:RemoveItem(itemId, amount)
    amount = amount or 1
    
    if SERVER then
        -- Get the player's inventory
        self:GetInventory(function(inventory)
            local remainingToRemove = amount
            local slots = {}
            
            -- Find slots with this item
            for slot, invItem in pairs(inventory) do
                if invItem.id == itemId then
                    table.insert(slots, {
                        slot = slot,
                        amount = invItem.amount
                    })
                end
            end
            
            -- Sort slots by amount (ascending)
            table.sort(slots, function(a, b)
                return a.amount < b.amount
            end)
            
            -- Remove items starting from the smallest stacks
            for _, slotData in ipairs(slots) do
                local toRemove = math.min(remainingToRemove, slotData.amount)
                
                if toRemove >= slotData.amount then
                    -- Remove the entire stack
                    inventory[slotData.slot] = nil
                else
                    -- Remove part of the stack
                    inventory[slotData.slot].amount = inventory[slotData.slot].amount - toRemove
                end
                
                remainingToRemove = remainingToRemove - toRemove
                
                if remainingToRemove <= 0 then
                    break
                end
            end
            
            -- Save the inventory
            self:SaveInventory(inventory)
            
            return (remainingToRemove <= 0)
        end)
    else
        net.Start("ATOMIC:RemoveItem")
        net.WriteString(itemId)
        net.WriteUInt(amount, 16)
        net.SendToServer()
    end
end

-- Use an item from a player's inventory
function meta:UseItem(itemId, slot)
    if SERVER then
        -- Get the player's inventory
        self:GetInventory(function(inventory)
            local invItem = inventory[slot]
            
            if not invItem or invItem.id ~= itemId then
                ATOMIC:NotifyError(self, "You don't have that item in that slot!")
                return false
            end
            
            local item = ATOMIC:GetItem(itemId)
            
            if not item then
                ATOMIC:Error("Tried to use non-existent item: " .. itemId)
                return false
            end
            
            -- Call the OnUse function if defined
            if item.OnUse then
                local shouldConsume = item.OnUse(self, item)
                
                if shouldConsume then
                    -- Remove one of the item
                    if invItem.amount > 1 then
                        inventory[slot].amount = inventory[slot].amount - 1
                    else
                        inventory[slot] = nil
                    end
                    
                    -- Save the inventory
                    self:SaveInventory(inventory)
                end
            end
            
            -- Also handle server-specific use logic if defined
            if item.OnUseServer then
                item.OnUseServer(self, item)
            end
            
            return true
        end)
    else
        net.Start("ATOMIC:UseItem")
        net.WriteString(itemId)
        net.WriteString(slot)
        net.SendToServer()
    end
end

-- Drop an item from a player's inventory
function meta:DropItem(itemId, slot, amount)
    if SERVER then
        -- Get the player's inventory
        self:GetInventory(function(inventory)
            local invItem = inventory[slot]
            
            if not invItem or invItem.id ~= itemId then
                ATOMIC:NotifyError(self, "You don't have that item in that slot!")
                return false
            end
            
            local item = ATOMIC:GetItem(itemId)
            
            if not item then
                ATOMIC:Error("Tried to drop non-existent item: " .. itemId)
                return false
            end
            
            -- Determine how many to drop
            amount = math.min(amount or invItem.amount, invItem.amount)
            
            -- Call the OnDrop function if defined
            if item.OnDrop then
                item.OnDrop(self, item, amount)
            else
                -- Default drop behavior - spawn the item in the world
                local tr = self:GetEyeTrace()
                local pos = tr.HitPos + Vector(0, 0, 10)
                
                -- Spawn the item entity
                local ent = ents.Create("atomic_item")
                ent:SetItemID(itemId)
                ent:SetItemAmount(amount)
                ent:SetPos(pos)
                ent:Spawn()
                
                -- Add some physics
                local phys = ent:GetPhysicsObject()
                if IsValid(phys) then
                    phys:Wake()
                    phys:SetVelocity(self:GetForward() * 200)
                end
            end
            
            -- Remove the items from the inventory
            if amount >= invItem.amount then
                inventory[slot] = nil
            else
                inventory[slot].amount = inventory[slot].amount - amount
            end
            
            -- Save the inventory
            self:SaveInventory(inventory)
            
            return true
        end)
    else
        net.Start("ATOMIC:DropItem")
        net.WriteString(itemId)
        net.WriteString(slot)
        net.WriteUInt(amount or 0, 16) -- 0 means drop all
        net.SendToServer()
    end
end

-- Move an item in the inventory
function meta:MoveItem(fromSlot, toSlot, amount)
    if SERVER then
        -- Get the player's inventory
        self:GetInventory(function(inventory)
            local fromItem = inventory[fromSlot]
            
            if not fromItem then
                ATOMIC:NotifyError(self, "No item in source slot!")
                return false
            end
            
            -- Determine how many to move
            amount = math.min(amount or fromItem.amount, fromItem.amount)
            
            -- Check if the destination slot is empty
            if not inventory[toSlot] then
                -- Move the item to the empty slot
                inventory[toSlot] = {
                    id = fromItem.id,
                    amount = amount
                }
                
                -- Update the source slot
                if amount >= fromItem.amount then
                    inventory[fromSlot] = nil
                else
                    inventory[fromSlot].amount = inventory[fromSlot].amount - amount
                end
            else
                -- Destination slot has an item
                local toItem = inventory[toSlot]
                
                -- Check if the items are the same type
                if toItem.id == fromItem.id then
                    -- Same item type, try to stack
                    local item = ATOMIC:GetItem(toItem.id)
                    local maxStack = item.MaxStack or 1
                    
                    -- Calculate how many can be stacked
                    local canStack = maxStack - toItem.amount
                    local toStack = math.min(amount, canStack)
                    
                    -- Stack the items
                    inventory[toSlot].amount = inventory[toSlot].amount + toStack
                    
                    -- Update the source slot
                    if toStack >= fromItem.amount then
                        inventory[fromSlot] = nil
                    else
                        inventory[fromSlot].amount = inventory[fromSlot].amount - toStack
                    end
                else
                    -- Different item types, swap the items
                    inventory[toSlot], inventory[fromSlot] = inventory[fromSlot], inventory[toSlot]
                end
            end
            
            -- Save the inventory
            self:SaveInventory(inventory)
            
            return true
        end)
    else
        net.Start("ATOMIC:MoveItem")
        net.WriteString(fromSlot)
        net.WriteString(toSlot)
        net.WriteUInt(amount or 0, 16) -- 0 means move all
        net.SendToServer()
    end
end

-- Get the player's max inventory slots
function meta:GetMaxInventorySlots()
    return self:GetNWInt("ATOMIC_MaxInventorySlots", 20)
end

-- Set the player's max inventory slots
function meta:SetMaxInventorySlots(slots)
    if SERVER then
        self:SetNWInt("ATOMIC_MaxInventorySlots", slots)
    end
end

if SERVER then
    -- Get a player's inventory
    function meta:GetInventory(callback)
        if not callback then return end
        
        -- Get the inventory from the database
        local steamID = self:SteamID64()
        
        -- TODO: Should load inventory
    end
    
    -- Save a player's inventory
    function meta:SaveInventory(inventory)
        local steamID = self:SteamID64()
        local inventoryJson = util.TableToJSON(inventory)
        
        -- TODO: Save inventory to database
    end
    
    -- Network strings for inventory management
    util.AddNetworkString("ATOMIC:AddItem")
    util.AddNetworkString("ATOMIC:RemoveItem")
    util.AddNetworkString("ATOMIC:UseItem")
    util.AddNetworkString("ATOMIC:DropItem")
    util.AddNetworkString("ATOMIC:MoveItem")
    util.AddNetworkString("ATOMIC:InventoryUpdated")
    util.AddNetworkString("ATOMIC:RequestInventory")
    
    -- Handle item adding
    net.Receive("ATOMIC:AddItem", function(len, ply)
        local itemId = net.ReadString()
        local amount = net.ReadUInt(16)
        ply:AddItem(itemId, amount)
    end)
    
    -- Handle item removal
    net.Receive("ATOMIC:RemoveItem", function(len, ply)
        local itemId = net.ReadString()
        local amount = net.ReadUInt(16)
        ply:RemoveItem(itemId, amount)
    end)
    
    -- Handle item usage
    net.Receive("ATOMIC:UseItem", function(len, ply)
        local itemId = net.ReadString()
        local slot = net.ReadString()
        ply:UseItem(itemId, slot)
    end)
    
    -- Handle item dropping
    net.Receive("ATOMIC:DropItem", function(len, ply)
        local itemId = net.ReadString()
        local slot = net.ReadString()
        local amount = net.ReadUInt(16)
        ply:DropItem(itemId, slot, amount > 0 and amount or nil)
    end)
    
    -- Handle item moving
    net.Receive("ATOMIC:MoveItem", function(len, ply)
        local fromSlot = net.ReadString()
        local toSlot = net.ReadString()
        local amount = net.ReadUInt(16)
        ply:MoveItem(fromSlot, toSlot, amount > 0 and amount or nil)
    end)
    
    -- Handle inventory request
    net.Receive("ATOMIC:RequestInventory", function(len, ply)
        ply:GetInventory(function(inventory)
            net.Start("ATOMIC:InventoryUpdated")
            net.WriteEntity(ply)
            net.WriteString(util.TableToJSON(inventory))
            net.Send(ply)
        end)
    end)
else -- CLIENT
    -- Local inventory cache
    local inventoryCache = {}
    
    -- Get the player's inventory (from cache)
    function meta:GetInventory()
        local steamID = self:SteamID64()
        return inventoryCache[steamID] or {}
    end
    
    -- Request inventory from server
    function meta:RequestInventory()
        net.Start("ATOMIC:RequestInventory")
        net.SendToServer()
    end
    
    -- Receive inventory updates
    net.Receive("ATOMIC:InventoryUpdated", function()
        local ply = net.ReadEntity()
        local inventoryJson = net.ReadString()
        
        if IsValid(ply) then
            local inventory = util.JSONToTable(inventoryJson) or {}
            inventoryCache[ply:SteamID64()] = inventory
            
            -- Trigger inventory update hook
            hook.Run("ATOMIC:InventoryUpdated", ply, inventory)
        end
    end)
    
    -- Request inventory when the player spawns
    hook.Add("InitPostEntity", "ATOMIC:RequestInventory", function()
        timer.Simple(2, function()
            LocalPlayer():RequestInventory()
        end)
    end)
    
    -- Update inventory cache when a player disconnects
    hook.Add("PlayerDisconnected", "ATOMIC:ClearInventoryCache", function(ply)
        inventoryCache[ply:SteamID64()] = nil
    end)
end
