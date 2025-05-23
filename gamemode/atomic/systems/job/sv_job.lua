ATOMIC.Jobs = ATOMIC.Jobs or {} -- Table to hold all job classes

local Job = {}
Job.__index = Job
Job.Identifier = "job" -- This will be unique, and job files should be named sv_{Job.Identifier}.lua, e.g., sv_citizen.lua
Job.Name = "Job"
Job.Description = "A job class"
Job.Model = "models/props_c17/oildrum001.mdl"
Job.Salary = 0

function Job:New(identifier, name, description, model, salary)
    local self = setmetatable({}, Job)
    self.Identifier = identifier or ATOMIC:Raise("Job identifier is required")
    self.Name = name or ATOMIC:Raise("Job name is required")
    self.Description = description or "No description provided"
    self.Model = model or Job.Model
    self.Salary = salary or 0
    return self
end

function Job:FitRequirements(ply)
    -- Check if the player meets the job requirements
    -- This should return a boolean value and an optional reason string
    -- This is a placeholder function and should be implemented based on your requirements
    -- Example: Check if the player has a specific rank, level, or need to be in a specific location/near an NPC
    return true
end

function Job:OnPreLoadout(ply)
    -- Called right before OnLoadout. Runs before OnLoadout
    -- This is a placeholder function and should be implemented based on your requirements
    -- Default behavior is to clear the player from weapons and ammo.

    if ply:IsValid() then
        ply:StripWeapons()
        ply:StripAmmo()
    end
end

function Job:DefaultLoadout(ply)
    -- Internal function to set the default loadout for the job
    -- This function is called to set the default loadout for the job
    -- If overridden, make sure to override the class function instead of instance function, as it's meant to be static.
    if ply:IsValid() then
        ply:Give("weapon_fists")
        ply:Give("weapon_physgun")
        ply:Give("weapon_physcannon")
    end
end

function Job:OnLoadout(ply)
    -- Called when the player needs to be populated with the job loadout
    -- This is a placeholder function and should be implemented based on your requirements
    -- Example: Give the player a weapon or item
end

function Job:OnJobAssigned(ply)
    -- Called when the job is assigned to the player. Runs before OnPreLoadout
    -- This is a placeholder function and should be implemented based on your requirements

    ATOMIC:Notify(ply, "You have been assigned the job: " .. self.Name)
end

function Job:OnJobRemoved(ply)
    -- Called when the job is removed from the player
    -- This is a placeholder function and should be implemented based on your requirements
end

--[[
    Player convenience functions
]]--
local playerMeta = FindMetaTable("Player")

function playerMeta:HasJob(jobIdentifier)
    -- Check if the player has a specific job
    return self:GetJob() == jobIdentifier
end

-- Fetches the players ATOMIC_Job data. This holds the job identifier.
function playerMeta:GetJob()
    -- Get the player's current job
    local job = self:GetNWString("ATOMIC_Job", nil)
    if job and job ~= "" and ATOMIC.Jobs[job] then
        return job
    end
    return nil
end

-- Sets the players ATOMIC_Job data. This will begin the job assignment process.
function playerMeta:SetJob(jobIdentifier)
    if not jobIdentifier then return end
    
    -- Unassign the current job
    local currentJob = self:GetJob()

    local prevented, preventedReason = hook.Run("SV_ATOMIC:CanPlayerChangeJob", self, currentJob, jobIdentifier)

    if prevented == false then
        ATOMIC:Notify(self, preventedReason and preventedReason or "You cannot change jobs right now.")
        return
    end
    
    if currentJob and ATOMIC.Jobs[currentJob] then
        local job = ATOMIC.Jobs[currentJob]
        job:OnJobRemoved(self)
    end
    
    -- Call the job assignment function
    local job = ATOMIC.Jobs[jobIdentifier]
    if not job then
        ATOMIC:Raise("Job " .. jobIdentifier .. " not found!")
        return;
    end
    
    -- Set the player's current job
    self:SetNWString("ATOMIC_Job", jobIdentifier)
    -- Set job information
    self:SetNWString("ATOMIC_Job_Name", job.Name)
    self:SetNWString("ATOMIC_Job_Description", job.Description)
    self:SetNWString("ATOMIC_Job_Model", job.Model)
    self:SetNWInt("ATOMIC_Job_Salary", job.Salary)
    -- Set the player's job model
    self:SetModel(job.Model)

    -- Call the job pre-loadout function
    job:OnJobAssigned(self)
    -- Call the job loadout functions
    job:OnPreLoadout(self)
    Job:DefaultLoadout(self)
    job:OnLoadout(self)

    hook.Run("SV_ATOMIC:PlayerJobChanged", self, currentJob, jobIdentifier)
end

util.AddNetworkString("ATOMIC:RequestJob")
-- Request to get a job
net.Receive("ATOMIC:RequestJob", function(len, ply)
    local jobName = net.ReadString()

    -- Check if the job exists
    local job = ATOMIC.Jobs[jobName]
    if not job then
        ATOMIC:Error("Job " .. jobName .. " not found!")
        return
    end

    local fitsRequirements, reason = job:FitRequirements(ply)
    if not fitsRequirements then
        ATOMIC:NotifyError(ply, reason and reason or "You do not meet the requirements for this job.")
        return
    end
    
    -- Set the player's job
    ply:SetJob(jobName)
end)

--[[
    Job management functions
]]--
function ATOMIC.Jobs:Add(identifier, jobData)
    -- Create a new job class
    local jobClass = Job:New(identifier, jobData.Name, jobData.Description, jobData.Model, jobData.Salary)

    jobData.Identifier = identifier
    
    -- Add the job class to the jobs table
    ATOMIC.Jobs[jobData.Identifier] = jobClass

    -- Print a message to the console
    ATOMIC:Debug("Job " .. jobData.Name .. " added successfully!")

    return jobClass
end


-- Load all job files
ATOMIC:IncludeDir("gamemode/atomic/jobs", "sv")