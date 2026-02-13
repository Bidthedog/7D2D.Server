#!/bin/bash

################################################################################
# 7 Days to Die Dedicated Server - Local Configuration Override
#
# This file overrides the default values in 7d2d-config.sh for your
# specific deployment. Copy this file to 7d2d-config.local.sh and
# customize the values below.
#
# Usage:
#   cp 7d2d-config.local.example.sh 7d2d-config.local.sh
#   Edit 7d2d-config.local.sh with your server settings
#   DO NOT commit 7d2d-config.local.sh to git
#
# The local config is automatically loaded and overrides defaults if it exists.
#
################################################################################

# === Server Configuration (deployment-specific) ===
# These settings override the defaults in 7d2d-config.sh

# Server name as shown in the server browser
SERVER_NAME="My Awesome 7D2D Server"

# Server description visible in server list
SERVER_DESCRIPTION="A friendly survival server for the community"

# Server region: NorthAmericaEast, NorthAmericaWest, CentralAmerica, SouthAmerica,
# Europe, Russia, Asia, MiddleEast, Africa, Oceania
SERVER_REGION="Europe"

# Game save name (IMPORTANT: NO COLONS (:) - Windows players won't connect if you use colons)
GAME_NAME="MyServerWorld"

# Server port (default: 26900, must match firewall rules)
SERVER_PORT="26900"

# Server visibility: 0=private (not listed), 1=public (listed in server browser)
SERVER_VISIBILITY="0"

# Server password - set to empty string for no password
SERVER_PASSWORD="MySecurePassword"

# Maximum number of players allowed on server
# Note: More players = higher CPU/RAM usage. Start with 8 and adjust
SERVER_MAX_PLAYERS="8"

# Allow crossplay: true = Windows/Mac/Linux players together, false = Linux only
# IMPORTANT: When crossplay=true, additional server constraints apply:
#   - LootRespawnDays must be: -1, 0, or >= 5 (not 1-4)
#   - Other gameplay settings have stricter validation
# RECOMMENDED: Keep as FALSE for port-forwarded Linux servers (most reliable)
ALLOW_CROSSPLAY="false"

# Disabled network protocols: Leave BLANK for both LiteNetLib AND SteamNetworking
# RECOMMENDED: Blank (both enabled) - LiteNetLib for direct connection,
#              SteamNetworking as fallback if port forwarding has NAT issues
# LiteNetLib = primary optimized protocol (requires working port forwarding)
# SteamNetworking = fallback that routes through Steam (higher latency, more reliable)
DISABLED_NETWORK_PROTOCOLS=""

# Game difficulty (higher = harder)
# 0=Easiest, 1=Easy, 2=Normal, 3=Hard, 4=Insane, 5=Nightmare
GAME_DIFFICULTY="2"

# Map type: Navezgane (hand-crafted, recommended for testing) or RWG (random generated)
GAME_WORLD="Navezgane"

# Random seed for RWG (if GameWorld=RWG) - empty for random
# Use the same seed to get the same map each time
WORLD_GEN_SEED=""

# RWG map size - only used if GameWorld=RWG
# Larger = longer generation time. Options: 2048, 4096, 8192
WORLD_GEN_SIZE="4096"

# Length of a game day in real time (minutes)
# Default 60 means 1 real minute = 1 game hour
DAY_NIGHT_LENGTH="60"

# Number of in-game days before loot respawns in containers
# Lower = loot respawns faster
# (-1 - 0, >= 5 if cross play enabled)
LOOT_RESPAWN_DAYS="7"

# Air drop frequency in in-game hours
# Default 72 = one airdrop every 3 game days
AIR_DROP_FREQUENCY="72"

# PvP (Player vs Player) mode
# 0=No PvP (peaceful), 1=PvP+PvE (both allowed), 2=PvP only (no zombies), 3=Friendly PvP (can trade)
PLAYER_KILLING_MODE="3"

# Enable/disable EAC (Easy Anti-Cheat)
# Set to 'false' if you have issues or want to allow mods that EAC blocks
EAC_ENABLED="true"

# Telnet console password for remote administration
# Empty = accessible only from localhost (127.0.0.1)
# Set a password if you need remote telnet access
TELNET_PASSWORD=""

# Enable blood moons (frequency in in-game days)
# Set to 0 to disable blood moons entirely
BLOOD_MOON_FREQUENCY="7"

# === Server Admin Configuration ===
# Steam IDs (SteamID64) of server admins - space-separated for multiple admins
# Find your Steam ID at: https://steamdb.info/calculator/, https://steamid.io/lookup
# Example with multiple admins: ADMIN_STEAM_IDS="YOUR_STEAM_ID_HERE 76561198021925107"
ADMIN_STEAM_IDS=""

# === Optional: Custom paths (uncomment to override) ===
# Uncomment these only if you need different paths than the defaults
# SERVER_DIR="/opt/7d2d-server"
# LOG_FILE="/var/log/7d2d-update.log"

################################################################################
# End of local configuration
################################################################################
