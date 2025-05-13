-- Client-side attributes implementation

ATOMIC.Attributes.Cache = ATOMIC.Attributes.Cache or {}

-- Receive attribute data from server
net.Receive("ATOMIC:SyncAttributes", function()
    local attributeData = net.ReadTable()
    
    -- Organize attributes by type
    local skills = {}
    local stats = {}
    
    for _, attr in ipairs(attributeData) do
        if attr.type == ATOMIC.AttributeTypes.SKILL then
            skills[attr.attribute] = {
                level = attr.value,
                xp = attr.xp
            }
        elseif attr.type == ATOMIC.AttributeTypes.STAT then
            stats[attr.attribute] = attr.value
        end
    end
    
    -- Update local cache
    ATOMIC.Attributes.Cache = {
        skills = skills,
        stats = stats
    }
    
    -- Notify UI of update
    hook.Run("ATOMIC:AttributesUpdated", skills, stats)
end)

-- Request sync from server
function ATOMIC.Attributes:RequestSync()
    net.Start("ATOMIC:RequestAttributesSync")
    net.SendToServer()
end

-- Reset all attributes
function ATOMIC.Attributes:RequestReset()
    net.Start("ATOMIC:ResetAttributes")
    net.SendToServer()
end

-- Get a skill level from cache
function ATOMIC.Attributes:GetSkillLevel(skill)
    if not self.Cache.skills or not self.Cache.skills[skill] then
        return 0
    end
    
    return self.Cache.skills[skill].level or 0
end

-- Get skill XP from cache
function ATOMIC.Attributes:GetSkillXP(skill)
    if not self.Cache.skills or not self.Cache.skills[skill] then
        return 0
    end
    
    return self.Cache.skills[skill].xp or 0
end

-- Get a stat value from cache
function ATOMIC.Attributes:GetStatValue(stat)
    if not self.Cache.stats or not self.Cache.stats[stat] then
        if self.Stats[stat] then
            return self.Stats[stat].default or 0
        end
        return 0
    end
    
    return self.Cache.stats[stat] or 0
end

-- Get skill progress as a percentage (for progress bars)
function ATOMIC.Attributes:GetSkillProgress(skill)
    local level = self:GetSkillLevel(skill)
    local xp = self:GetSkillXP(skill)
    
    local currentLevelXP = self:GetXPForLevel(level)
    local nextLevelXP = self:GetXPForLevel(level + 1)
    
    if nextLevelXP <= currentLevelXP then
        return 100
    end
    
    local progress = (xp - currentLevelXP) / (nextLevelXP - currentLevelXP) * 100
    return math.Clamp(progress, 0, 100)
end

