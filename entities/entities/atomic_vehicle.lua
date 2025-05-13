AddCSLuaFile()

ENT.Type = "anim"
ENT.PrintName = "Atomic Vehicle"
ENT.Category = "Vehicles"
ENT.Spawnable = true
ENT.RenderGroup = RENDERGROUP_BOTH

-- Settable on spawn
ENT.Upgrades = {
    -- Default values
    Color = { 255, 255, 255, 255 },    -- Color of the vehicle
    Health = 1000,                      -- Max health of the vehicle
    Armor = 0.0,                        -- (Float) Armor %. Damage will be reduced by this amount.
    MaxSpeed = 200,                     -- Max speed of the vehicle
}

function ENT:Initialize()
    if SERVER then
        self:SetModel("models/props_junk/watermelon01.mdl") -- Set a temporary model
        self:SetSolid(SOLID_NONE) -- Set solid type to none
        self:SetUseType(SIMPLE_USE)

        if self.vehicle then
            local vehicle = ents.Create(self.vehicle.Class or "prop_vehicle_jeep")
            if self.vehicle.Script then
                vehicle:SetKeyValue("vehiclescript", self.vehicle.Script)
            end
            vehicle:SetModel(self.vehicle.Model)
            vehicle:SetPos(self:GetPos())
            vehicle:SetAngles(self:GetAngles())
            vehicle:SetRenderMode(RENDERMODE_TRANSALPHA)
            
            vehicle:Spawn()
            vehicle:Activate()
            
            -- Transfer control to the new vehicle entity
            self.VehicleEntity = vehicle
            self:SetVehicleEntity(vehicle)
            vehicle.VehicleController = self
            self:SetNWInt("VehicleEntityIndex", vehicle:EntIndex())
            vehicle:SetNWInt("VehicleControllerIndex", self:EntIndex())

            -- Remove the temporary model
            self:SetModelScale(0)

            -- Apply upgrades
            self:ApplyUpgrades()
            
            -- Set vehicle properties
            local this = self
            if IsValid(vehicle) then
                vehicle.GetController = function()
                    return this
                end
                vehicle:SetNWBool("IsAtomicVehicle", true)
                
                vehicle:CallOnRemove("removeController", function()
                    if IsValid(this) then
                        this:Remove()
                    end

                    if IsValid(this.hookObj) then
                        this.hookObj:Remove()
                    end
                end)

                -- Special case for: tow truck
                if self.vehicle.Model == "models/tdmcars/ram3500_tow.mdl" then
                    local hookObj = ents.Create("atomic_towhook")
                    hookObj:AttachToVehicle(vehicle, Vector(0.20592176914215, -158.0849609375, 114.19325256348))
                    self.hookObj = hookObj
                end
            end
        end
    end
end

function ENT:SetVehicle(vehicleId)
    self.vehicleId = vehicleId
    self.vehicle = ATOMIC.Vehicles[vehicleId]
    return self.vehicle ~= nil
end

function ENT:SetVehicleOwner(ply)
    self:SetNWEntity("Owner", ply)
end

function ENT:GetVehicleOwner()
    return self:GetNWEntity("Owner")
end

function ENT:SetOwnedId(id)
    self:SetNWInt("OwnedId", id or -1)
end

function ENT:GetOwnedId()
    return self:GetNWInt("OwnedId", -1)
end

function ENT:SetVehicleEntity(ent)
    return self:SetNWString("VehicleEntityIndex", ent:EntIndex())
end

function ENT:GetVehicleEntity()
    return ents.GetByIndex(self:GetNWString("VehicleEntityIndex"))
end

function ENT:GetVehiclePos()
    if not IsValid(self.VehicleEntity) then return nil end
    return self.VehicleEntity:GetPos()
end

-- Health functions
function ENT:SetHealth(amount)
    local veh = self.VehicleEntity
    if not IsValid(veh) then return end
    
    -- Set health using either SVMOD or directly
    if veh.SV_SetHealth then
        veh:SV_SetHealth(amount)
    else
        veh:SetNWFloat("Health", amount)
    end
