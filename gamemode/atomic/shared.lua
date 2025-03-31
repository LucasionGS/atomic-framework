DeriveGamemode("sandbox")

ATOMIC = ATOMIC or {} -- Global for Atomic Framework
include("../config/config.lua")
include("config.lua")

GM.Name = ATOMIC.Config.Name
GM.Author = ATOMIC.Config.Author
GM.Sandbox = true

function ATOMIC:Debug(...)
    if ATOMIC.Config.Debug then
        print("[Atomic Debug]", ...)
    end
end


-- function GM:SpawnMenuOpen()
--     return true -- allows the sandbox spawn menu (Q menu)
-- end