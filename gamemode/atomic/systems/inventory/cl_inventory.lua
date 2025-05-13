-- File: cl_inventory.lua
-- Client-side inventory UI for the Atomic framework

ATOMIC.InventoryUI = ATOMIC.InventoryUI or {}

-- Create the inventory UI
function ATOMIC:OpenInventoryMenu(storageEntity)
    if ATOMIC.InventoryUI.Frame and IsValid(ATOMIC.InventoryUI.Frame) then
        ATOMIC.InventoryUI.Frame:Remove()
    end
    
    local ply = LocalPlayer()
    
    -- Request the latest inventory data
    ply:RequestInventory()
    
    -- Create the frame
    local frame = vgui.Create("DFrame")
    ATOMIC.InventoryUI.Frame = frame
    
    local width = ScrW() * 0.8
    local height = ScrH() * 0.8
    
    frame:SetSize(width, height)
    frame:SetTitle("Inventory")
    frame:Center()
    frame:MakePopup()
    
    -- Main layout
    local mainPanel = vgui.Create("DPanel", frame)
    mainPanel:Dock(FILL)
    mainPanel:DockMargin(10, 10, 10, 10)
    mainPanel.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(30, 30, 30, 150))
    end
    
    -- Split into inventory panel (left) and item details panel (right)
    local leftPanel = vgui.Create("DPanel", mainPanel)
    leftPanel:Dock(LEFT)
    leftPanel:SetWide(width * 0.6)
    leftPanel.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(40, 40, 40, 100))
    end
    
    local rightPanel = vgui.Create("DPanel", mainPanel)
    rightPanel:Dock(RIGHT)
    rightPanel:SetWide(width * 0.4 - 10)
    rightPanel:DockMargin(10, 0, 0, 0)
    rightPanel.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(40, 40, 40, 100))
    end
    
    -- Inventory grid
    local inventoryScroll = vgui.Create("DScrollPanel", leftPanel)
    inventoryScroll:Dock(FILL)
    inventoryScroll:DockMargin(10, 10, 10, 10)
    
    local inventoryGrid = vgui.Create("DGrid", inventoryScroll)
    inventoryGrid:SetPos(0, 0)
    inventoryGrid:SetCols(5)
    inventoryGrid:SetColWide(90)
    inventoryGrid:SetRowHeight(90)
    
    -- Item details panel
    local itemDetailsPanel = vgui.Create("DPanel", rightPanel)
    itemDetailsPanel:Dock(FILL)
    itemDetailsPanel:DockMargin(10, 10, 10, 10)
    itemDetailsPanel.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(30, 30, 30, 100))
    end
    
    -- Item details header
    local itemName = vgui.Create("DLabel", itemDetailsPanel)
    itemName:SetText("Select an item")
    itemName:SetFont("DermaLarge")
    itemName:SetTextColor(Color(255, 255, 255))
    itemName:Dock(TOP)
    itemName:DockMargin(10, 10, 10, 5)
    itemName:SetContentAlignment(5) -- Center
    
    -- Item model display
    local itemModel = vgui.Create("DModelPanel", itemDetailsPanel)
    itemModel:SetSize(200, 200)
    itemModel:Dock(TOP)
    itemModel:SetModel("")
    itemModel:DockMargin(10, 5, 10, 5)
    itemModel.LayoutEntity = function(ent) return end -- Disable animation
    
    -- Item description
    local itemDescription = vgui.Create("DLabel", itemDetailsPanel)
    itemDescription:SetText("")
    itemDescription:SetFont("DermaDefault")
    itemDescription:SetTextColor(Color(255, 255, 255))
    itemDescription:Dock(TOP)
    itemDescription:DockMargin(10, 5, 10, 5)
    itemDescription:SetWrap(true)
    itemDescription:SetAutoStretchVertical(true)
    
    -- Item info panel
    local itemInfo = vgui.Create("DPanel", itemDetailsPanel)
    itemInfo:Dock(TOP)
    itemInfo:SetHeight(100)
    itemInfo:DockMargin(10, 5, 10, 5)
    itemInfo.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(20, 20, 20, 100))
    end
    
    -- Weight label
    local weightLabel = vgui.Create("DLabel", itemInfo)
    weightLabel:SetText("Weight: -")
    weightLabel:SetFont("DermaDefault")
    weightLabel:SetTextColor(Color(255, 255, 255))
    weightLabel:Dock(TOP)
    weightLabel:DockMargin(5, 5, 5, 0)
    
    -- Type label
    local typeLabel = vgui.Create("DLabel", itemInfo)
    typeLabel:SetText("Type: -")
    typeLabel:SetFont("DermaDefault")
    typeLabel:SetTextColor(Color(255, 255, 255))
    typeLabel:Dock(TOP)
    typeLabel:DockMargin(5, 5, 5, 0)
    
    -- Action buttons panel
    local actionPanel = vgui.Create("DPanel", itemDetailsPanel)
    actionPanel:Dock(BOTTOM)
    actionPanel:SetHeight(120)
    actionPanel:DockMargin(10, 5, 10, 10)
    actionPanel.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(20, 20, 20, 100))
    end
    
    -- Use button
    local useButton = vgui.Create("DButton", actionPanel)
    useButton:SetText("Use")
    useButton:SetFont("DermaDefaultBold")
    useButton:Dock(TOP)
    useButton:DockMargin(5, 5, 5, 5)
    useButton:SetHeight(30)
    useButton:SetEnabled(false)
    
    -- Drop button
    local dropButton = vgui.Create("DButton", actionPanel)
    dropButton:SetText("Drop")
    dropButton:SetFont("DermaDefaultBold")
    dropButton:Dock(TOP)
    dropButton:DockMargin(5, 5, 5, 5)
    dropButton:SetHeight(30)
    dropButton:SetEnabled(false)
    
    -- Drop amount slider (only visible when dropping items)
    local dropSlider = vgui.Create("DNumSlider", actionPanel)
    dropSlider:SetText("Amount")
    dropSlider:SetMin(1)
    dropSlider:SetMax(1)
    dropSlider:SetDecimals(0)
    dropSlider:Dock(TOP)
    dropSlider:DockMargin(5, 5, 5, 5)
    dropSlider:SetVisible(false)
    
    -- Selected item reference
    local selectedItem = nil
    local selectedSlot = nil
    
    -- Function to update the item details panel
    local function UpdateItemDetails(item, slot)
        selectedItem = item
        selectedSlot = slot
        
        if item then
            local itemData = ATOMIC:GetItem(item.id)
            
            if itemData then
                itemName:SetText(itemData.Name .. (item.amount > 1 and " x" .. item.amount or ""))
                
                -- Show model
                if itemData.Model then
                    itemModel:SetModel(itemData.Model)
                    
                    -- Auto-adjust camera position
                    local mn, mx = itemModel.Entity:GetRenderBounds()
                    local size = 0
                    size = math.max(size, math.abs(mn.x) + math.abs(mx.x))
                    size = math.max(size, math.abs(mn.y) + math.abs(mx.y))
                    size = math.max(size, math.abs(mn.z) + math.abs(mx.z))

                    itemModel:SetFOV(45)
                    itemModel:SetCamPos(Vector(size, size, size * 0.75))
                    itemModel:SetLookAt((mn + mx) * 0.5)
                else
                    itemModel:SetModel("models/props_junk/cardboard_box004a.mdl")
                end
                
                -- Update description and info
                itemDescription:SetText(itemData.Description or "No description available.")
                weightLabel:SetText("Weight: " .. (itemData.Weight or 1))
                typeLabel:SetText("Type: " .. (itemData.Type or "Unknown"))
                
                -- Configure action buttons
                useButton:SetEnabled(itemData.OnUse ~= nil)
                dropButton:SetEnabled(true)
                
                -- Configure drop slider
                dropSlider:SetVisible(item.amount > 1)
                dropSlider:SetMin(1)
                dropSlider:SetMax(item.amount)
                dropSlider:SetValue(1)
                
                useButton.DoClick = function()
                    LocalPlayer():UseItem(item.id, slot)
                    frame:Close() -- Optionally close the menu after using an item
                end
                
                dropButton.DoClick = function()
                    local amount = item.amount
                    if item.amount > 1 then
                        amount = math.floor(dropSlider:GetValue())
                    end
                    
                    LocalPlayer():DropItem(item.id, slot, amount)
                    
                    -- If we dropped all of the item, reset the details panel
                    if amount >= item.amount then
                        UpdateItemDetails(nil, nil)
                    end
                end
            else
                -- Invalid item
                itemName:SetText("Unknown Item")
                itemModel:SetModel("models/error.mdl")
                itemDescription:SetText("Item definition not found.")
                weightLabel:SetText("Weight: -")
                typeLabel:SetText("Type: -")
                
                useButton:SetEnabled(false)
                dropButton:SetEnabled(false)
                dropSlider:SetVisible(false)
            end
        else
            -- No item selected
            itemName:SetText("Select an item")
            itemModel:SetModel("")
            itemDescription:SetText("")
            weightLabel:SetText("Weight: -")
            typeLabel:SetText("Type: -")
            
            useButton:SetEnabled(false)
            dropButton:SetEnabled(false)
            dropSlider:SetVisible(false)
        end
    end
    
    -- Function to create inventory slots
    local function CreateInventorySlots(inventory)
        inventoryGrid:Clear()
        
        local maxSlots = LocalPlayer():GetMaxInventorySlots()
        
        -- Create slots
        for i = 1, maxSlots do
            local slotString = tostring(i)
            local item = inventory[slotString]
            
            -- Create slot panel
            local slot = vgui.Create("DButton")
            slot:SetSize(80, 80)
            slot:SetText("")
            
            -- Custom drawing for the slot
            slot.Paint = function(self, w, h)
                draw.RoundedBox(4, 0, 0, w, h, Color(50, 50, 50, 150))
                
                if self:IsHovered() then
                    draw.RoundedBox(4, 0, 0, w, h, Color(100, 100, 100, 50))
                end
                
                -- Draw border if selected
                if selectedSlot == slotString then
                    draw.RoundedBox(4, 0, 0, w, h, Color(100, 150, 255, 50))
                    surface.SetDrawColor(100, 150, 255, 255)
                    surface.DrawOutlinedRect(0, 0, w, h, 2)
                end
            end
            
            -- Item model (if the slot has an item)
            if item then
                local itemData = ATOMIC:GetItem(item.id)
                
                if itemData then
                    -- Create model panel
                    local itemIcon = vgui.Create("SpawnIcon", slot)
                    itemIcon:SetSize(70, 70)
                    itemIcon:SetPos(5, 5)
                    itemIcon:SetModel(itemData.Model or "models/props_junk/cardboard_box004a.mdl")
                    itemIcon:SetToolTip(itemData.Name)
                    
                    -- Make the icon non-clickable
                    itemIcon.DoClick = function() end
                    
                    -- Show amount for stacked items
                    if item.amount > 1 then
                        local amountLabel = vgui.Create("DLabel", slot)
                        amountLabel:SetText(item.amount)
                        amountLabel:SetFont("DermaDefaultBold")
                        amountLabel:SetTextColor(Color(255, 255, 255))
                        amountLabel:SetPos(5, 60)
                        amountLabel:SizeToContents()
                        
                        -- Add a background to make it more visible
                        amountLabel.Paint = function(self, w, h)
                            draw.RoundedBox(4, -2, -2, w + 4, h + 4, Color(0, 0, 0, 150))
                        end
                    end
                end
                
                -- Handle item selection
                slot.DoClick = function()
                    UpdateItemDetails(item, slotString)
                end
            end
            
            inventoryGrid:AddItem(slot)
        end
    end
    
    -- Update when inventory changes
    hook.Add("ATOMIC:InventoryUpdated", "ATOMIC:UpdateInventoryUI", function(updatedPly, inventory)
        if not IsValid(frame) then return end
        
        if updatedPly == LocalPlayer() then
            CreateInventorySlots(inventory)
            
            -- If the currently selected item was updated, refresh its details
            if selectedSlot and inventory[selectedSlot] then
                UpdateItemDetails(inventory[selectedSlot], selectedSlot)
            elseif selectedSlot and not inventory[selectedSlot] then
                -- The selected item has been removed
                UpdateItemDetails(nil, nil)
            end
        end
    end)
    
    -- Initialize with current inventory
    CreateInventorySlots(ply:GetInventory())
    
    -- Cleanup
    frame.OnClose = function()
        hook.Remove("ATOMIC:InventoryUpdated", "ATOMIC:UpdateInventoryUI")
    end
end

-- Open inventory with F2
hook.Add("Think", "ATOMIC:InventoryHotkey", function()
    local ply = LocalPlayer()
    
    if input.IsKeyDown(KEY_F2) and not ply:GetNWBool("ATOMIC:DialogOpen", false) then
        -- Only open if not already open and not pressing chat key
        if not ATOMIC.InventoryUI.Frame or not IsValid(ATOMIC.InventoryUI.Frame) then
            if not vgui.CursorVisible() and not ply:IsTyping() then
                ATOMIC:OpenInventoryMenu()
            end
        end
    end
end)

-- Register network handlers
net.Receive("ATOMIC:OpenInventory", function()
    ATOMIC:OpenInventoryMenu()
end)

-- Register console command
concommand.Add("atomic_inventory", function()
    ATOMIC:OpenInventoryMenu()
end)