end

function ENT:GetHealth()
    local veh = self.VehicleEntity
    if not IsValid(veh) then return 0 end
    
    -- Get health using either SVMOD or directly
    if veh.SV_GetHealth then
        return veh:SV_GetHealth()
    else
        return veh:GetNWFloat("Health", 1000)
    end
end

function ENT:SetMaxHealth(amount)
    local veh = self.VehicleEntity
    if not IsValid(veh) then return end
    
    -- Set max health using either SVMOD or directly
    if veh.SV_SetMaxHealth then
        veh:SV_SetMaxHealth(amount)
    else
        veh:SetNWFloat("MaxHealth", amount)
    end
end

function ENT:GetMaxHealth()
    local veh = self.VehicleEntity
    if not IsValid(veh) then return 0 end
    
    -- Get max health using either SVMOD or directly
    if veh.SV_GetMaxHealth then
        return veh:SV_GetMaxHealth()
    else
        return veh:GetNWFloat("MaxHealth", 1000)
    end
end

-- Fuel functions
function ENT:SetFuel(amount)
    local veh = self.VehicleEntity
    if not IsValid(veh) then return end
    
    -- Set fuel using either SVMOD or directly
    if veh.SV_SetFuel then
        veh:SV_SetFuel(amount)
    else
        veh:SetNWFloat("Fuel", amount)
    end
end

function ENT:GetFuel()
    local veh = self.VehicleEntity
    if not IsValid(veh) then return 0 end
    
    -- Get fuel using either SVMOD or directly
    if veh.SV_GetFuel then
        return veh:SV_GetFuel()
    else
        return veh:GetNWFloat("Fuel", 100)
    end
end

function ENT:SetMaxFuel(amount)
    local veh = self.VehicleEntity
    if not IsValid(veh) then return end
    
    -- Set max fuel using either SVMOD or directly
    if veh.SV_SetMaxFuel then
        veh:SV_SetMaxFuel(amount)
    else
        veh:SetNWFloat("MaxFuel", amount)
    end
end

function ENT:GetMaxFuel()
    local veh = self.VehicleEntity
    if not IsValid(veh) then return 0 end
    
    -- Get max fuel using either SVMOD or directly
    if veh.SV_GetMaxFuel then
        return veh:SV_GetMaxFuel()
    else
        return veh:GetNWFloat("MaxFuel", 100)
    end
end

function ENT:SetVehicleColor(color)
    local veh = self.VehicleEntity
    if IsValid(veh) then
        veh:SetColor(color)
    end
end

function ENT:SetColorFromArray(color)
    self:SetVehicleColor(Color(color[1], color[2], color[3], color[4] or 255))
end

function ENT:SetNitro(value)
    self:SetNWInt("ATOMIC_Nitro", value)
end

function ENT:GetNitro()
    return self:GetNWInt("ATOMIC_Nitro", 0)
end

function ENT:SetHydraulics(value)
    self:SetNWInt("ATOMIC_Hydraulics", value)
end

function ENT:GetHydraulics()
    return self:GetNWInt("ATOMIC_Hydraulics", 0)
end

function ENT:SetAssistedBreaks(value)
    self:SetNWInt("ATOMIC_AssistedBreaks", value)
end

function ENT:GetAssistedBreaks()
    return self:GetNWInt("ATOMIC_AssistedBreaks", 0)
end

function ENT:Lock()
    local veh = self.VehicleEntity
    if IsValid(veh) then
        -- Lock using either SVMOD or directly
        if veh.SV_Lock then
            veh:SV_Lock()
        else
            veh:Fire("Lock")
        end
        
        -- Play lock sound
        sound.Play("atomic/key_lock.wav", veh:GetPos(), 75)
    end
end

