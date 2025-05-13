--[[
    Client-side Vehicle System
    This file contains client-side functionality for the vehicle system.
]]--

-- Vehicle menus and UI will be implemented here
net.Receive("ATOMIC_VehicleManager_GetPlayerVehicles", function(len)
    local vehicles = net.ReadTable()
    hook.Run("ATOMIC_PlayerVehiclesUpdated", vehicles)
end)

-- Create a vehicle dealer menu
function ATOMIC:OpenVehicleDealerMenu(dealer)
    -- Create a frame for the vehicle dealer menu
    local frame = vgui.Create("DFrame")
    frame:SetSize(800, 600)
    frame:SetTitle(dealer.name or "Vehicle Dealer")
    frame:Center()
    frame:MakePopup()
    
    -- Create a tab panel for different vehicle categories
    local tabs = vgui.Create("DPropertySheet", frame)
    tabs:Dock(FILL)
    
    -- Add tabs for each vehicle category
    for categoryId, category in pairs(ATOMIC:GetVehicleCategories()) do
        local vehicles = ATOMIC:GetVehiclesByCategory(categoryId)
        
        if table.Count(vehicles) > 0 then
            local panel = vgui.Create("DPanel")
            
            -- Create a scroll panel to hold the vehicles
            local scroll = vgui.Create("DScrollPanel", panel)
            scroll:Dock(FILL)
            
            -- Create a grid to display the vehicles
            local grid = vgui.Create("DGrid", scroll)
            grid:Dock(FILL)
            grid:SetCols(3)
            grid:SetColWide(250)
            grid:SetRowHeight(250)
            
            -- Add each vehicle to the grid
            for id, data in pairs(vehicles) do
                local vehiclePanel = vgui.Create("DPanel")
                vehiclePanel:SetSize(240, 240)
                
                -- Add vehicle details and controls here
                local nameLabel = vgui.Create("DLabel", vehiclePanel)
                nameLabel:SetText(data.Name)
                nameLabel:SetFont("DermaLarge")
                nameLabel:SizeToContents()
                nameLabel:SetPos(10, 10)
                
                local brandLabel = vgui.Create("DLabel", vehiclePanel)
                brandLabel:SetText(data.Brand or "")
                brandLabel:SetFont("DermaDefault")
                brandLabel:SizeToContents()
                brandLabel:SetPos(10, 30)
                
                local priceLabel = vgui.Create("DLabel", vehiclePanel)
                priceLabel:SetText("$" .. string.Comma(data.BasePrice or 0))
                priceLabel:SetFont("DermaDefault")
                priceLabel:SizeToContents()
                priceLabel:SetPos(10, 50)
                
                local buyButton = vgui.Create("DButton", vehiclePanel)
                buyButton:SetText("Buy")
                buyButton:SetSize(80, 30)
                buyButton:SetPos(10, 200)
                buyButton.DoClick = function()
                    net.Start("ATOMIC_VehicleManager_BuyVehicle")
                    net.WriteString(id)
                    net.SendToServer()
                    frame:Close()
                end
                
                local testButton = vgui.Create("DButton", vehiclePanel)
                testButton:SetText("Test Drive")
                testButton:SetSize(80, 30)
                testButton:SetPos(100, 200)
                testButton.DoClick = function()
                    net.Start("ATOMIC_VehicleManager_TestVehicle")
                    net.WriteString(id)
                    net.SendToServer()
                    frame:Close()
                end
                
                grid:AddItem(vehiclePanel)
            end
            
            tabs:AddSheet(category.name, panel, category.icon)
        end
    end
end

