-- File: cl_character.lua
-- Client-side character system for the Atomic framework

-- Character menu
function ATOMIC:OpenCharacterMenu()
    if IsValid(ATOMIC.CharacterMenu) then
        ATOMIC.CharacterMenu:Remove()
    end
    
    -- Create the main frame
    local frame = vgui.Create("DFrame")
    ATOMIC.CharacterMenu = frame
    
    frame:SetSize(ScrW(), ScrH())
    frame:SetTitle("")
    frame:SetDraggable(false)
    frame:ShowCloseButton(false)
    frame:MakePopup()
    
    -- Background
    frame.Paint = function(self, w, h)
        -- Background gradient
        surface.SetDrawColor(10, 10, 10, 255)
        surface.DrawRect(0, 0, w, h)
        
        -- Draw a title
        draw.SimpleText("Atomic Roleplay", "AtomicLargeBold", w / 2, 60, ATOMIC.Config.Colors.Primary, TEXT_ALIGN_CENTER)
        
        -- Draw separator line
        surface.SetDrawColor(ATOMIC.Config.Colors.Primary)
        surface.DrawRect(w / 2 - 150, 100, 300, 2)
    end
    
    -- Create the content panel
    local content = vgui.Create("DPanel", frame)
    content:SetSize(frame:GetWide(), frame:GetTall() - 120)
    content:SetPos(0, 120)
    content.Paint = function() end
    
    -- Check if there are characters
    if #ATOMIC.Characters.List > 0 then
        -- Show character selection
        self:ShowCharacterSelection(content)
    else
        -- Show character creation
        self:ShowCharacterCreation(content)
    end
end