function ENT:Unlock()
    local veh = self.VehicleEntity
    if IsValid(veh) then
        -- Unlock using either SVMOD or directly
        if veh.SV_Unlock then
            veh:SV_Unlock()
        else
            veh:Fire("Unlock")
        end
        
        -- Play unlock sound
        sound.Play("atomic/key_lock.wav", veh:GetPos(), 75)
    end
end

function ENT:IsLocked()
    local veh = self.VehicleEntity
    if not IsValid(veh) then return true end
    
    -- Get locked state using either SVMOD or directly
    if veh.SV_GetLocked then
        return veh:SV_GetLocked()
    else
        return veh:GetInternalVariable("m_bLocked") or false
    end
end

function ENT:SetUpgrades(upgrades)
    self.Upgrades = self.Upgrades or {}
    upgrades = upgrades or {}

    for key, value in pairs(upgrades) do
        self.Upgrades[key] = value
    end
end

-- Clean up the vehicle entity when the custom entity is removed
function ENT:OnRemove()
    if IsValid(self.VehicleEntity) then
        self.VehicleEntity:Remove()
    end
    
    -- Get owner
    local owner = self:GetVehicleOwner()
    if IsValid(owner) then
        owner:SetCurrentVehicle(nil)
    end
end

function ENT:ApplyUpgrade(upgrade, value)
    local veh = self.VehicleEntity
    if not IsValid(veh) then return end
    
    if upgrade == "health" then
        self:SetHealth(value)
        self:SetMaxHealth(value)
    elseif upgrade == "fuel" then
        self:SetFuel(value)
        self:SetMaxFuel(value)
    elseif upgrade == "color" then
        self:SetColorFromArray(value)
    elseif upgrade == "nitro" then
        self:SetNitro(value)
    elseif upgrade == "hydraulics" then
        self:SetHydraulics(value)
    elseif upgrade == "assistedBreaks" then
        self:SetAssistedBreaks(value)
    elseif upgrade == "bodygroups" then
        for key, value in pairs(value) do
            veh:SetBodygroup(key, value)
        end
    elseif upgrade == "skin" then
        veh:SetSkin(value)
    elseif upgrade == "underglowColor" then
        if IsValid(self.underglow1) then
            self.underglow1:Remove()
            self.underglow1 = nil
        end
        if IsValid(self.underglow2) then
            self.underglow2:Remove()
            self.underglow2 = nil
        end
        
        -- Underglow light
        if self.Upgrades and self.Upgrades.underglow then
            local color = self.Upgrades.underglowColor or { 255, 0, 255 }
            
            local underglow1 = ents.Create("light_dynamic")
            underglow1:SetPos(veh:GetPos() + veh:GetRight() * 30)
            underglow1:SetKeyValue("_light", color[1] .. " " .. color[2] .. " " .. color[3] .. " 255")
            underglow1:SetKeyValue("brightness", "4")
            underglow1:SetKeyValue("distance", "100")
            underglow1:SetKeyValue("style", "0")
            underglow1:SetParent(veh)
            underglow1:Spawn()
            underglow1:Activate()
            
            local underglow2 = ents.Create("light_dynamic")
            underglow2:SetPos(veh:GetPos() - veh:GetRight() * 30)
            underglow2:SetKeyValue("_light", color[1] .. " " .. color[2] .. " " .. color[3] .. " 255")
            underglow2:SetKeyValue("brightness", "4")
            underglow2:SetKeyValue("distance", "100")
            underglow2:SetKeyValue("style", "0")
            underglow2:SetParent(veh)
            underglow2:Spawn()
            underglow2:Activate()

            self.underglow1 = underglow1
            self.underglow2 = underglow2
        end
    end
end

function ENT:ApplyUpgrades()
    if not IsValid(self.VehicleEntity) then return end
    
    -- Apply upgrades
    for key, value in pairs(self.Upgrades) do
        if value then
            self:ApplyUpgrade(key, value)
        end
    end
end

if CLIENT then
    function ENT:Draw()
        self:DrawModel()
    end
end

scripted_ents.Register(ENT, "atomic_vehicle")
