# 7 Days to Die Dedicated Server

Automated setup and management for a 7 Days to Die dedicated server on **Debian Linux** with automatic updates and systemd service management.

## Quick Start

### Prerequisites

- **Debian 12+** Linux Proxmox Container (CT)
- **6 GB RAM** (4 GB minimum), **20 GB disk** (10 GB minimum)
- **Root access** (via `sudo` if using privileged container or full Debian; unprivileged CTs run as root by default)
- Network access to Steam

> **Note**: These instructions are optimized for hosting on an unprivileged Proxmox Debian container (CT). If you're using a privileged container or full Debian instance, modifications may be required (especially regarding `sudo` usage, file permissions, and systemd service definitions).

### Initial Setup

1. Copy scripts to your Linux server:
   ```bash
   scp *.sh user@server:~/
   ```

2. Configure your server (create from example):
   ```bash
   mv 7d2d-config.local.example.sh 7d2d-config.local.sh
   # Edit with your server name, password, game name, etc
   nano 7d2d-config.local.sh
   ```

3. Run initial installation:
   ```bash
   ~/update-server.sh
   ```

4. Setup systemd service (run once; use `sudo` if in a privileged container or full Debian):
   ```bash
   ~/setup-service.sh    # Unprivileged Proxmox container (already root)
   sudo ~/setup-service.sh  # Privileged container or full Debian instance
   ```

5. Start and manage server:
   ```bash
   7d2d_start      # Start server
   7d2d_stop       # Stop server
   7d2d_restart    # Restart (auto-updates first)
   7d2d_status     # Check status
   7d2d_log        # View systemd logs (startup/errors)
   7d2d_serverlog  # View server logs (players/game events)
   ```

## Default Directory and File Locations

| Item | Location |
|------|----------|
| 7D2D Server | `/opt/7d2d-server/` |
| Update Log | `/var/log/7d2d-update.log` |
| Service Config | `/etc/systemd/system/7d2d.service` |

## Configuration

All server configuration is managed through shell variables in `7d2d-config.sh` and `7d2d-config.local.sh`. The update script automatically applies these settings to the server's `serverconfig.xml` file.

### Shell Configuration Setup

**Shared defaults** in `7d2d-config.sh` - Edit only to change generic defaults or add features.

**Per-deployment settings** in `7d2d-config.local.sh`:

1. Copy the example:
   ```bash
   cp 7d2d-config.local.example.sh 7d2d-config.local.sh
   ```

2. Edit with your settings:
   ```bash
   nano 7d2d-config.local.sh
   ```

   Key settings to customize:
   ```bash
   SERVER_NAME="Your Server Name"       # Server name in browser
   SERVER_DESCRIPTION="..."             # Server description
   GAME_NAME="Your Server Name World"   # Save game name (NO COLONS!)
   SERVER_PASSWORD="secretpassword"     # Server password
   SERVER_VISIBILITY="0"                # 0=private, 1=public
   SERVER_MAX_PLAYERS="6"               # Max concurrent players
   GAME_DIFFICULTY="2"                  # 0=Easiest ... 5=Nightmare
   GAME_WORLD="Navezgane"               # Navezgane or RWG
   PLAYER_KILLING_MODE="3"              # PvP mode
   EAC_ENABLED="true"                   # Anti-cheat enabled
   ADMIN_STEAM_IDS="YOUR_STEAM_ID_HERE" # Your Steam ID (SteamID64 format)
   ```

The local config contains private information and should **NOT** be pushed remotely - keeps passwords secure and allows different deployments.

### How Configuration Works

1. **First Run**: Server auto-generates `serverconfig.xml` with default settings
2. **Config Application**: The update script automatically applies your shell config settings to `serverconfig.xml`
3. **Updates**: Each time the update script runs, it reapplies settings from `7d2d-config.local.sh`

