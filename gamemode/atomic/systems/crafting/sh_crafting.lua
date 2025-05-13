AddCSLuaFile()

ATOMIC.Crafting = ATOMIC.Crafting or {}

-- Recipe definition structure
ATOMIC.Crafting.Recipes = {}

-- Item categories for crafting menu
ATOMIC.Crafting.Categories = {
    "Food",
    "Drinks",
    "Medical",
    "Weapons",
    "Tools",
    "Materials",
    "Other"
}

-- Crafting configuration
ATOMIC.Crafting.Config = {
    CraftingTime = 3, -- Base crafting time in seconds
    EnableSkillRequirements = true, -- Whether to require skills for crafting
    EnableCraftingBonus = true, -- Whether to apply crafting skill bonuses
}

-- Register a crafting recipe
function ATOMIC.Crafting:RegisterRecipe(recipe)
    if not recipe.id then
        error("Recipe must have an ID")
        return
    end
    
    if not recipe.result then
        error("Recipe must have a result")
        return
    end
    
    if not recipe.ingredients or #recipe.ingredients == 0 then
        error("Recipe must have ingredients")
        return
    end
    
    self.Recipes[recipe.id] = recipe
end

-- Check if a player can craft an item
function ATOMIC.Crafting:CanPlayerCraft(ply, recipeID)
    local recipe = self.Recipes[recipeID]
    if not recipe then return false, "Invalid recipe" end
    
    -- Check ingredient requirements
    local hasIngredients, missingItems = self:HasIngredients(ply, recipe)
    if not hasIngredients then
        return false, "Missing ingredients: " .. missingItems
    end
    
    -- Check skill requirements if enabled
    if self.Config.EnableSkillRequirements and recipe.skillRequirements then
        if not ATOMIC.Attributes then
            return true -- Skip skill check if attributes system not loaded
        end
        
        for skill, level in pairs(recipe.skillRequirements) do
            local playerLevel = ATOMIC.Attributes:GetSkillLevel(skill)
            if playerLevel < level then
                return false, "You need " .. ATOMIC.Attributes.Skills[skill].name .. " level " .. level .. " (You have " .. playerLevel .. ")"
            end
        end
    end
    
    return true
end

-- Check if player has the required ingredients
function ATOMIC.Crafting:HasIngredients(ply, recipe)
    if not IsValid(ply) then return false, "Invalid player" end
    
    local inventory = ply:GetInventory()
    if not inventory then return false, "No inventory" end
    
    local missingItems = ""
    
    for _, ingredient in ipairs(recipe.ingredients) do
        local itemID = ingredient.id
        local amount = ingredient.amount or 1
        
        local hasAmount = inventory:GetItemAmount(itemID)
        
        if hasAmount < amount then
            local itemName = ATOMIC.Items[itemID] and ATOMIC.Items[itemID].name or itemID
            missingItems = missingItems .. itemName .. " (need " .. amount .. ", have " .. hasAmount .. "), "
        end
    end
    
    if missingItems ~= "" then
        missingItems = string.sub(missingItems, 1, -3) -- Remove last comma and space
        return false, missingItems
    end
    
    return true
end

