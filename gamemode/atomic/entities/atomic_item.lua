AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Atomic Item"
ENT.Author = "Lucasion"
ENT.Category = "Atomic"
ENT.Spawnable = false
ENT.AdminSpawnable = false

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "ItemID")
    self:NetworkVar("Int", 0, "ItemAmount")
end

if SERVER then
    function ENT:Initialize()
        self:SetModel("models/props_junk/cardboard_box004a.mdl") -- Default model
        self:SetHullType(HULL_TINY)
        self:SetHullSizeNormal()
        self:SetSolid(SOLID_BBOX)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE)
        
        -- Setup Physics
        self:PhysicsInit(SOLID_VPHYSICS)
        local phys = self:GetPhysicsObject()
        if phys:IsValid() then
            phys:Wake()
            phys:SetMass(10)
        end
        
        -- Set the model based on the item if available
        local itemID = self:GetItemID()
        if itemID and itemID ~= "" then
            local item = ATOMIC:GetItem(itemID)
            if item and item.Model then
                self:SetModel(item.Model)
            end
        end
    end
    
    function ENT:Use(activator, caller)
        if activator:IsPlayer() then
            local itemID = self:GetItemID()
            local amount = self:GetItemAmount()
            
            if itemID and itemID ~= "" and amount > 0 then
                -- Attempt to add the item to the player's inventory
                activator:AddItem(itemID, amount)
                
                -- Remove the entity
                self:Remove()
            end
        end
    end
else -- CLIENT
    function ENT:Draw()
        self:DrawModel()
    end
    
    -- Draw item name when looking at it
    function ENT:DrawTranslucent()
        self:DrawModel()
        
        local pos = self:GetPos() + Vector(0, 0, 10)
        local ang = Angle(0, LocalPlayer():EyeAngles().y - 90, 90)
        
        local itemID = self:GetItemID()
        local amount = self:GetItemAmount()
        
        if itemID and itemID ~= "" then
            local item = ATOMIC:GetItem(itemID)
            if item then
                local distance = LocalPlayer():GetPos():Distance(self:GetPos())
                if distance < 300 then
                    cam.Start3D2D(pos, ang, 0.1)
                    draw.SimpleText(item.Name .. (amount > 1 and " x" .. amount or ""), "DermaLarge", 0, 0, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    cam.End3D2D()
                end
            end
        end
    end
end
