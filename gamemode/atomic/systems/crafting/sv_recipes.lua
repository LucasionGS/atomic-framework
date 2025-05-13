-- Basic crafting recipes

-- Food recipes
ATOMIC.Crafting:RegisterRecipe({
    id = "recipe_burger",
    name = "Burger",
    description = "Craft a delicious burger from raw ingredients.",
    category = "Food",
    difficulty = "Medium",
    craftingSkill = "cooking",
    craftSound = "physics/flesh/flesh_squishy_impact_hard3.wav",
    
    ingredients = {
        { id = "item_raw_meat", amount = 1 },
        { id = "item_food_bread", amount = 1 }
    },
    
    result = {
        id = "item_food_burger",
        amount = 1
    },
    
    skillRequirements = {
        cooking = 2
    }
})

-- Bandage recipe
ATOMIC.Crafting:RegisterRecipe({
    id = "recipe_bandage",
    name = "Bandage",
    description = "Craft a basic bandage from cloth.",
    category = "Medical",
    difficulty = "Easy",
    craftingSkill = "medical",
    craftSound = "physics/cardboard/cardboard_box_break1.wav",
    
    ingredients = {
        { id = "item_cloth", amount = 2 }
    },
    
    result = {
        id = "item_medicine_bandage",
        amount = 1
    }
})

-- First Aid Kit recipe
ATOMIC.Crafting:RegisterRecipe({
    id = "recipe_firstaid",
    name = "First Aid Kit",
    description = "Craft a more advanced medical kit.",
    category = "Medical",
    difficulty = "Medium",
    craftingSkill = "medical",
    craftSound = "physics/cardboard/cardboard_box_break1.wav",
    
    ingredients = {
        { id = "item_medicine_bandage", amount = 3 },
        { id = "item_cloth", amount = 2 },
        { id = "item_alcohol", amount = 1 }
    },
    
    result = {
        id = "item_medicine_firstaid",
        amount = 1
    },
    
    skillRequirements = {
        medical = 5
    }
})

-- Add some basic material items
ATOMIC:RegisterItem({
    id = "item_raw_meat",
    name = "Raw Meat",
    description = "Raw, uncooked meat. Needs to be cooked before eating.",
    model = "models/props_junk/garbage_bag001a.mdl",
    weight = 0.5,
    category = "Materials",
    price = 20
})

ATOMIC:RegisterItem({
    id = "item_cloth",
    name = "Cloth",
    description = "A piece of fabric. Used in crafting.",
    model = "models/props_junk/garbage_newspaper001a.mdl",
    weight = 0.2,
    category = "Materials",
    price = 10
})

ATOMIC:RegisterItem({
    id = "item_alcohol",
    name = "Medical Alcohol",
    description = "Used for disinfecting wounds and crafting medical items.",
    model = "models/props_junk/glassbottle01a.mdl",
    weight = 0.3,
    category = "Materials",
    price = 15
})

-- Advanced healing item recipe
ATOMIC:RegisterItem({
    id = "item_medicine_advanced",
    name = "Advanced Medical Kit",
    description = "A highly advanced medical kit that fully restores health.",
    model = "models/Items/HealthKit.mdl",
    weight = 1.5,
    category = "Medical",
    price = 200,
    foodType = ATOMIC.Survival.FoodTypes.MEDICINE,
    healthRestore = 100,
    consumeText = "You used an %s.",
    consumeSound = "items/medshot4.wav",
    
    OnUse = function(self, ply)
        if SERVER then
            -- Fully restore health
            ply:SetHealth(100)
            
            -- Play sound
            ply:EmitSound(self.consumeSound)
            
            -- Show message
            ATOMIC:Notify(ply, string.format(self.consumeText, self.name))
            
            -- Attempt significant medical skill increase
            if ATOMIC.Attributes then
                ATOMIC.Attributes:AttemptSkillIncrease(ply, "medical", "Hard")
            end
            
            return true
        end
        
        return false
    end
})

ATOMIC.Crafting:RegisterRecipe({
    id = "recipe_advanced_medkit",
    name = "Advanced Medical Kit",
    description = "Craft a highly advanced medical kit for full health restoration.",
    category = "Medical",
    difficulty = "Hard",
    craftingSkill = "medical",
    craftSound = "physics/cardboard/cardboard_box_break1.wav",
    
    ingredients = {
        { id = "item_medicine_firstaid", amount = 2 },
        { id = "item_alcohol", amount = 3 },
        { id = "item_cloth", amount = 5 }
    },
    
    result = {
        id = "item_medicine_advanced",
        amount = 1
    },
    
    skillRequirements = {
        medical = 10
    }
})
