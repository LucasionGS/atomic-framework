-- File: sh_character.lua
-- Shared character system for the Atomic framework

-- Character configuration
ATOMIC.Characters = ATOMIC.Characters or {}
ATOMIC.Config.MaxCharacters = 5 -- Maximum number of characters per player

-- Available models for character creation
ATOMIC.Config.CharacterModels = {
    -- Male models
    {
        name = "Male 01",
        model = "models/player/Group01/male_01.mdl",
        gender = "male"
    },
    {
        name = "Male 02",
        model = "models/player/Group01/male_02.mdl",
        gender = "male"
    },
    {
        name = "Male 03",
        model = "models/player/Group01/male_03.mdl",
        gender = "male"
    },
    {
        name = "Male 04",
        model = "models/player/Group01/male_04.mdl",
        gender = "male"
    },
    {
        name = "Male 05",
        model = "models/player/Group01/male_05.mdl",
        gender = "male"
    },
    {
        name = "Male 06",
        model = "models/player/Group01/male_06.mdl",
        gender = "male"
    },
    {
        name = "Male 07",
        model = "models/player/Group01/male_07.mdl",
        gender = "male"
    },
    {
        name = "Male 08",
        model = "models/player/Group01/male_08.mdl",
        gender = "male"
    },
    {
        name = "Male 09",
        model = "models/player/Group01/male_09.mdl",
        gender = "male"
    },
    
    -- Female models
    {
        name = "Female 01",
        model = "models/player/Group01/female_01.mdl",
        gender = "female"
    },
    {
        name = "Female 02",
        model = "models/player/Group01/female_02.mdl",
        gender = "female"
    },
    {
        name = "Female 03",
        model = "models/player/Group01/female_03.mdl",
        gender = "female"
    },
    {
        name = "Female 04",
        model = "models/player/Group01/female_04.mdl",
        gender = "female"
    },
    {
        name = "Female 05",
        model = "models/player/Group01/female_05.mdl",
        gender = "female"
    },
    {
        name = "Female 06",
        model = "models/player/Group01/female_06.mdl",
        gender = "female"
    }
}

-- Player meta functions
local playerMeta = FindMetaTable("Player")

-- Get the player's active character
function playerMeta:GetCharacter()
    return self:GetNWInt("ATOMIC_CharacterID", 0)
end

-- Check if the player has an active character
function playerMeta:HasCharacter()
    return self:GetCharacter() > 0
end

-- Get the player's character name
function playerMeta:GetCharacterName()
    local firstname = self:GetNWString("ATOMIC_CharFirstname", "")
    local lastname = self:GetNWString("ATOMIC_CharLastname", "")
    
    if firstname == "" and lastname == "" then
        return self:Nick()
    end
    
    return firstname .. " " .. lastname
end

-- Get player's first name
function playerMeta:GetFirstName()
    return self:GetNWString("ATOMIC_CharFirstname", "")
end

-- Get player's last name
function playerMeta:GetLastName()
    return self:GetNWString("ATOMIC_CharLastname", "")
end

