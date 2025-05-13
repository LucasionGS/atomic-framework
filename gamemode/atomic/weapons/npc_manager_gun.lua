AddCSLuaFile()

SWEP.PrintName = "NPC Manager Gun"
SWEP.Author = "Lucasion"
SWEP.Instructions = "Left Click: Place NPC, Right Click: Remove NPC, Reload: Cycle NPC Types"
SWEP.Category = "Atomic"
SWEP.Spawnable = false
SWEP.AdminSpawnable = true
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.Weight = 5
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.Slot = 5
SWEP.SlotPos = 1
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.ViewModel = "models/weapons/c_pistol.mdl"
SWEP.WorldModel = "models/weapons/w_pistol.mdl"

-- Keep track of which NPC type is selected
SWEP.CurrentNPCIndex = 1
SWEP.NPCList = {}

function SWEP:Initialize()
    self:SetHoldType("pistol")
    
    -- Build the NPC list on initialize
    self:BuildNPCList()
end

function SWEP:BuildNPCList()
    -- Reset the NPC list
    self.NPCList = {}
    
    -- Populate with registered NPCs
    for npcId, _ in pairs(ATOMIC.NPCs) do
        table.insert(self.NPCList, npcId)
    end
    
    -- Sort the list alphabetically
    table.sort(self.NPCList)
    
    -- Reset the index
    self.CurrentNPCIndex = 1
end

function SWEP:Deploy()
    -- Show current NPC when deployed
    self:ShowCurrentNPC()
    return true
end

function SWEP:ShowCurrentNPC()
    if #self.NPCList == 0 then
        self:BuildNPCList()
    end
    
    if #self.NPCList == 0 then
        self.Owner:ChatPrint("No NPCs have been registered.")
        return
    end
    
    local currentNPC = self.NPCList[self.CurrentNPCIndex]
    local npcData = ATOMIC.NPCs[currentNPC]
    
    if not npcData then 
        self.Owner:ChatPrint("Error: Selected NPC not found.")
        return
    end
    
    self.Owner:ChatPrint("Selected NPC: " .. (npcData.Name or currentNPC) .. " (" .. self.CurrentNPCIndex .. "/" .. #self.NPCList .. ")")
end

function SWEP:PrimaryAttack()
    if not self.Owner:IsSuperAdmin() then return end
    if SERVER then
        local tr = self.Owner:GetEyeTrace()
        if not tr.HitPos then return end
        
        -- Check if the trace hit the world
        if not tr.HitWorld then
            self.Owner:ChatPrint("You must place NPCs on the world.")
            return
        end
        
        if #self.NPCList == 0 then
            self.Owner:ChatPrint("No NPCs have been registered.")
            return
        end
        
        local currentNPC = self.NPCList[self.CurrentNPCIndex]
        local npcData = ATOMIC.NPCs[currentNPC]
        
        if not npcData then 
            self.Owner:ChatPrint("Error: Selected NPC not found.")
            return
        end
        
        -- Setup the position and angle
        local pos = tr.HitPos
        pos.z = pos.z + 2 -- Lift slightly above ground
        
        local ang = Angle(0, self.Owner:EyeAngles().y - 180, 0)
        
        -- Create spawn data if it doesn't exist
        if not npcData.Spawns then
            npcData.Spawns = {}
        end
        
        -- Add the spawn point to the NPC
        table.insert(npcData.Spawns, {
            Pos = pos,
            Ang = ang
        })
        
        -- Spawn the NPC
        ATOMIC:SpawnNPC(currentNPC, pos, ang)
        
        self.Owner:ChatPrint("Placed " .. (npcData.Name or currentNPC) .. " at position " .. tostring(pos))
        
        -- Save NPCs to file
        ATOMIC:SaveNPCs()
    end
end

function SWEP:SecondaryAttack()
    if not self.Owner:IsSuperAdmin() then return end
    if SERVER then
        local tr = self.Owner:GetEyeTrace()
        if not tr.Entity or not IsValid(tr.Entity) then return end
        
        -- Check if the entity is an NPC
        if tr.Entity:GetClass() ~= "atomic_npc" then
            self.Owner:ChatPrint("You must be looking at an Atomic NPC.")
            return
        end
        
        local npcType = tr.Entity:GetNPCType()
        
        -- Check if the NPC exists in our registry
        if not ATOMIC.NPCs[npcType] then
            self.Owner:ChatPrint("Error: NPC type not found in registry.")
            return
        end
        
        local npcData = ATOMIC.NPCs[npcType]
        
        -- Find the spawn point that matches the entity's position
        local pos = tr.Entity:GetPos()
        local removed = false
        
        -- Remove the spawn point
        if npcData.Spawns then
            for i, spawn in ipairs(npcData.Spawns) do
                if spawn.Pos:DistToSqr(pos) < 100 then
                    table.remove(npcData.Spawns, i)
                    removed = true
                    break
                end
            end
        end
        
        -- Remove the entity
        tr.Entity:Remove()
        
        if removed then
            self.Owner:ChatPrint("Removed " .. (npcData.Name or npcType) .. " spawn point.")
            
            -- Save NPCs to file
            ATOMIC:SaveNPCs()
        else
            self.Owner:ChatPrint("Removed " .. (npcData.Name or npcType) .. " entity, but couldn't find matching spawn point.")
        end
    end
end

function SWEP:Reload()
    if #self.NPCList == 0 then
        self:BuildNPCList()
    end
    
    if #self.NPCList == 0 then
        self.Owner:ChatPrint("No NPCs have been registered.")
        return
    end
    
    -- Cycle to the next NPC
    self.CurrentNPCIndex = self.CurrentNPCIndex + 1
    if self.CurrentNPCIndex > #self.NPCList then
        self.CurrentNPCIndex = 1
    end
    
    -- Show the new current NPC
    self:ShowCurrentNPC()
end
