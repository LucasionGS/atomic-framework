function ATOMIC:Debug(...)
    if ATOMIC.Config.Debug then
        MsgC(Color(203, 152, 24),  "[Atomic Debug] ", Color(214, 214, 214), ...)
        MsgC("\n")
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