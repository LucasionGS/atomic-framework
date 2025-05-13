--[[
    Server-side attributes and skills system.
    This handles setting, updating, and persisting player attributes.
]]--

-- Network strings
util.AddNetworkString("ATOMIC:AttributeUpdate")
util.AddNetworkString("ATOMIC:AttributeXPGain")
util.AddNetworkString("ATOMIC:OpenSkillsMenu")

-- Initialize database tables
hook.Add("ATOMIC:DatabaseInitialized", "ATOMIC:InitAttributesTables", function()
    ATOMIC.DB:CreateTable("attributes", {
        { name = "id", type = "INTEGER PRIMARY KEY AUTOINCREMENT" },
        { name = "steamid", type = "VARCHAR(32)" },
        { name = "type", type = "VARCHAR(16)" },
        { name = "attribute", type = "VARCHAR(32)" },
        { name = "value", type = "INTEGER" },
        { name = "xp", type = "INTEGER" },
    })

    -- Create indexes
    ATOMIC.DB:Query("CREATE INDEX IF NOT EXISTS idx_attributes_steamid ON attributes (steamid)")
    ATOMIC.DB:Query("CREATE INDEX IF NOT EXISTS idx_attributes_type ON attributes (type)")
end)

-- Load player attributes when character is loaded
hook.Add("ATOMIC:PlayerCharacterLoaded", "ATOMIC:LoadPlayerAttributes", function(ply)
    ATOMIC:LoadPlayerAttributes(ply)
end)

-- Load player attributes from database
function ATOMIC:LoadPlayerAttributes(ply)
    local steamID = ply:SteamID64()
    
    local query = ATOMIC.DB:Query("SELECT * FROM attributes WHERE steamid = ? AND (type = 'skill' OR type = 'gene')")
    query:SetString(1, steamID)
    
    query:OnSuccess(function(data)
        if not IsValid(ply) then return end
        
        -- Reset all attribute values first to ensure we don't have stale data
        for skillID, _ in pairs(ATOMIC.Skills) do
            ply:SetNWInt("char_skill_" .. skillID, 0)
            ply:SetNWInt("char_skill_xp_" .. skillID, 0)
        end
        
        for geneID, _ in pairs(ATOMIC.Genetics) do
            ply:SetNWInt("char_gene_" .. geneID, 0)
        end
        
        -- Apply loaded attributes
        for _, attribute in pairs(data) do
            if attribute.type == "skill" then
                ply:SetNWInt("char_skill_" .. attribute.attribute, attribute.value)
                ply:SetNWInt("char_skill_xp_" .. attribute.attribute, attribute.xp)
            elseif attribute.type == "gene" then
                ply:SetNWInt("char_gene_" .. attribute.attribute, attribute.value)
            end
        end
        
        -- Create default attributes if they don't exist
        for skillID, _ in pairs(ATOMIC.Skills) do
            if ply:GetSkillLevel(skillID) == 0 and ply:GetSkillXP(skillID) == 0 then
                ATOMIC:CreateAttribute(ply, "skill", skillID, 0, 0)
            end
        end
        
        for geneID, _ in pairs(ATOMIC.Genetics) do
            if ply:GetGeneLevel(geneID) == 0 then
                ATOMIC:CreateAttribute(ply, "gene", geneID, 0, 0)
            end
        end
    end)
    
    query:OnError(function(err)
        ATOMIC:Error("Error loading attributes for player " .. ply:Nick() .. ": " .. err)
    end)
    
    query:Start()
end

-- Create a new attribute
function ATOMIC:CreateAttribute(ply, attributeType, attributeID, value, xp)
    local steamID = ply:SteamID64()
    
    local query = ATOMIC.DB:Query("INSERT INTO attributes (steamid, type, attribute, value, xp) VALUES (?, ?, ?, ?, ?)")
    query:SetString(1, steamID)
    query:SetString(2, attributeType)
    query:SetString(3, attributeID)
    query:SetNumber(4, value or 0)
    query:SetNumber(5, xp or 0)
    
    query:OnSuccess(function()
        ATOMIC:Debug("Created attribute " .. attributeID .. " for player " .. ply:Nick())
    end)
    
    query:OnError(function(err)
        ATOMIC:Error("Error creating attribute " .. attributeID .. " for player " .. ply:Nick() .. ": " .. err)
    end)
    
    query:Start()
end