-- Attempt to craft an item
function ATOMIC.Crafting:CraftItem(ply, recipeID, callback)
    if not IsValid(ply) then return false, "Invalid player" end
    
    local recipe = self.Recipes[recipeID]
    if not recipe then return false, "Invalid recipe" end
    
    -- Check if player can craft
    local canCraft, reason = self:CanPlayerCraft(ply, recipeID)
    if not canCraft then
        return false, reason
    end
    
    if SERVER then
        -- Take ingredients
        local inventory = ply:GetInventory()
        
        for _, ingredient in ipairs(recipe.ingredients) do
            inventory:TakeItem(ingredient.id, ingredient.amount or 1)
        end
        
        -- Calculate crafting time with skill bonus
        local craftTime = self.Config.CraftingTime
        
        if self.Config.EnableCraftingBonus and ATOMIC.Attributes then
            local craftingLevel = 0
            
            if recipe.craftingSkill then
                -- Use specific skill if defined
                craftingLevel = ATOMIC.Attributes:GetSkillLevel(recipe.craftingSkill)
            else
                -- Default to general crafting skill
                craftingLevel = ATOMIC.Attributes:GetSkillLevel("crafting")
            end
            
            -- Apply time reduction based on skill (up to 50% reduction)
            local timeReduction = math.min(0.5, craftingLevel / 100)
            craftTime = craftTime * (1 - timeReduction)
        end
        
        -- Start crafting timer
        ply:Freeze(true)
        ATOMIC:Notify(ply, "Crafting " .. recipe.name .. "...")
        
        timer.Create("ATOMIC:Crafting_" .. ply:SteamID64(), craftTime, 1, function()
            if not IsValid(ply) then return end
            
            ply:Freeze(false)
            
            -- Give the crafted item
            local resultItem = recipe.result
            ply:GetInventory():AddItem(resultItem.id, resultItem.amount or 1)
            
            -- Play sound
            ply:EmitSound(recipe.craftSound or "items/ammo_pickup.wav")
            
            -- Show success message
            ATOMIC:Notify(ply, "Successfully crafted " .. recipe.name .. "!")
            
            -- Attempt skill increase
            if ATOMIC.Attributes then
                if recipe.craftingSkill then
                    ATOMIC.Attributes:AttemptSkillIncrease(ply, recipe.craftingSkill, recipe.difficulty or "Medium")
                else
                    ATOMIC.Attributes:AttemptSkillIncrease(ply, "crafting", recipe.difficulty or "Medium")
                end
            end
            
            if callback then callback(true) end
        end)
        
        return true, "Crafting started"
    end
    
    return false, "Not on server"
end

-- Cancel crafting
function ATOMIC.Crafting:CancelCrafting(ply)
    if SERVER then
        if timer.Exists("ATOMIC:Crafting_" .. ply:SteamID64()) then
            timer.Remove("ATOMIC:Crafting_" .. ply:SteamID64())
            ply:Freeze(false)
            ATOMIC:Notify(ply, "Crafting cancelled.")
            return true
        end
    end
    
    return false
end

-- Networking
if SERVER then
    util.AddNetworkString("ATOMIC:RequestCrafting")
    util.AddNetworkString("ATOMIC:CancelCrafting")
    util.AddNetworkString("ATOMIC:SyncRecipes")
    
    -- Listen for crafting requests
    net.Receive("ATOMIC:RequestCrafting", function(len, ply)
        local recipeID = net.ReadString()
        ATOMIC.Crafting:CraftItem(ply, recipeID)
    end)
    
    -- Listen for crafting cancellations
    net.Receive("ATOMIC:CancelCrafting", function(len, ply)
        ATOMIC.Crafting:CancelCrafting(ply)
    end)
    
    -- Sync recipes to client
    function ATOMIC.Crafting:SyncRecipesToClient(ply)
        net.Start("ATOMIC:SyncRecipes")
        net.WriteTable(self.Recipes)
        
        if ply then
            net.Send(ply)
        else
            net.Broadcast()
        end
    end
    
    -- Send recipes when player initializes
    hook.Add("ATOMIC:PlayerInitialized", "ATOMIC:SyncCraftingRecipes", function(ply)
        timer.Simple(2, function()
            if IsValid(ply) then
                ATOMIC.Crafting:SyncRecipesToClient(ply)
            end
        end)
    end)
else -- CLIENT
    -- Receive recipes from server
    net.Receive("ATOMIC:SyncRecipes", function()
        local recipes = net.ReadTable()
        ATOMIC.Crafting.Recipes = recipes
    end)
    
    -- Request to craft an item
    function ATOMIC.Crafting:RequestCraft(recipeID)
        net.Start("ATOMIC:RequestCrafting")
        net.WriteString(recipeID)
        net.SendToServer()
    end
    
    -- Request to cancel crafting
    function ATOMIC.Crafting:RequestCancelCraft()
        net.Start("ATOMIC:CancelCrafting")
        net.SendToServer()
    end
end