-- Character selection panel
function ATOMIC:ShowCharacterSelection(parent)
    -- Clear the parent
    parent:Clear()
    
    -- Create the character list
    local charList = vgui.Create("DScrollPanel", parent)
    charList:SetSize(400, 500)
    charList:SetPos(50, 50)
    charList.Paint = function(self, w, h)
        surface.SetDrawColor(30, 30, 30, 150)
        surface.DrawRect(0, 0, w, h)
        
        surface.SetDrawColor(ATOMIC.Config.Colors.Primary)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
        
        -- Title
        draw.SimpleText("Select Character", "AtomicLargeBold", w / 2, 10, Color(255, 255, 255), TEXT_ALIGN_CENTER)
    end
    
    -- Add characters to the list
    for i, char in ipairs(ATOMIC.Characters.List) do
        local charPanel = vgui.Create("DButton", charList)
        charPanel:SetSize(380, 70)
        charPanel:SetPos(10, 40 + (i-1) * 80)
        charPanel:SetText("")
        
        charPanel.Paint = function(self, w, h)
            surface.SetDrawColor(50, 50, 50, 200)
            surface.DrawRect(0, 0, w, h)
            
            if self:IsHovered() then
                surface.SetDrawColor(ATOMIC.Config.Colors.Primary)
                surface.DrawOutlinedRect(0, 0, w, h, 2)
            end
            
            -- Draw character info
            draw.SimpleText(char.firstname .. " " .. char.lastname, "AtomicNormalBold", 10, 10, Color(255, 255, 255))
            draw.SimpleText("Job: " .. char.job, "AtomicNormal", 10, 30, Color(200, 200, 200))
            draw.SimpleText("Money: " .. ATOMIC:MoneyToString(char.money), "AtomicNormal", 10, 50, Color(200, 200, 200))
            
            -- Last used date
            local lastUsed = os.date("%m/%d/%Y", char.last_used and os.time({year=string.sub(char.last_used, 1, 4), month=string.sub(char.last_used, 6, 7), day=string.sub(char.last_used, 9, 10)}) or os.time())
            draw.SimpleText("Last played: " .. lastUsed, "AtomicNormal", w - 140, 10, Color(200, 200, 200), TEXT_ALIGN_RIGHT)
        end
        
        -- Select character when clicked
        charPanel.DoClick = function()
            -- Play sound
            surface.PlaySound("buttons/button14.wav")
            
            -- Select the character
            ATOMIC:SelectCharacter(char.id)
            
            -- Close the menu
            if IsValid(ATOMIC.CharacterMenu) then
                ATOMIC.CharacterMenu:Remove()
            end
        end
        
        -- Delete the character when right-clicked
        charPanel.DoRightClick = function()
            local menu = DermaMenu()
            
            menu:AddOption("Delete Character", function()
                Derma_Query(
                    "Are you sure you want to delete " .. char.firstname .. " " .. char.lastname .. "?",
                    "Confirm Delete",
                    "Yes",
                    function()
                        -- Delete the character
                        ATOMIC:DeleteCharacter(char.id)
                        
                        -- Play sound
                        surface.PlaySound("buttons/button15.wav")
                    end,
                    "No",
                    function() end
                )
            end)
            
            menu:Open()
        end
    end
    
    -- Create new character button
    local newButton = vgui.Create("DButton", parent)
    newButton:SetSize(200, 50)
    newButton:SetPos(150, 570)
    newButton:SetText("")
    
    newButton.Paint = function(self, w, h)
        surface.SetDrawColor(50, 50, 50, 200)
        surface.DrawRect(0, 0, w, h)
        
        if self:IsHovered() then
            surface.SetDrawColor(ATOMIC.Config.Colors.Primary)
            surface.DrawOutlinedRect(0, 0, w, h, 2)
        end
        
        draw.SimpleText("Create New Character", "AtomicNormalBold", w / 2, h / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    newButton.DoClick = function()
        -- Check if the player has reached the character limit
        if #ATOMIC.Characters.List >= ATOMIC.Config.MaxCharacters then
            ATOMIC:NotifyError(LocalPlayer(), "You've reached the maximum number of characters (" .. ATOMIC.Config.MaxCharacters .. ").")
            return
        end
        
        -- Play sound
        surface.PlaySound("buttons/button14.wav")
        
        -- Show character creation
        ATOMIC:ShowCharacterCreation(parent)
    end
    
    -- Create the model preview panel
    local modelPanel = vgui.Create("DModelPanel", parent)
    modelPanel:SetSize(500, 600)
    modelPanel:SetPos(parent:GetWide() - 550, 0)
    modelPanel:SetFOV(60)
    modelPanel:SetCamPos(Vector(50, 50, 50))
    modelPanel:SetLookAt(Vector(0, 0, 30))
    
    -- Function to set the model
    local function SetModelPreview(index)
        if not ATOMIC.Characters.List[index] then return end
        
        local char = ATOMIC.Characters.List[index]
        modelPanel:SetModel(char.model)
        
        -- Set skin
        modelPanel.Entity:SetSkin(char.skin or 0)
        
        -- Set bodygroups
        local bodygroups = util.JSONToTable(char.bodygroups) or {}
        for k, v in pairs(bodygroups) do
            modelPanel.Entity:SetBodygroup(k, v)
        end
        
        -- Draw entity info
        modelPanel.Paint = function(self, w, h)
            surface.SetDrawColor(30, 30, 30, 150)
            surface.DrawRect(0, 0, w, h)
            
            if ATOMIC.Characters.List[index] then
                draw.SimpleText(char.firstname .. " " .. char.lastname, "AtomicLarge", w / 2, 30, Color(255, 255, 255), TEXT_ALIGN_CENTER)
            end
        end
    end
    
    -- Set the model to the first character
    SetModelPreview(1)
    
    -- Update the model preview when hovering over a character
    for i, char in ipairs(ATOMIC.Characters.List) do
        local panel = charList:GetChildren()[i+1] -- +1 because of the scrollbar
        if IsValid(panel) then
            panel.OnCursorEntered = function()
                SetModelPreview(i)
            end
        end
    end
end

-- Character creation panel
function ATOMIC:ShowCharacterCreation(parent)
    -- Clear the parent
    parent:Clear()
    
    -- Character data
    local characterData = {
        firstname = "",
        lastname = "",
        model = "models/player/Group01/male_01.mdl",
        skin = 0,
        bodygroups = "{}",
        money = ATOMIC.Config.StartingMoney or 1000,
        bank = ATOMIC.Config.StartingBank or 0,
        health = 100,
        armor = 0,
        job = "citizen"
    }
    
    -- Create the form panel
    local formPanel = vgui.Create("DPanel", parent)
    formPanel:SetSize(400, 600)
    formPanel:SetPos(50, 50)
    formPanel.Paint = function(self, w, h)
        surface.SetDrawColor(30, 30, 30, 150)
        surface.DrawRect(0, 0, w, h)
        
        surface.SetDrawColor(ATOMIC.Config.Colors.Primary)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
        
        -- Title
        draw.SimpleText("Create Character", "AtomicLargeBold", w / 2, 10, Color(255, 255, 255), TEXT_ALIGN_CENTER)
    end
    
    -- Create the form
    local firstNameLabel = vgui.Create("DLabel", formPanel)
    firstNameLabel:SetPos(20, 60)
    firstNameLabel:SetSize(200, 20)
    firstNameLabel:SetText("First Name:")
    firstNameLabel:SetFont("AtomicNormalBold")
    
    local firstNameEntry = vgui.Create("DTextEntry", formPanel)
    firstNameEntry:SetPos(20, 80)
    firstNameEntry:SetSize(360, 30)
    firstNameEntry:SetFont("AtomicNormal")
    
    local lastNameLabel = vgui.Create("DLabel", formPanel)
    lastNameLabel:SetPos(20, 120)
    lastNameLabel:SetSize(200, 20)
    lastNameLabel:SetText("Last Name:")
    lastNameLabel:SetFont("AtomicNormalBold")
    
    local lastNameEntry = vgui.Create("DTextEntry", formPanel)
    lastNameEntry:SetPos(20, 140)
    lastNameEntry:SetSize(360, 30)
    lastNameEntry:SetFont("AtomicNormal")
    
    -- Gender selection
    local genderLabel = vgui.Create("DLabel", formPanel)
    genderLabel:SetPos(20, 180)
    genderLabel:SetSize(200, 20)
    genderLabel:SetText("Gender:")
    genderLabel:SetFont("AtomicNormalBold")
    
    local genderCombo = vgui.Create("DComboBox", formPanel)
    genderCombo:SetPos(20, 200)
    genderCombo:SetSize(360, 30)
    genderCombo:AddChoice("Male", "male")
    genderCombo:AddChoice("Female", "female")
    genderCombo:SetValue("Male")
    genderCombo:SetFont("AtomicNormal")
    
    -- Model selection
    local modelLabel = vgui.Create("DLabel", formPanel)
    modelLabel:SetPos(20, 240)
    modelLabel:SetSize(200, 20)
    modelLabel:SetText("Model:")
    modelLabel:SetFont("AtomicNormalBold")
    
    local modelCombo = vgui.Create("DComboBox", formPanel)
    modelCombo:SetPos(20, 260)
    modelCombo:SetSize(360, 30)
    modelCombo:SetFont("AtomicNormal")
    
    -- Populate models based on gender
    local function PopulateModelList(gender)
        modelCombo:Clear()
        
        for _, model in ipairs(ATOMIC.Config.CharacterModels) do
            if model.gender == gender then
                modelCombo:AddChoice(model.name, model.model)
            end
        end
        
        -- Select the first model
        modelCombo:ChooseOptionID(1)
    end
    
    -- Initial population of male models
    PopulateModelList("male")
    
    -- Update model list when gender changes
    genderCombo.OnSelect = function(_, index, value, data)
        PopulateModelList(data)
    end
    
    -- Skin selection
    local skinLabel = vgui.Create("DLabel", formPanel)
    skinLabel:SetPos(20, 300)
    skinLabel:SetSize(200, 20)
    skinLabel:SetText("Skin:")
    skinLabel:SetFont("AtomicNormalBold")
    
    local skinSlider = vgui.Create("DNumSlider", formPanel)
    skinSlider:SetPos(20, 320)
    skinSlider:SetSize(360, 30)
    skinSlider:SetMin(0)
    skinSlider:SetMax(0)
    skinSlider:SetDecimals(0)
    
    -- Create the model preview panel
    local modelPanel = vgui.Create("DModelPanel", parent)
    modelPanel:SetSize(500, 600)
    modelPanel:SetPos(parent:GetWide() - 550, 0)
    modelPanel:SetModel(characterData.model)
    modelPanel:SetFOV(60)
    modelPanel:SetCamPos(Vector(50, 50, 50))
    modelPanel:SetLookAt(Vector(0, 0, 30))
    
    -- Function to set the model in the preview
    local function UpdateModelPreview()
        modelPanel:SetModel(characterData.model)
        
        -- Set skin
        modelPanel.Entity:SetSkin(characterData.skin)
        
        -- Set max skin value
        local maxSkins = modelPanel.Entity:SkinCount() - 1
        skinSlider:SetMax(maxSkins)
        
        if maxSkins <= 0 then
            skinSlider:SetEnabled(false)
            skinLabel:SetEnabled(false)
        else
            skinSlider:SetEnabled(true)
            skinLabel:SetEnabled(true)
        end
    end
    
    -- Update model when selection changes
    modelCombo.OnSelect = function(_, index, value, data)
        characterData.model = data
        UpdateModelPreview()
    end
    
    -- Update skin when slider changes
    skinSlider.OnValueChanged = function(_, value)
        characterData.skin = math.Round(value)
        if IsValid(modelPanel.Entity) then
            modelPanel.Entity:SetSkin(characterData.skin)
        end
    end
    
    -- Create button
    local createButton = vgui.Create("DButton", formPanel)
    createButton:SetSize(200, 50)
    createButton:SetPos(100, 400)
    createButton:SetText("")
    
    createButton.Paint = function(self, w, h)
        surface.SetDrawColor(50, 50, 50, 200)
        surface.DrawRect(0, 0, w, h)
        
        if self:IsHovered() then
            surface.SetDrawColor(ATOMIC.Config.Colors.Primary)
            surface.DrawOutlinedRect(0, 0, w, h, 2)
        end
        
        draw.SimpleText("Create Character", "AtomicNormalBold", w / 2, h / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    createButton.DoClick = function()
        -- Validate character data
        if firstNameEntry:GetValue():len() < 2 then
            ATOMIC:NotifyError(LocalPlayer(), "First name must be at least 2 characters.")
            return
        end
        
        if lastNameEntry:GetValue():len() < 2 then
            ATOMIC:NotifyError(LocalPlayer(), "Last name must be at least 2 characters.")
            return
        end
        
        -- Play sound
        surface.PlaySound("buttons/button14.wav")
        
        -- Update character data
        characterData.firstname = firstNameEntry:GetValue()
        characterData.lastname = lastNameEntry:GetValue()
        
        -- Create the character
        ATOMIC:CreateCharacter(characterData)
        
        -- Show character selection
        timer.Simple(1, function()
            if IsValid(parent) then
                ATOMIC:ShowCharacterSelection(parent)
            end
        end)
    end
    
    -- Back button
    if #ATOMIC.Characters.List > 0 then
        local backButton = vgui.Create("DButton", formPanel)
        backButton:SetSize(200, 50)
        backButton:SetPos(100, 460)
        backButton:SetText("")
        
        backButton.Paint = function(self, w, h)
            surface.SetDrawColor(50, 50, 50, 200)
            surface.DrawRect(0, 0, w, h)
            
            if self:IsHovered() then
                surface.SetDrawColor(ATOMIC.Config.Colors.Error)
                surface.DrawOutlinedRect(0, 0, w, h, 2)
            end
            
            draw.SimpleText("Back to Selection", "AtomicNormalBold", w / 2, h / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        
        backButton.DoClick = function()
            -- Play sound
            surface.PlaySound("buttons/button15.wav")
            
            -- Show character selection
            ATOMIC:ShowCharacterSelection(parent)
        end
    end
    
    -- Initialize model preview
    UpdateModelPreview()
end

-- Command to open character menu
concommand.Add("atomic_character", function()
    ATOMIC:OpenCharacterMenu()
end)
