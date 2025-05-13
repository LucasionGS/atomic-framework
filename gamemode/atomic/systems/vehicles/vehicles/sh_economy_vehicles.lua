-- Example economy vehicles
local VEHICLE = {
    Name = "Toyota Corolla",
    Brand = "Toyota",
    Model = "models/tdmcars/toyotacorolla.mdl", -- Replace with actual model path if different
    Category = "economy",
    Script = "scripts/vehicles/tdmcars/toyotacorolla.txt", -- Replace with actual script path
    BasePrice = 25000,
    MaxSpeed = 150,
    Health = 800,
    Acceleration = 8,
    Weight = 8,
    Fuel = 100,
    FuelTank = 100,
    Class = "prop_vehicle_jeep",
}

ATOMIC:RegisterVehicle("toyota_corolla", VEHICLE)

local VEHICLE = {
    Name = "Honda Civic",
    Brand = "Honda",
    Model = "models/tdmcars/hon_civic.mdl", -- Replace with actual model path if different
    Category = "economy",
    Script = "scripts/vehicles/tdmcars/hon_civic.txt", -- Replace with actual script path
    BasePrice = 22000,
    MaxSpeed = 145,
    Health = 750,
    Acceleration = 7,
    Weight = 7,
    Fuel = 100,
    FuelTank = 100,
    Class = "prop_vehicle_jeep",
}

ATOMIC:RegisterVehicle("honda_civic", VEHICLE)
