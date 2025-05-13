AddCSLuaFile()

ENT.Type = "anim"
ENT.PrintName = "Atomic Tow Truck Hook"
ENT.Category = "Entities"
ENT.Spawnable = true

ENT.WinchState = 0
ENT.AttachedEntity = nil
ENT.AttachedObject = nil
ENT.VehPos = Vector(0, 0, 0)
ENT.Weld = nil
ENT.Rope = nil
ENT.RopeLengthMin = 50
ENT.RopeLengthMax = 1000
ENT.RopeLength = ENT.RopeLengthMin * 2

if SERVER then
    function ENT:Initialize()
        self.Entity:SetModel("models/props_junk/meathook001a.mdl")
        self.Entity:PhysicsInit(SOLID_VPHYSICS)
        self.Entity:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)

        local phys = self.Entity:GetPhysicsObject()
        if phys:IsValid() then
            phys:Wake()
        end
    end

    function ENT:AttachToVehicle(vehicle, localPoint)
        self.AttachedEntity = vehicle
        self.VehPos = localPoint
        self:Spawn()
        self.Rope = constraint.Rope(
            self, -- Ent1
            self.AttachedEntity, -- Ent2
            0,
            0,
            Vector(0, 0, 0), -- LPos1
            self.VehPos, -- LPos2
            self.RopeLength, -- Length
            0,
            0,
            2,
            "cable/cable2",
            false
        )

        local spawnpoint = self.AttachedEntity:LocalToWorld(self.VehPos)
        spawnpoint = Vector(spawnpoint.x, spawnpoint.y, spawnpoint.z - 10)
        
        self.Entity:SetPos(spawnpoint)
        self.Entity:SetAngles(self.AttachedEntity:GetAngles())
    end

    function ENT:AttachToObject(object)
        self.AttachedObject = object
        self.Weld = constraint.Weld(self, self.AttachedObject, 0, 0, 0, true)
    end

    function ENT:SetLength(length)
        self.RopeLength = length
        if self.Rope and IsValid(self.Rope) then
            self.Rope:Remove()
        end
        self.Rope = constraint.Rope(self.Entity, self.AttachedEntity, 0, 0, Vector(0, 0, 0), self.VehPos, self.RopeLength, 0, 0, 2, "cable/cable2", false)
    end

    function ENT:Use(activator, caller)
        if constraint.FindConstraint(self, "Weld") then
            self.LastUse = CurTime() + 5
            constraint.RemoveConstraints(self, "Weld")
        end
        if caller:IsPlayer() then
            caller:PickupObject(self)
        end
    end

    function ENT:Touch(hit)
        -- Weld the hook to the hit entity
        if IsValid(self.AttachedEntity) and hit:EntIndex() ~= self.AttachedEntity:EntIndex() then
            self:AttachToObject(hit)
        end
    end
end

scripted_ents.Register(ENT, "atomic_towhook")
