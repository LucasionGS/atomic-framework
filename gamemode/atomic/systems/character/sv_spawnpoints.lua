-- File: sv_spawnpoints.lua
-- Server-side spawn points for new characters

-- Define default spawn points for new characters
-- These are used when a character doesn't have a saved position
ATOMIC.Config.DefaultSpawnPoints = {
    Vector(0, 0, 100), -- Default fallback (replace with actual coordinates)
    
    -- Add map-specific spawn points here, examples:
    -- For rp_downtown_v4c_v2
    Vector(-782, -1219, 143),
    Vector(-684, -1231, 143),
    Vector(-596, -1247, 143),
    Vector(-511, -1267, 143),
    
    -- For rp_evocity_v2d
    Vector(-5439, -5764, 456),
    Vector(-5520, -5629, 456),
    Vector(-5602, -5499, 456),
    
    -- For rp_rockford_v2b
    Vector(-181, -58, 236),
    Vector(-281, -38, 236),
    Vector(-381, -18, 236),
}

-- Function to add a spawnpoint
function ATOMIC:AddSpawnPoint(position)
    if not position or not isvector(position) then return end
    
    table.insert(ATOMIC.Config.DefaultSpawnPoints, position)
    ATOMIC:Log("Added spawnpoint at " .. tostring(position))
end

-- Command to add a spawnpoint
ATOMIC:AddCommand("addspawn", function(player, args)
    local pos = player:GetPos()
    ATOMIC:AddSpawnPoint(pos)
    ATOMIC:Notify(player, "Added spawnpoint at " .. tostring(pos))
end, {
    rank = "admin",
    requireDuty = true
})

-- Command to list all spawnpoints
ATOMIC:AddCommand("listspawns", function(player, args)
    local count = #ATOMIC.Config.DefaultSpawnPoints
    
    if IsValid(player) then
        ATOMIC:Notify(player, "There are " .. count .. " spawnpoints defined.")
        
        for i, pos in ipairs(ATOMIC.Config.DefaultSpawnPoints) do
            ATOMIC:Notify(player, i .. ": " .. tostring(pos))
        end
    else
        -- Console output
        print("There are " .. count .. " spawnpoints defined.")
        
        for i, pos in ipairs(ATOMIC.Config.DefaultSpawnPoints) do
            print(i .. ": " .. tostring(pos))
        end
    end
end, {
    rank = "admin",
    requireDuty = true
})

-- Command to teleport to a spawnpoint
ATOMIC:AddCommand("gotopoint", function(player, args)
    local id = tonumber(args[2]) -- Get the argument from the args array
    
    if not id or not ATOMIC.Config.DefaultSpawnPoints[id] then
        ATOMIC:NotifyError(player, "Invalid spawnpoint ID.")
        return
    end
    
    player:SetPos(ATOMIC.Config.DefaultSpawnPoints[id])
    ATOMIC:Notify(player, "Teleported to spawnpoint " .. id .. ".")
end, {
    rank = "admin",
    requireDuty = true
})

-- Load spawnpoints from database (future implementation)
hook.Add("SV_ATOMIC:DatabaseReady", "ATOMIC:LoadSpawnpoints", function()
    -- In a future version, we could load spawn points from the database
    ATOMIC:Log("Loaded " .. #ATOMIC.Config.DefaultSpawnPoints .. " default spawn points.")
end)
