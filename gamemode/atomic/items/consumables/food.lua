-- Base food item
ATOMIC:RegisterItem({
    id = "item_food_base",
    name = "Food Item",
    description = "A basic food item.",
    model = "models/props_junk/garbage_bag001a.mdl",
    weight = 0.5,
    category = "Food", 
    type = "Food", -- Add type field for compatibility
    isBase = true,
    foodType = ATOMIC.Survival.FoodTypes.FOOD,
    hungerRestore = 15,
    thirstRestore = 0,
    healthRestore = 0,
    consumeText = "You ate %s.",
    consumeSound = "physics/flesh/flesh_impact_hard1.wav",
    
    -- Use function
    OnUse = function(self, ply)
        if SERVER then
            -- Restore hunger
            if self.hungerRestore > 0 then
                ATOMIC.Survival:RestoreHunger(ply, self.hungerRestore)
            end
            
            -- Restore thirst
            if self.thirstRestore > 0 then
                ATOMIC.Survival:RestoreThirst(ply, self.thirstRestore)
            end
            
            -- Restore health
            if self.healthRestore > 0 then
                ATOMIC.Survival:RestoreHealth(ply, self.healthRestore)
            end
            
            -- Play sound
            if self.consumeSound then
                ply:EmitSound(self.consumeSound)
            end
            
            -- Show message
            if self.consumeText then
                ATOMIC:Notify(ply, string.format(self.consumeText, self.name))
            end
            
            -- Attempt cooking skill increase
            if ATOMIC.Attributes then
                ATOMIC.Attributes:AttemptSkillIncrease(ply, "cooking", "VeryEasy")
            end
            
            return true -- Item consumed successfully
        end
        
        return false -- Item not consumed
    end
})

-- Apple
ATOMIC:RegisterItem({
    id = "item_food_apple",
    baseID = "item_food_base",
    name = "Apple",
    description = "A fresh, juicy apple. Restores a small amount of hunger.",
    model = "models/props/de_inferno/crate_fruit_break_gib2.mdl",
    weight = 0.2,
    price = 10,
    hungerRestore = 10,
    thirstRestore = 5,
})

-- Bread
ATOMIC:RegisterItem({
    id = "item_food_bread",
    baseID = "item_food_base",
    name = "Bread",
    description = "A freshly baked loaf of bread. Restores hunger.",
    model = "models/props_junk/garbage_bag001a.mdl",
    weight = 0.5,
    price = 25,
    hungerRestore = 20,
})

-- Burger
ATOMIC:RegisterItem({
    id = "item_food_burger",
    baseID = "item_food_base",
    name = "Burger",
    description = "A delicious burger. Restores a good amount of hunger.",
    model = "models/food/burger.mdl",
    weight = 0.6,
    price = 40,
    hungerRestore = 30,
})

-- Steak
ATOMIC:RegisterItem({
    id = "item_food_steak",
    baseID = "item_food_base",
    name = "Steak",
    description = "A juicy steak. Restores a large amount of hunger and some health.",
    model = "models/props_junk/garbage_bag001a.mdl",
    weight = 0.8,
    price = 60,
    hungerRestore = 45,
    healthRestore = 5,
})

-- Base drink item
ATOMIC:RegisterItem({
    id = "item_drink_base",
    name = "Drink Item",
    description = "A basic drink item.",
    model = "models/props_junk/garbage_plasticbottle003a.mdl",
    weight = 0.3,
    category = "Drinks",
    type = "Drinks", -- Add type field for compatibility
    isBase = true,
    foodType = ATOMIC.Survival.FoodTypes.DRINK,
    hungerRestore = 0,
    thirstRestore = 15,
    healthRestore = 0,
    consumeText = "You drank %s.",
    consumeSound = "npc/barnacle/barnacle_gulp1.wav",
})

-- Water Bottle
ATOMIC:RegisterItem({
    id = "item_drink_water",
    baseID = "item_drink_base",
    name = "Water Bottle",
    description = "A bottle of clean water. Restores thirst.",
    model = "models/props_junk/PopCan01a.mdl",
    weight = 0.3,
    price = 15,
    thirstRestore = 30,
})

