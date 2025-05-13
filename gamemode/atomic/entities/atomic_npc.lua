AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Atomic NPC"
ENT.Author = "Lucasion"
ENT.Category = "Atomic"
ENT.Spawnable = false
ENT.AdminSpawnable = true

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "NPCType") -- The type of NPC (by ID)
end

if SERVER then
    function ENT:Initialize()
        self:SetModel("models/Humans/Group01/male_01.mdl") -- Default model
        self:SetHullType(HULL_HUMAN)
        self:SetHullSizeNormal()
        self:SetSolid(SOLID_BBOX)
        self:SetMoveType(MOVETYPE_NONE)
        self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
        
        -- Setup Physics
        self:PhysicsInit(SOLID_BBOX)
        local phys = self:GetPhysicsObject()
        if phys:IsValid() then
            phys:Wake()
            phys:EnableMotion(false)
        end
        
        -- Set the NPC type from the entity's saved data or by spawn parameters
        local npcType = self:GetNPCType()
        if npcType and npcType ~= "" and ATOMIC.NPCs[npcType] then
            -- Set model from NPC data
            local model = ATOMIC:GetNPCModel(ATOMIC.NPCs[npcType])
            self:SetModel(model)
            
            -- Set name (entity name, not NPC name)
            self:SetName("atomic_npc_" .. npcType)
            
            -- Call OnSpawn function if defined
            if ATOMIC.NPCs[npcType].OnSpawn then
                ATOMIC.NPCs[npcType].OnSpawn(self)
            end
        end
    end
    
    function ENT:Use(activator, caller)
        if activator:IsPlayer() then
            local npcType = self:GetNPCType()
            
            -- Trigger the OnUse function if defined
            if ATOMIC.NPCs[npcType] and ATOMIC.NPCs[npcType].OnUse then
                ATOMIC.NPCs[npcType].OnUse(activator, self)
            end
            
            -- Open dialog by default
            net.Start("ATOMIC:NPCDialog")
            net.WriteInt(self:EntIndex(), 32)
            net.Send(activator)
        end
    end
    
    function ENT:Think()
        -- Idle animation randomization
        if not self.NextIdle or CurTime() >= self.NextIdle then
            -- Add random idle animations
            self.NextIdle = CurTime() + math.random(10, 30)
            
            -- Random sequence between 1-10% of available sequences
            local seqCount = self:GetSequenceCount()
            local seqID = math.random(1, math.max(2, math.floor(seqCount * 0.1)))
            self:SetSequence(seqID)
        end
        
        self:NextThink(CurTime() + 1)
        return true
    end
else -- CLIENT
    function ENT:Draw()
        self:DrawModel()
    end
    
    -- Add 3D2D name display
    function ENT:DrawTranslucent()
        self:DrawModel()
        
        -- Get the NPC data
        local npcType = self:GetNPCType()
        if not npcType or not ATOMIC.NPCs[npcType] then return end
        
        local npc = ATOMIC.NPCs[npcType]
        local npcName = ATOMIC:GetNPCName(npc)
        
        -- Calculate position above NPC's head
        local pos = self:GetPos() + Vector(0, 0, self:OBBMaxs().z + 10)
        local ang = Angle(0, LocalPlayer():EyeAngles().y - 90, 90)
        
        -- Draw name
        local distance = LocalPlayer():GetPos():Distance(self:GetPos())
        if distance < 500 then
            cam.Start3D2D(pos, ang, 0.1)
            draw.SimpleText(npcName, "DermaLarge", 0, 0, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            
            -- Draw subtitle or job if defined
            if npc.Subtitle then
                draw.SimpleText(npc.Subtitle, "DermaDefault", 0, 25, Color(220, 220, 220, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            cam.End3D2D()
        end
    end
    
    -- Handle dialog for this NPC
    net.Receive("ATOMIC:NPCDialog", function()
        local npc = net.ReadEntity()
        local name = net.ReadString()
        local options = net.ReadTable()
        
        -- Open dialog window with these options
        if IsValid(npc) then
            ATOMIC:OpenDialog(name, options, function(optionIndex)
                net.Start("ATOMIC:NPCDialogResponse")
                net.WriteInt(npc:EntIndex(), 32)
                net.WriteInt(optionIndex, 32)
                net.SendToServer()
            end)
        end
    end)
    
    -- Handle sequence changes
    net.Receive("ATOMIC:NPCSequence", function()
        local npcIndex = net.ReadInt(32)
        local sequence = net.ReadInt(32)
        local npc = Entity(npcIndex)
        
        if IsValid(npc) and npc:GetClass() == "atomic_npc" then
            npc:ResetSequenceInfo()
            npc:SetSequence(sequence)
        end
    end)
end