-- Open the garage menu
function ATOMIC:OpenGarageMenu(garage)
    local ply = LocalPlayer()
    
    -- Get the player's owned vehicles
    ply:OwnedVehicles()
    
    -- Create a frame for the garage menu
    local frame = vgui.Create("DFrame")
    frame:SetSize(600, 400)
    frame:SetTitle(garage.name or "Garage")
    frame:Center()
    frame:MakePopup()
    
    -- Create a list view for the vehicles
    local list = vgui.Create("DListView", frame)
    list:Dock(FILL)
    list:SetMultiSelect(false)
    list:AddColumn("Name")
    list:AddColumn("Brand")
    list:AddColumn("Health")
    list:AddColumn("Fuel")
    
    -- Add a refresh function
    local function RefreshVehicles(vehicles)
        list:Clear()
        
        for i, vehicle in ipairs(vehicles or {}) do
            local line = list:AddLine(
                vehicle.name or "Unknown",
                vehicle.brand or "Unknown",
                vehicle.health and math.Round(vehicle.health) .. "%" or "100%",
                vehicle.fuel and math.Round(vehicle.fuel) .. "%" or "100%"
            )
            line.vehicleId = vehicle.id
        end
    end
    
    -- Hook to refresh the list when the player's vehicles are updated
    hook.Add("ATOMIC_PlayerVehiclesUpdated", "ATOMIC_GarageMenu_Refresh", RefreshVehicles)
    
    -- Add buttons
    local buttonPanel = vgui.Create("DPanel", frame)
    buttonPanel:Dock(BOTTOM)
    buttonPanel:SetHeight(40)
    buttonPanel:DockPadding(5, 5, 5, 5)
    
    local spawnButton = vgui.Create("DButton", buttonPanel)
    spawnButton:SetText("Spawn")
    spawnButton:Dock(LEFT)
    spawnButton:SetWidth(120)
    spawnButton.DoClick = function()
        local selectedLine = list:GetSelectedLine()
        if selectedLine then
            local vehicleId = list:GetLine(selectedLine).vehicleId
            net.Start("ATOMIC_VehicleManager_SpawnVehicle")
            net.WriteInt(vehicleId, 32)
            net.SendToServer()
            frame:Close()
        end
    end
    
    local sellButton = vgui.Create("DButton", buttonPanel)
    sellButton:SetText("Sell")
    sellButton:Dock(LEFT)
    sellButton:SetWidth(120)
    sellButton:DockMargin(5, 0, 0, 0)
    sellButton.DoClick = function()
        local selectedLine = list:GetSelectedLine()
        if selectedLine then
            local vehicleId = list:GetLine(selectedLine).vehicleId
            
            -- Confirmation dialog
            local confirmFrame = vgui.Create("DFrame")
            confirmFrame:SetSize(300, 150)
            confirmFrame:SetTitle("Confirm Sale")
            confirmFrame:Center()
            confirmFrame:MakePopup()
            
            local confirmLabel = vgui.Create("DLabel", confirmFrame)
            confirmLabel:SetText("Are you sure you want to sell this vehicle?")
            confirmLabel:SizeToContents()
            confirmLabel:SetPos(20, 40)
            
            local confirmButton = vgui.Create("DButton", confirmFrame)
            confirmButton:SetText("Yes, Sell")
            confirmButton:SetSize(120, 30)
            confirmButton:SetPos(20, 80)
            confirmButton.DoClick = function()
                net.Start("ATOMIC_VehicleManager_SellVehicle")
                net.WriteInt(vehicleId, 32)
                net.SendToServer()
                confirmFrame:Close()
                frame:Close()
            end
            
            local cancelButton = vgui.Create("DButton", confirmFrame)
            cancelButton:SetText("Cancel")
            cancelButton:SetSize(120, 30)
            cancelButton:SetPos(160, 80)
            cancelButton.DoClick = function()
                confirmFrame:Close()
            end
        end
    end
    
    local closeButton = vgui.Create("DButton", buttonPanel)
    closeButton:SetText("Close")
    closeButton:Dock(RIGHT)
    closeButton:SetWidth(120)
    closeButton.DoClick = function()
        frame:Close()
    end
    
    -- Clean up hook when frame closes
    frame.OnClose = function()
        hook.Remove("ATOMIC_PlayerVehiclesUpdated", "ATOMIC_GarageMenu_Refresh")
    end
end
