AddCSLuaFile()

SWEP.PrintName = "Property Manager Gun"
SWEP.Author = "Lucasion"
SWEP.Instructions = "Left Click: Select Door, Right Click: Create Property, Reload: Clear Selection"
SWEP.Category = "Atomic"
SWEP.Spawnable = false
SWEP.AdminSpawnable = true
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.Weight = 5
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.Slot = 5
SWEP.SlotPos = 2
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.ViewModel = "models/weapons/c_357.mdl"
SWEP.WorldModel = "models/weapons/w_357.mdl"

-- Keep track of selected doors
SWEP.SelectedDoors = {}
SWEP.PropertyData = {
    name = "",
    description = "",
    price = 50000,
    type = "house",
    group = "default",
    spawnPos = Vector(0, 0, 0),
    spawnAng = Angle(0, 0, 0)
}

function SWEP:Initialize()
    self:SetHoldType("revolver")
    self.SelectedDoors = {}
    self.PropertyData = {
        name = "",
        description = "",
        price = 50000,
        type = "house",
        group = "default",
        spawnPos = Vector(0, 0, 0),
        spawnAng = Angle(0, 0, 0)
    }
end

function SWEP:Deploy()
    self:ShowStatus()
    return true
end

function SWEP:ShowStatus()
    if SERVER then return end
    
    local doorCount = #self.SelectedDoors
    local message = "Property Gun: " .. doorCount .. " door(s) selected"
    
    chat.AddText(Color(50, 150, 255), message)
    
    if doorCount > 0 then
        chat.AddText(Color(255, 255, 255), "Right click to create a property with these doors")
    else
        chat.AddText(Color(255, 255, 255), "Left click to select doors")
    end
end

