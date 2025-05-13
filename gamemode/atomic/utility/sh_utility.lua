function ATOMIC:Debug(...)
    if ATOMIC.Config.Debug then
        MsgC(Color(203, 152, 24),  "[Atomic Debug] ", Color(214, 214, 214), ...)
        MsgC("\n")
    end
end

function ATOMIC:Print(...)
    MsgC(Color(65, 105, 225), "[Atomic] ", Color(255, 255, 255), ...)
    MsgC("\n")
end

function ATOMIC:Log(category, ply, ...)
    if SERVER then
        local prefix = ""
        if ply and IsValid(ply) and ply:IsPlayer() then
            prefix = "(" .. ply:SteamID64() .. ") "
        end
        
        local message = prefix .. table.concat({...}, " ")
        ATOMIC:Print("[" .. category .. "] " .. message)
        
        -- TODO: Add database logging functionality
    end
end

function ATOMIC:Error(...)
    MsgC(Color(203, 24, 24),  "[Atomic Error] ", Color(247, 197, 197), ...)
    MsgC("\n")
end

function ATOMIC:Raise(...)
    Error("[Atomic Raised Error]", ...)
end

function ATOMIC:ColorToHex(color)
    if not color or not IsColor(color) then
        return nil
    end

    local r, g, b = color.r, color.g, color.b
    local hex = string.format("#%02X%02X%02X", r, g, b)

    return hex
end

function ATOMIC:HexToColor(hex)
    if not hex or type(hex) ~= "string" then
        return nil
    end

    local r, g, b = string.match(hex, "#(%x%x)(%x%x)(%x%x)")
    if not r or not g or not b then
        return nil
    end

    return Color(tonumber(r, 16), tonumber(g, 16), tonumber(b, 16))
end

function ATOMIC:LightenColor(color, amount)
    local newColor = Color(
        math.Clamp(color.r + amount, 0, 255), 
        math.Clamp(color.g + amount, 0, 255), 
        math.Clamp(color.b + amount, 0, 255), 
        color.a
    )
    return newColor
end

function ATOMIC:DarkenColor(color, amount)
    local newColor = Color(
        math.Clamp(color.r - amount, 0, 255), 
        math.Clamp(color.g - amount, 0, 255), 
        math.Clamp(color.b - amount, 0, 255), 
        color.a
    )
    return newColor
end

-- Get position vector and angle from a getpos console command output
function ATOMIC:GetPosStringToVector(getposOutput)
    -- Format: setpos -7073.956543 -8901.465820 136.031250;setang -1.388707 0.561369 0.000000
    local split = string.Explode(';', getposOutput)
    local posString = split[1]
    local angString = split[2]
    local pos = string.Explode(' ', posString)
    local posVector = Vector(pos[2], pos[3], pos[4])
    
    local ang = string.Explode(' ', angString)
    local angVector = Angle(ang[2], ang[3], ang[4])

    return posVector, angVector
end

-- Find a player by identifier (name, steamid, etc.)
function ATOMIC:FindPlayer(identifier)
    local ply = player.GetBySteamID64(identifier)
    if IsValid(ply) then return ply end
    ply = player.GetBySteamID(identifier)
    if IsValid(ply) then return ply end
    ply = player.GetByUniqueID(identifier)
    if IsValid(ply) then return ply end

    for _, ply in ipairs(player.GetAll()) do
        if string.find(string.lower(ply:Nick()), string.lower(identifier)) then return ply end
    end

    return nil
end

-- Helper to check if a player has a specific rank or higher
function ATOMIC:IsRankEqualOrHigher(playerRank, requiredRank)
    if not ATOMIC.Ranks then return false end
    
    local playerRankIndex = table.KeyFromValue(ATOMIC.Ranks, playerRank)
    local requiredRankIndex = table.KeyFromValue(ATOMIC.Ranks, requiredRank)
    
    if not playerRankIndex or not requiredRankIndex then return false end
    
    return playerRankIndex >= requiredRankIndex
end

-- Convert time in seconds to a human readable format
function ATOMIC:SecondsToTime(seconds)
    if not seconds or seconds < 0 then return "0s" end
    
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    
    local timeStr = ""
    if hours > 0 then timeStr = timeStr .. hours .. "h " end
    if minutes > 0 then timeStr = timeStr .. minutes .. "m " end
    if secs > 0 or (hours == 0 and minutes == 0) then timeStr = timeStr .. secs .. "s" end
    
    return timeStr
end

-- Load all the files in a folder
function ATOMIC:LoadFolder(folderPath, prefix)
    local files, folders = file.Find(folderPath .. "/*", "LUA")
    
    for _, f in ipairs(files) do
        if string.EndsWith(f, ".lua") then
            if prefix then
                if string.StartWith(f, prefix .. "_") then
                    ATOMIC:AddFile(f, folderPath .. "/")
                end
            else
                ATOMIC:AddFile(f, folderPath .. "/")
            end
        end
    end
    
    for _, f in ipairs(folders) do
        ATOMIC:LoadFolder(folderPath .. "/" .. f, prefix)
    end
end