-- Set attribute value
function ATOMIC:SetAttribute(ply, attributeType, attributeID, value, xp)
    local steamID = ply:SteamID64()
    
    -- Update client network vars immediately
    if attributeType == "skill" then
        ply:SetNWInt("char_skill_" .. attributeID, value)
        if xp then ply:SetNWInt("char_skill_xp_" .. attributeID, xp) end
    elseif attributeType == "gene" then
        ply:SetNWInt("char_gene_" .. attributeID, value)
    end
    
    -- Create the query
    local query
    if xp then
        query = ATOMIC.DB:Query("UPDATE attributes SET value = ?, xp = ? WHERE steamid = ? AND type = ? AND attribute = ?")
        query:SetNumber(1, value)
        query:SetNumber(2, xp)
        query:SetString(3, steamID)
        query:SetString(4, attributeType)
        query:SetString(5, attributeID)
    else
        query = ATOMIC.DB:Query("UPDATE attributes SET value = ? WHERE steamid = ? AND type = ? AND attribute = ?")
        query:SetNumber(1, value)
        query:SetString(2, steamID)
        query:SetString(3, attributeType)
        query:SetString(4, attributeID)
    end
    
    query:OnError(function(err)
        ATOMIC:Error("Error updating attribute " .. attributeID .. " for player " .. ply:Nick() .. ": " .. err)
    end)
    
    query:Start()
end

-- Add XP to a skill and level up if needed
function ATOMIC:AddSkillXP(ply, skillID, xpAmount)
    local currentLevel = ply:GetSkillLevel(skillID)
    local currentXP = ply:GetSkillXP(skillID)
    local skillInfo = ATOMIC.Skills[skillID]
    
    if not skillInfo then return end
    if currentLevel >= skillInfo.max then return end
    
    -- Apply intelligence bonus if applicable
    local intelligenceLevel = ply:GetGeneLevel("intelligence")
    local xpMultiplier = 1 + (intelligenceLevel * 0.1) -- 10% bonus per intelligence level
    xpAmount = math.floor(xpAmount * xpMultiplier)
    
    -- Add XP
    local newXP = currentXP + xpAmount
    ATOMIC:SetAttribute(ply, "skill", skillID, currentLevel, newXP)
    
    -- Notify the player of XP gain
    net.Start("ATOMIC:AttributeXPGain")
    net.WriteString(skillID)
    net.WriteInt(xpAmount, 16)
    net.Send(ply)
    
    -- Check for level up
    local xpForNextLevel = ATOMIC:GetXPForLevel(currentLevel + 1)
    if newXP >= xpForNextLevel then
        -- Level up
        local newLevel = currentLevel + 1
        ATOMIC:SetAttribute(ply, "skill", skillID, newLevel, newXP - xpForNextLevel)
        
        -- Notify player
        net.Start("ATOMIC:AttributeUpdate")
        net.WriteString("skill")
        net.WriteString(skillID)
        net.WriteInt(newLevel, 8)
        net.Send(ply)
        
        ATOMIC:NotifyPlayer(ply, "Your " .. skillInfo.name .. " skill has increased to level " .. newLevel .. "!")
    end
end

local playerMeta = FindMetaTable("Player")

-- Player meta function to set attribute
function playerMeta:SetAttribute(attributeType, attributeID, value, xp)
    ATOMIC:SetAttribute(self, attributeType, attributeID, value, xp)
end

-- Player meta function to add skill XP
function playerMeta:AddSkillXP(skillID, xpAmount)
    ATOMIC:AddSkillXP(self, skillID, xpAmount)
end

-- Command to open skills menu
concommand.Add("atomic_skills", function(ply)
    if not IsValid(ply) then return end
    
    net.Start("ATOMIC:OpenSkillsMenu")
    net.Send(ply)
end)

-- Debug commands (admin only)
concommand.Add("atomic_debug_setskill", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    
    local skillID = args[1]
    local level = tonumber(args[2]) or 1
    local xp = tonumber(args[3]) or 0
    
    if not ATOMIC.Skills[skillID] then
        ply:ChatPrint("Invalid skill ID. Available skills:")
        for id, _ in pairs(ATOMIC.Skills) do
            ply:ChatPrint("- " .. id)
        end
        return
    end
    
    ply:SetAttribute("skill", skillID, level, xp)
    ply:ChatPrint("Set " .. skillID .. " to level " .. level .. " with " .. xp .. " XP.")
end)

concommand.Add("atomic_debug_setgene", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    
    local geneID = args[1]
    local level = tonumber(args[2]) or 1
    
    if not ATOMIC.Genetics[geneID] then
        ply:ChatPrint("Invalid genetic ID. Available genetics:")
        for id, _ in pairs(ATOMIC.Genetics) do
            ply:ChatPrint("- " .. id)
        end
        return
    end
    
    ply:SetAttribute("gene", geneID, level)
    ply:ChatPrint("Set " .. geneID .. " to level " .. level .. ".")
end)
