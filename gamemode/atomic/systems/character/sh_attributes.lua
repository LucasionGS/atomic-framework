--[[
    Shared attributes and skills system for the gamemode.
    This defines the attributes and skills available to players.

    Skills are learned and improved through use, whereas attributes/genetics
    are inherent characteristics that can be upgraded with special items or events.
]]--

-- Define the skills table
ATOMIC.Skills = {
    ["cooking"] = {
        order = 1,
        name = "Cooking",
        description = "Your ability to prepare food. Higher levels allow crafting more complex recipes.",
        icon = "icon16/cake.png",
        color = Color(255, 165, 0),
        max = 10
    },
    ["crafting"] = {
        order = 2,
        name = "Crafting",
        description = "Your ability to craft items. Higher levels allow crafting more complex items.",
        icon = "icon16/wrench.png",
        color = Color(50, 50, 200),
        max = 10
    },
    ["driving"] = {
        order = 3,
        name = "Driving",
        description = "Your ability to handle vehicles. Higher levels improve handling and acceleration.",
        icon = "icon16/car.png",
        color = Color(50, 200, 50),
        max = 10
    },
    ["fitness"] = {
        order = 4,
        name = "Fitness",
        description = "Your physical fitness. Higher levels increase stamina and running speed.",
        icon = "icon16/user_go.png",
        color = Color(200, 50, 50),
        max = 10
    },
    ["first_aid"] = {
        order = 5,
        name = "First Aid",
        description = "Your ability to provide medical aid. Higher levels improve healing effectiveness.",
        icon = "icon16/heart.png",
        color = Color(158, 0, 0),
        max = 10,
        hideEmpty = true
    },
    ["hardiness"] = {
        order = 6,
        name = "Hardiness",
        description = "Your resistance to damage and environmental effects. Higher levels increase health.",
        icon = "icon16/shield.png",
        color = Color(158, 0, 0),
        max = 10,
        hideEmpty = true
    },
    ["lock_picking"] = {
        order = 7,
        name = "Lock Picking",
        description = "Your ability to pick locks. Higher levels allow picking more complex locks.",
        icon = "icon16/key.png",
        color = Color(158, 0, 0),
        max = 10,
        hideEmpty = true
    },
    ["unarmed_combat"] = {
        order = 8,
        name = "Unarmed Combat",
        description = "Your ability in hand-to-hand combat. Higher levels increase damage with fists.",
        icon = "icon16/user_red.png",
        color = Color(158, 0, 0),
        max = 10
    },
    ["pistol_mark"] = {
        order = 9,
        name = "Pistol Marksman",
        description = "Your accuracy with pistols. Higher levels improve accuracy and reduce recoil.",
        icon = "icon16/gun.png",
        color = Color(158, 0, 0),
        max = 10,
        hideEmpty = true
    },
    ["smg_mark"] = {
        order = 10,
        name = "SMG Marksman",
        description = "Your accuracy with submachine guns. Higher levels improve accuracy and reduce recoil.",
        icon = "icon16/gun.png",
        color = Color(158, 0, 0),
        max = 10,
        hideEmpty = true
    },
    ["shotgun_mark"] = {
        order = 11,
        name = "Shotgun Marksman",
        description = "Your accuracy with shotguns. Higher levels improve accuracy and reduce recoil.",
        icon = "icon16/gun.png",
        color = Color(158, 0, 0),
        max = 10,
        hideEmpty = true
    },
    ["rifle_mark"] = {
        order = 12,
        name = "Rifle Marksman",
        description = "Your accuracy with rifles. Higher levels improve accuracy and reduce recoil.",
        icon = "icon16/gun.png",
        color = Color(158, 0, 0),
        max = 10,
        hideEmpty = true
    },
    ["weed_expert"] = {
        order = 14,
        name = "Weed Expertise",
        description = "Your knowledge of growing and processing marijuana. Higher levels increase yield quality.",
        icon = "icon16/asterisk_yellow.png",
        color = Color(0, 158, 0),
        max = 10,
        hidden = true
    },
    ["mushroom_expert"] = {
        order = 15,
        name = "Mushroom Expertise",
        description = "Your knowledge of growing and processing mushrooms. Higher levels increase yield quality.",
        icon = "icon16/asterisk_orange.png",
        color = Color(158, 80, 0),
        max = 10,
        hidden = true
    },
    ["meth_expert"] = {
        order = 16,
        name = "Meth Expertise",
        description = "Your knowledge of synthesizing methamphetamine. Higher levels increase yield purity.",
        icon = "icon16/asterisk_blue.png",
        color = Color(0, 80, 158),
        max = 10,
        hidden = true
    },
}

-- Define genetics/attributes table
ATOMIC.Genetics = {
    ["strength"] = {
        order = 1,
        name = "Strength",
        description = "Your physical strength. Affects carrying capacity and melee damage.",
        icon = "icon16/brick.png",
        color = Color(255, 0, 0),
        max = 5
    },
    ["intelligence"] = {
        order = 2,
        name = "Intelligence",
        description = "Your mental capacity. Affects crafting success and XP gain.",
        icon = "icon16/lightbulb.png",
        color = Color(0, 0, 255),
        max = 5
    },
    ["dexterity"] = {
        order = 3,
        name = "Dexterity",
        description = "Your physical agility and coordination. Affects movement speed and accuracy.",
        icon = "icon16/arrow_in.png",
        color = Color(0, 255, 0),
        max = 5
    },
    ["influence"] = {
        order = 4,
        name = "Influence",
        description = "Your social aptitude. Affects prices and interactions with NPCs.",
        icon = "icon16/user_comment.png",
        color = Color(255, 255, 0),
        max = 5
    },
    ["perception"] = {
        order = 5,
        name = "Perception",
        description = "Your awareness of surroundings. Affects detection range and detail visibility.",
        icon = "icon16/eye.png",
        color = Color(255, 0, 255),
        max = 5
    },
}

-- Player meta functions for working with attributes
local playerMeta = FindMetaTable("Player")

-- Get skill level
function playerMeta:GetSkillLevel(skill)
    return self:GetNWInt("char_skill_" .. skill, 0)
end

-- Get skill XP
function playerMeta:GetSkillXP(skill)
    return self:GetNWInt("char_skill_xp_" .. skill, 0)
end

-- Get genetic attribute level
function playerMeta:GetGeneLevel(gene)
    return self:GetNWInt("char_gene_" .. gene, 0)
end

-- Check if player has at least the specified level in a skill
function playerMeta:HasSkill(skill, level)
    return self:GetSkillLevel(skill) >= (level or 1)
end

-- Get all attributes (both skills and genetics)
function playerMeta:GetAttributes()
    local attributes = {}
    
    -- Skills
    attributes.skills = {}
    for skillID, _ in pairs(ATOMIC.Skills) do
        attributes.skills[skillID] = {
            value = self:GetSkillLevel(skillID),
            xp = self:GetSkillXP(skillID)
        }
    end
    
    -- Genetics
    attributes.genes = {}
    for geneID, _ in pairs(ATOMIC.Genetics) do
        attributes.genes[geneID] = {
            value = self:GetGeneLevel(geneID)
        }
    end
    
    return attributes
end

-- Calculate the XP needed for a specific skill level
function ATOMIC:GetXPForLevel(level)
    -- Exponential XP curve: 100 * level^2
    return 100 * (level * level)
end
