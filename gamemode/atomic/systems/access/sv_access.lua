ATOMIC.RankData = ATOMIC.RankData or {}

hook.Add("SV_ATOMIC:DatabaseReady", "Atomic_Ranks", function()
    local RankModel = Database:Model("ranks")

    local existingRanks = RankModel:Select():Run():Wait()
    PrintTable(existingRanks)
    if existingRanks and #existingRanks > 0 then
        -- If ranks already exist, do not create default ranks
        return
    end
    
    
    ATOMIC.RankData = ATOMIC.RankData or {}
    -- Create default ranks
    ATOMIC.RankData["user"] = {
        index = 1,
        name = "user",
        displayName = "User",
        color = Color(255, 255, 255),
        permissions = { }
    }
    ATOMIC.RankData["admin"] = {
        index = 2,
        name = "admin",
        displayName = "Admin",
        color = Color(0, 255, 0),
        inherits = "user",
        permissions = { "*" }
    }
    ATOMIC.RankData["superadmin"] = {
        index = 3,
        name = "superadmin",
        displayName = "Super Admin",
        color = Color(255, 0, 0),
        inherits = "admin",
        permissions = { "*" }
    }

    RankModel:Insert(
        ATOMIC:GetRankDataToSqlObject(ATOMIC.RankData["user"]),
        ATOMIC:GetRankDataToSqlObject(ATOMIC.RankData["admin"]),
        ATOMIC:GetRankDataToSqlObject(ATOMIC.RankData["superadmin"])
    ):Run()
end)



function ATOMIC:GetRankDataToSqlObject(rankData)
    return {
        index = rankData.index,
        name = rankData.name,
        displayName = rankData.displayName,
        color = ATOMIC:ColorToHex(rankData.color),
        permissions = util.TableToJSON(rankData.permissions),
    }
end

function ATOMIC:GetRankDataFromSqlObject(rankData)
    return {
        index = rankData.rank,
        name = rankData.name,
        displayName = rankData.displayName,
        color = ATOMIC:HexToColor(rankData.color),
        permissions = util.JSONToTable(rankData.permissions),
    }
end