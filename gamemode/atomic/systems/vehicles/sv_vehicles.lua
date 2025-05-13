--[[
    Server-side Vehicle System
    This file contains server-side functionality for the vehicle system.
]]--

ATOMIC.VehicleManager = ATOMIC.VehicleManager or {}

-- Network strings
util.AddNetworkString("ATOMIC_VehicleManager_BuyVehicle")
util.AddNetworkString("ATOMIC_VehicleManager_TestVehicle")
util.AddNetworkString("ATOMIC_VehicleManager_SpawnVehicle")
util.AddNetworkString("ATOMIC_VehicleManager_SellVehicle")
util.AddNetworkString("ATOMIC_VehicleManager_GetPlayerVehicles")

-- Get a player's vehicles
function ATOMIC.VehicleManager:GetPlayerVehicles(ply, callback)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    local query = ATOMIC.Database:Select("atomic_vehicles")
    query:Where("owner_id", ply:SteamID64())
    query:Order("id", "ASC")
    query:Callback(function(result, status, lastID)
        if result then
            -- Send the vehicles to the client
            if callback then
                callback(result)
            else
                net.Start("ATOMIC_VehicleManager_GetPlayerVehicles")
                net.WriteTable(result)
                net.Send(ply)
            end
        else
            ATOMIC:Error("Failed to get player vehicles: " .. status)
            if callback then
                callback({})
            else
                net.Start("ATOMIC_VehicleManager_GetPlayerVehicles")
                net.WriteTable({})
                net.Send(ply)
            end
        end
    end)
    
    query:Execute()
end

-- Get a specific owned vehicle by ID
function ATOMIC.VehicleManager:GetOwnedVehicle(vehicleId, callback)
    local query = ATOMIC.Database:Select("atomic_vehicles")
    query:Where("id", vehicleId)
    query:Callback(function(result, status, lastID)
        if result and #result > 0 then
            callback(result[1])
        else
            callback(nil)
        end
    end)
    
    query:Execute()
end

-- Update an owned vehicle
function ATOMIC.VehicleManager:UpdateOwnedVehicle(vehicleId, data, callback)
    local query = ATOMIC.Database:Update("atomic_vehicles", data)
    query:Where("id", vehicleId)
    query:Callback(function(result, status, lastID)
        if callback then
            callback(result, status)
        end
    end)
    
    query:Execute()
end

-- Buy a vehicle
function ATOMIC.VehicleManager:BuyVehicle(ply, vehicleId)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    local vehicle = ATOMIC.Vehicles[vehicleId]
    if not vehicle then
        ply:Notify("That vehicle does not exist.", NOTIFY_ERROR)
        return
    end
    
    if not ATOMIC:CanAffordVehicle(ply, vehicleId) then
        ply:Notify("You cannot afford this vehicle.", NOTIFY_ERROR)
        return
    end
    
    -- Take money from player
    ply:AddMoney(-vehicle.BasePrice)
    
    -- Add vehicle to database
    local data = {
        owner_id = ply:SteamID64(),
        vehicle_id = vehicleId,
        health = ATOMIC.Config.VehicleBaseHealth,
        fuel = ATOMIC.Config.VehicleMaxFuel,
        purchase_date = os.time(),
        upgrades = util.TableToJSON({}),
        last_position = util.TableToJSON({x = 0, y = 0, z = 0}),
    }
    
    local query = ATOMIC.Database:Insert("atomic_vehicles", data)
    query:Callback(function(result, status, lastID)
        if result then
            ply:Notify("You have purchased a " .. vehicle.Name .. "!", NOTIFY_GENERIC)
        else
            -- Refund the player if the purchase fails
            ply:AddMoney(vehicle.BasePrice)
            ply:Notify("Failed to purchase vehicle: " .. status, NOTIFY_ERROR)
        end
    end)
    
    query:Execute()
end

