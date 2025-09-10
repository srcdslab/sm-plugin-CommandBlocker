# Copilot Instructions for CommandBlocker SourceMod Plugin

## Repository Overview
This repository contains the **CommandBlocker** SourceMod plugin, which allows server administrators to block, kick, or ban players who attempt to use specific commands. The plugin is designed for Source engine game servers using SourceMod 1.11+ and follows modern SourcePawn development practices.

## Project Structure
```
addons/sourcemod/
├── scripting/
│   ├── CommandBlocker.sp          # Main plugin file
│   └── include/
│       └── CCommandBlocker.inc    # Methodmap class definition
└── configs/
    └── commandblocker.cfg         # Plugin configuration file

.github/
└── workflows/
    └── ci.yml                     # CI/CD pipeline

sourceknight.yaml                  # Build system configuration
```

## Build System & Environment
- **Build Tool**: SourceKnight (configured via `sourceknight.yaml`)
- **Compiler**: SourceMod compiler (spcomp) via SourceKnight
- **Dependencies**: SourceMod 1.11.0-git6934, sm-plugin-basic
- **Output**: Compiled `.smx` files in `/addons/sourcemod/plugins`

### Building the Plugin
```bash
# Install SourceKnight if not available
pip install sourceknight

# Build the plugin
sourceknight build
```

## Code Style & Standards (Specific to this Repository)

### Naming Conventions
- **Global variables**: Prefix with `g_` (e.g., `g_aCommands`, `g_cv_BanLength`)
- **ConVars**: Use `g_cv_` prefix (e.g., `g_cv_BlockLog`)
- **Functions**: PascalCase for public functions (e.g., `OnPluginStart`)
- **Local variables**: camelCase (e.g., `sCommand`, `iUserID`)
- **Constants**: ALL_CAPS with underscores (e.g., `CMD_MAX_LEN`)

### Required Pragmas
```sourcepawn
#pragma semicolon 1
#pragma newdecls required
```

### Memory Management Rules
- Use `delete` directly without null checks (SourceMod handles this)
- Always delete ArrayLists and StringMaps when done
- Never use `.Clear()` on collections - use `delete` and recreate
- Properly cleanup in `OnPluginEnd()` and before reloading configs

### File Organization
- Main plugin logic in `CommandBlocker.sp`
- Class definitions in separate `.inc` files in `include/` folder
- Use methodmaps for data structures (see `CCommandBlocker` class)

## Plugin Architecture

### Core Components
1. **Command Monitoring**: Uses `AddCommandListener` to intercept all commands
2. **Configuration System**: KeyValues-based config in `commandblocker.cfg`
3. **Block Types**: Three action types (Block, Kick, Ban) defined in `eBlockType` enum
4. **Data Storage**: ArrayList of `CCommandBlocker` objects for runtime command storage

### Key Functions
- `OnPluginStart()`: Initialize ConVars, register admin commands, setup command listener
- `OnConfigsExecuted()`: Load configuration file
- `Command_OnAny()`: Main command interception logic
- `LoadConfig()`: Parse and load blocked commands from config
- `ExecuteCommandBlock()`: Execute the appropriate block action
- `AddCommandBlock()`: Add new blocked command to runtime storage

### Configuration Format
```
"CommandBlocker"
{
    "0"  // Unique identifier
    {
        "command"   "blocked_command"
        "blocktype" "2"  // 0=Block, 1=Kick, 2=Ban
    }
}
```

## Development Guidelines

### Adding New Features
1. Maintain backward compatibility with existing configs
2. Follow the existing ConVar naming pattern (`sm_commandblocker_*`)
3. Use admin flags appropriately (ADMFLAG_ROOT for dangerous operations)
4. Always validate user input and handle edge cases
5. Log important actions using `LogAction()` or `LogMessage()`

### Error Handling
- Check file existence before loading configs
- Validate KeyValues operations return successfully
- Use `IsValidClient()` for client validation
- Handle cases where commands may not exist

### Performance Considerations
- Command interception happens frequently - keep `Command_OnAny()` efficient
- Cache config data in memory (ArrayList) rather than reading files repeatedly
- Use string comparison carefully in hot paths
- Consider command frequency when adding blocking logic

### Admin Commands
- `sm_commandblocker_reloadcfg`: Reload configuration (ADMFLAG_GENERIC)
- `sm_commandblocker_block`: Add runtime block command (ADMFLAG_ROOT)
- `sm_commandblocker_kick`: Add runtime kick command (ADMFLAG_ROOT)
- `sm_commandblocker_ban`: Add runtime ban command (ADMFLAG_ROOT)

## Testing & Validation

### Manual Testing
1. Load plugin on test server
2. Test each block type (block, kick, ban)
3. Verify config reloading works
4. Test admin commands with proper permissions
5. Validate logging functionality

### Config Validation
- Ensure `commandblocker.cfg` follows KeyValues format
- Test with empty configs and malformed entries
- Verify blocktype values are within valid range (0-2)

## ConVar Configuration
- `sm_commandblocker_ban_length`: Ban duration in minutes (default: 5)
- `sm_commandblocker_block_log`: Enable/disable logging (default: 1)
- `sm_commandblocker_ban_reason_hidden`: Use command index instead of name in ban reason (default: 0)

## Dependencies
- **SourceMod**: 1.11.0+ required
- **basic.inc**: From sm-plugin-basic repository (for methodmap base class)

## CI/CD Pipeline
- Automated building via GitHub Actions using SourceKnight
- Artifact packaging including configs
- Automatic releases on tags and main branch pushes
- Multi-platform builds (Ubuntu 24.04)

## Common Issues & Solutions
1. **Plugin fails to load**: Check SourceMod version compatibility
2. **Commands not blocked**: Verify config file path and format
3. **Memory leaks**: Ensure proper cleanup in config reloading
4. **Permission errors**: Check admin flag requirements for commands

## Best Practices for Contributors
- Test all changes on a development server before submitting
- Maintain consistent code formatting with existing files
- Update version number in plugin info when making changes
- Document any new ConVars or admin commands
- Follow the established error handling patterns
- Keep the plugin lightweight and efficient for production use