-- Server-side attributes implementation

-- Initialize all attributes for a character
function ATOMIC.Attributes:InitializeCharacter(ply)
    local char = ply:GetCharacter()
    if not char then return end
    
    local charID = char.id
    
    -- Load existing attributes from database
    Database:Model("attributes"):Where({"characterId = ?", charID}):Select():Run(function(data)
        local attributeMap = {}
        
        -- Map existing attributes
        for _, attr in ipairs(data or {}) do
            local key = attr.type .. "_" .. attr.attribute
            attributeMap[key] = attr
        end
        
        -- Initialize skills
        for skillID, skillData in pairs(self.Skills) do
            local key = ATOMIC.AttributeTypes.SKILL .. "_" .. skillID
            if not attributeMap[key] then
                -- Create skill if it doesn't exist
                Database:Model("attributes"):Insert({
                    characterId = charID,
                    type = ATOMIC.AttributeTypes.SKILL,
                    attribute = skillID,
                    value = 0, -- Level starts at 0
                    xp = 0
                }):Run()
            end
        end
        
        -- Initialize stats
        for statID, statData in pairs(self.Stats) do
            local key = ATOMIC.AttributeTypes.STAT .. "_" .. statID
            if not attributeMap[key] then
                -- Create stat if it doesn't exist
                Database:Model("attributes"):Insert({
                    characterId = charID,
                    type = ATOMIC.AttributeTypes.STAT,
                    attribute = statID,
                    value = statData.default or 0,
                    xp = 0
                }):Run()
            end
        end
        
        -- Send attributes to client
        self:SyncCharacterAttributes(ply)
    end)
end

-- Sync all attributes to client
function ATOMIC.Attributes:SyncCharacterAttributes(ply)
    local char = ply:GetCharacter()
    if not char then return end
    
    local charID = char.id
    
    Database:Model("attributes"):Where({"characterId = ?", charID}):Select():Run(function(data)
        if not IsValid(ply) then return end
        
        net.Start("ATOMIC:SyncAttributes")
        net.WriteTable(data or {})
        net.Send(ply)
    end)
end

-- Set an attribute value and synchronize it
function ATOMIC.Attributes:SetAttribute(ply, type, attribute, value, xp)
    local char = ply:GetCharacter()
    if not char then return end
    
    local charID = char.id
    
    Database:Model("attributes"):Where({
        {"characterId = ?", charID}, 
        {"type = ?", type}, 
        {"attribute = ?", attribute}
    }):Select():Run(function(data)
        if not data or #data == 0 then
            -- Create attribute if it doesn't exist
            Database:Model("attributes"):Insert({
                characterId = charID,
                type = type,
                attribute = attribute,
                value = value or 0,
                xp = xp or 0
            }):Run(function()
                self:SyncCharacterAttributes(ply)
            end)
        else
            -- Update existing attribute
            local updateData = {}
            if value ~= nil then updateData.value = value end
            if xp ~= nil then updateData.xp = xp end
            
            Database:Model("attributes"):Where({
                {"characterId = ?", charID}, 
                {"type = ?", type}, 
                {"attribute = ?", attribute}
            }):Update(updateData):Run(function()
                self:SyncCharacterAttributes(ply)
            end)
        end
    end)
end

-- Add XP to a skill and check for level ups
function ATOMIC.Attributes:AddSkillXP(ply, skill, xpAmount)
    if xpAmount <= 0 then return end
    local char = ply:GetCharacter()
    if not char then return end
    
    local charID = char.id
    
    Database:Model("attributes"):Where({
        {"characterId = ?", charID}, 
        {"type = ?", ATOMIC.AttributeTypes.SKILL}, 
        {"attribute = ?", skill}
    }):Select():Run(function(data)
        if not data or #data == 0 then
            -- Create skill if it doesn't exist
            Database:Model("attributes"):Insert({
                characterId = charID,
                type = ATOMIC.AttributeTypes.SKILL,
                attribute = skill,
                value = 0,
                xp = xpAmount
            }):Run(function()
                self:CheckForLevelUp(ply, skill, 0, xpAmount)
                self:SyncCharacterAttributes(ply)
            end)
        else
            -- Update existing skill
            local currentXP = data[1].xp or 0
            local currentLevel = data[1].value or 0
            local newXP = math.min(currentXP + xpAmount, self.Config.MaxXP)
            
            Database:Model("attributes"):Where({
                {"characterId = ?", charID}, 
                {"type = ?", ATOMIC.AttributeTypes.SKILL}, 
                {"attribute = ?", skill}
            }):Update({{"value = ?, xp = ?", currentLevel, newXP}}):Run(function()
                self:CheckForLevelUp(ply, skill, currentLevel, newXP)
                self:SyncCharacterAttributes(ply)
            end)
        end
    end)
end

-- Check if a skill levels up based on XP
function ATOMIC.Attributes:CheckForLevelUp(ply, skill, currentLevel, totalXP)
    local newLevel = self:GetLevelFromXP(totalXP)
    
    if newLevel > currentLevel then
        local char = ply:GetCharacter()
        if not char then return end
        local charID = char.id
        
        -- Update the level
        Database:Model("attributes"):Where({
            {"characterId = ?", charID}, 
            {"type = ?", ATOMIC.AttributeTypes.SKILL}, 
            {"attribute = ?", skill}
        }):Update({{"value = ?", newLevel}}):Run(function()
            -- Notify player of level up
            ply:EmitSound(self.Config.LevelUpSound)
            
            local skillName = (self.Skills[skill] and self.Skills[skill].name) or skill
            ATOMIC:Notify(ply, "Your " .. skillName .. " skill increased to level " .. newLevel .. "!")
            
            self:SyncCharacterAttributes(ply)
            
            -- Fire level up hook for other systems to use
            hook.Run("ATOMIC:PlayerSkillLevelUp", ply, skill, newLevel, currentLevel)
        end)
    end