-- Test drive a vehicle
function ATOMIC.VehicleManager:TestDriveVehicle(ply, vehicleId)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    local vehicle = ATOMIC.Vehicles[vehicleId]
    if not vehicle then
        ply:Notify("That vehicle does not exist.", NOTIFY_ERROR)
        return
    end
    
    -- Store the player's current position
    ply:SetNWVector("ATOMIC_TestDrive_PrevPos", ply:GetPos())
    
    -- Spawn the vehicle
    local veh = self:SpawnVehicle(ply, vehicleId, {}, nil)
    
    if veh then
        ply:Notify("Test drive started. You have " .. ATOMIC.Config.VehicleTestDuration .. " seconds.", NOTIFY_GENERIC)
        
        -- Set a timer to end the test drive
        timer.Create("ATOMIC_TestDrive_" .. ply:SteamID64(), ATOMIC.Config.VehicleTestDuration, 1, function()
            if IsValid(veh) then
                veh:Remove()
            end
            
            if IsValid(ply) then
                -- Return the player to their original position
                ply:SetPos(ply:GetNWVector("ATOMIC_TestDrive_PrevPos"))
                ply:SetNWVector("ATOMIC_TestDrive_PrevPos", nil)
                ply:Notify("Your test drive has ended.", NOTIFY_GENERIC)
            end
        end)
    end
end

-- Spawn a vehicle
function ATOMIC.VehicleManager:SpawnVehicle(ply, vehicleId, upgrades, ownedVehicleId)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    local vehicleData = ATOMIC.Vehicles[vehicleId]
    if not vehicleData then
        ply:Notify("That vehicle does not exist.", NOTIFY_ERROR)
        return nil
    end
    
    -- Create the vehicle entity
    local vehicle = ents.Create("atomic_vehicle")
    if not IsValid(vehicle) then
        ply:Notify("Failed to create vehicle.", NOTIFY_ERROR)
        return nil
    end
    
    -- Set up the vehicle
    vehicle:SetVehicle(vehicleId)
    vehicle:SetVehicleOwner(ply)
    vehicle:SetUpgrades(upgrades or {})
    vehicle:SetOwnedId(ownedVehicleId or -1)
    
    -- Position the vehicle
    local spawnPos = ply:GetPos() + ply:GetForward() * 100
    local trace = util.TraceLine({
        start = spawnPos,
        endpos = spawnPos - Vector(0, 0, 100),
        filter = ply
    })
    
    local finalPos = trace.HitPos + Vector(0, 0, 20)
    vehicle:SetPos(finalPos)
    vehicle:SetAngles(ply:GetAngles())
    
    -- Spawn the vehicle
    vehicle:Spawn()
    vehicle:Activate()
    
    -- Set as player's current vehicle
    ply:SetCurrentVehicle(vehicle)
    
    -- If this is an owned vehicle, apply health and fuel
    if ownedVehicleId and ownedVehicleId ~= -1 then
        self:GetOwnedVehicle(ownedVehicleId, function(data)
            if IsValid(vehicle) and data then
                -- Apply vehicle data from database
                local upgrades = util.JSONToTable(data.upgrades or "{}")
                vehicle:SetUpgrades(upgrades)
                
                -- Set health and fuel
                if IsValid(vehicle.VehicleEntity) then
                    vehicle:SetHealth(data.health or ATOMIC.Config.VehicleBaseHealth)
                    vehicle:SetMaxHealth(data.health or ATOMIC.Config.VehicleBaseHealth)
                    vehicle:SetFuel(data.fuel or ATOMIC.Config.VehicleMaxFuel)
                    vehicle:SetMaxFuel(ATOMIC.Config.VehicleMaxFuel)
                    
                    -- Lock the vehicle by default
                    vehicle:Lock()
                end
                
                -- Update vehicle position in database
                local pos = {
                    x = vehicle:GetPos().x,
                    y = vehicle:GetPos().y,
                    z = vehicle:GetPos().z
                }
                self:UpdateOwnedVehicle(ownedVehicleId, {
                    last_position = util.TableToJSON(pos)
                })
            end
        end)
    end
    
    return vehicle
