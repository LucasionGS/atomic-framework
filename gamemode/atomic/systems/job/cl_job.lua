-- Player convenience functions
local playerMeta = FindMetaTable("Player")

function playerMeta:HasJob(jobIdentifier)
    -- Check if the player has a specific job
    return self:GetJob() == jobIdentifier
end

-- Fetches the players ATOMIC_Job data. This holds the job identifier.
function playerMeta:GetJob()
    -- Get the player's current job
    local job = self:GetNWString("ATOMIC_Job", nil)
    if job and job ~= "" then
        return job
    end
    return nil
end

-- Request to get a job
function playerMeta:RequestJob(jobName)
    net.Start("ATOMIC:RequestJob")
        net.WriteString(jobName)
    net.SendToServer()
end