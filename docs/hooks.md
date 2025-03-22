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