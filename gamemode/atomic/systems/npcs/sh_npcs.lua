-- File: sh_npcs.lua
-- This file contains the shared NPC system for the Atomic framework

-- Table to store all registered NPCs
ATOMIC.NPCs = ATOMIC.NPCs or {}
ATOMIC.NPC_MODELS = ATOMIC.NPC_MODELS or {}

--[[
    NPC Definition:
    {
        Name = "NPC Name",
        Names = {"Random Name 1", "Random Name 2"}, -- Optional array of names to randomly select from
        Model = "models/path/to/model.mdl",
        Models = {"models/path/to/model1.mdl", "models/path/to/model2.mdl"}, -- Optional array of models to randomly select from
        Spawns = {
            {
                Pos = Vector(x, y, z),
                Ang = Angle(p, y, r)
            }
        },
        OnDialog = function(ply, npc)
            -- Dialog interaction
            -- Return a table of dialog options
            return {
                {
                    Text = "Option 1",
                    OnSelect = function(ply, npc)
                        -- Do something when this option is selected
                    end
                },
                {
                    Text = "Option 2",
                    OnSelect = function(ply, npc)
                        -- Do something when this option is selected
                    end
                }
            }
        end,
        OnRegister = function(npc)
            -- Called when the NPC is registered
        end,
        OnSpawn = function(npc)
            -- Called when the NPC spawns
        end,
        OnUse = function(ply, npc)
            -- Called when the NPC is used by a player
        end
    }
]]--

-- Register a new NPC
function ATOMIC:RegisterNPC(id, data)
    data.__key = id -- Store the original key for reference
    
    -- Validate required fields
    if not data.Name and not data.Names then
        ATOMIC:Error("NPC " .. id .. " has no name(s)!")
        return
    end
    
    if not data.Model and not data.Models then
        ATOMIC:Error("NPC " .. id .. " has no model(s)!")
        return
    end
    
    if not data.Spawns or #data.Spawns == 0 then
        data.Spawns = {}
        ATOMIC:Debug("NPC " .. id .. " has no spawn points. Add them with the NPC Manager Gun.")
    end
    
    -- Add the NPC to the global table
    ATOMIC.NPCs[id] = data
    
    -- Register models for precaching
    if data.Model and not table.HasValue(ATOMIC.NPC_MODELS, data.Model) then
        table.insert(ATOMIC.NPC_MODELS, data.Model)
    end
    
    if data.Models then
        for _, model in ipairs(data.Models) do
            if not table.HasValue(ATOMIC.NPC_MODELS, model) then
                table.insert(ATOMIC.NPC_MODELS, model)
            end
        end
    end
    
    if data.OnRegister then
        data.OnRegister(data)
    end
    
    return data
end

-- Get a random name from the Names array or return the Name
function ATOMIC:GetNPCName(npc)
    if npc.Names and #npc.Names > 0 then
        return npc.Names[math.random(#npc.Names)]
    end
    return npc.Name or "Unknown NPC"
end

-- Get a random model from the Models array or return the Model
function ATOMIC:GetNPCModel(npc)
    if npc.Models and #npc.Models > 0 then
        return npc.Models[math.random(#npc.Models)]
    end
    return npc.Model or "models/error.mdl"
end

-- Get models for an NPC by ID
function ATOMIC:GetNPCModels(npcId)
    local npc = ATOMIC.NPCs[npcId]
    if npc then
        return npc.Models or {npc.Model}
    end
    return {"models/error.mdl"}
end
