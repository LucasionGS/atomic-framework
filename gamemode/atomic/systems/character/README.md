# Atomic Character System

## Overview
The character system is one of the core components of the Atomic Framework. It handles:

1. Character creation and customization
2. Character selection
3. Character data persistence
4. Character-specific attributes and stats

## Command Format

Commands in the Atomic framework use the following format:

```lua
ATOMIC:AddCommand("commandname", function(player, args)
    -- Command logic here
    -- player: The player who executed the command
    -- args: Array of arguments (args[1] is the command name itself)
end, {
    -- Optional settings
    rank = "admin", -- Required rank to use the command
    requireDuty = true -- Whether the player needs to be on duty
})
```

## Available Commands

### Player Commands

- `!changename <firstname> <lastname>` - Change your character's name
- `!savecharacter` - Save your current character data

### Admin Commands

- `!deletecharacter <steamid> <characterid>` - Delete a character
- `!setcharactermoney <target> <amount>` - Set a character's money
- `!setcharacterbank <target> <amount>` - Set a character's bank balance
- `!addspawn` - Add a spawnpoint at your current position
- `!listspawns` - List all available spawnpoints
- `!gotopoint <id>` - Teleport to a specific spawnpoint

## Database Structure

Characters are stored in the `characters` table with the following fields:

- `id` - Unique character ID
- `steamid64` - Player's SteamID64
- `firstname` - Character first name
- `lastname` - Character last name
- `model` - Character model path
- `bodygroups` - JSON encoded bodygroups
- `clothing` - JSON encoded clothing
- `money` - Cash amount
- `bank` - Bank balance
- `x`, `y`, `z` - Last known position
- `stats` - JSON encoded character stats
- `created_at` - Creation timestamp
- `lastused_at` - Last used timestamp

## Integration with Other Systems

The character system integrates with:

- Player system for spawning and equipment
- Commands system for character actions
- Database system for persistence
