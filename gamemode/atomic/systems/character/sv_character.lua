-- File: sv_character.lua
-- Server-side character system for the Atomic framework

-- Default spawn points for new characters
ATOMIC.Config.DefaultSpawnPoints = {
    Vector(0, 0, 100) -- Add your default spawn points
}

-- Player meta functions
local playerMeta = FindMetaTable("Player")

-- Get a random spawn point
function ATOMIC:GetRandomSpawnPoint()
    if #ATOMIC.Config.DefaultSpawnPoints > 0 then
        local randomIndex = math.random(1, #ATOMIC.Config.DefaultSpawnPoints)
        return ATOMIC.Config.DefaultSpawnPoints[randomIndex]
    end
    
    -- Fallback to default map spawn
    return Vector(0, 0, 100)
end

-- Character hooks
hook.Add("PlayerSpawn", "ATOMIC:SetCharacterModel", function(ply)
    if ply:HasCharacter() then
        local characterID = ply:GetCharacter()
        
        -- Find the character data
        local CharacterModel = Database:Model("characters")
        
        CharacterModel:Select("*"):Where({"id = ?", characterID}):Limit(1):Run(function(data)
            if not data or not data[1] then return end
            
            local character = data[1]
            
            -- Set the player model
            ply:SetModel(character.model)
            ply:SetSkin(character.skin)
            
            -- Set bodygroups
            local bodygroups = util.JSONToTable(character.bodygroups) or {}
            for k, v in pairs(bodygroups) do
                ply:SetBodygroup(k, v)
            end
            
            -- Set health and armor with a small delay to ensure it applies after spawn
            timer.Simple(0.1, function()
                if IsValid(ply) then
                    ply:SetHealth(character.health)
                    ply:SetArmor(character.armor)
                end
            end)
            
            -- Notify all players about the character
            hook.Run("ATOMIC:PlayerLoadedCharacter", ply, character)
        end)
    else
        -- Player has no active character - this shouldn't happen
        -- But if it does, send them back to character selection
        ply:Freeze(true) -- Freeze them
        
        -- Send them the character menu
        net.Start("ATOMIC:OpenCharacterMenu")
        net.Send(ply)
        
        -- Log this situation
        ATOMIC:Log("Player " .. ply:Nick() .. " spawned without a character.")
    end
end)

-- Auto-save characters on server shutdown
hook.Add("ShutDown", "ATOMIC:SaveCharactersOnShutDown", function()
    ATOMIC:SaveAllCharacters()
end)

-- Handle character name changes
function playerMeta:ChangeCharacterName(firstname, lastname, callback)
    if not self:HasCharacter() then
        if callback then
            callback(false, "No active character.")
        end
        return
    end
    
    -- Check if they can afford it
    if self:GetCash() < ATOMIC.Config.NameChangePrice then
        if callback then
            callback(false, "You can't afford to change your name. It costs " .. ATOMIC:MoneyToString(ATOMIC.Config.NameChangePrice) .. ".")
        end
        return
    end
    
    -- Take the money
    self:AddCash(-ATOMIC.Config.NameChangePrice)
    
    -- Update the character
    local CharacterModel = Database:Model("characters")
    
    CharacterModel:Update({
        firstname = firstname,
        lastname = lastname
    }):Where({"id = ?", self:GetCharacter()}):Run(function(result)
        -- Update the player's name
        self:SetCharacterName(firstname, lastname)
        
        if callback then
            callback(true)
        end
        
        ATOMIC:Notify(self, "Name changed to " .. firstname .. " " .. lastname .. " for " .. ATOMIC:MoneyToString(ATOMIC.Config.NameChangePrice) .. ".")
        
        -- Log the name change
        ATOMIC:Log(self:Nick() .. " changed their character name to " .. firstname .. " " .. lastname .. ".")
    end)
end

-- Commands
ATOMIC:AddCommand("changename", function(player, args)
    local firstname = args[2]
    local lastname = args[3]
    
    if not firstname or #firstname < 2 then
        ATOMIC:NotifyError(player, "First name must be at least 2 characters.")
        return
    end
    
    if not lastname or #lastname < 2 then
        ATOMIC:NotifyError(player, "Last name must be at least 2 characters.")
        return
    end
    
    player:ChangeCharacterName(firstname, lastname, function(success, message)
        if not success then
            ATOMIC:NotifyError(player, message)
        end
    end)
end)

ATOMIC:AddCommand("savecharacter", function(player, args)
    if not player:HasCharacter() then
        ATOMIC:NotifyError(player, "You don't have an active character.")
        return
    end
    
    player:SaveCharacter(function(success)
        if success then
            ATOMIC:Notify(player, "Character saved successfully.")
        else
            ATOMIC:NotifyError(player, "Failed to save character.")
        end
    end)
end)

-- Admin commands
ATOMIC:AddCommand("deletecharacter", function(player, args)
    local steamid = args[2]
    local characterid = tonumber(args[3])
    
    if not steamid or not characterid then
        ATOMIC:NotifyError(player, "Invalid arguments. Usage: !deletecharacter <steamid> <characterid>")
        return
    end
    
    local CharacterModel = Database:Model("characters")
    
    CharacterModel:Delete():Where({"steamid64 = ?", steamid} ,{ "id = ?", characterid}):Run(function(result)
        if IsValid(player) then
            ATOMIC:Notify(player, "Character " .. characterid .. " for SteamID " .. steamid .. " has been deleted.")
        end
        
        -- Log the deletion
        ATOMIC:Log("Character " .. characterid .. " for SteamID " .. steamid .. " was deleted by " .. (IsValid(player) and player:Nick() or "CONSOLE") .. ".")
    end)
end)

ATOMIC:AddCommand("setcharactermoney", function(player, args)
    local target = ATOMIC:FindPlayer(args[2])
    local amount = tonumber(args[3])
    
    if not target then
        ATOMIC:NotifyError(player, "Target not found.")
        return
    end
    
    if not amount then
        ATOMIC:NotifyError(player, "Invalid amount specified.")
        return
    end
    
    if not target:HasCharacter() then
        ATOMIC:NotifyError(player, "Target doesn't have an active character.")
        return
    end
    
    -- Set the money
    target:SetCash(amount)
    
    -- Update the database
    local CharacterModel = Database:Model("characters")
    
    CharacterModel:Update({"money = ?", amount}):Where({"id = ?", target:GetCharacter()}):Run()
    
    ATOMIC:Notify(player, "Set " .. target:Nick() .. "'s money to " .. ATOMIC:MoneyToString(amount) .. ".")
    ATOMIC:Notify(target, "Your money has been set to " .. ATOMIC:MoneyToString(amount) .. " by an administrator.")
    
    -- Log the change
    ATOMIC:Log(player:Nick() .. " set " .. target:Nick() .. "'s money to " .. amount .. ".")
end)

ATOMIC:AddCommand("setcharacterbank", function(player, args)
    local target = ATOMIC:FindPlayer(args[2])
    local amount = tonumber(args[3])
    
    if not target then
        ATOMIC:NotifyError(player, "Target not found.")
        return
    end
    
    if not amount then
        ATOMIC:NotifyError(player, "Invalid amount specified.")
        return
    end
    
    if not target:HasCharacter() then
        ATOMIC:NotifyError(player, "Target doesn't have an active character.")
        return
    end
    
    -- Set the bank balance
    target:SetBank(amount)
    
    -- Update the database
    local CharacterModel = Database:Model("characters")
    
    CharacterModel:Update({"bank = ?", amount}):Where({"id = ?", target:GetCharacter()}):Run()
    
    ATOMIC:Notify(player, "Set " .. target:Nick() .. "'s bank balance to " .. ATOMIC:MoneyToString(amount) .. ".")
    ATOMIC:Notify(target, "Your bank balance has been set to " .. ATOMIC:MoneyToString(amount) .. " by an administrator.")
    
    -- Log the change
    ATOMIC:Log(player:Nick() .. " set " .. target:Nick() .. "'s bank balance to " .. amount .. ".")
end)

-- Register default character models
hook.Add("SV_ATOMIC:DatabaseReady", "ATOMIC:RegisterCharacterModels", function()
    -- This hook is just for future expansion
    -- We might want to load character models from the database in the future
    ATOMIC:Log("Character system initialized.")
end)