end

-- Set a stat value (like health, stamina, hunger, thirst)
function ATOMIC.Attributes:SetStatValue(ply, stat, value)
    local maxValue = (self.Stats[stat] and self.Stats[stat].max) or 100
    value = math.Clamp(value, 0, maxValue)
    
    self:SetAttribute(ply, ATOMIC.AttributeTypes.STAT, stat, value)
    
    -- Fire stat changed hook
    hook.Run("ATOMIC:PlayerStatChanged", ply, stat, value)
end

-- Adjust a stat by a delta amount
function ATOMIC.Attributes:AdjustStatValue(ply, stat, delta)
    local char = ply:GetCharacter()
    if not char then return end
    
    local charID = char.id
    
    Database:Model("attributes"):Where({
        {"characterId = ?", charID}, 
        {"type = ?", ATOMIC.AttributeTypes.STAT}, 
        {"attribute = ?", stat}
    }):Select():Run(function(data)
        if not data or #data == 0 then
            -- Create with default value if it doesn't exist
            local defaultValue = (self.Stats[stat] and self.Stats[stat].default) or 0
            local newValue = math.Clamp(defaultValue + delta, 0, (self.Stats[stat] and self.Stats[stat].max) or 100)
            
            self:SetAttribute(ply, ATOMIC.AttributeTypes.STAT, stat, newValue)
        else
            -- Adjust existing stat
            local currentValue = data[1].value or 0
            local maxValue = (self.Stats[stat] and self.Stats[stat].max) or 100
            local newValue = math.Clamp(currentValue + delta, 0, maxValue)
            
            if newValue ~= currentValue then
                self:SetAttribute(ply, ATOMIC.AttributeTypes.STAT, stat, newValue)
            end
        end
    end)
end

-- Attempt to increase a skill based on chance
function ATOMIC.Attributes:AttemptSkillIncrease(ply, skill, difficulty)
    if not self.Skills[skill] then return end
    if not self.Config.BaseXPGain[difficulty] then difficulty = "Medium" end
    
    local chance = self.Config.SkillIncreaseChance
    
    if math.random() <= chance then
        local xpGain = self.Config.BaseXPGain[difficulty]
        self:AddSkillXP(ply, skill, xpGain)
    end
end

-- Reset all attributes for a character
function ATOMIC.Attributes:ResetAttributes(ply)
    local char = ply:GetCharacter()
    if not char then return end
    
    -- Check if player has enough money
    if not ply:CanAfford(self.Config.ResetCost) then
        ATOMIC:Notify(ply, "You need " .. self.Config.ResetCost .. " to reset your attributes!")
        return false
    end
    
    -- Take money
    ply:TakeMoney(self.Config.ResetCost)
    
    local charID = char.id
    
    -- Reset all skills to 0
    Database:Model("attributes"):Where({
        {"characterId = ?", charID}, 
        {"type = ?", ATOMIC.AttributeTypes.SKILL}
    }):Update({{"value = ?, xp = ?", 0, 0}}):Run()
    
    -- Reset all stats to default values
    for statID, statData in pairs(self.Stats) do
        Database:Model("attributes"):Where({
            {"characterId = ?", charID}, 
            {"type = ?", ATOMIC.AttributeTypes.STAT},
            {"attribute = ?", statID}
        }):Update({{"value = ?", statData.default or 0}}):Run()
    end
    
    -- Sync back to client
    self:SyncCharacterAttributes(ply)
    
    ATOMIC:Notify(ply, "Your attributes have been reset!")
    return true
end

-- Setup network strings
util.AddNetworkString("ATOMIC:SyncAttributes")
util.AddNetworkString("ATOMIC:RequestAttributesSync")
util.AddNetworkString("ATOMIC:UseAttributePoint")
util.AddNetworkString("ATOMIC:ResetAttributes")

-- Network request handlers
net.Receive("ATOMIC:RequestAttributesSync", function(len, ply)
    ATOMIC.Attributes:SyncCharacterAttributes(ply)
end)

net.Receive("ATOMIC:ResetAttributes", function(len, ply)
    ATOMIC.Attributes:ResetAttributes(ply)
end)

-- Hook into character changes
hook.Add("ATOMIC:PlayerCharacterLoaded", "ATOMIC:Attributes:LoadCharacter", function(ply, char)
    timer.Simple(0.5, function()
        if IsValid(ply) and ply:GetCharacter() then
            ATOMIC.Attributes:SyncCharacterAttributes(ply)
        end
    end)
end)

-- Apply stat effects periodically
timer.Create("ATOMIC:AttributeStatEffects", 1, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        if not IsValid(ply) or not ply:GetCharacter() then continue end
        
        -- Handle hunger and thirst decrease
        for statID, statData in pairs(ATOMIC.Attributes.Stats) do
            if statData.decreaseRate and statData.decreaseRate > 0 then
                ATOMIC.Attributes:AdjustStatValue(ply, statID, -statData.decreaseRate)
            end
        end
    end
end)

-- Initialize when the attributes module loads
hook.Add("Initialize", "ATOMIC:SetupAttributes", function()
    print("[ATOMIC] Attributes system initialized")
end)
