-- Player movement affected by attributes

-- Store the default movement speeds
local defaultWalkSpeed = ATOMIC.Config.PlayerBaseWalkSpeed
local defaultRunSpeed = ATOMIC.Config.PlayerBaseRunSpeed
local defaultJumpPower = ATOMIC.Config.PlayerBaseJumpPower
local defaultCrouchSpeed = ATOMIC.Config.PlayerBaseCrouchSpeed

-- Timer to handle stamina regeneration
local staminaRegenRate = 1 -- % per second when not sprinting
local staminaUseRate = 3   -- % per second when sprinting

-- Apply attribute effects to player movement
hook.Add("PlayerSpawn", "ATOMIC:SetupPlayerMovement", function(ply)
    if not IsValid(ply) or not ply:GetCharacter() then return end
    
    -- Set base speeds
    ply:SetWalkSpeed(defaultWalkSpeed)
    ply:SetRunSpeed(defaultRunSpeed)
    ply:SetJumpPower(defaultJumpPower)
    ply:SetCrouchedWalkSpeed(defaultCrouchSpeed)
    
    -- Apply attribute bonuses if attribute system is enabled
    timer.Simple(1, function()
        if not IsValid(ply) or not ply:GetCharacter() then return end
        
        -- Apply attribute bonuses if available
        if ATOMIC.Attributes then
            local agilityLevel = 0
            local strengthLevel = 0
            local enduranceLevel = 0
            
            Database:Model("attributes"):Where(
                {"characterId = ?", ply:GetCharacter()}, 
                {"type = ?", ATOMIC.AttributeTypes.SKILL}
            ):Select():Run(function(data)
                if data then
                    for _, attr in ipairs(data) do
                        if attr.attribute == "agility" then
                            agilityLevel = attr.value
                        elseif attr.attribute == "strength" then
                            strengthLevel = attr.value
                        elseif attr.attribute == "endurance" then
                            enduranceLevel = attr.value
                        end
                    end
                    
                    -- Apply speed bonuses based on agility
                    local agilityBonus = ATOMIC.Attributes:GetAttributeBonus("agility", agilityLevel)
                    local strengthBonus = ATOMIC.Attributes:GetAttributeBonus("strength", strengthLevel)
                    local enduranceBonus = ATOMIC.Attributes:GetAttributeBonus("endurance", enduranceLevel)
                    
                    -- Apply walk/run speed bonus (agility)
                    local newWalkSpeed = defaultWalkSpeed * (1 + agilityBonus)
                    local newRunSpeed = defaultRunSpeed * (1 + agilityBonus)
                    ply:SetWalkSpeed(newWalkSpeed)
                    ply:SetRunSpeed(newRunSpeed)
                    
                    -- Apply jump power bonus (combination of strength and agility)
                    local jumpBonus = (strengthBonus + agilityBonus) / 2
                    local newJumpPower = defaultJumpPower * (1 + jumpBonus)
                    ply:SetJumpPower(newJumpPower)
                    
                    -- Store these values for later reference
                    ply.AtomicMovementStats = {
                        walkSpeed = newWalkSpeed,
                        runSpeed = newRunSpeed,
                        jumpPower = newJumpPower,
                        agilityLevel = agilityLevel,
                        strengthLevel = strengthLevel,
                        enduranceLevel = enduranceLevel
                    }
                end
            end)
        end
    end)
end)

-- Handle sprinting and stamina
hook.Add("KeyPress", "ATOMIC:SprintAndStamina", function(ply, key)
    if not IsValid(ply) or not ply:GetCharacter() then return end
    if not ATOMIC.Attributes then return end
    
    -- Check if player is sprinting
    if key == IN_SPEED then
        ply.IsSprinting = true
    end
end)

hook.Add("KeyRelease", "ATOMIC:SprintAndStaminaRelease", function(ply, key)
    if not IsValid(ply) or not ply:GetCharacter() then return end
    
    -- Check if player stopped sprinting
    if key == IN_SPEED then
        ply.IsSprinting = false
    end
end)

