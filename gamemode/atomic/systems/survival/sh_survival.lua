AddCSLuaFile()

ATOMIC.Survival = ATOMIC.Survival or {}

-- Survival system configuration
ATOMIC.Survival.Config = {
    -- Hunger and thirst settings
    EnableHunger = true,
    EnableThirst = true,
    
    -- Decrease rates (% per second)
    HungerDecreaseRate = 0.05,
    ThirstDecreaseRate = 0.08,
    
    -- Damage thresholds
    HungerDamageThreshold = 10, -- Start taking damage when below this value
    ThirstDamageThreshold = 5,  -- Start taking damage when below this value
    
    -- Damage intervals (seconds)
    DamageInterval = 15,
    
    -- Damage amount
    HungerDamage = 1,
    ThirstDamage = 2,
    
    -- Death enabled? If false, will never go below 1 HP
    AllowDeath = true,
    
    -- Messages
    HungerMessages = {
        [30] = "You're starting to feel hungry.",
        [15] = "You're very hungry. You need to eat something soon.",
        [5] = "You're starving! Find food immediately!"
    },
    
    ThirstMessages = {
        [30] = "You're starting to feel thirsty.",
        [15] = "You're very thirsty. You need to drink something soon.",
        [5] = "You're severely dehydrated! Find water immediately!"
    }
}

-- Food item base definitions
ATOMIC.Survival.FoodTypes = {
    FOOD = "food",
    DRINK = "drink",
    MEDICINE = "medicine"
}

-- Restore a player's hunger
function ATOMIC.Survival:RestoreHunger(ply, amount)
    if not ATOMIC.Attributes or not IsValid(ply) or not ply:GetCharacter() then return false end
    
    if SERVER then
        ATOMIC.Attributes:AdjustStatValue(ply, "hunger", amount)
        return true
    end
    
    return false
end

-- Restore a player's thirst
function ATOMIC.Survival:RestoreThirst(ply, amount)
    if not ATOMIC.Attributes or not IsValid(ply) or not ply:GetCharacter() then return false end
    
    if SERVER then
        ATOMIC.Attributes:AdjustStatValue(ply, "thirst", amount)
        return true
    end
    
    return false
end

-- Restore a player's health
function ATOMIC.Survival:RestoreHealth(ply, amount)
    if not IsValid(ply) or not ply:GetCharacter() then return false end
    
    if SERVER then
        local newHealth = math.min(ply:Health() + amount, 100)
        ply:SetHealth(newHealth)
        return true
    end
    
    return false
end

if SERVER then
    -- Initialize the survival system
    hook.Add("PlayerSpawn", "ATOMIC:InitializeSurvival", function(ply)
        if not IsValid(ply) or not ply:GetCharacter() then return end
        
        -- Reset hunger and thirst to default values when spawning
        timer.Simple(1, function()
            if not IsValid(ply) or not ply:GetCharacter() then return end
            
            if ATOMIC.Attributes then
                -- Reset to full values
                ATOMIC.Attributes:SetAttribute(ply, ATOMIC.AttributeTypes.STAT, "hunger", 100)
                ATOMIC.Attributes:SetAttribute(ply, ATOMIC.AttributeTypes.STAT, "thirst", 100)
                
                -- Update the decrease rates based on config
                if ATOMIC.Survival.Config.EnableHunger then
                    ATOMIC.Attributes.Stats.hunger.decreaseRate = ATOMIC.Survival.Config.HungerDecreaseRate
                else
                    ATOMIC.Attributes.Stats.hunger.decreaseRate = 0
                end
                
                if ATOMIC.Survival.Config.EnableThirst then
                    ATOMIC.Attributes.Stats.thirst.decreaseRate = ATOMIC.Survival.Config.ThirstDecreaseRate
                else
                    ATOMIC.Attributes.Stats.thirst.decreaseRate = 0
                end
                
                -- Sync to client
                ATOMIC.Attributes:SyncCharacterAttributes(ply)
            end
        end)
    end)
    
    -- Handle hunger and thirst damage effects
    timer.Create("ATOMIC:SurvivalDamageEffects", ATOMIC.Survival.Config.DamageInterval, 0, function()
        for _, ply in ipairs(player.GetAll()) do
            if not IsValid(ply) or not ply:GetCharacter() or not ply:Alive() then continue end
            if not ATOMIC.Attributes then continue end
            
            -- Check hunger level
            ATOMIC.Attributes:GetStatValue(ply, "hunger", function(hunger)
                -- Show notification for reaching specific thresholds
                for threshold, message in pairs(ATOMIC.Survival.Config.HungerMessages) do
                    if hunger <= threshold and hunger > threshold - 1 then
                        ATOMIC:Notify(ply, message)
                    end
                end
                
                -- Apply damage if below threshold
                if hunger < ATOMIC.Survival.Config.HungerDamageThreshold then
                    local newHealth = ply:Health() - ATOMIC.Survival.Config.HungerDamage
                    
                    if newHealth <= 0 and not ATOMIC.Survival.Config.AllowDeath then
                        newHealth = 1
                    end
                    
                    if newHealth > 0 then
                        ply:SetHealth(newHealth)
                    else
                        -- Kill player from starvation
                        local dmgInfo = DamageInfo()
                        dmgInfo:SetDamageType(DMG_STARVE)
                        dmgInfo:SetDamage(100)
                        dmgInfo:SetAttacker(game.GetWorld())
                        ply:TakeDamageInfo(dmgInfo)
                    end
                end
            end)
            
            -- Check thirst level
            ATOMIC.Attributes:GetStatValue(ply, "thirst", function(thirst)
                -- Show notification for reaching specific thresholds
                for threshold, message in pairs(ATOMIC.Survival.Config.ThirstMessages) do
                    if thirst <= threshold and thirst > threshold - 1 then
                        ATOMIC:Notify(ply, message)
                    end
                end
                
                -- Apply damage if below threshold
                if thirst < ATOMIC.Survival.Config.ThirstDamageThreshold then
                    local newHealth = ply:Health() - ATOMIC.Survival.Config.ThirstDamage
                    
                    if newHealth <= 0 and not ATOMIC.Survival.Config.AllowDeath then
                        newHealth = 1
                    end
                    
                    if newHealth > 0 then
                        ply:SetHealth(newHealth)
                    else
                        -- Kill player from dehydration
                        local dmgInfo = DamageInfo()
                        dmgInfo:SetDamageType(DMG_DROWNRECOVER)
                        dmgInfo:SetDamage(100)
                        dmgInfo:SetAttacker(game.GetWorld())
                        ply:TakeDamageInfo(dmgInfo)
                    end
                end
            end)
        end
    end)
end