end

-- Sell a vehicle
function ATOMIC.VehicleManager:SellVehicle(ply, vehicleId)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    self:GetOwnedVehicle(vehicleId, function(data)
        if not data then
            ply:Notify("Vehicle not found.", NOTIFY_ERROR)
            return
        end
        
        if tostring(data.owner_id) ~= ply:SteamID64() then
            ply:Notify("You don't own that vehicle.", NOTIFY_ERROR)
            return
        end
        
        local vehicle = ATOMIC.Vehicles[data.vehicle_id]
        if not vehicle then
            ply:Notify("Vehicle type not found.", NOTIFY_ERROR)
            return
        end
        
        -- Calculate sell price (50% of purchase price)
        local sellPrice = math.floor((vehicle.BasePrice or 0) * 0.5)
        
        -- Give money to player
        ply:AddMoney(sellPrice)
        
        -- Remove from database
        local query = ATOMIC.Database:Delete("atomic_vehicles")
        query:Where("id", vehicleId)
        query:Callback(function(result, status, lastID)
            if result then
                ply:Notify("You sold your " .. vehicle.Name .. " for $" .. string.Comma(sellPrice) .. ".", NOTIFY_GENERIC)
            else
                -- Refund the money if the sale fails
                ply:AddMoney(-sellPrice)
                ply:Notify("Failed to sell vehicle: " .. status, NOTIFY_ERROR)
            end
        end)
        
        query:Execute()
    end)
end

-- IsAtomVehicle check function
function ATOMIC.VehicleManager:IsAtomicVehicle(vehicle)
    return IsValid(vehicle) and vehicle:IsVehicle() and vehicle:GetNWBool("IsAtomicVehicle", false)
end

-- Network message handlers
net.Receive("ATOMIC_VehicleManager_BuyVehicle", function(len, ply)
    local vehicleId = net.ReadString()
    ATOMIC.VehicleManager:BuyVehicle(ply, vehicleId)
end)

net.Receive("ATOMIC_VehicleManager_TestVehicle", function(len, ply)
    local vehicleId = net.ReadString()
    ATOMIC.VehicleManager:TestDriveVehicle(ply, vehicleId)
end)

net.Receive("ATOMIC_VehicleManager_SpawnVehicle", function(len, ply)
    local vehicleId = net.ReadInt(32)
    ATOMIC.VehicleManager:GetOwnedVehicle(vehicleId, function(data)
        if data and tostring(data.owner_id) == ply:SteamID64() then
            ATOMIC.VehicleManager:SpawnVehicle(ply, data.vehicle_id, util.JSONToTable(data.upgrades or "{}"), vehicleId)
        else
            ply:Notify("You don't own that vehicle.", NOTIFY_ERROR)
        end
    end)
end)

net.Receive("ATOMIC_VehicleManager_SellVehicle", function(len, ply)
    local vehicleId = net.ReadInt(32)
    ATOMIC.VehicleManager:SellVehicle(ply, vehicleId)
end)

net.Receive("ATOMIC_VehicleManager_GetPlayerVehicles", function(len, ply)
    ATOMIC.VehicleManager:GetPlayerVehicles(ply)
end)

-- Initialize database table
hook.Add("ATOMIC:DatabaseReady", "ATOMIC_VehicleManager_Init", function()
    ATOMIC.Database:CreateTable("atomic_vehicles", {
        { name = "id", type = "INT NOT NULL AUTO_INCREMENT PRIMARY KEY" },
        { name = "owner_id", type = "VARCHAR(64) NOT NULL" },
        { name = "vehicle_id", type = "VARCHAR(64) NOT NULL" },
        { name = "health", type = "FLOAT NOT NULL DEFAULT 1000" },
        { name = "fuel", type = "FLOAT NOT NULL DEFAULT 100" },
        { name = "purchase_date", type = "INT NOT NULL" },
        { name = "upgrades", type = "TEXT" },
        { name = "last_position", type = "TEXT" },
    })
end)