The update script applies these settings:
- `ServerName`, `ServerDescription`, `ServerPassword` - Server identification
- `ServerPort`, `ServerVisibility`, `ServerMaxPlayerCount` - Server behavior
- `GameName`, `GameDifficulty`, `GameWorld` - Game creation
- `WorldGenSize`, `WorldGenSeed` - Map generation (for RWG)
- `DayNightLength`, `LootRespawnDays`, `AirDropFequency` - Game mechanics
- `PlayerKillingMode` - PvP settings
- `EACEnabled`, `TelnetEnabled`, `TelnetPassword` - Security and admin access
- `BloodMoonFrequency` - Difficulty and event settings

**Important Notes:**
- DO NOT use colons (`:`) in `GameName`, or Windows players can't connect
- Changes take effect after server restart
- Set `EACEnabled` to `false` if using mods that conflict with anti-cheat

## Server Administration

### Admin Configuration

Configure server admins by setting `ADMIN_STEAM_IDS` in `7d2d-config.local.sh`:

```bash
# Single admin
ADMIN_STEAM_IDS="YOUR_STEAM_ID_HERE"

# Multiple admins (space-separated)
ADMIN_STEAM_IDS="YOUR_STEAM_ID_HERE 76561198021925107 76561198045685453"
```

The admin list is automatically applied to `~/.local/share/7DaysToDie/Saves/serveradmin.xml` when the update script runs.

**Finding Your Steam ID:**
1. Visit [steamid.io](https://steamid.io) or [steamdb.info/calculator](https://steamdb.info/calculator)
2. Search for your Steam username or profile URL
3. Copy your **SteamID64** (a 17-digit number starting with 765611)

**Admin Permissions:**
- Admins get permission level 0 (highest priority)
- Can execute all console commands
- Can use the Telnet console or Web Dashboard for remote administration

## Logging

### Server Logs

The 7 Days to Die server outputs to two different locations:

**Game server logs** (player connections, game events, detailed activity):
```bash
# View live server logs (recommended for monitoring gameplay)
7d2d_serverlog

# Or manually:
tail -f $(ls -t /opt/7d2d-server/output_log__*.txt | head -1)
```

**Systemd logs** (service startup, errors, basic status):
```bash
# View live systemd logs
7d2d_log

# Or manually:
journalctl -u 7d2d.service -f
```

> **Note**: With `-logfile /dev/stdout` enabled, `7d2d_log` should now capture most server output. If you don't see player connections or game events, use `7d2d_serverlog` as a fallback to directly view the Unity output_log files.

### Update Script Logs

All script operations are logged to `/var/log/7d2d-update.log` with:
- Timestamps
- Detailed operation tracking

View logs:
```bash
# View full update log
cat /var/log/7d2d-update.log

# View recent entries
tail -n 50 /var/log/7d2d-update.log
```

## Dependencies

Scripts automatically install missing dependencies:
- `curl` - For downloading files
- `xmlstarlet` - For XML configuration (serverconfig.xml)
- `steamcmd` - For game server installation

## Troubleshooting

### Service won't start
```bash
# Check service status
systemctl status 7d2d.service

# View full errors
journalctl -u 7d2d.service -n 50

# View update log
cat /var/log/7d2d-update.log | tail -50
```

### Reconfigure everything
```bash
# Update configuration and rerun setup
# Unprivileged Proxmox container (no sudo needed):
~/setup-service.sh
7d2d_restart

# Privileged container or full Debian (with sudo):
sudo ~/setup-service.sh
7d2d_restart
```

## Architecture Notes

- **Idempotent updates**: Scripts can be run multiple times without causing issues
- **Config management**: Shell variables combined with xmlstarlet for dynamic serverconfig.xml updates
- **Log rotation**: Old server logs (>30 days) automatically purged during updates

## Support

For 7 Days to Die-specific issues:
- https://steamcommunity.com/sharedfiles/filedetails/?id=360404397
- https://7daystodie.com/

## License & References

- 7 Days to Die: https://7daystodie.com/
- 7 Days to Die Mods: https://7daystodiemods.com/
