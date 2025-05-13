-- File: cl_admin_panel.lua
-- Client-side admin panel for the Atomic framework

ATOMIC.AdminPanel = ATOMIC.AdminPanel or {}

-- Open the admin panel
function ATOMIC:OpenAdminPanel()
    local ply = LocalPlayer()
    
    if not ply:IsAdmin() then
        ATOMIC:NotifyError(ply, "You don't have permission to access the admin panel.")
        return
    end
    
    -- Close existing panel if open
    if ATOMIC.AdminPanel.Frame and IsValid(ATOMIC.AdminPanel.Frame) then
        ATOMIC.AdminPanel.Frame:Remove()
    end
    
    -- Create the main frame
    local frame = vgui.Create("DFrame")
    ATOMIC.AdminPanel.Frame = frame
    
    local width = ScrW() * 0.8
    local height = ScrH() * 0.8
    
    frame:SetSize(width, height)
    frame:SetTitle("Atomic Admin Panel")
    frame:Center()
    frame:MakePopup()
    
    -- Create the main layout
    local mainPanel = vgui.Create("DPanel", frame)
    mainPanel:Dock(FILL)
    mainPanel:DockMargin(5, 5, 5, 5)
    mainPanel.Paint = function() end
    
    -- Create the sidebar
    local sidebar = vgui.Create("DPanel", mainPanel)
    sidebar:SetWide(200)
    sidebar:Dock(LEFT)
    sidebar:DockMargin(0, 0, 5, 0)
    sidebar.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(50, 50, 50, 200))
    end
    
    -- Create the content area
    local content = vgui.Create("DPanel", mainPanel)
    content:Dock(FILL)
    content.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 40, 200))
    end
    
    -- Create sidebar sections
    local sections = {}
    
    -- Add a section to the sidebar
    local function AddSection(name, icon, contentFn)
        local button = vgui.Create("DButton", sidebar)
        button:Dock(TOP)
        button:DockMargin(5, 5, 5, 0)
        button:SetHeight(40)
        button:SetText(name)
        button:SetContentAlignment(4) -- Left-center alignment
        button:SetTextInset(30, 0)
        button:SetFont("DermaDefaultBold")
        
        button.Paint = function(self, w, h)
            local color = self:IsHovered() and Color(60, 120, 200, 200) or Color(60, 60, 60, 200)
            draw.RoundedBox(4, 0, 0, w, h, color)
        end
        
        -- Add icon if provided
        if icon then
            local iconImage = vgui.Create("DImage", button)
            iconImage:SetSize(16, 16)
            iconImage:SetPos(10, 12)
            iconImage:SetImage(icon)
        end
        
        button.DoClick = function()
            -- Clear the content area
            content:Clear()
            
            -- Add the section's content
            contentFn(content)
        end
        
        table.insert(sections, {
            name = name,
            button = button,
            contentFn = contentFn
        })
        
        return button
    end
    
    -- Create the sections
    
    -- Players section
    AddSection("Players", "icon16/user.png", function(panel)
        local playerList = vgui.Create("DListView", panel)
        playerList:Dock(FILL)
        playerList:DockMargin(10, 10, 10, 10)
        playerList:SetMultiSelect(false)
        playerList:AddColumn("Name")
        playerList:AddColumn("SteamID")
        playerList:AddColumn("Rank")
        playerList:AddColumn("Money")
        playerList:AddColumn("Job")
        
        -- Add players to the list
        for _, ply in pairs(player.GetAll()) do
            playerList:AddLine(
                ply:Nick(),
                ply:SteamID(),
                ply:GetNWString("ATOMIC_Rank", "user"),
                ply:GetNWInt("ATOMIC_Cash", 0) + ply:GetNWInt("ATOMIC_Bank", 0),
                ply:GetNWString("ATOMIC_Job", "None")
            )
        end
        
        -- Context menu for player actions
        playerList.OnRowRightClick = function(panel, lineID, line)
            local menu = DermaMenu()
            local playerName = line:GetValue(1)
            local playerSteamID = line:GetValue(2)
            
            menu:AddOption("Teleport To", function()
                RunConsoleCommand("say", "/teleport " .. playerName)
            end):SetIcon("icon16/arrow_right.png")
            
            menu:AddOption("Bring", function()
                RunConsoleCommand("say", "/bring " .. playerName)
            end):SetIcon("icon16/arrow_left.png")
            
            menu:AddOption("Set Job", function()
                local jobMenu = DermaMenu()
                
                for id, job in pairs(ATOMIC.Jobs or {}) do
                    jobMenu:AddOption(job.Name or id, function()
                        RunConsoleCommand("say", "/setjob " .. playerName .. " " .. id)
                    end)
                end
                
                jobMenu:Open()
            end):SetIcon("icon16/user_suit.png")
            
            menu:AddOption("Set Rank", function()
                local rankMenu = DermaMenu()
                
                for _, rank in ipairs(ATOMIC.Config.Ranks or {"user", "admin", "superadmin"}) do
                    rankMenu:AddOption(ATOMIC.Config.RankNames[rank] or rank, function()
                        RunConsoleCommand("say", "/setrank " .. playerName .. " " .. rank)
                    end)
                end
                
                rankMenu:Open()
            end):SetIcon("icon16/shield.png")
            
            menu:AddSpacer()
            
            menu:AddOption("Give Money", function()
                Derma_StringRequest(
                    "Give Money",
                    "Amount of money to give to " .. playerName,
                    "1000",
                    function(text)
                        local amount = tonumber(text)
                        if amount then
                            RunConsoleCommand("say", "/givemoney " .. playerName .. " " .. amount)
                        end
                    end
                )
            end):SetIcon("icon16/money_add.png")
            
            menu:AddOption("Set Wallet", function()
                Derma_StringRequest(
                    "Set Wallet",
                    "Set " .. playerName .. "'s wallet amount",
                    "1000",
                    function(text)
                        local amount = tonumber(text)
                        if amount then
                            RunConsoleCommand("say", "/setwallet " .. playerName .. " " .. amount)
                        end
                    end
                )
            end):SetIcon("icon16/money.png")
            
            menu:AddOption("Set Bank", function()
                Derma_StringRequest(
                    "Set Bank",
                    "Set " .. playerName .. "'s bank amount",
                    "1000",
                    function(text)
                        local amount = tonumber(text)
                        if amount then
                            RunConsoleCommand("say", "/setbank " .. playerName .. " " .. amount)
                        end
                    end
                )
            end):SetIcon("icon16/money_dollar.png")
            
            menu:AddOption("Revive", function()
                RunConsoleCommand("say", "/revive " .. playerName)
            end):SetIcon("icon16/heart.png")
            
            menu:Open()
        end
        
        -- Refresh button
        local refreshButton = vgui.Create("DButton", panel)
        refreshButton:SetText("Refresh")
        refreshButton:SetPos(10, 10)
        refreshButton:SetSize(100, 30)
        refreshButton.DoClick = function()
            playerList:Clear()
            
            for _, ply in pairs(player.GetAll()) do
                playerList:AddLine(
                    ply:Nick(),
                    ply:SteamID(),
                    ply:GetNWString("ATOMIC_Rank", "user"),
                    ply:GetNWInt("ATOMIC_Cash", 0) + ply:GetNWInt("ATOMIC_Bank", 0),
                    ply:GetNWString("ATOMIC_Job", "None")
                )
            end
        end
    end)
    
    -- Properties section
    AddSection("Properties", "icon16/house.png", function(panel)
        local propertyList = vgui.Create("DListView", panel)
        propertyList:Dock(FILL)
        propertyList:DockMargin(10, 10, 10, 10)
        propertyList:SetMultiSelect(false)
        propertyList:AddColumn("Name")
        propertyList:AddColumn("Price")
        propertyList:AddColumn("Type")
        propertyList:AddColumn("Group")
        propertyList:AddColumn("Owner")
        
        -- Add properties to the list
        for id, property in pairs(ATOMIC.Properties or {}) do
            local ownerName = property.owner and (IsValid(property.owner) and property.owner:Nick() or "Unknown") or "None"
            
            propertyList:AddLine(
                property.name,
                property.price,
                property.type,
                property.group,
                ownerName,
                id -- Hidden ID column for reference
            )
        end
        
        -- Context menu for property actions
        propertyList.OnRowRightClick = function(panel, lineID, line)
            local menu = DermaMenu()
            local propertyName = line:GetValue(1)
            local propertyId = line:GetValue(6)
            
            menu:AddOption("Teleport To", function()
                net.Start("ATOMIC:AdminTeleportToProperty")
                net.WriteString(propertyId)
                net.SendToServer()
            end):SetIcon("icon16/arrow_right.png")
            
            menu:AddOption("Reset Owner", function()
                net.Start("ATOMIC:AdminResetPropertyOwner")
                net.WriteString(propertyId)
                net.SendToServer()
            end):SetIcon("icon16/user_delete.png")
            
            menu:AddOption("Edit Property", function()
                -- Open property editor
                local frame = vgui.Create("DFrame")
                frame:SetSize(400, 400)
                frame:SetTitle("Edit Property: " .. propertyName)
                frame:Center()
                frame:MakePopup()
                
                local property = ATOMIC.Properties[propertyId]
                if not property then return end
                
                local panel = vgui.Create("DScrollPanel", frame)
                panel:Dock(FILL)
                panel:DockMargin(5, 5, 5, 5)
                
                -- Name
                local nameLabel = panel:Add("DLabel")
                nameLabel:Dock(TOP)
                nameLabel:DockMargin(0, 5, 0, 0)
                nameLabel:SetText("Name:")
                
                local nameEntry = panel:Add("DTextEntry")
                nameEntry:Dock(TOP)
                nameEntry:DockMargin(0, 5, 0, 5)
                nameEntry:SetText(property.name)
                
                -- Description
                local descLabel = panel:Add("DLabel")
                descLabel:Dock(TOP)
                descLabel:DockMargin(0, 5, 0, 0)
                descLabel:SetText("Description:")
                
                local descEntry = panel:Add("DTextEntry")
                descEntry:Dock(TOP)
                descEntry:DockMargin(0, 5, 0, 5)
                descEntry:SetText(property.description or "")
                
                -- Price
                local priceLabel = panel:Add("DLabel")
                priceLabel:Dock(TOP)
                priceLabel:DockMargin(0, 5, 0, 0)
                priceLabel:SetText("Price:")
                
                local priceEntry = panel:Add("DNumberWang")
                priceEntry:Dock(TOP)
                priceEntry:DockMargin(0, 5, 0, 5)
                priceEntry:SetValue(property.price)
                priceEntry:SetMin(0)
                priceEntry:SetMax(10000000)
                
                -- Type
                local typeLabel = panel:Add("DLabel")
                typeLabel:Dock(TOP)
                typeLabel:DockMargin(0, 5, 0, 0)
                typeLabel:SetText("Type:")
                
                local typeCombo = panel:Add("DComboBox")
                typeCombo:Dock(TOP)
                typeCombo:DockMargin(0, 5, 0, 5)
                typeCombo:SetValue(property.type)
                typeCombo:AddChoice("house")
                typeCombo:AddChoice("business")
                typeCombo:AddChoice("government")
                
                -- Group
                local groupLabel = panel:Add("DLabel")
                groupLabel:Dock(TOP)
                groupLabel:DockMargin(0, 5, 0, 0)
                groupLabel:SetText("Group:")
                
                local groupEntry = panel:Add("DTextEntry")
                groupEntry:Dock(TOP)
                groupEntry:DockMargin(0, 5, 0, 5)
                groupEntry:SetText(property.group)
                
                -- For Sale
                local forSaleCheck = panel:Add("DCheckBoxLabel")
                forSaleCheck:Dock(TOP)
                forSaleCheck:DockMargin(0, 5, 0, 5)
                forSaleCheck:SetText("For Sale")
                forSaleCheck:SetValue(property.flags.forSale)
                
                -- Save button
                local saveButton = panel:Add("DButton")
                saveButton:Dock(TOP)
                saveButton:DockMargin(0, 15, 0, 0)
                saveButton:SetText("Save Changes")
                saveButton:SetHeight(30)
                
                saveButton.DoClick = function()
                    -- Update property in the database
                    net.Start("ATOMIC:AdminUpdateProperty")
                    net.WriteString(propertyId)
                    net.WriteTable({
                        name = nameEntry:GetValue(),
                        description = descEntry:GetValue(),
                        price = priceEntry:GetValue(),
                        type = typeCombo:GetValue(),
                        group = groupEntry:GetValue(),
                        forSale = forSaleCheck:GetChecked()
                    })
                    net.SendToServer()
                    
                    frame:Close()
                end
            end):SetIcon("icon16/pencil.png")
            
            menu:Open()
        end
        
        -- Refresh button
        local refreshButton = vgui.Create("DButton", panel)
        refreshButton:SetText("Refresh")
        refreshButton:SetPos(10, 10)
        refreshButton:SetSize(100, 30)
        refreshButton.DoClick = function()
            ATOMIC:RequestProperties()
            
            timer.Simple(0.5, function()
                propertyList:Clear()
                
                for id, property in pairs(ATOMIC.Properties or {}) do
                    local ownerName = property.owner and (IsValid(property.owner) and property.owner:Nick() or "Unknown") or "None"
                    
                    propertyList:AddLine(
                        property.name,
                        property.price,
                        property.type,
                        property.group,
                        ownerName,
                        id -- Hidden ID column for reference
                    )
                end
            end)
        end
        
        -- Property tools section
        local toolsPanel = vgui.Create("DPanel", panel)
        toolsPanel:Dock(TOP)
        toolsPanel:DockMargin(10, 10, 10, 10)
        toolsPanel:SetHeight(50)
        toolsPanel.Paint = function() end
        
        local propertyGunButton = vgui.Create("DButton", toolsPanel)
        propertyGunButton:SetText("Get Property Gun")
        propertyGunButton:Dock(LEFT)
        propertyGunButton:DockMargin(0, 0, 10, 0)
        propertyGunButton:SetWide(150)
        propertyGunButton.DoClick = function()
            RunConsoleCommand("property_manager_gun")
        end
    end)
    
    -- NPCs section
    AddSection("NPCs", "icon16/user_green.png", function(panel)
        local npcList = vgui.Create("DListView", panel)
        npcList:Dock(FILL)
        npcList:DockMargin(10, 10, 10, 10)
        npcList:SetMultiSelect(false)
        npcList:AddColumn("Name")
        npcList:AddColumn("Type")
        npcList:AddColumn("Spawns")
        
        -- Add NPCs to the list
        for id, npc in pairs(ATOMIC.NPCs or {}) do
            npcList:AddLine(
                npc.Name or id,
                id,
                npc.Spawns and #npc.Spawns or 0
            )
        end
        
        -- Context menu for NPC actions
        npcList.OnRowRightClick = function(panel, lineID, line)
            local menu = DermaMenu()
            local npcName = line:GetValue(1)
            local npcId = line:GetValue(2)
            
            menu:AddOption("Teleport To Spawn", function()
                local npc = ATOMIC.NPCs[npcId]
                if npc and npc.Spawns and #npc.Spawns > 0 then
                    net.Start("ATOMIC:AdminTeleportToNPC")
                    net.WriteString(npcId)
                    net.SendToServer()
                else
                    ATOMIC:NotifyError(LocalPlayer(), "No spawn points found for this NPC.")
                end
            end):SetIcon("icon16/arrow_right.png")
            
            menu:Open()
        end
        
        -- NPC tools section
        local toolsPanel = vgui.Create("DPanel", panel)
        toolsPanel:Dock(TOP)
        toolsPanel:DockMargin(10, 10, 10, 10)
        toolsPanel:SetHeight(50)
        toolsPanel.Paint = function() end
        
        local npcGunButton = vgui.Create("DButton", toolsPanel)
        npcGunButton:SetText("Get NPC Gun")
        npcGunButton:Dock(LEFT)
        npcGunButton:DockMargin(0, 0, 10, 0)
        npcGunButton:SetWide(150)
        npcGunButton.DoClick = function()
            RunConsoleCommand("npc_manager_gun")
        end
        
        local refreshButton = vgui.Create("DButton", toolsPanel)
        refreshButton:SetText("Refresh NPCs")
        refreshButton:Dock(LEFT)
        refreshButton:DockMargin(0, 0, 10, 0)
        refreshButton:SetWide(150)
        refreshButton.DoClick = function()
            net.Start("ATOMIC:LoadNPCs")
            net.SendToServer()
            
            timer.Simple(0.5, function()
                npcList:Clear()
                
                for id, npc in pairs(ATOMIC.NPCs or {}) do
                    npcList:AddLine(
                        npc.Name or id,
                        id,
                        npc.Spawns and #npc.Spawns or 0
                    )
                end
            end)
        end
        
        local saveButton = vgui.Create("DButton", toolsPanel)
        saveButton:SetText("Save NPCs")
        saveButton:Dock(LEFT)
        saveButton:DockMargin(0, 0, 10, 0)
        saveButton:SetWide(150)
        saveButton.DoClick = function()
            net.Start("ATOMIC:SaveNPCs")
            net.SendToServer()
        end
    end)
    
    -- Settings section
    AddSection("Settings", "icon16/cog.png", function(panel)
        local settingsScroll = vgui.Create("DScrollPanel", panel)
        settingsScroll:Dock(FILL)
        settingsScroll:DockMargin(10, 10, 10, 10)
        
        -- Game settings
        local gameLabel = vgui.Create("DLabel", settingsScroll)
        gameLabel:Dock(TOP)
        gameLabel:DockMargin(0, 10, 0, 5)
        gameLabel:SetFont("DermaLarge")
        gameLabel:SetText("Game Settings")
        
        -- Chat radius setting
        local chatRadiusLabel = vgui.Create("DLabel", settingsScroll)
        chatRadiusLabel:Dock(TOP)
        chatRadiusLabel:DockMargin(0, 10, 0, 0)
        chatRadiusLabel:SetText("Chat Radius")
        
        local chatRadiusSlider = vgui.Create("DNumSlider", settingsScroll)
        chatRadiusSlider:Dock(TOP)
        chatRadiusSlider:DockMargin(10, 0, 0, 10)
        chatRadiusSlider:SetText("")
        chatRadiusSlider:SetMin(100)
        chatRadiusSlider:SetMax(2000)
        chatRadiusSlider:SetDecimals(0)
        chatRadiusSlider:SetValue(ATOMIC.Config.ChatRadius or 600)
        
        -- Name change price setting
        local nameChangePriceLabel = vgui.Create("DLabel", settingsScroll)
        nameChangePriceLabel:Dock(TOP)
        nameChangePriceLabel:DockMargin(0, 10, 0, 0)
        nameChangePriceLabel:SetText("Name Change Price")
        
        local nameChangePriceEntry = vgui.Create("DNumberWang", settingsScroll)
        nameChangePriceEntry:Dock(TOP)
        nameChangePriceEntry:DockMargin(10, 0, 200, 10)
        nameChangePriceEntry:SetMin(0)
        nameChangePriceEntry:SetMax(1000000)
        nameChangePriceEntry:SetValue(ATOMIC.Config.NameChangePrice or 25000)
        
        -- Organization price setting
        local orgPriceLabel = vgui.Create("DLabel", settingsScroll)
        orgPriceLabel:Dock(TOP)
        orgPriceLabel:DockMargin(0, 10, 0, 0)
        orgPriceLabel:SetText("Organization Creation Price")
        
        local orgPriceEntry = vgui.Create("DNumberWang", settingsScroll)
        orgPriceEntry:Dock(TOP)
        orgPriceEntry:DockMargin(10, 0, 200, 10)
        orgPriceEntry:SetMin(0)
        orgPriceEntry:SetMax(1000000)
        orgPriceEntry:SetValue(ATOMIC.Config.OrganizationPrice or 50000)
        
        -- Save button
        local saveButton = vgui.Create("DButton", settingsScroll)
        saveButton:Dock(TOP)
        saveButton:DockMargin(0, 20, 0, 0)
        saveButton:SetHeight(40)
        saveButton:SetText("Save Settings")
        
        saveButton.DoClick = function()
            -- Update settings on the server
            net.Start("ATOMIC:AdminUpdateSettings")
            net.WriteTable({
                ChatRadius = chatRadiusSlider:GetValue(),
                NameChangePrice = nameChangePriceEntry:GetValue(),
                OrganizationPrice = orgPriceEntry:GetValue()
            })
            net.SendToServer()
            
            ATOMIC:Notify(LocalPlayer(), "Settings have been updated.")
        end
    end)
    
    -- Server management section
    AddSection("Server", "icon16/server.png", function(panel)
        local serverPanel = vgui.Create("DPanel", panel)
        serverPanel:Dock(FILL)
        serverPanel:DockMargin(10, 10, 10, 10)
        serverPanel.Paint = function() end
        
        local buttonPanel = vgui.Create("DPanel", serverPanel)
        buttonPanel:Dock(TOP)
        buttonPanel:SetHeight(200)
        buttonPanel:DockMargin(0, 0, 0, 10)
        buttonPanel.Paint = function() end
        
        -- Create a button with a confirmation dialog
        local function CreateConfirmButton(text, icon, command)
            local button = vgui.Create("DButton", buttonPanel)
            button:Dock(TOP)
            button:DockMargin(0, 5, 0, 5)
            button:SetHeight(50)
            button:SetText(text)
            
            if icon then
                button:SetImage(icon)
            end
            
            button.DoClick = function()
                Derma_Query(
                    "Are you sure you want to " .. string.lower(text) .. "?",
                    "Confirmation",
                    "Yes",
                    function()
                        RunConsoleCommand(command)
                    end,
                    "No",
                    function() end
                )
            end
            
            return button
        end
        
        -- Server restart button
        CreateConfirmButton("Restart Server", "icon16/arrow_refresh.png", "atomic_restart_server")
        
        -- Reload gamemode button
        CreateConfirmButton("Reload Gamemode", "icon16/script_go.png", "atomic_reload_gamemode")
        
        -- Clean up server button
        CreateConfirmButton("Clean Up Server", "icon16/bin.png", "atomic_cleanup_server")
    end)
    
    -- About section
    AddSection("About", "icon16/information.png", function(panel)
        local aboutPanel = vgui.Create("DPanel", panel)
        aboutPanel:Dock(FILL)
        aboutPanel:DockMargin(10, 10, 10, 10)
        aboutPanel.Paint = function(self, w, h)
            draw.RoundedBox(8, 0, 0, w, h, Color(30, 30, 30, 100))
        end
        
        local aboutText = vgui.Create("DLabel", aboutPanel)
        aboutText:SetPos(20, 20)
        aboutText:SetSize(800, 500)
        aboutText:SetText(
            "Atomic Framework\n\n" ..
            "Version: 1.0\n" ..
            "Author: Lucasion\n\n" ..
            "A modular roleplay framework for Garry's Mod.\n\n" ..
            "Thank you for using Atomic Framework!"
        )
        aboutText:SetFont("DermaDefaultBold")
    end)
    
    -- Select the first section by default
    if #sections > 0 then
        sections[1].contentFn(content)
    end
end

-- Register network handlers
net.Receive("ATOMIC:OpenAdminPanel", function()
    ATOMIC:OpenAdminPanel()
end)

-- Register console command
concommand.Add("atomic_admin", function()
    ATOMIC:OpenAdminPanel()
end)
