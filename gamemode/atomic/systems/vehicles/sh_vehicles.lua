--[[
    Shared Vehicle System
    This file contains shared functionality for the vehicle system.
]]--

ATOMIC.Vehicles = ATOMIC.Vehicles or {}
ATOMIC.VehicleCategories = ATOMIC.VehicleCategories or {}

-- Register a vehicle category
function ATOMIC:RegisterVehicleCategory(id, name, icon)
    ATOMIC.VehicleCategories[id] = {
        name = name,
        icon = icon or "icon16/car.png"
    }
end

-- Register a vehicle
function ATOMIC:RegisterVehicle(id, data)
    ATOMIC.Vehicles[id] = data
end

-- Check if a player can afford a vehicle
function ATOMIC:CanAffordVehicle(ply, vehicleId)
    local vehicle = ATOMIC.Vehicles[vehicleId]
    if not vehicle then return false end
    
    return ply:GetCash() >= vehicle.BasePrice
end

-- Get all vehicles in a category
function ATOMIC:GetVehiclesByCategory(category)
    local vehicles = {}
    
    for id, data in pairs(ATOMIC.Vehicles) do
        if data.Category == category then
            vehicles[id] = data
        end
    end
    
    return vehicles
end

-- Get all vehicle categories
function ATOMIC:GetVehicleCategories()
    return ATOMIC.VehicleCategories
end

-- Load vehicle definitions
function ATOMIC:LoadVehicles()
    -- Register default categories
    ATOMIC:RegisterVehicleCategory("economy", "Economy")
    ATOMIC:RegisterVehicleCategory("sports", "Sports")
    ATOMIC:RegisterVehicleCategory("luxury", "Luxury")
    ATOMIC:RegisterVehicleCategory("offroad", "Off-Road")
    ATOMIC:RegisterVehicleCategory("heavy", "Heavy Duty")
    ATOMIC:RegisterVehicleCategory("emergency", "Emergency")
    ATOMIC:RegisterVehicleCategory("other", "Other")

    -- Load vehicle files
    ATOMIC:IncludeDir("gamemode/atomic/systems/vehicles/vehicles", "sh")
end

-- Player meta functions
local playerMeta = FindMetaTable("Player")

function playerMeta:OwnedVehicles(callback)
    if SERVER then
        ATOMIC.VehicleManager:GetPlayerVehicles(self, callback)
    else
        net.Start("ATOMIC_VehicleManager_GetPlayerVehicles")
        net.SendToServer()
    end
end

function playerMeta:SetCurrentVehicle(vehicle)
    self:SetNWEntity("ATOMIC_CurrentVehicle", vehicle)
end

function playerMeta:GetCurrentVehicle()
    return self:GetNWEntity("ATOMIC_CurrentVehicle")
end

-- Load the vehicles when this file is executed
ATOMIC:LoadVehicles()