-- Handle stamina consumption and regeneration
timer.Create("ATOMIC:StaminaHandler", 0.5, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        if not IsValid(ply) or not ply:GetCharacter() then continue end
        if not ATOMIC.Attributes then continue end
        
        local isMoving = ply:GetVelocity():Length() > 10
        local isSprinting = ply.IsSprinting and isMoving
        
        -- Get endurance level for bonus calculations
        local enduranceLevel = 0
        local enduranceBonus = 0
        
        if ply.AtomicMovementStats and ply.AtomicMovementStats.enduranceLevel then
            enduranceLevel = ply.AtomicMovementStats.enduranceLevel
            enduranceBonus = ATOMIC.Attributes:GetAttributeBonus("endurance", enduranceLevel)
        end
        
        -- Handle sprinting stamina consumption
        if isSprinting then
            -- Reduce stamina
            local staminaReduction = staminaUseRate * (1 - enduranceBonus * 0.5) * 0.5 -- 0.5 factor for the timer interval
            ATOMIC.Attributes:AdjustStatValue(ply, "stamina", -staminaReduction)
            
            -- Check if out of stamina
            ATOMIC.Attributes:GetStatValue(ply, "stamina", function(stamina)
                if stamina < 10 then
                    -- Force player to stop sprinting if stamina too low
                    ply:SetRunSpeed(ply:GetWalkSpeed() * 0.8)
                else
                    -- Restore normal run speed
                    if ply.AtomicMovementStats and ply.AtomicMovementStats.runSpeed then
                        ply:SetRunSpeed(ply.AtomicMovementStats.runSpeed)
                    else
                        ply:SetRunSpeed(defaultRunSpeed)
                    end
                end
            end)
        else
            -- Regenerate stamina when not sprinting
            local staminaIncrease = staminaRegenRate * (1 + enduranceBonus) * 0.5 -- 0.5 factor for the timer interval
            ATOMIC.Attributes:AdjustStatValue(ply, "stamina", staminaIncrease)
            
            -- Restore run speed if it was reduced
            if ply.AtomicMovementStats and ply.AtomicMovementStats.runSpeed then
                ply:SetRunSpeed(ply.AtomicMovementStats.runSpeed)
            end
        end
        
        -- Handle hunger/thirst effects on movement
        ATOMIC.Attributes:GetStatValue(ply, "hunger", function(hunger)
            ATOMIC.Attributes:GetStatValue(ply, "thirst", function(thirst)
                local hungerPenalty = 0
                local thirstPenalty = 0
                
                -- Apply penalties for low hunger/thirst
                if hunger < 20 then
                    hungerPenalty = 0.3
                elseif hunger < 40 then
                    hungerPenalty = 0.15
                end
                
                if thirst < 20 then
                    thirstPenalty = 0.4
                elseif thirst < 40 then
                    thirstPenalty = 0.2
                end
                
                local totalPenalty = hungerPenalty + thirstPenalty
                
                -- Apply movement penalties
                if totalPenalty > 0 and ply.AtomicMovementStats then
                    local baseWalk = ply.AtomicMovementStats.walkSpeed or defaultWalkSpeed
                    local baseRun = ply.AtomicMovementStats.runSpeed or defaultRunSpeed
                    
                    ply:SetWalkSpeed(baseWalk * (1 - totalPenalty))
                    ply:SetRunSpeed(baseRun * (1 - totalPenalty))
                end
            end)
        end)
    end
end)

-- Apply attribute levels when they change
hook.Add("ATOMIC:PlayerSkillLevelUp", "ATOMIC:UpdateMovementAttributes", function(ply, skill, newLevel)
    if not IsValid(ply) then return end
    
    -- Update movement stats when relevant skills increase
    if skill == "agility" or skill == "strength" or skill == "endurance" then
        -- Create or update the movement stats table
        ply.AtomicMovementStats = ply.AtomicMovementStats or {}
        
        -- Track the new level
        if skill == "agility" then
            ply.AtomicMovementStats.agilityLevel = newLevel
        elseif skill == "strength" then
            ply.AtomicMovementStats.strengthLevel = newLevel
        elseif skill == "endurance" then
            ply.AtomicMovementStats.enduranceLevel = newLevel
        end
        
        -- Recalculate bonuses
        local agilityBonus = ATOMIC.Attributes:GetAttributeBonus("agility", ply.AtomicMovementStats.agilityLevel or 0)
        local strengthBonus = ATOMIC.Attributes:GetAttributeBonus("strength", ply.AtomicMovementStats.strengthLevel or 0)
        local enduranceBonus = ATOMIC.Attributes:GetAttributeBonus("endurance", ply.AtomicMovementStats.enduranceLevel or 0)
        
        -- Apply the new speeds
        local newWalkSpeed = defaultWalkSpeed * (1 + agilityBonus)
        local newRunSpeed = defaultRunSpeed * (1 + agilityBonus)
        local jumpBonus = (strengthBonus + agilityBonus) / 2
        local newJumpPower = defaultJumpPower * (1 + jumpBonus)
        
        ply:SetWalkSpeed(newWalkSpeed)
        ply:SetRunSpeed(newRunSpeed)
        ply:SetJumpPower(newJumpPower)
        
        -- Store the new values
        ply.AtomicMovementStats.walkSpeed = newWalkSpeed
        ply.AtomicMovementStats.runSpeed = newRunSpeed
        ply.AtomicMovementStats.jumpPower = newJumpPower
    end
end)

-- Fix for ATOMIC.Attributes:GetStatValue function
function ATOMIC.Attributes:GetStatValue(ply, stat, callback)
    local char = ply:GetCharacter()
    if not char then
        if callback then callback(0) end
        return
    end
    
    local charID = char
    
    Database:Model("attributes"):Where(
        {"characterId = ?", charID}, 
        {"type = ?", ATOMIC.AttributeTypes.STAT}, 
        {"attribute = ?", stat}
    ):Select():Run(function(data)
        if not data or #data == 0 then
            -- Return default value if stat not found
            local defaultValue = (self.Stats[stat] and self.Stats[stat].default) or 0
            if callback then callback(defaultValue) end
            return
        end
        
        if callback then callback(data[1].value) end
    end)
end