-- Soda
ATOMIC:RegisterItem({
    id = "item_drink_soda",
    baseID = "item_drink_base",
    name = "Soda",
    description = "A fizzy drink. Restores thirst and a small amount of hunger.",
    model = "models/props_junk/PopCan01a.mdl",
    weight = 0.3,
    price = 20,
    thirstRestore = 20,
    hungerRestore = 5,
})

-- Energy Drink
ATOMIC:RegisterItem({
    id = "item_drink_energy",
    baseID = "item_drink_base",
    name = "Energy Drink",
    description = "An energy drink. Restores thirst and gives temporary speed boost.",
    model = "models/props_junk/PopCan01a.mdl",
    weight = 0.3,
    price = 35,
    thirstRestore = 15,
    
    -- Override use function to add speed boost
    OnUse = function(self, ply)
        if SERVER then
            -- Restore thirst
            ATOMIC.Survival:RestoreThirst(ply, self.thirstRestore)
            
            -- Play sound
            ply:EmitSound(self.consumeSound)
            
            -- Show message
            ATOMIC:Notify(ply, string.format(self.consumeText, self.name))
            
            -- Apply speed boost
            local currentRunSpeed = ply:GetRunSpeed()
            ply:SetRunSpeed(currentRunSpeed * 1.2)
            
            -- Reset after 30 seconds
            timer.Create("ATOMIC:EnergyDrink_" .. ply:SteamID64(), 30, 1, function()
                if IsValid(ply) then
                    ply:SetRunSpeed(currentRunSpeed)
                    ATOMIC:Notify(ply, "Your energy boost has worn off.")
                end
            end)
            
            return true
        end
        
        return false
    end
})

-- Medicine item
ATOMIC:RegisterItem({
    id = "item_medicine_bandage",
    name = "Bandage",
    description = "A medical bandage. Restores a small amount of health.",
    model = "models/props_junk/garbage_newspaper001a.mdl",
    weight = 0.2,
    category = "Medical",
    type = "Medical", -- Add type field for compatibility
    foodType = ATOMIC.Survival.FoodTypes.MEDICINE,
    healthRestore = 15,
    consumeText = "You used a %s.",
    consumeSound = "items/medshot4.wav",
    
    OnUse = function(self, ply)
        if SERVER then
            -- Restore health
            ATOMIC.Survival:RestoreHealth(ply, self.healthRestore)
            
            -- Play sound
            ply:EmitSound(self.consumeSound)
            
            -- Show message
            ATOMIC:Notify(ply, string.format(self.consumeText, self.name))
            
            -- Attempt medical skill increase
            if ATOMIC.Attributes then
                ATOMIC.Attributes:AttemptSkillIncrease(ply, "medical", "Easy")
            end
            
            return true
        end
        
        return false
    end
})

-- First Aid Kit
ATOMIC:RegisterItem({
    id = "item_medicine_firstaid",
    name = "First Aid Kit",
    description = "A first aid kit. Restores a significant amount of health.",
    model = "models/items/healthkit.mdl",
    weight = 1.0,
    category = "Medical",
    type = "Medical", -- Add type field for compatibility
    price = 75,
    foodType = ATOMIC.Survival.FoodTypes.MEDICINE,
    healthRestore = 50,
    consumeText = "You used a %s.",
    consumeSound = "items/medshot4.wav",
    
    OnUse = function(self, ply)
        if SERVER then
            -- Restore health
            ATOMIC.Survival:RestoreHealth(ply, self.healthRestore)
            
            -- Play sound
            ply:EmitSound(self.consumeSound)
            
            -- Show message
            ATOMIC:Notify(ply, string.format(self.consumeText, self.name))
            
            -- Attempt medical skill increase
            if ATOMIC.Attributes then
                ATOMIC.Attributes:AttemptSkillIncrease(ply, "medical", "Medium")
            end
            
            return true
        end
        
        return false
    end
})
