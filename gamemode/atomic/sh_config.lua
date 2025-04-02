-- Process configuration
ATOMIC.Config = ATOMIC.Config or {}
ATOMIC.Config.GamemodeFolderName = ATOMIC.Config.GamemodeFolderName or nil

if ATOMIC.Config.GamemodeFolderName == nil then
    print("ERROR: Gamemode folder name not set. Please set ATOMIC.Config.GamemodeFolderName in config/config.lua.")
end

ATOMIC.Config.DataFolder = ATOMIC.Config.DataFolder or ATOMIC.Config.GamemodeFolderName or nil

if ATOMIC.Config.DataFolder == nil then
    print("ERROR: Data folder not set. Please set ATOMIC.Config.DataFolder in config/config.lua.")
end


-- Default colors
ATOMIC.Config.Colors = ATOMIC.Config.Colors or {}
local acc = ATOMIC.Config.Colors
ATOMIC.Config.Colors.Primary = acc.Primary          or Color( 128, 20, 128, 100 )
ATOMIC.Config.Colors.Secondary = acc.Secondary      or Color( 255, 255, 255, 100 )
ATOMIC.Config.Colors.Tertiary = acc.Tertiary        or Color( 0, 0, 0, 100 )
ATOMIC.Config.Colors.Background = acc.Background    or Color( 30, 30, 30, 230 )
ATOMIC.Config.Colors.Text = acc.Text                or Color( 255, 255, 255, 255 )
ATOMIC.Config.Colors.Error = acc.Error              or Color( 255, 0, 0, 255 )