-- Functions to create, load, and switch characters
if SERVER then
    util.AddNetworkString("ATOMIC:CharacterCreate")
    util.AddNetworkString("ATOMIC:CharacterSelect")
    util.AddNetworkString("ATOMIC:CharacterDelete")
    util.AddNetworkString("ATOMIC:CharacterList")
    util.AddNetworkString("ATOMIC:OpenCharacterMenu")
    util.AddNetworkString("ATOMIC:CharacterLoaded")
    
    -- Set player's active character
    function playerMeta:SetCharacter(characterID)
        self:SetNWInt("ATOMIC_CharacterID", characterID)
    end
    
    -- Set player's character name
    function playerMeta:SetCharacterName(firstname, lastname)
        self:SetNWString("ATOMIC_CharFirstname", firstname)
        self:SetNWString("ATOMIC_CharLastname", lastname)
    end
    
    -- Get all characters for a player
    function playerMeta:GetCharacters(callback)
        local CharacterModel = Database:Model("characters")
        
        CharacterModel:Select("*"):Where({"steamid64 = ?", self:SteamID64()}):Run(function(data)
            if callback then
                callback(data or {})
            end
        end)
    end
    
    -- Create a new character
    function playerMeta:CreateCharacter(data, callback)
        -- Check if the player has reached the character limit
        self:GetCharacters(function(characters)
            if #characters >= ATOMIC.Config.MaxCharacters then
                if callback then
                    callback(false, "You have reached the maximum number of characters.")
                end
                return
            end
            
            -- Create the character
            local CharacterModel = Database:Model("characters")
            
            -- Set default values
            data.steamid64 = self:SteamID64()
            data.created_at = os.date("%Y-%m-%d %H:%M:%S")
            data.last_used = os.date("%Y-%m-%d %H:%M:%S")
            
            -- Insert the character
            CharacterModel:Insert(data):Run(function(result)
                if callback then
                    callback(true)
                end
            end)
        end)
    end
    
    -- Load a character
    function playerMeta:LoadCharacter(characterID, callback)
        local CharacterModel = Database:Model("characters")
        
        -- Check if the character belongs to the player
        CharacterModel:Select("*"):Where({"id = ?", characterID, "steamid64 = ?", self:SteamID64()}):Limit(1):Run(function(data)
            if not data or not data[1] then
                if callback then
                    callback(false, "Character not found.")
                end
                return
            end
            
            local character = data[1]
            
            -- Update last used timestamp
            CharacterModel:Update({"last_used = ?", os.date("%Y-%m-%d %H:%M:%S")}, { "active = 1" }):Where({"id = ?", characterID}):Run()
            
            -- Set all other characters as inactive
            CharacterModel:Update({"active = 0"}):Where({"steamid64 = ?", self:SteamID64()}, { "id != ?", characterID}):Run()
            
            -- Set character data on player
            self:SetCharacter(characterID)
            self:SetCharacterName(character.firstname, character.lastname)
            
            -- Set player model
            self:SetModel(character.model)
            self:SetSkin(character.skin)
            
            -- Set bodygroups if available
            local bodygroups = util.JSONToTable(character.bodygroups) or {}
            for k, v in pairs(bodygroups) do
                self:SetBodygroup(k, v)
            end
            
            -- Set player stats
            self:SetCash(character.money)
            self:SetBank(character.bank)
            
            -- Set health and armor
            self:SetHealth(character.health)
            self:SetArmor(character.armor)
            
            -- Set job
            self:SetJob(character.job)
            
            -- Load inventory
            if character.inventory then
                self:SaveInventory(util.JSONToTable(character.inventory) or {})
            end
            
            -- Tell the client the character was loaded
            net.Start("ATOMIC:CharacterLoaded")
            net.WriteInt(characterID, 32)
            net.Send(self)
            
            -- Run callback
            if callback then
                callback(true, character)
            end
            
            -- Run hook
            hook.Run("ATOMIC:CharacterLoaded", self, character)
        end)
    end
    
    -- Save the current character
    function playerMeta:SaveCharacter(callback)
        if not self:HasCharacter() then
            if callback then
                callback(false, "No active character.")
            end
            return
        end
        
        local characterID = self:GetCharacter()
        local CharacterModel = Database:Model("characters")
        
        -- Get player position
        local pos = self:GetPos()
        
        -- Create bodygroups table
        local bodygroups = {}
        for i = 0, self:GetNumBodyGroups() - 1 do
            bodygroups[i] = self:GetBodygroup(i)
        end
        
        -- Save character data
        CharacterModel:UpdateEntry(characterID,
            {"money = ?", self:GetCash()},
            {"bank = ?", self:GetBank()},
            {"position_x = ?", pos.x},
            {"position_y = ?", pos.y},
            {"position_z = ?", pos.z},
            {"health = ?", self:Health()},
            {"armor = ?", self:Armor()},
            {"model = ?", self:GetModel()},
            {"skin = ?", self:GetSkin()},
            {"bodygroups = ?", util.TableToJSON(bodygroups)},
            {"job = ?", self:GetJob()},
            {"last_used = ?", os.date("%Y-%m-%d %H:%M:%S")}
        ):Run(function(result)
            if callback then
                callback(true)
            end
        end)
    end
    
    -- Delete a character
    function playerMeta:DeleteCharacter(characterID, callback)
        local CharacterModel = Database:Model("characters")
        
        -- Check if the character belongs to the player
        CharacterModel:Select("*"):Where({"id = ?", characterID, "steamid64 = ?", self:SteamID64()}):Limit(1):Run(function(data)
            if not data or not data[1] then
                if callback then
                    callback(false, "Character not found.")
                end
                return
            end
            
            -- Delete the character
            CharacterModel:Delete():Where({"id = ?", characterID}):Run(function(result)
                if callback then
                    callback(true)
                end
            end)
        end)
    end
    
    -- Save all online characters
    function ATOMIC:SaveAllCharacters()
        for _, ply in ipairs(player.GetAll()) do
            if ply:HasCharacter() then
                ply:SaveCharacter()
            end
        end
    end
    
    -- Autosave timer
    timer.Create("ATOMIC:CharacterAutosave", 300, 0, function() -- Save every 5 minutes
        ATOMIC:SaveAllCharacters()
    end)
    
    -- Network events
    net.Receive("ATOMIC:CharacterCreate", function(len, ply)
        local data = net.ReadTable()
        
        -- Validate character data
        if not data.firstname or data.firstname:len() < 2 then
            ATOMIC:NotifyError(ply, "First name must be at least 2 characters.")
            return
        end
        
        if not data.lastname or data.lastname:len() < 2 then
            ATOMIC:NotifyError(ply, "Last name must be at least 2 characters.")
            return
        end
        
        if not data.model then
            ATOMIC:NotifyError(ply, "You must select a model.")
            return
        end
        
        -- Create the character
        ply:CreateCharacter(data, function(success)
            if success then
                -- Send updated character list
                ply:GetCharacters(function(characters)
                    net.Start("ATOMIC:CharacterList")
                    net.WriteTable(characters)
                    net.Send(ply)
                end)
                
                ATOMIC:Notify(ply, "Character created successfully.")
            else
                ATOMIC:NotifyError(ply, "Failed to create character.")
            end
        end)
    end)
    
    net.Receive("ATOMIC:CharacterSelect", function(len, ply)
        local characterID = net.ReadInt(32)
        
        ply:LoadCharacter(characterID, function(success, result)
            if success then
                ATOMIC:Notify(ply, "Character loaded successfully.")
                
                -- Spawn the player
                ply:Spawn()
                
                -- If character has saved position, teleport there
                if result.position_x ~= 0 and result.position_y ~= 0 and result.position_z ~= 0 then
                    ply:SetPos(Vector(result.position_x, result.position_y, result.position_z))
                end
            else
                ATOMIC:NotifyError(ply, result)
                
                -- Send the character menu again
                net.Start("ATOMIC:OpenCharacterMenu")
                net.Send(ply)
            end
        end)
    end)
    
    net.Receive("ATOMIC:CharacterDelete", function(len, ply)
        local characterID = net.ReadInt(32)
        
        ply:DeleteCharacter(characterID, function(success, result)
            if success then
                ATOMIC:Notify(ply, "Character deleted successfully.")
                
                -- Send updated character list
                ply:GetCharacters(function(characters)
                    net.Start("ATOMIC:CharacterList")
                    net.WriteTable(characters)
                    net.Send(ply)
                end)
            else
                ATOMIC:NotifyError(ply, result)
            end
        end)
    end)
    
    -- Player Hooks
    hook.Add("PlayerDisconnected", "ATOMIC:SaveCharacterOnDisconnect", function(ply)
        if ply:HasCharacter() then
            ply:SaveCharacter()
        end
    end)
    
    hook.Add("PlayerInitialSpawn", "ATOMIC:CheckForCharacters", function(ply)
        -- Check if the player has characters
        ply:GetCharacters(function(characters)
            -- Send the character list to the client
            net.Start("ATOMIC:CharacterList")
            net.WriteTable(characters)
            net.Send(ply)
            
            -- Open the character menu
            net.Start("ATOMIC:OpenCharacterMenu")
            net.Send(ply)
        end)
    end)
    
    -- Add command to open character menu
    concommand.Add("atomic_characters", function(ply)
        if not IsValid(ply) then return end
        
        ply:GetCharacters(function(characters)
            net.Start("ATOMIC:CharacterList")
            net.WriteTable(characters)
            net.Send(ply)
            
            net.Start("ATOMIC:OpenCharacterMenu")
            net.Send(ply)
        end)
    end)
