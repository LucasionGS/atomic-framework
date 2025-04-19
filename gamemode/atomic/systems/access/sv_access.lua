ATOMIC.DefaultRanks = ATOMIC.DefaultRanks or {
    "user",
    "admin",
    "superadmin"
}

ATOMIC.RankData = ATOMIC.RankData or {}

hook.Add("SV_ATOMIC:DatabaseReady", "Atomic_Ranks", function()
    local RankModel = Database:GetModel("Rank")
    
    ATOMIC.RankData = ATOMIC.RankData or {}
    ATOMIC.RankData["user"] = {
        name = "User",
        color = Color(255, 255, 255),
        access = {
            ["*"] = false
        }
    }
    ATOMIC.RankData["admin"] = {
        name = "Admin",
        color = Color(0, 255, 0),
        inherits = "user",
        access = {
            ["*"] = true
        }
    }
    ATOMIC.RankData["superadmin"] = {
        name = "Super Admin",
        color = Color(255, 0, 0),
        inherits = "admin",
        access = {
            ["*"] = true
        }
    }
end)