-- Example vehicle definition
local VEHICLE = {
    Name = "Aston Martin DB5",
    Brand = "Aston Martin",
    Model = "models/tdmcars/ast_db5.mdl",
    Category = "luxury",
    Script = "scripts/vehicles/tdmcars/ast_db5.txt",
    BasePrice = 3371086,
    MaxSpeed = 200,
    Health = 1000,
    Acceleration = 10,
    Weight = 10,
    Fuel = 100,
    FuelTank = 100,
    -- Use TDMCars vehicles or any other vehicle addon
    Class = "prop_vehicle_jeep", -- or "prop_vehicle_jeep_old" for HL2 jeep
}

ATOMIC:RegisterVehicle("aston_martin_db5", VEHICLE)