else -- CLIENT
    -- Request character list
    function ATOMIC:RequestCharacterList()
        net.Start("ATOMIC:CharacterList")
        net.SendToServer()
    end
    
    -- Store character list
    ATOMIC.Characters.List = ATOMIC.Characters.List or {}
    
    -- Get model data from path
    function ATOMIC:GetModelInfo(modelPath)
        for _, model in ipairs(ATOMIC.Config.CharacterModels) do
            if model.model == modelPath then
                return model
            end
        end
        
        return nil
    end
    
    -- Network events
    net.Receive("ATOMIC:CharacterList", function()
        ATOMIC.Characters.List = net.ReadTable()
    end)
    
    net.Receive("ATOMIC:CharacterLoaded", function()
        local characterID = net.ReadInt(32)
        
        -- Find the character in the list
        for _, char in ipairs(ATOMIC.Characters.List) do
            if char.id == characterID then
                ATOMIC.Characters.Current = char
                break
            end
        end
        
        hook.Run("ATOMIC:CharacterLoaded", ATOMIC.Characters.Current)
    end)
    
    -- Open character menu
    net.Receive("ATOMIC:OpenCharacterMenu", function()
        ATOMIC:OpenCharacterMenu()
    end)
    
    -- Create character
    function ATOMIC:CreateCharacter(data)
        net.Start("ATOMIC:CharacterCreate")
        net.WriteTable(data)
        net.SendToServer()
    end
    
    -- Select character
    function ATOMIC:SelectCharacter(characterID)
        net.Start("ATOMIC:CharacterSelect")
        net.WriteInt(characterID, 32)
        net.SendToServer()
    end
    
    -- Delete character
    function ATOMIC:DeleteCharacter(characterID)
        net.Start("ATOMIC:CharacterDelete")
        net.WriteInt(characterID, 32)
        net.SendToServer()
    end
end
