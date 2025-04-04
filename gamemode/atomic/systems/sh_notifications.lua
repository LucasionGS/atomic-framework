AddCSLuaFile()

-- Make sure the notification system is loaded on both server and client
NOTIFY_GENERIC  = 0
NOTIFY_ERROR    = 1
NOTIFY_UNDO     = 2
NOTIFY_HINT     = 3
NOTIFY_CLEANUP  = 4


if SERVER then
    util.AddNetworkString("ATOMIC:PlayerNotification")
else -- Client
    net.Receive("ATOMIC:PlayerNotification", function()
        local message = net.ReadString()
        local notifType = net.ReadUInt(8)

        -- Add legacy notification for client
        ATOMIC:NotifyType(LocalPlayer(), notifType, 5, message)
    end)
end

-- Handles the notification system
function ATOMIC:NotifyType(ply, notifType, time, ...)
    if ply == nil and CLIENT then
        ply = LocalPlayer()
    end
    
    if not IsValid(ply) then return end

    local message = string.format(...)
    -- Send notification to the player
    if SERVER then
        -- Send notification to the player
        net.Start("ATOMIC:PlayerNotification")
        net.WriteString(message)
        net.WriteUInt(notifType, 8)
        net.Send(ply)
    else
        -- Add legacy notification for client
        notification.AddLegacy(message, notifType, time)
        -- Play sound
        if notifType == NOTIFY_ERROR then
            surface.PlaySound("buttons/button10.wav")
        elseif notifType == NOTIFY_GENERIC then
            surface.PlaySound("buttons/button3.wav")
        end
    end
end

-- Regular notification
function ATOMIC:Notify(ply, ...)
    ATOMIC:NotifyType(ply, NOTIFY_GENERIC, 5, ...)
end

-- Error notification
function ATOMIC:NotifyError(ply, ...)
    ATOMIC:NotifyType(ply, NOTIFY_ERROR, 5, ...)
end