function SWEP:PrimaryAttack()
    if not self.Owner:IsSuperAdmin() then return end
    
    if CLIENT then return end
    
    local tr = self.Owner:GetEyeTrace()
    if not tr.Entity or not tr.Entity:IsValid() then return end
    
    -- Check if the entity is a door
    if not tr.Entity:IsDoor() then
        self.Owner:ChatPrint("You must select a door.")
        return
    end
    
    local doorIndex = tr.Entity:MapCreationID()
    local doorMap = game.GetMap()
    
    -- Check if the door is already selected
    for k, v in pairs(self.SelectedDoors) do
        if v.index == doorIndex and v.map == doorMap then
            self.Owner:ChatPrint("This door is already selected.")
            return
        end
    end
    
    -- Add the door to the selected doors
    table.insert(self.SelectedDoors, {
        index = doorIndex,
        map = doorMap,
        entity = tr.Entity
    })
    
    self.Owner:ChatPrint("Door selected. Total: " .. #self.SelectedDoors .. " door(s)")
    
    -- Send updated selection to client
    net.Start("ATOMIC:PropertyGun:UpdateSelection")
    net.WriteTable(self.SelectedDoors)
    net.Send(self.Owner)
end

function SWEP:SecondaryAttack()
    if not self.Owner:IsSuperAdmin() then return end
    
    if CLIENT then
        if #self.SelectedDoors == 0 then
            chat.AddText(Color(255, 100, 100), "No doors selected.")
            return
        end
        
        -- Open property creation menu
        self:OpenPropertyMenu()
        return
    end
end

function SWEP:Reload()
    if not self.Owner:IsSuperAdmin() then return end
    
    if SERVER then
        -- Clear selected doors
        self.SelectedDoors = {}
        self.Owner:ChatPrint("Selected doors cleared.")
        
        -- Send updated selection to client
        net.Start("ATOMIC:PropertyGun:UpdateSelection")
        net.WriteTable(self.SelectedDoors)
        net.Send(self.Owner)
    end
end

if CLIENT then
    -- Create property menu
    function SWEP:OpenPropertyMenu()
        local frame = vgui.Create("DFrame")
        frame:SetSize(400, 500)
        frame:SetTitle("Create Property")
        frame:Center()
        frame:MakePopup()
        
        local scroll = vgui.Create("DScrollPanel", frame)
        scroll:Dock(FILL)
        
        -- Name field
        local nameLabel = vgui.Create("DLabel", scroll)
        nameLabel:SetText("Property Name:")
        nameLabel:Dock(TOP)
        nameLabel:DockMargin(10, 10, 10, 0)
        
        local nameEntry = vgui.Create("DTextEntry", scroll)
        nameEntry:SetValue(self.PropertyData.name)
        nameEntry:Dock(TOP)
        nameEntry:DockMargin(10, 5, 10, 10)
        nameEntry.OnChange = function(self)
            self:GetParent():GetParent():GetParent().Weapon.PropertyData.name = self:GetValue()
        end
        
        -- Description field
        local descLabel = vgui.Create("DLabel", scroll)
        descLabel:SetText("Description:")
        descLabel:Dock(TOP)
        descLabel:DockMargin(10, 0, 10, 0)
        
        local descEntry = vgui.Create("DTextEntry", scroll)
        descEntry:SetValue(self.PropertyData.description)
        descEntry:Dock(TOP)
        descEntry:DockMargin(10, 5, 10, 10)
        descEntry.OnChange = function(self)
            self:GetParent():GetParent():GetParent().Weapon.PropertyData.description = self:GetValue()
        end
        
        -- Price field
        local priceLabel = vgui.Create("DLabel", scroll)
        priceLabel:SetText("Price:")
        priceLabel:Dock(TOP)
        priceLabel:DockMargin(10, 0, 10, 0)
        
        local priceEntry = vgui.Create("DNumberWang", scroll)
        priceEntry:SetValue(self.PropertyData.price)
        priceEntry:SetMinMax(1, 10000000)
        priceEntry:Dock(TOP)
        priceEntry:DockMargin(10, 5, 10, 10)
        priceEntry.OnValueChanged = function(self, val)
            self:GetParent():GetParent():GetParent().Weapon.PropertyData.price = val
        end
        
        -- Type field
        local typeLabel = vgui.Create("DLabel", scroll)
        typeLabel:SetText("Type:")
        typeLabel:Dock(TOP)
        typeLabel:DockMargin(10, 0, 10, 0)
        
        local typeCombo = vgui.Create("DComboBox", scroll)
        typeCombo:SetValue(self.PropertyData.type)
        typeCombo:AddChoice("house")
        typeCombo:AddChoice("business")
        typeCombo:AddChoice("government")
        typeCombo:AddChoice("apartment")
        typeCombo:Dock(TOP)
        typeCombo:DockMargin(10, 5, 10, 10)
        typeCombo.OnSelect = function(self, index, value)
            self:GetParent():GetParent():GetParent().Weapon.PropertyData.type = value
        end
        
        -- Group field
        local groupLabel = vgui.Create("DLabel", scroll)
        groupLabel:SetText("Group:")
        groupLabel:Dock(TOP)
        groupLabel:DockMargin(10, 0, 10, 0)
        
        local groupEntry = vgui.Create("DTextEntry", scroll)
        groupEntry:SetValue(self.PropertyData.group)
        groupEntry:Dock(TOP)
        groupEntry:DockMargin(10, 5, 10, 10)
        groupEntry.OnChange = function(self)
            self:GetParent():GetParent():GetParent().Weapon.PropertyData.group = self:GetValue()
        end
        
        -- Spawn position and angle
        local spawnPosLabel = vgui.Create("DLabel", scroll)
        spawnPosLabel:SetText("Spawn Position:")
        spawnPosLabel:Dock(TOP)
        spawnPosLabel:DockMargin(10, 0, 10, 0)
        
        local spawnPosButton = vgui.Create("DButton", scroll)
        spawnPosButton:SetText("Set to Current Position")
        spawnPosButton:Dock(TOP)
        spawnPosButton:DockMargin(10, 5, 10, 10)
        spawnPosButton.DoClick = function()
            local ply = LocalPlayer()
            if IsValid(ply) then
                local pos = ply:GetPos()
                local ang = ply:EyeAngles()
                ang.p = 0 -- Zero out pitch
                ang.r = 0 -- Zero out roll
                
                self.PropertyData.spawnPos = pos
                self.PropertyData.spawnAng = ang
                
                chat.AddText(Color(100, 255, 100), "Spawn position and angle set to your current position.")
            end
        end
        
        -- Create property button
        local createButton = vgui.Create("DButton", scroll)
        createButton:SetText("Create Property")
        createButton:Dock(TOP)
        createButton:DockMargin(10, 20, 10, 10)
        createButton:SetHeight(40)
        createButton.DoClick = function()
            -- Validate input
            if string.Trim(self.PropertyData.name) == "" then
                chat.AddText(Color(255, 100, 100), "Property must have a name.")
                return
            end
            
            if self.PropertyData.price <= 0 then
                chat.AddText(Color(255, 100, 100), "Price must be greater than 0.")
                return
            end
            
            -- Generate a unique ID for the property
            local id = string.lower(string.gsub(self.PropertyData.name, "[^%w]", "_"))
            id = id .. "_" .. os.time()
            
            -- Send property data to server
            net.Start("ATOMIC:PropertyGun:CreateProperty")
            net.WriteString(id)
            net.WriteTable(self.PropertyData)
            net.SendToServer()
            
            frame:Close()
        end
    end
end

if SERVER then
    -- Register network strings
    util.AddNetworkString("ATOMIC:PropertyGun:UpdateSelection")
    util.AddNetworkString("ATOMIC:PropertyGun:CreateProperty")
    
    -- Handle property creation
    net.Receive("ATOMIC:PropertyGun:CreateProperty", function(len, ply)
        if not ply:IsSuperAdmin() then return end
        
        local weapon = ply:GetWeapon("property_manager_gun")
        if not IsValid(weapon) then return end
        
        local id = net.ReadString()
        local propertyData = net.ReadTable()
        
        -- Create the property data
        local property = {
            name = propertyData.name,
            description = propertyData.description,
            price = propertyData.price,
            type = propertyData.type,
            group = propertyData.group,
            spawnPos = propertyData.spawnPos,
            spawnAng = propertyData.spawnAng,
            doors = {}
        }
        
        -- Add doors to the property
        for _, door in pairs(weapon.SelectedDoors) do
            table.insert(property.doors, {
                map = door.map,
                index = door.index
            })
        end
        
        -- Register the property
        ATOMIC:RegisterProperty(id, property)
        
        -- Save properties
        ATOMIC:SaveProperties()
        
        -- Update door ownership
        ATOMIC:UpdateDoorOwnership()
        
        -- Send properties to all players
        ATOMIC:SendPropertiesToPlayers(player.GetAll())
        
        -- Clear selected doors
        weapon.SelectedDoors = {}
        ply:ChatPrint("Property '" .. propertyData.name .. "' created successfully!")
    end)
end

-- Add entity method to check if it's a door
local doorClasses = {
    ["func_door"] = true,
    ["func_door_rotating"] = true,
    ["prop_door_rotating"] = true
}

function ENT:IsDoor()
    return doorClasses[self:GetClass()] or false
end
