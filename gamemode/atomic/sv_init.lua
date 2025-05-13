function GM:Initialize()
    print("Atomic Framework: Server initialized.")
end

hook.Add("SV_ATOMIC:DatabaseConnected", "Atomic_SuccessfullyConnected", function()
    print("Atomic Framework: Database connected.")
    for i, model in ipairs(Database.ModelOrder) do
        local m = Database:Model(model)
        if not m:TableExists():Wait() then
            print("Creating table for model: " .. model)
            local res = m:CreateTable():wait()
        end
    end

    hook.Run("SV_ATOMIC:DatabaseReady")
end)


hook.Add("SV_ATOMIC:DatabaseConnectionFailed", "Atomic_FailureConnecting", function(err)
    print("Failed to connect to the MySQL database:")
    print(err)
end)