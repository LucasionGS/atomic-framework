-- File: cl_model_preload.lua
-- Client-side model preloading for the Atomic framework

local function PreloadModels()
    for _, modelData in ipairs(ATOMIC.Config.CharacterModels) do
        util.PrecacheModel(modelData.model)
    end
end

-- Preload models when initializing
hook.Add("InitPostEntity", "ATOMIC:PreloadCharacterModels", function()
    PreloadModels()
end)