-- Build the attributes menu UI
function ATOMIC.Attributes:OpenMenu()
    if IsValid(self.Menu) then
        self.Menu:Remove()
    end
    
    -- Create base frame
    local frame = vgui.Create("DFrame")
    frame:SetTitle("Character Attributes")
    frame:SetSize(800, 600)
    frame:Center()
    frame:MakePopup()
    
    -- Setup tabs
    local tabPanel = vgui.Create("DPropertySheet", frame)
    tabPanel:Dock(FILL)
    
    -- Skills tab
    local skillsPanel = vgui.Create("DScrollPanel")
    local skillsList = vgui.Create("DIconLayout", skillsPanel)
    skillsList:Dock(FILL)
    skillsList:SetSpaceY(10)
    skillsList:SetSpaceX(5)
    
    for skillID, skillInfo in pairs(self.Skills) do
        local skillPanel = vgui.Create("DPanel")
        skillPanel:SetSize(skillsList:GetWide(), 80)
        
        local level = self:GetSkillLevel(skillID)
        local xp = self:GetSkillXP(skillID)
        local progress = self:GetSkillProgress(skillID)
        local remaining = self:GetRemainingXP(xp, level)
        
        -- Skill icon
        local icon = vgui.Create("DImage", skillPanel)
        icon:SetPos(5, 5)
        icon:SetSize(32, 32)
        icon:SetImage(skillInfo.icon)
        
        -- Skill name and level
        local nameLabel = vgui.Create("DLabel", skillPanel)
        nameLabel:SetPos(45, 5)
        nameLabel:SetText(skillInfo.name .. " (Level " .. level .. ")")
        nameLabel:SetFont("DermaLarge")
        nameLabel:SizeToContents()
        
        -- Skill description
        local descLabel = vgui.Create("DLabel", skillPanel)
        descLabel:SetPos(45, 30)
        descLabel:SetText(skillInfo.description)
        descLabel:SetFont("DermaDefault")
        descLabel:SizeToContents()
        
        -- Progress bar
        local progressBar = vgui.Create("DProgress", skillPanel)
        progressBar:SetPos(45, 55)
        progressBar:SetSize(skillPanel:GetWide() - 50, 15)
        progressBar:SetFraction(progress / 100)
        
        -- XP info
        local xpInfo = vgui.Create("DLabel", skillPanel)
        xpInfo:SetPos(skillPanel:GetWide() - 100, 35)
        xpInfo:SetText("XP: " .. xp .. " / " .. self:GetXPForLevel(level + 1))
        xpInfo:SizeToContents()
        
        skillsList:Add(skillPanel)
    end
    
    -- Stats tab
    local statsPanel = vgui.Create("DScrollPanel")
    local statsList = vgui.Create("DIconLayout", statsPanel)
    statsList:Dock(FILL)
    statsList:SetSpaceY(10)
    statsList:SetSpaceX(5)
    
    for statID, statInfo in pairs(self.Stats) do
        local statPanel = vgui.Create("DPanel")
        statPanel:SetSize(statsList:GetWide(), 60)
        
        local value = self:GetStatValue(statID)
        local percentage = (value / (statInfo.max or 100)) * 100
        
        -- Stat icon
        local icon = vgui.Create("DImage", statPanel)
        icon:SetPos(5, 5)
        icon:SetSize(32, 32)
        icon:SetImage(statInfo.icon)
        
        -- Stat name and value
        local nameLabel = vgui.Create("DLabel", statPanel)
        nameLabel:SetPos(45, 5)
        nameLabel:SetText(statInfo.name .. " (" .. value .. "/" .. (statInfo.max or 100) .. ")")
        nameLabel:SetFont("DermaLarge")
        nameLabel:SizeToContents()
        
        -- Stat description
        local descLabel = vgui.Create("DLabel", statPanel)
        descLabel:SetPos(45, 30)
        descLabel:SetText(statInfo.description)
        descLabel:SetFont("DermaDefault")
        descLabel:SizeToContents()
        
        -- Progress bar
        local progressBar = vgui.Create("DProgress", statPanel)
        progressBar:SetPos(45, statPanel:GetTall() - 15)
        progressBar:SetSize(statPanel:GetWide() - 50, 10)
        progressBar:SetFraction(percentage / 100)
        
        statsList:Add(statPanel)
    end
    
    -- Add tabs to panel
    tabPanel:AddSheet("Skills", skillsPanel, "icon16/user_gray.png")
    tabPanel:AddSheet("Stats", statsPanel, "icon16/heart.png")
    
    -- Reset button
    local resetButton = vgui.Create("DButton", frame)
    resetButton:SetText("Reset All Attributes (" .. ATOMIC.Attributes.Config.ResetCost .. " money)")
    resetButton:SetPos(frame:GetWide() - 220, frame:GetTall() - 40)
    resetButton:SetSize(200, 30)
    resetButton.DoClick = function()
        Derma_Query(
            "Are you sure you want to reset all your attributes? This will cost " .. ATOMIC.Attributes.Config.ResetCost .. " money.",
            "Confirm Reset",
            "Reset",
            function() 
                self:RequestReset()
            end,
            "Cancel",
            function() end
        )
    end
    
    -- Keep reference
    self.Menu = frame
    
    -- Update attributes immediately
    self:RequestSync()
    
    return frame
end

-- Add command to open attributes menu
concommand.Add("atomic_attributes", function()
    ATOMIC.Attributes:OpenMenu()
end)

-- Initialize when client loads
hook.Add("InitPostEntity", "ATOMIC:RequestAttributesSync", function()
    timer.Simple(2, function()
        ATOMIC.Attributes:RequestSync()
    end)
end)

-- Add attributes to F1 menu
hook.Add("ATOMIC:BuildF1Menu", "ATOMIC:AddAttributesToF1", function(panel, sheet)
    local attributesTab = vgui.Create("DPanel")
    
    local button = vgui.Create("DButton", attributesTab)
    button:SetText("Open Attributes Menu")
    button:SetSize(200, 40)
    button:Center()
    button.DoClick = function()
        ATOMIC.Attributes:OpenMenu()
    end
    
    sheet:AddSheet("Attributes", attributesTab, "icon16/user.png")
end)
