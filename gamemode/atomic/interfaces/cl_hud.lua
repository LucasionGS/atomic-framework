--[[
    Available HUDs
    - CHudChat
    - CHudWeaponSelection
    - CHUDQuickInfo
    - CHudHealth
    - CHudSecondaryAmmo
    - CHudAmmo
    - CHudTrain
    - CHudMessage
    - CHudMenu
    - CHudWeapon
    - CHudCrosshair
    - CHudCloseCaption
    - CHudGMod
    - CHudChat
    - CHudWeaponSelection
    - CHUDQuickInfo
    - CHudHealth
    - CHudSecondaryAmmo
    - CHudAmmo
    - CHudTrain
    - CHudMessage
    - CHudMenu
    - CHudWeapon
    - CHudCrosshair
    - CHudCloseCaption
    - CHudGMod
]]--

-- Disables the default HUD
hook.Add("HUDShouldDraw", "AtomicHudShouldDraw", function(name) 
    -- print("HUDShouldDraw", name)
    if name == "CHudHealth" or name == "CHudBattery" then
        return false
    end
end)

--[[
    HUD management functions
]]--
function ATOMIC:DrawHUD()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local colors = ATOMIC.Config.Colors
    local screenWidth, screenHeight = ScrW(), ScrH()
    local hudWidth, hudHeight = 300, 100
    -- local hudX, hudY = screenWidth - hudWidth - 20, screenHeight - hudHeight - 20
    local hudX, hudY = hudWidth + 20, screenHeight - hudHeight - 40
    
    -- Draw the health bar
    local health = ply:Health()
    local maxHealth = ply:GetMaxHealth()
    local healthPercent = health / maxHealth
    local healthBarWidth = 200
    local healthBarHeight = 20

    -- Draw the health bar background
    surface.SetDrawColor(colors.Background)
    surface.DrawRect(hudX, hudY, healthBarWidth, healthBarHeight)
    -- Draw the health bar
    surface.SetDrawColor(colors.Primary)
    surface.DrawRect(hudX, hudY, healthBarWidth * healthPercent, healthBarHeight)
    -- Draw the health text
    draw.SimpleText("Health: " .. health .. "/" .. maxHealth, "AtomicHud", hudX, hudY + healthBarHeight / 2, colors.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    -- Draw the job name
    local jobName = ply:GetJob()
    if jobName then
        draw.SimpleText("Job: " .. jobName, "AtomicHud", hudX, hudY + healthBarHeight + 10, colors.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    -- Draw the money
    local money = ply:GetMoney()
    local bank = ply:GetBank()
    draw.SimpleText("Money: " .. ATOMIC:MoneyToString(money), "AtomicHud", hudX, hudY + healthBarHeight + 30, colors.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText("Bank: " .. ATOMIC:MoneyToString(bank), "AtomicHud", hudX, hudY + healthBarHeight + 50, colors.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    -- Draw the ammo
    local weapon = ply:GetActiveWeapon()
    if IsValid(weapon) and weapon:IsWeapon() then
        local ammoCount = ply:GetAmmoCount(weapon:GetPrimaryAmmoType())
        local maxAmmo = weapon:GetMaxClip1()
        draw.SimpleText("Ammo: " .. ammoCount .. "/" .. maxAmmo, "AtomicHud", hudX, hudY + healthBarHeight + 70, colors.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    -- Draw the armor
    local armor = ply:Armor()
    local maxArmor = ply:GetMaxArmor()
    draw.SimpleText("Armor: " .. armor .. "/" .. maxArmor, "AtomicHud", hudX, hudY + healthBarHeight + 90, colors.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

function GM:HUDPaint()
    ATOMIC:DrawHUD()
end