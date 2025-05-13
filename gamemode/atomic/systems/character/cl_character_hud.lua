-- Character HUD display

local attributeIcons = {
    health = Material("icon16/heart.png"),
    stamina = Material("icon16/lightning.png"),
    hunger = Material("icon16/cake.png"),
    thirst = Material("icon16/drink.png"),
}

-- Define HUD positions and sizes
local HUD = {
    x = 20,
    y = ScrH() - 120,
    width = 200,
    height = 100,
    padding = 5,
    barHeight = 16,
    barSpacing = 5,
    textPadding = 5,
    backgroundColor = Color(0, 0, 0, 180),
    borderColor = Color(50, 50, 50, 200),
    textColor = Color(255, 255, 255, 255)
}

-- Color mapping for status bars
local statusColors = {
    health = {
        Color(200, 0, 0, 200),     -- Critical
        Color(255, 30, 30, 200),   -- Low
        Color(255, 100, 100, 200)  -- Normal
    },
    stamina = {
        Color(0, 100, 200, 200),   -- Critical
        Color(30, 150, 255, 200),  -- Low
        Color(100, 200, 255, 200)  -- Normal
    },
    hunger = {
        Color(200, 50, 0, 200),    -- Critical
        Color(255, 100, 0, 200),   -- Low
        Color(255, 160, 0, 200)    -- Normal
    },
    thirst = {
        Color(0, 50, 200, 200),    -- Critical
        Color(0, 100, 255, 200),   -- Low
        Color(100, 150, 255, 200)  -- Normal
    },
}

-- Get color based on percentage value
local function GetBarColor(type, percent)
    local colors = statusColors[type]
    if percent < 0.25 then
        return colors[1]
    elseif percent < 0.5 then
        return colors[2]
    else
        return colors[3]
    end
end

