-- Client-side crafting menu
ATOMIC.Crafting = ATOMIC.Crafting or {}

-- Create the crafting menu
function ATOMIC.Crafting:OpenMenu()
    if IsValid(self.Menu) then
        self.Menu:Remove()
    end
    
    -- Create the base frame
    local frame = vgui.Create("DFrame")
    frame:SetTitle("Crafting")
    frame:SetSize(800, 600)
    frame:Center()
    frame:MakePopup()
    
    -- Create the category list
    local categoryList = vgui.Create("DListView", frame)
    categoryList:Dock(LEFT)
    categoryList:SetWidth(150)
    categoryList:AddColumn("Categories")
    
    -- Add "All" category
    categoryList:AddLine("All")
    
    -- Add all defined categories
    for _, category in ipairs(self.Categories) do
        categoryList:AddLine(category)
    end
    
    -- Create recipe list panel
    local recipeList = vgui.Create("DListView", frame)
    recipeList:Dock(TOP)
    recipeList:SetHeight(200)
    recipeList:AddColumn("Recipe")
    recipeList:AddColumn("Requirements")
    recipeList:AddColumn("Can Craft")
    
    -- Create recipe details panel
    local detailsPanel = vgui.Create("DPanel", frame)
    detailsPanel:Dock(FILL)
    
    -- Recipe name
    local recipeName = vgui.Create("DLabel", detailsPanel)
    recipeName:SetPos(10, 10)
    recipeName:SetFont("DermaLarge")
    recipeName:SetText("Select a recipe")
    recipeName:SizeToContents()
    
    -- Recipe description
    local recipeDesc = vgui.Create("DLabel", detailsPanel)
    recipeDesc:SetPos(10, 40)
    recipeDesc:SetWide(detailsPanel:GetWide() - 20)
    recipeDesc:SetText("Choose a recipe from the list above to view details.")
    recipeDesc:SetWrap(true)
    recipeDesc:SetTall(40)
    
    -- Ingredients list
    local ingredientsLabel = vgui.Create("DLabel", detailsPanel)
    ingredientsLabel:SetPos(10, 90)
    ingredientsLabel:SetFont("DermaDefault")
    ingredientsLabel:SetText("Ingredients:")
    ingredientsLabel:SizeToContents()
    
    local ingredientsList = vgui.Create("DPanelList", detailsPanel)
    ingredientsList:SetPos(10, 110)
    ingredientsList:SetSize(detailsPanel:GetWide() - 20, 120)
    ingredientsList:EnableVerticalScrollbar(true)
    ingredientsList:SetSpacing(2)
    ingredientsList:SetPadding(5)
    
    -- Skill requirements
    local skillsLabel = vgui.Create("DLabel", detailsPanel)
    skillsLabel:SetPos(10, 240)
    skillsLabel:SetFont("DermaDefault")
    skillsLabel:SetText("Skill Requirements:")
    skillsLabel:SizeToContents()
    
    local skillsList = vgui.Create("DPanelList", detailsPanel)
    skillsList:SetPos(10, 260)
    skillsList:SetSize(detailsPanel:GetWide() - 20, 100)
    skillsList:EnableVerticalScrollbar(true)
    skillsList:SetSpacing(2)
    skillsList:SetPadding(5)
    
    -- Craft button
    local craftButton = vgui.Create("DButton", detailsPanel)
    craftButton:SetPos(detailsPanel:GetWide() / 2 - 50, detailsPanel:GetTall() - 50)
    craftButton:SetSize(100, 40)
    craftButton:SetText("Craft")
    craftButton:SetEnabled(false)
    
    local selectedRecipeID = nil
    
    -- Function to refresh the recipe list based on selected category
    local function RefreshRecipeList(category)
        recipeList:Clear()
        
        for recipeID, recipe in pairs(ATOMIC.Crafting.Recipes) do
            -- Filter by category if not "All"
            if category ~= "All" and recipe.category ~= category then
                continue
            end
            
            -- Check if player can craft this recipe
            local canCraft, reason = ATOMIC.Crafting:CanPlayerCraft(LocalPlayer(), recipeID)
            
            -- Build requirements string
            local requirements = ""
            if recipe.skillRequirements then
                for skill, level in pairs(recipe.skillRequirements) do
                    local skillName = ATOMIC.Attributes.Skills[skill] and ATOMIC.Attributes.Skills[skill].name or skill
                    requirements = requirements .. skillName .. " Lvl " .. level .. ", "
                end
                requirements = string.sub(requirements, 1, -3) -- Remove last comma
            end
            
            -- Add to list
            local line = recipeList:AddLine(recipe.name, requirements, canCraft and "Yes" or "No")
            line.recipeID = recipeID
            
            -- Color the line based on craftability
            if not canCraft then
                line:SetTextColor(Color(150, 150, 150))
            end
        end
    end
    
    -- Function to update the details panel
    local function UpdateDetails(recipeID)
        local recipe = ATOMIC.Crafting.Recipes[recipeID]
        if not recipe then return end
        
        selectedRecipeID = recipeID
        
        -- Update recipe name and description
        recipeName:SetText(recipe.name)
        recipeName:SizeToContents()
        
        recipeDesc:SetText(recipe.description or "No description available.")
        
        -- Clear ingredients list
        ingredientsList:Clear()
        
        -- Add each ingredient to the list
        for _, ingredient in ipairs(recipe.ingredients) do
            local itemData = ATOMIC.Items[ingredient.id]
            local amount = ingredient.amount or 1
            
            if itemData then
                local panel = vgui.Create("DPanel")
                panel:SetSize(ingredientsList:GetWide(), 30)
                
                local itemIcon = vgui.Create("DModelPanel", panel)
                itemIcon:SetSize(24, 24)
                itemIcon:SetPos(5, 3)
                itemIcon:SetModel(itemData.model)
                
                local itemName = vgui.Create("DLabel", panel)
                itemName:SetPos(40, 8)
                itemName:SetText(itemData.name .. " x" .. amount)
                itemName:SizeToContents()
                
                -- Check if player has this ingredient
                local hasAmount = LocalPlayer():GetInventory() and LocalPlayer():GetInventory():GetItemAmount(ingredient.id) or 0
                
                local haveLabel = vgui.Create("DLabel", panel)
                haveLabel:SetPos(panel:GetWide() - 60, 8)
                haveLabel:SetText("Have: " .. hasAmount)
                haveLabel:SizeToContents()
                
                -- Color based on whether player has enough
                if hasAmount < amount then
                    haveLabel:SetTextColor(Color(255, 0, 0))
                else
                    haveLabel:SetTextColor(Color(0, 255, 0))
                end
                
                ingredientsList:AddItem(panel)
            end
        end
        
        -- Clear skill requirements list
        skillsList:Clear()
        
        -- Add skill requirements if any
        if recipe.skillRequirements then
            for skill, level in pairs(recipe.skillRequirements) do
                local skillData = ATOMIC.Attributes.Skills[skill]
                
                local panel = vgui.Create("DPanel")
                panel:SetSize(skillsList:GetWide(), 30)
                
                local skillIcon = vgui.Create("DImage", panel)
                skillIcon:SetSize(16, 16)
                skillIcon:SetPos(5, 7)
                skillIcon:SetImage(skillData and skillData.icon or "icon16/error.png")
                
                local skillName = vgui.Create("DLabel", panel)
                skillName:SetPos(30, 8)
                skillName:SetText((skillData and skillData.name or skill) .. " - Level " .. level)
                skillName:SizeToContents()
                
                -- Check player's skill level
                local playerLevel = ATOMIC.Attributes:GetSkillLevel(skill)
                
                local levelLabel = vgui.Create("DLabel", panel)
                levelLabel:SetPos(panel:GetWide() - 60, 8)
                levelLabel:SetText("Have: " .. playerLevel)
                levelLabel:SizeToContents()
                
                -- Color based on whether player meets requirement
                if playerLevel < level then
                    levelLabel:SetTextColor(Color(255, 0, 0))
                else
                    levelLabel:SetTextColor(Color(0, 255, 0))
                end
                
                skillsList:AddItem(panel)
            end
        else
            local panel = vgui.Create("DPanel")
            panel:SetSize(skillsList:GetWide(), 30)
            
            local noSkillLabel = vgui.Create("DLabel", panel)
            noSkillLabel:SetPos(10, 8)
            noSkillLabel:SetText("No skill requirements for this recipe.")
            noSkillLabel:SizeToContents()
            
            skillsList:AddItem(panel)
        end
        
        -- Update craft button state
        local canCraft, reason = ATOMIC.Crafting:CanPlayerCraft(LocalPlayer(), recipeID)
        craftButton:SetEnabled(canCraft)
        
        if canCraft then
            craftButton:SetText("Craft")
        else
            craftButton:SetText("Cannot Craft")
            craftButton:SetTooltip(reason)
        end
    end
    
    -- Handle category selection
    categoryList.OnRowSelected = function(lst, index, pnl)
        local category = pnl:GetValue(1)
        RefreshRecipeList(category)
    end
    
    -- Handle recipe selection
    recipeList.OnRowSelected = function(lst, index, pnl)
        UpdateDetails(pnl.recipeID)
    end
    
    -- Handle craft button
    craftButton.DoClick = function()
        if selectedRecipeID then
            ATOMIC.Crafting:RequestCraft(selectedRecipeID)
            frame:Close()
        end
    end
    
    -- Initial population of the recipe list with "All" category
    RefreshRecipeList("All")
    
    -- Store reference to the menu
    self.Menu = frame
    
    return frame
end

-- Add command to open crafting menu
concommand.Add("atomic_crafting", function()
    ATOMIC.Crafting:OpenMenu()
end)

-- Add crafting to F1 menu
hook.Add("ATOMIC:BuildF1Menu", "ATOMIC:AddCraftingToF1", function(panel, sheet)
    local craftingTab = vgui.Create("DPanel")
    
    local button = vgui.Create("DButton", craftingTab)
    button:SetText("Open Crafting Menu")
    button:SetSize(200, 40)
    button:Center()
    button.DoClick = function()
        ATOMIC.Crafting:OpenMenu()
    end
    
    sheet:AddSheet("Crafting", craftingTab, "icon16/cog.png")
end)
