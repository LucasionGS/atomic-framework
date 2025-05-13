-- File: sv_npcs.lua
-- This file contains the server-side NPC system for the Atomic framework

-- Register the NPC entity
function ATOMIC:SpawnNPC(id, pos, ang)
    if not ATOMIC.NPCs[id] then
        ATOMIC:Error("Tried to spawn unknown NPC: " .. id)
        return
    end
    
    local npc = ents.Create("atomic_npc")
    npc:SetNPCType(id)
    npc:SetPos(pos)
    npc:SetAngles(ang)
    npc:Spawn()
    
    return npc
end

-- Save NPCs to file
function ATOMIC:SaveNPCs()
    local map = game.GetMap()
    
    -- Deep copy only the Spawns data to avoid saving functions
    local npcs = {}
    for k, v in pairs(ATOMIC.NPCs) do
        if v.Spawns and #v.Spawns > 0 then
            npcs[k] = table.Copy(v.Spawns)
        end
    end
    
    file.Write(ATOMIC.Config.DataFolder .. "/npcs_" .. map .. ".json", util.TableToJSON(npcs))
    ATOMIC:Print("Saved NPCs to file.")
end

-- Load NPCs from file
function ATOMIC:LoadNPCs()
    local map = game.GetMap()
    if file.Exists(ATOMIC.Config.DataFolder .. "/npcs_" .. map .. ".json", "DATA") then
        local npcs = util.JSONToTable(file.Read(ATOMIC.Config.DataFolder .. "/npcs_" .. map .. ".json", "DATA"))
        for npcId, spawns in pairs(npcs) do
            if ATOMIC.NPCs[npcId] then
                ATOMIC.NPCs[npcId].Spawns = spawns
                ATOMIC:Print("Loaded NPC: " .. npcId .. " (" .. #spawns .. " spawns)")
            end
        end
    end
end

-- Get all active NPC points
function ATOMIC:GetActiveNPCPoints()
    local npcs = {}
    for npcName, npc in pairs(ATOMIC.NPCs) do
        if npc.Spawns and #npc.Spawns > 0 then
            npcs[npcName] = npc.Spawns
        end
    end
    return npcs
end

-- Network strings for NPC management
util.AddNetworkString("ATOMIC:SaveNPCs")
util.AddNetworkString("ATOMIC:LoadNPCs")
util.AddNetworkString("ATOMIC:GetActiveNPCPoints")
util.AddNetworkString("ATOMIC:NPCDialog")
util.AddNetworkString("ATOMIC:NPCDialogResponse")
util.AddNetworkString("ATOMIC:NPCSequence")

-- Handle NPC saving
net.Receive("ATOMIC:SaveNPCs", function(len, ply)
    if ply:IsAdmin() then
        ATOMIC:SaveNPCs()
        ATOMIC:Notify(ply, "NPCs saved.")
    else
        ATOMIC:NotifyError(ply, "You don't have permission to save NPCs.")
    end
end)

-- Handle NPC loading
net.Receive("ATOMIC:LoadNPCs", function(len, ply)
    if ply:IsAdmin() then
        ATOMIC:LoadNPCs()
        ATOMIC:Notify(ply, "NPCs reloaded.")
    else
        ATOMIC:NotifyError(ply, "You don't have permission to reload NPCs.")
    end
end)

-- Handle getting active NPC points
net.Receive("ATOMIC:GetActiveNPCPoints", function(len, ply)
    if ply:IsAdmin() then
        local npcs = ATOMIC:GetActiveNPCPoints()
        net.Start("ATOMIC:GetActiveNPCPoints")
        net.WriteTable(npcs)
        net.Send(ply)
    end
end)

-- Handle NPC dialog
net.Receive("ATOMIC:NPCDialog", function(len, ply)
    local npcIndex = net.ReadInt(32)
    local npc = Entity(npcIndex)
    
    if IsValid(npc) and npc:GetClass() == "atomic_npc" then
        local npcType = npc:GetNPCType()
        local npcData = ATOMIC.NPCs[npcType]
        
        if npcData and npcData.OnDialog then
            local dialogOptions = npcData.OnDialog(ply, npc)
            
            if dialogOptions then
                -- Convert dialog functions to indices
                local serializedOptions = {}
                for i, option in ipairs(dialogOptions) do
                    table.insert(serializedOptions, {
                        Text = option.Text,
                        Index = i
                    })
                end
                
                -- Store the original options with functions
                npc.DialogOptions = dialogOptions
                
                -- Send serialized options to client
                net.Start("ATOMIC:NPCDialog")
                net.WriteEntity(npc)
                net.WriteString(ATOMIC:GetNPCName(npcData))
                net.WriteTable(serializedOptions)
                net.Send(ply)
            end
        end
    end
end)

-- Handle NPC dialog response
net.Receive("ATOMIC:NPCDialogResponse", function(len, ply)
    local npcIndex = net.ReadInt(32)
    local optionIndex = net.ReadInt(32)
    local npc = Entity(npcIndex)
    
    if IsValid(npc) and npc:GetClass() == "atomic_npc" and npc.DialogOptions then
        local option = npc.DialogOptions[optionIndex]
        
        if option and option.OnSelect then
            option.OnSelect(ply, npc)
        end
    end
end)

-- Handle NPC sequence change
net.Receive("ATOMIC:NPCSequence", function(len, ply)
    local npcIndex = net.ReadInt(32)
    local sequence = net.ReadInt(32)
    local npc = Entity(npcIndex)
    
    if IsValid(npc) and npc:GetClass() == "atomic_npc" then
        npc:SetSequence(sequence)
        
        -- Broadcast to all clients
        net.Start("ATOMIC:NPCSequence")
        net.WriteInt(npcIndex, 32)
        net.WriteInt(sequence, 32)
        net.Broadcast()
    end
end)

-- Load NPCs when the server starts
hook.Add("InitPostEntity", "ATOMIC:LoadNPCs", function()
    ATOMIC:LoadNPCs()
    
    -- Spawn all NPCs
    timer.Simple(1, function()
        for npcId, npc in pairs(ATOMIC.NPCs) do
            if npc.Spawns then
                for _, spawn in ipairs(npc.Spawns) do
                    ATOMIC:SpawnNPC(npcId, spawn.Pos, spawn.Ang)
                end
            end
        end
    end)
end)