-- Draw the character status HUD
hook.Add("HUDPaint", "ATOMIC:CharacterStatusHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:HasCharacter() then return end
    
    -- Only draw if enabled in settings
    if ATOMIC.Config.ShowHUD == false then return end
    
    local health = ply:Health() / 100
    local armor = ply:Armor() / 100
    
    -- Get attribute values if available
    local stamina = 1
    local hunger = 1
    local thirst = 1
    
    if ATOMIC.Attributes and ATOMIC.Attributes.GetStatValue then
        stamina = ATOMIC.Attributes:GetStatValue("stamina") / 100
        hunger = ATOMIC.Attributes:GetStatValue("hunger") / 100
        thirst = ATOMIC.Attributes:GetStatValue("thirst") / 100
    end
    
    -- Background panel
    draw.RoundedBox(4, HUD.x, HUD.y, HUD.width, HUD.height, HUD.backgroundColor)
    draw.RoundedBoxEx(4, HUD.x, HUD.y - 25, HUD.width, 25, HUD.backgroundColor, true, true, false, false)
    
    -- Character name and money
    local charName = ply:GetCharacterName() or "Unknown Character"
    draw.SimpleText(charName, "DermaDefault", HUD.x + HUD.padding, HUD.y - 25 + HUD.textPadding, HUD.textColor)
    
    local money = ply:GetCash() or 0
    local moneyText = ATOMIC:MoneyToString(money)
    local moneyWidth = surface.GetTextSize(moneyText)
    draw.SimpleText(moneyText, "DermaDefault", HUD.x + HUD.width - moneyWidth - HUD.padding, 
        HUD.y - 25 + HUD.textPadding, Color(100, 255, 100, 255))
    
    -- Status bars
    local currentY = HUD.y + HUD.padding
    
    -- Health bar
    draw.RoundedBox(2, HUD.x + HUD.padding + 20, currentY, HUD.width - 2*HUD.padding - 20, HUD.barHeight, Color(50, 50, 50))
    draw.RoundedBox(2, HUD.x + HUD.padding + 20, currentY, (HUD.width - 2*HUD.padding - 20) * health, HUD.barHeight, 
        GetBarColor("health", health))
    surface.SetDrawColor(255, 255, 255, 255)
    surface.SetMaterial(attributeIcons.health)
    surface.DrawTexturedRect(HUD.x + HUD.padding, currentY, 16, 16)
    draw.SimpleText(math.floor(health * 100) .. "%", "DermaDefault", 
        HUD.x + HUD.width - 30, currentY + (HUD.barHeight/2) - 7, Color(255, 255, 255))
    
    currentY = currentY + HUD.barHeight + HUD.barSpacing
    
    -- Armor bar (only show if player has armor)
    if armor > 0 then
        draw.RoundedBox(2, HUD.x + HUD.padding, currentY, HUD.width - 2*HUD.padding, HUD.barHeight, Color(50, 50, 50))
        draw.RoundedBox(2, HUD.x + HUD.padding, currentY, (HUD.width - 2*HUD.padding) * armor, HUD.barHeight, Color(30, 80, 200))
        draw.SimpleText("Armor: " .. math.floor(armor * 100) .. "%", "DermaDefault", 
            HUD.x + HUD.padding + HUD.textPadding, currentY + (HUD.barHeight/2) - 7, Color(255, 255, 255))
        
        currentY = currentY + HUD.barHeight + HUD.barSpacing
    end
    
    -- Stamina bar (if attributes system is active)
    if ATOMIC.Attributes then
        -- Stamina
        draw.RoundedBox(2, HUD.x + HUD.padding + 20, currentY, HUD.width - 2*HUD.padding - 20, HUD.barHeight, Color(50, 50, 50))
        draw.RoundedBox(2, HUD.x + HUD.padding + 20, currentY, (HUD.width - 2*HUD.padding - 20) * stamina, HUD.barHeight, 
            GetBarColor("stamina", stamina))
        surface.SetDrawColor(255, 255, 255, 255)
        surface.SetMaterial(attributeIcons.stamina)
        surface.DrawTexturedRect(HUD.x + HUD.padding, currentY, 16, 16)
        draw.SimpleText(math.floor(stamina * 100) .. "%", "DermaDefault", 
            HUD.x + HUD.width - 30, currentY + (HUD.barHeight/2) - 7, Color(255, 255, 255))
        
        currentY = currentY + HUD.barHeight + HUD.barSpacing
        
        -- Hunger 
        draw.RoundedBox(2, HUD.x + HUD.padding + 20, currentY, HUD.width - 2*HUD.padding - 20, HUD.barHeight, Color(50, 50, 50))
        draw.RoundedBox(2, HUD.x + HUD.padding + 20, currentY, (HUD.width - 2*HUD.padding - 20) * hunger, HUD.barHeight, 
            GetBarColor("hunger", hunger))
        surface.SetDrawColor(255, 255, 255, 255)
        surface.SetMaterial(attributeIcons.hunger)
        surface.DrawTexturedRect(HUD.x + HUD.padding, currentY, 16, 16)
        draw.SimpleText(math.floor(hunger * 100) .. "%", "DermaDefault", 
            HUD.x + HUD.width - 30, currentY + (HUD.barHeight/2) - 7, Color(255, 255, 255))
        
        currentY = currentY + HUD.barHeight + HUD.barSpacing
        
        -- Thirst
        draw.RoundedBox(2, HUD.x + HUD.padding + 20, currentY, HUD.width - 2*HUD.padding - 20, HUD.barHeight, Color(50, 50, 50))
        draw.RoundedBox(2, HUD.x + HUD.padding + 20, currentY, (HUD.width - 2*HUD.padding - 20) * thirst, HUD.barHeight, 
            GetBarColor("thirst", thirst))
        surface.SetDrawColor(255, 255, 255, 255)
        surface.SetMaterial(attributeIcons.thirst)
        surface.DrawTexturedRect(HUD.x + HUD.padding, currentY, 16, 16)
        draw.SimpleText(math.floor(thirst * 100) .. "%", "DermaDefault", 
            HUD.x + HUD.width - 30, currentY + (HUD.barHeight/2) - 7, Color(255, 255, 255))
    end
end)

-- Hide default HL2 HUD elements
local hideHUDElements = {
    ["CHudHealth"] = true,
    ["CHudBattery"] = true,
    ["CHudAmmo"] = true,
    ["CHudSecondaryAmmo"] = true,
}

hook.Add("HUDShouldDraw", "ATOMIC:HideDefaultHUD", function(name)
    if hideHUDElements[name] then return false end
end)
