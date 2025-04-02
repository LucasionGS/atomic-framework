DeriveGamemode("sandbox")

GM.Name = ATOMIC.Config.Name
GM.Author = ATOMIC.Config.Author
GM.Sandbox = true

function ATOMIC:Debug(...)
    if ATOMIC.Config.Debug then
        print("[Atomic Debug]", ...)
    end
end

function ATOMIC:Error(...)
    ErrorNoHalt("[Atomic Error]", ...)
end


function GM:SpawnMenuOpen()
    notification.AddLegacy("Atomic Framework: Spawn menu is disabled.", NOTIFY_GENERIC, 5)
    return false -- allows the sandbox spawn menu (Q menu)
end