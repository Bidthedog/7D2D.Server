#!/bin/bash

################################################################################
# 7 Days to Die Dedicated Server - Shared Configuration
#
# This file contains all shared configuration variables used by the
# 7 Days to Die server management scripts. Source this file to use these variables.
#
# Usage in other scripts:
#   source ./7d2d-config.sh
#   or
#   source "$(dirname "$0")/7d2d-config.sh"
#
################################################################################

# === System & Logging ===
LOG_FILE="/var/log/7d2d-update.log"
STEAMCMD_DIR="/usr/games"

# === Server Installation ===
SERVER_DIR="/opt/7d2d-server"
SERVER_APP_ID="294420"

# === Server Configuration ===
# These values are defaults and can be overridden in 7d2d-config.local.sh
# DO NOT commit sensitive settings to git - use the .local file instead
SERVER_NAME="My 7D2D Server"
SERVER_DESCRIPTION="A 7 Days to Die Survival Server"
SERVER_REGION="Europe"
SERVER_PORT="26900"
SERVER_VISIBILITY="0"
SERVER_PASSWORD="changeme"
SERVER_MAX_PLAYERS="8"
ALLOW_CROSSPLAY="true"
DISABLED_NETWORK_PROTOCOLS="SteamNetworking"

# === Game Configuration ===
GAME_NAME="MyWorld"
GAME_DIFFICULTY="2"
GAME_WORLD="Navezgane"
WORLD_GEN_SEED=""
WORLD_GEN_SIZE="4096"
DAY_NIGHT_LENGTH="60"
LOOT_RESPAWN_DAYS="7"
AIR_DROP_FREQUENCY="72"
PLAYER_KILLING_MODE="3"
EAC_ENABLED="true"
TELNET_PASSWORD=""
BLOOD_MOON_FREQUENCY="7"

# === Server Admin Configuration ===
# Steam ID (SteamID64) of server admin(s) - space-separated for multiple admins
# Find your Steam ID at: https://steamdb.info/calculator/, https://steamid.io/lookup
ADMIN_STEAM_IDS=""

# === Systemd Service Configuration ===
SERVICE_NAME="7d2d"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
BASHRC_FILE="/root/.bashrc"

# === Color codes for terminal output ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

################################################################################
# Load local configuration overrides (not committed to git)
################################################################################
# This allows deployment-specific settings without modifying the main config
if [ -f "$(dirname "$0")/7d2d-config.local.sh" ]; then
    source "$(dirname "$0")/7d2d-config.local.sh"
fi

################################################################################
# End of shared configuration
################################################################################
