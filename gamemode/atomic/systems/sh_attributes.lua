AddCSLuaFile()

ATOMIC.Attributes = ATOMIC.Attributes or {}

-- Define attribute types
ATOMIC.AttributeTypes = {
    SKILL = "skill",
    STAT = "stat"
}

-- Default attributes configuration
ATOMIC.Attributes.Config = {
    MaxLevel = 100,
    BaseXP = 100,        -- Base XP needed for level 1
    XPMultiplier = 1.1,  -- XP growth multiplier per level
    MaxXP = 1000000,     -- Maximum XP possible
    ResetCost = 5000,    -- Money cost to reset attributes
    LevelUpSound = "buttons/button14.wav",
    
    -- Skill increase chance per action (0.0 to 1.0)
    SkillIncreaseChance = 0.3,
    
    -- XP gained per action
    BaseXPGain = {
        VeryEasy = 1,
        Easy = 2, 
        Medium = 5,
        Hard = 10,
        VeryHard = 20
    }
}

-- Define default attributes
ATOMIC.Attributes.Skills = {
    strength = {
        name = "Strength",
        description = "Affects how much you can carry and your physical damage",
        icon = "icon16/medal_gold_1.png"
    },
    agility = {
        name = "Agility",
        description = "Affects your movement speed and jumping ability",
        icon = "icon16/lightning.png"
    },
    endurance = {
        name = "Endurance",
        description = "Affects your health and stamina regeneration",
        icon = "icon16/heart.png"
    },
    intelligence = {
        name = "Intelligence",
        description = "Affects crafting abilities and some specialized tasks",
        icon = "icon16/lightbulb.png"
    },
    crafting = {
        name = "Crafting",
        description = "Determines your ability to craft items efficiently",
        icon = "icon16/wrench.png" 
    },
    cooking = {
        name = "Cooking",
        description = "Affects the quality and effects of food you prepare",
        icon = "icon16/cup.png"
    },
    medical = {
        name = "Medical",
        description = "Improves healing abilities and medical crafting",
        icon = "icon16/heart_add.png"
    },
    lockpicking = {
        name = "Lockpicking",
        description = "Affects your ability to pick locks",
        icon = "icon16/lock_open.png"
    },
    hacking = {
        name = "Hacking",
        description = "Affects your ability to hack electronic devices",
        icon = "icon16/computer.png"
    }
}

ATOMIC.Attributes.Stats = {
    health = {
        name = "Health",
        description = "Your maximum health",
        icon = "icon16/heart.png",
        default = 100,
        max = 200
    },
    stamina = {
        name = "Stamina",
        description = "Your ability to sprint and perform physical actions",
        icon = "icon16/lightning.png",
        default = 100,
        max = 200
    },
    hunger = {
        name = "Hunger",
        description = "How hungry you are. Lower is hungrier",
        icon = "icon16/cake.png",
        default = 100,
        max = 100,
        decreaseRate = 0.05 -- % per second
    },
    thirst = {
        name = "Thirst",
        description = "How thirsty you are. Lower is thirstier",
        icon = "icon16/drink.png",
        default = 100,
        max = 100,
        decreaseRate = 0.1 -- % per second
    }
}

-- Calculate XP required for a specific level
function ATOMIC.Attributes:GetXPForLevel(level)
    if level <= 0 then return 0 end
    if level > self.Config.MaxLevel then return self.Config.MaxXP end
    
    local xp = self.Config.BaseXP * math.pow(self.Config.XPMultiplier, level - 1)
    return math.min(math.floor(xp), self.Config.MaxXP)
end

-- Calculate level from XP
function ATOMIC.Attributes:GetLevelFromXP(xp)
    if xp <= 0 then return 0 end
    
    local level = 1
    while level <= self.Config.MaxLevel do
        local requiredXP = self:GetXPForLevel(level)
        if xp < requiredXP then
            return level - 1
        end
        level = level + 1
    end
    
    return self.Config.MaxLevel
end

-- Get attribute bonus effect based on level
function ATOMIC.Attributes:GetAttributeBonus(attributeName, level)
    if not level or level <= 0 then return 0 end
    
    -- Define bonus formulas for each attribute
    local bonuses = {
        strength = level * 0.01,      -- 1% per level
        agility = level * 0.01,       -- 1% per level
        endurance = level * 0.01,     -- 1% per level
        intelligence = level * 0.01,  -- 1% per level
        crafting = level * 0.02,      -- 2% per level
        cooking = level * 0.02,       -- 2% per level
        medical = level * 0.02,       -- 2% per level
        lockpicking = level * 0.015,  -- 1.5% per level
        hacking = level * 0.015,      -- 1.5% per level
        -- Stats are handled differently as they have direct values
    }
    
    return bonuses[attributeName] or 0
end

-- Hook into the framework
hook.Add("ATOMIC:PlayerInitialized", "ATOMIC:Attributes:Initialize", function(ply)
    if SERVER then
        -- Initialize attributes for the player's character
        timer.Simple(1, function()
            if IsValid(ply) and ply:GetCharacter() then
                ATOMIC.Attributes:InitializeCharacter(ply)
            end
        end)
    end
end)

-- Get remaining XP needed to level up
function ATOMIC.Attributes:GetRemainingXP(currentXP, currentLevel)
    local nextLevelXP = self:GetXPForLevel(currentLevel + 1)
    return nextLevelXP - currentXP
end
