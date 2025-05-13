--[[
    Client-side NPC System
    This file contains client-side functionality for the NPC system.
]]--

-- Precache NPC models
hook.Add("Initialize", "ATOMIC_NPCs_Precache", function()
    for _, model in ipairs(ATOMIC.NPC_MODELS) do
        util.PrecacheModel(model)
    end
end)

-- Create NPC dialog menu
function ATOMIC:CreateNPCDialog(npc, options)
    -- Create the dialog frame
    local frame = vgui.Create("DFrame")
    frame:SetTitle(npc:GetNWString("NPCName", "NPC"))
    frame:SetSize(400, 500)
    frame:Center()
    frame:MakePopup()
    
    -- Create a scrollable panel for the dialog options
    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)
    
    -- Add the dialog options
    for i, option in ipairs(options) do
        local button = vgui.Create("DButton", scroll)
        button:SetText(option.Text)
        button:SetHeight(40)
        button:Dock(TOP)
        button:DockMargin(5, 5, 5, 0)
        button.DoClick = function()
            net.Start("ATOMIC_NPC_DialogOption")
            net.WriteEntity(npc)
            net.WriteInt(i, 8)
            net.SendToServer()
            frame:Close()
        end
    end
    
    -- Add a close button
    local closeButton = vgui.Create("DButton", frame)
    closeButton:SetText("Close")
    closeButton:SetHeight(40)
    closeButton:Dock(BOTTOM)
    closeButton:DockMargin(5, 5, 5, 5)
    closeButton.DoClick = function()
        frame:Close()
    end
end

-- Network receivers
net.Receive("ATOMIC_NPC_Dialog", function(len)
    local npc = net.ReadEntity()
    local options = net.ReadTable()
    
    ATOMIC:CreateNPCDialog(npc, options)
end)

-- Draw NPC names above their heads
hook.Add("HUDPaint", "ATOMIC_NPCs_DrawNames", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    -- Only draw names within a certain radius
    local radius = 300
    
    for _, npc in ipairs(ents.FindByClass("atomic_npc")) do
        if IsValid(npc) and npc:GetPos():DistToSqr(ply:GetPos()) < radius * radius then
            local pos = npc:GetPos() + Vector(0, 0, 70)
            local screenPos = pos:ToScreen()
            
            -- Draw the NPC name
            draw.SimpleText(
                npc:GetNWString("NPCName", "NPC"),
                "DermaLarge",
                screenPos.x,
                screenPos.y,
                Color(255, 255, 255, 255),
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER
            )
        end
    end
end)
