# Hook Events
All events are prefixed with `NAMESPACE:EventName`.  
For example, to listen to an invent in the namespace `SV_ATOMIC`, like `DatabaseConnected` or `DatabaseConnectionFailed`; you would listen to `SV_ATOMIC:DatabaseConnected` or `SV_ATOMIC:DatabaseConnectionFailed`.
```lua
hook.Add('SV_ATOMIC:DatabaseConnected', function()
    print('Database connected')
end)

hook.Add('SV_ATOMIC:DatabaseConnectionFailed', function(err)
    print('Database connection failed:', err)
end)
```

## SV_ATOMIC
SV_ATOMIC contains general hooks that are triggered by the Atomic core exclusively on the server side.

### DatabaseConnected
Triggered when the database connection is successfully established.

### DatabaseConnectionFailed
- `err` (string) - The error message.

Triggered when the database connection fails to establish.

### DatabaseReady
Triggered when the database is ready to be used. This is triggered after the database connection is established and the database has been initialized, and the tables created. This is useful for running queries that require the database to be ready.

### CanPlayerChangeJob
- `ply` (Player) - The player who is trying to change their job.
- `oldJob` (string) - The player's old job identifier.
- `newJob` (string) - The player's new job identifier.

Triggered when a player tries to change their job. This is useful for preventing players from changing their job if they are not allowed to do so. This is triggered before the job is changed, so you can prevent the job change by returning `false` and an optional reason string. If you return a string, it will be sent to the player as a notification.
```lua
hook.Add('SV_ATOMIC:CanPlayerChangeJob', function(ply, oldJob, newJob)
    if not ply:IsAdmin() then
        return false, 'You are not allowed to change your job.'
    end
end)
```

### PlayerJobChanged
- `ply` (Player) - The player whose job has changed.
- `oldJob` (string) - The player's old job identifier.
- `newJob` (string) - The player's new job identifier.
Triggered when a player changes their job. This is useful for running code when a player changes their job, such as updating their inventory or sending them a notification. This is triggered after the job is changed, so you can use the new job and old job to determine what to do.