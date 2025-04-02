-- Create a dialog box
function ATOMIC:Dialog(title, text, options)
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    -- Check if the dialog is already open. This is to prevent multiple dialogs from opening at the same time.
    if ply:GetNWBool("ATOMIC:DialogOpen") then return end
    ply:SetNWBool("ATOMIC:DialogOpen", true)

    local textHeight = #string.Explode("\n", text) * 16 + 60

    if #options == 0 then
        options = {
            {
                text = "<Leave>",
            }
        }
    end
    
    local optionsHeight = ((30 + 5) * #options)
    
    local frame = vgui.Create("DFrame")
    frame:SetSize(500, textHeight + optionsHeight)
    frame:SetTitle("")
    frame:SetDraggable(false)
    frame:CenterHorizontal()
    frame:SetPos(frame:GetX(), ScrH() - frame:GetTall() - 50)
    frame:MakePopup()
    frame:ShowCloseButton(false)

    -- frame.Paint = function(self, w, h)
    --     draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30, 230))
    -- end

    frame.Paint = function(self, w, h)
        local bg = ATOMIC.Config.Colors.Background
        draw.RoundedBox(4, 0, 0, w, h, ATOMIC.Config.Colors.Background)
        -- local gradient = Material("gui/gradient") -- Use the built-in gradient material
        -- local prim = ATOMIC.Config.Colors.Primary
        -- surface.SetDrawColor(prim.r, prim.g, prim.b, 100) -- Start color (purple)
        -- surface.SetMaterial(gradient)
        -- surface.DrawTexturedRectRotated(w / 2, h / 2, h, w, -90) -- Draw gradient from top to bottom
    end

    local titleLabel = vgui.Create("DLabel", frame)
    titleLabel:SetText(title or "")
    titleLabel:SetFont("AtomicLarge")
    titleLabel:SetTextColor(Color(255, 255, 255))
    titleLabel:SizeToContents()
    titleLabel:SetPos(frame:GetWide() / 2 - titleLabel:GetWide() / 2, 10)

    local dialogText = vgui.Create("DLabel", frame)
    dialogText:SetText(text)
    dialogText:SetFont("AtomicNormalBold")
    dialogText:SetTextColor(Color(255, 255, 255))
    dialogText:SetWrap(true)
    dialogText:SetAutoStretchVertical(true)
    dialogText:SetSize(frame:GetWide() - 20, 0)
    dialogText:SetPos(10, 50)

    local optionsList = vgui.Create("DScrollPanel", frame)
    optionsList:SetPos(10, textHeight)
    optionsList:SetSize(frame:GetWide() - 20, optionsHeight)

    local function setupOption(parent, option, shouldFitInLine)
        shouldFitInLine = shouldFitInLine or 1
        local button = parent:Add("DButton")
        button:SetText(option.text)
        button:Dock(shouldFitInLine == 1 and TOP or LEFT)
        button:DockMargin(2, 0, 2, 5)
        button:SetTall(30)
        button:SetFont("AtomicNormalBold")
        button:SetTextColor(Color(255, 255, 255))
        button:SetWide(parent:GetWide() / shouldFitInLine)

        local clr = ATOMIC.Config.Colors.Background

        local gradient = Material("gui/gradient") -- Use the built-in gradient material
        local hvr = ATOMIC.Config.Colors.Primary
        
        local buttonColor = option.color or Color(clr.r, clr.g, clr.b, 230)
        local buttonHoverColor = option.hoverColor or Color(hvr.r, hvr.g, hvr.b, 230)
        
        button.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, buttonColor)
            if self:IsHovered() then
                surface.SetDrawColor(buttonHoverColor)
                surface.SetMaterial(gradient)
                surface.DrawTexturedRectRotated(w / 2, h / 2, h, w, -90)
            end
        end

        if option.isLabel == true then
            -- Act as a label
            button:DockMargin(2, 0, 2, 0)
            button.Paint = function(self, w, h)
                draw.RoundedBox(4, 0, 0, w, h, Color(0, 0, 0, 0))
            end
        else
            button.DoClick = function()
                if not option.nosound then
                    surface.PlaySound("buttons/lightswitch2.wav")
                end
                ply:SetNWBool("ATOMIC:DialogOpen", false)
                local shouldClose = true
                if option.click then -- Runs after it closes
                    shouldClose = option.click()
                end
                if shouldClose ~= false then
                    frame:Close()
                end
            end
        end
    end
    
    for _, option in ipairs(options) do
        -- Check if option is custom
        if option.custom then
            option.custom(optionsList)
            continue
        end
        
        -- Check if option is a list of options
        if not option.text then
            local panel = vgui.Create("DPanel", optionsList)
            panel:Dock(TOP)
            panel:SetTall(30)
            panel:SetWide(optionsList:GetWide())
            panel.Paint = function(self, w, h)
                draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 0))
            end
            local subOptionCount = #option
            for i, subOption in ipairs(option) do
                -- Ensure that the key is a number
                if not isnumber(i) then continue end
                setupOption(panel, subOption, subOptionCount)
            end
            continue
        end
        
        setupOption(optionsList, option)
    end
end


concommand.Add("dialog_test", function(ply, cmd, args)
    ATOMIC:Dialog("Test Dialog", "This is a test dialog. Click the buttons to see what happens.", {
        {
            text = "Option 1",
            click = function()
                print("Option 1 clicked")
            end
        },
        {
            text = "Option 2",
            click = function()
                print("Option 2 clicked")
            end
        },
        {
            text = "Option 3",
            click = function()
                print("Option 3 clicked")
            end
        },
        {
            text = "Second menu!",
            click = function()
                ATOMIC:Dialog("Second Menu", "This is a second menu. Click the buttons to see what happens.", {
                    {
                        text = "Option 1",
                        click = function()
                            print("Option 1 clicked")
                        end
                    },
                    {
                        text = "Option 2",
                        click = function()
                            print("Option 2 clicked")
                        end
                    },
                    {
                        text = "Option 3",
                        click = function()
                            print("Option 3 clicked")
                        end
                    }
                })
            end
        }
    })
end)