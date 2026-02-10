#!/bin/bash

################################################################################
# 7 Days to Die Dedicated Server - Install/Update Script
#
# This script automates the complete setup and maintenance of a 7 Days to Die
# dedicated server.
#
# This script:
# 1. Performs system package updates (apt update & upgrade)
# 2. Installs or updates SteamCMD for downloading game files
# 3. Installs or updates the 7 Days to Die dedicated server via SteamCMD
# 4. Applies server configuration from shell variables to serverconfig.xml
#
# Command line options:
#   -clearLogs, -c          Clear the log file before starting
#
# Deployment: Copy this script to ~/ on the Linux box
# Execution: Run from ~/ on the Linux box (requires elevated permissions)
# Example: ~/update-server.sh
# Example with options: ~/update-server.sh -c
#
# Dependencies:
#   - curl: For downloading files
#   - xmlstarlet: For XML configuration management
#   - steamcmd: Installed automatically if not present
#
# Configuration Files:
#   - ~/7d2d-config.sh: Shared server configuration
#   - ~/7d2d-config.local.sh: Deployment-specific overrides (not committed)
#   - /opt/7d2d-server/: Installation directory for server
#   - /var/log/7d2d-update.log: Detailed execution log
#
################################################################################

set -e  # Exit on error
set -o pipefail  # Exit on pipeline errors

# Source shared configuration
source "$(dirname "$0")/7d2d-config.sh"

# Parse command line arguments
CLEAR_LOGS=false
for arg in "$@"; do
    case $arg in
        -clearLogs|-c)
            CLEAR_LOGS=true
            shift
            ;;
    esac
done


# Clear logs if requested
if [ "$CLEAR_LOGS" = true ]; then
    echo "Clearing log file..."
    > "${LOG_FILE}"
    echo "Log file cleared at $(date '+%Y-%m-%d %H:%M:%S')" >> "${LOG_FILE}"
fi

# Create directories
mkdir -p "${SERVER_DIR}"

################################################################################
# Logging
################################################################################
log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] $@" | tee -a "${LOG_FILE}"
}

log_error() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${RED}[${timestamp}] $@${NC}" | tee -a "${LOG_FILE}"
}

log_warning() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${YELLOW}[${timestamp}] $@${NC}" | tee -a "${LOG_FILE}"
}

log_section() {
    echo "" >> "${LOG_FILE}"
    log "============================================"
    log "$@"
    log "============================================"
}

################################################################################
# Purge Old Server Logs
################################################################################
purge_old_logs() {
    log_section "Purging Old Server Logs (>30 days)"

    local log_dir="${SERVER_DIR}"
    local days_threshold=30
    local count=0

    # Find and delete logs older than 30 days
    while IFS= read -r logfile; do
        rm -f "$logfile"
        log "Deleted: $(basename "$logfile")"
        ((count++))
    done < <(find "${log_dir}" -maxdepth 1 -name "output_log__*.txt" -type f -mtime +${days_threshold})

    if [ ${count} -gt 0 ]; then
        log "Purged ${count} old log file(s)"
    else
        log "No logs older than ${days_threshold} days found"
    fi
}

################################################################################
# Install/Update SteamCMD
################################################################################
install_steamcmd() {
    log_section "Installing/Updating SteamCMD"

    # Check if steamcmd is already installed
    if command -v steamcmd &> /dev/null || [ -f "/opt/steamcmd/steamcmd.sh" ]; then
        log "SteamCMD is already installed; skipping installation"
        return 0
    fi

    # Update package list
    log "Updating package list..."
    apt update

    # Add i386 architecture if not present (required for steamcmd)
    if ! dpkg --print-foreign-architectures | grep -q i386; then
        log "Adding i386 architecture..."
        dpkg --add-architecture i386
        apt update
    fi

    # Install steamcmd
    log "Installing steamcmd package..."
    if DEBIAN_FRONTEND=noninteractive apt install -y steamcmd; then
        log "SteamCMD installed via apt"
    else
        log_warning "steamcmd package not available; installing from Valve tarball"
        DEBIAN_FRONTEND=noninteractive apt install -y curl ca-certificates tar lib32gcc-s1 lib32stdc++6

        local steamcmd_root="/opt/steamcmd"
        mkdir -p "${steamcmd_root}"

        log "Downloading steamcmd from Valve..."
        curl -fsSL -o "${steamcmd_root}/steamcmd_linux.tar.gz" \
            "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz"

        log "Extracting steamcmd..."
        tar -xzf "${steamcmd_root}/steamcmd_linux.tar.gz" -C "${steamcmd_root}"
        chmod +x "${steamcmd_root}/steamcmd.sh"

        ln -sf "${steamcmd_root}/steamcmd.sh" /usr/games/steamcmd
        log "SteamCMD installed from Valve"
    fi

    # Create symlink if needed
    if [ ! -f "${STEAMCMD_DIR}/steamcmd" ] && [ -f "/usr/games/steamcmd" ]; then
        ln -sf /usr/games/steamcmd "${STEAMCMD_DIR}/steamcmd"
    fi

    if ! command -v steamcmd &> /dev/null && [ ! -f "/usr/games/steamcmd" ]; then
        log_error "ERROR: SteamCMD installation failed"
        return 1
    fi

    # Bootstrap SteamCMD to generate initial config and update client
    # Set HOME to /opt/steamcmd to keep all Steam files contained there
    if [ -f "/opt/steamcmd/steamcmd.sh" ]; then
        log "Bootstrapping SteamCMD client..."
        (cd /opt/steamcmd && HOME=/opt/steamcmd ./steamcmd.sh +quit) || true
    fi

    log "SteamCMD installation completed"
}

################################################################################
# Update System Packages
################################################################################
update_system_packages() {
    log_section "Updating System Packages"

    log "Running apt update..."
    apt update 2>&1 | tee -a "${LOG_FILE}"

    log "Running apt upgrade..."
    DEBIAN_FRONTEND=noninteractive apt upgrade -y 2>&1 | tee -a "${LOG_FILE}"

    log "System packages updated successfully"
    return 0
}

################################################################################
# Install/Update 7 Days to Die Server
################################################################################
install_7d2d_server() {
    log_section "Installing/Updating 7 Days to Die Dedicated Server"

    # Verify steamcmd is available
    local STEAMCMD_PATH=""
    if [ -f "/opt/steamcmd/steamcmd.sh" ]; then
        STEAMCMD_PATH="/opt/steamcmd/steamcmd.sh"
    elif command -v steamcmd &> /dev/null; then
        STEAMCMD_PATH="steamcmd"
    elif [ -f "/usr/games/steamcmd" ]; then
        STEAMCMD_PATH="/usr/games/steamcmd"
    else
        log_error "ERROR: steamcmd not found"
        return 1
    fi

    log "Using steamcmd at: ${STEAMCMD_PATH}"
    log "Target directory: ${SERVER_DIR}"
    log "App ID: ${SERVER_APP_ID}"

    # Check for updates before running app_update
    local installed_build=""
    if [ -f "${SERVER_DIR}/steamapps/appmanifest_${SERVER_APP_ID}.acf" ]; then
        installed_build=$(grep '"buildid"' "${SERVER_DIR}/steamapps/appmanifest_${SERVER_APP_ID}.acf" | \
            grep -o '"[0-9]*"' | tr -d '"')
    fi

    log "Checking latest build ID via SteamCMD..."
    local latest_build=""
    if [ "${STEAMCMD_PATH}" = "/opt/steamcmd/steamcmd.sh" ]; then
        latest_build=$(cd /opt/steamcmd && HOME=/opt/steamcmd ./steamcmd.sh +login anonymous +app_info_update 1 \
            +app_info_print ${SERVER_APP_ID} +quit | awk -F'"' '/"buildid"/ {print $4; exit}')
    else
        latest_build=$(${STEAMCMD_PATH} +login anonymous +app_info_update 1 \
            +app_info_print ${SERVER_APP_ID} +quit | awk -F'"' '/"buildid"/ {print $4; exit}')
    fi

    local skip_update=false
    if [ -n "${installed_build}" ] && [ -n "${latest_build}" ]; then
        log "Installed build ID: ${installed_build}"
        log "Latest build ID: ${latest_build}"
        if [ "${installed_build}" = "${latest_build}" ]; then
            log "7 Days to Die server already up to date; skipping app_update"
            skip_update=true
        fi
    fi

    local update_result=0
    if [ "${skip_update}" = false ]; then
        log "Running steamcmd app_update..."
        if [ "${STEAMCMD_PATH}" = "/opt/steamcmd/steamcmd.sh" ]; then
            (cd /opt/steamcmd && HOME=/opt/steamcmd ./steamcmd.sh +@sSteamCmdForcePlatformType linux \
                +force_install_dir "${SERVER_DIR}" \
                +login anonymous \
                +app_update ${SERVER_APP_ID} validate \
                +quit)
        else
            ${STEAMCMD_PATH} +@sSteamCmdForcePlatformType linux \
                +force_install_dir "${SERVER_DIR}" \
                +login anonymous \
                +app_update ${SERVER_APP_ID} validate \
                +quit
        fi
        update_result=$?
    fi

    if [ ${update_result} -eq 0 ]; then
        log "7 Days to Die server installation/update completed successfully"

        # Make server executables executable
        if [ -f "${SERVER_DIR}/startserver.sh" ]; then
            chmod +x "${SERVER_DIR}/startserver.sh"
            log "Set executable permissions on startserver.sh"
        fi

        if [ -f "${SERVER_DIR}/7DaysToDieServer.x86_64" ]; then
            chmod +x "${SERVER_DIR}/7DaysToDieServer.x86_64"
            log "Set executable permissions on 7DaysToDieServer.x86_64"
        fi

        # Get build ID from the local manifest
        if [ -f "${SERVER_DIR}/steamapps/appmanifest_${SERVER_APP_ID}.acf" ]; then
            local installed_build=$(grep '"buildid"' "${SERVER_DIR}/steamapps/appmanifest_${SERVER_APP_ID}.acf" | \
                                   grep -o '"[0-9]*"' | tr -d '"')
            if [ -n "${installed_build}" ]; then
                log "7 Days to Die server build ID: ${installed_build}"
            fi
        fi

        return 0
    else
        log_error "ERROR: 7 Days to Die server installation/update failed"
        return 1
    fi
}

################################################################################
# Update Server Admin List in serveradmin.xml
################################################################################
update_server_admins() {
    log_section "Updating Server Admin List"

    local admin_dir="${HOME}/.local/share/7DaysToDie/Saves"
    local admin_file="${admin_dir}/serveradmin.xml"

    # Check if serveradmin.xml exists
    if [ ! -f "${admin_file}" ]; then
        log_warning "WARNING: serveradmin.xml not found at ${admin_file}"
        log_warning "The server must be started at least once to create this file"
        return 0
    fi

    # Add admin users if configured
    if [ -n "${ADMIN_STEAM_IDS}" ]; then
        log "Adding admin users to serveradmin.xml..."

        # Ensure xmlstarlet is installed
        if ! command -v xmlstarlet &> /dev/null; then
            log "Installing xmlstarlet..."
            DEBIAN_FRONTEND=noninteractive apt install -y xmlstarlet &>> "${LOG_FILE}"
        fi

        # Process each admin Steam ID
        for steam_id in ${ADMIN_STEAM_IDS}; do
            # Check if this user already exists
            local user_count=$(xmlstarlet sel -t -c "count(//user[@platform='Steam' and @userid='${steam_id}'])" "${admin_file}" 2>/dev/null || echo "0")

            if [ "${user_count}" != "1" ]; then
                # User doesn't exist, add them
                log "  Adding admin: ${steam_id}"
                xmlstarlet ed -L \
                    -s '//users' -t elem -n 'user' \
                    -i '//users/user[not(@platform)]' -t attr -n 'platform' -v 'Steam' \
                    -i '//users/user[@platform="Steam" and not(@userid)]' -t attr -n 'userid' -v "${steam_id}" \
                    -i '//users/user[@platform="Steam" and @userid="'${steam_id}'" and not(@permission_level)]' -t attr -n 'permission_level' -v '0' \
                    "${admin_file}"
            else
                log "  Admin already exists: ${steam_id}"
            fi
        done
    else
        log "No admin Steam IDs configured (ADMIN_STEAM_IDS is empty)"
    fi
}

################################################################################
# Apply Configuration to serverconfig.xml
################################################################################
apply_config_to_serverconfig() {
    log_section "Applying Configuration to serverconfig.xml"

    local config_file="${SERVER_DIR}/serverconfig.xml"

    # If serverconfig.xml doesn't exist, it will be created by the server on first run
    if [ ! -f "${config_file}" ]; then
        log "serverconfig.xml not found - will be created by server on first run"
        log "Run the server once, then run this script again to apply config settings"
        return 0
    fi

    # Ensure xmlstarlet is installed for proper XML manipulation
    if ! command -v xmlstarlet &> /dev/null; then
        log "Installing xmlstarlet for XML configuration..."
        DEBIAN_FRONTEND=noninteractive apt install -y xmlstarlet &>> "${LOG_FILE}"
    fi

    log "Updating serverconfig.xml with settings from 7d2d-config.local.sh..."

    # Use xmlstarlet to safely update XML properties
    # Format: xmlstarlet ed -L -u '//property[@name="PropertyName"]/@value' -v "NewValue" file

    log "  ServerName: ${SERVER_NAME}"
    xmlstarlet ed -L -u '//property[@name="ServerName"]/@value' -v "${SERVER_NAME}" "${config_file}"

    log "  ServerDescription: ${SERVER_DESCRIPTION}"
    xmlstarlet ed -L -u '//property[@name="ServerDescription"]/@value' -v "${SERVER_DESCRIPTION}" "${config_file}"

    log "  ServerPort: ${SERVER_PORT}"
    xmlstarlet ed -L -u '//property[@name="ServerPort"]/@value' -v "${SERVER_PORT}" "${config_file}"

    log "  ServerVisibility: ${SERVER_VISIBILITY}"
    xmlstarlet ed -L -u '//property[@name="ServerVisibility"]/@value' -v "${SERVER_VISIBILITY}" "${config_file}"

    log "  ServerPassword: [REDACTED]"
    xmlstarlet ed -L -u '//property[@name="ServerPassword"]/@value' -v "${SERVER_PASSWORD}" "${config_file}"

    log "  ServerMaxPlayerCount: ${SERVER_MAX_PLAYERS}"
    xmlstarlet ed -L -u '//property[@name="ServerMaxPlayerCount"]/@value' -v "${SERVER_MAX_PLAYERS}" "${config_file}"

    log "  GameName: ${GAME_NAME}"
    xmlstarlet ed -L -u '//property[@name="GameName"]/@value' -v "${GAME_NAME}" "${config_file}"

    log "  GameDifficulty: ${GAME_DIFFICULTY}"
    xmlstarlet ed -L -u '//property[@name="GameDifficulty"]/@value' -v "${GAME_DIFFICULTY}" "${config_file}"

    log "  GameWorld: ${GAME_WORLD}"
    xmlstarlet ed -L -u '//property[@name="GameWorld"]/@value' -v "${GAME_WORLD}" "${config_file}"

    if [ -n "${WORLD_GEN_SEED}" ]; then
        log "  WorldGenSeed: ${WORLD_GEN_SEED}"
        xmlstarlet ed -L -u '//property[@name="WorldGenSeed"]/@value' -v "${WORLD_GEN_SEED}" "${config_file}"
    fi

    log "  WorldGenSize: ${WORLD_GEN_SIZE}"
    xmlstarlet ed -L -u '//property[@name="WorldGenSize"]/@value' -v "${WORLD_GEN_SIZE}" "${config_file}"

    log "  DayNightLength: ${DAY_NIGHT_LENGTH}"
    xmlstarlet ed -L -u '//property[@name="DayNightLength"]/@value' -v "${DAY_NIGHT_LENGTH}" "${config_file}"

    log "  LootRespawnDays: ${LOOT_RESPAWN_DAYS}"
    xmlstarlet ed -L -u '//property[@name="LootRespawnDays"]/@value' -v "${LOOT_RESPAWN_DAYS}" "${config_file}"

    log "  AirDropFequency: ${AIR_DROP_FREQUENCY}"
    xmlstarlet ed -L -u '//property[@name="AirDropFequency"]/@value' -v "${AIR_DROP_FREQUENCY}" "${config_file}"

    log "  PlayerKillingMode: ${PLAYER_KILLING_MODE}"
    xmlstarlet ed -L -u '//property[@name="PlayerKillingMode"]/@value' -v "${PLAYER_KILLING_MODE}" "${config_file}"

    log "  EACEnabled: ${EAC_ENABLED}"
    xmlstarlet ed -L -u '//property[@name="EACEnabled"]/@value' -v "${EAC_ENABLED}" "${config_file}"

    log "  TelnetEnabled: true"
    xmlstarlet ed -L -u '//property[@name="TelnetEnabled"]/@value' -v "true" "${config_file}"

    log "  TelnetPort: 8081"
    xmlstarlet ed -L -u '//property[@name="TelnetPort"]/@value' -v "8081" "${config_file}"

    if [ -n "${TELNET_PASSWORD}" ]; then
        log "  TelnetPassword: [REDACTED]"
        xmlstarlet ed -L -u '//property[@name="TelnetPassword"]/@value' -v "${TELNET_PASSWORD}" "${config_file}"
    fi

    log "  BloodMoonFrequency: ${BLOOD_MOON_FREQUENCY}"
    xmlstarlet ed -L -u '//property[@name="BloodMoonFrequency"]/@value' -v "${BLOOD_MOON_FREQUENCY}" "${config_file}"

    log "Configuration applied to serverconfig.xml"
    return 0
}
main() {
    echo "" >> "${LOG_FILE}"
    echo "################################################################################" >> "${LOG_FILE}"
    echo "################################################################################" >> "${LOG_FILE}"
    echo "###                          SERVER STARTING                                 ###" >> "${LOG_FILE}"
    echo "################################################################################" >> "${LOG_FILE}"
    echo "################################################################################" >> "${LOG_FILE}"
    echo "" >> "${LOG_FILE}"

    log_section "7 Days to Die Server Install/Update Script Started"
    log "Server directory: ${SERVER_DIR}"

    # Update system packages
    if update_system_packages; then
        log "System packages updated"
    else
        log_warning "WARNING: System package update had issues (continuing anyway)"
    fi

    # Install/update steamcmd
    if install_steamcmd; then
        log "SteamCMD ready"
    else
        log_error "ERROR: SteamCMD installation failed"
        exit 1
    fi

    # Install/update 7 Days to Die server
    if install_7d2d_server; then
        log "7 Days to Die server ready"
    else
        log_error "ERROR: 7 Days to Die server installation failed"
        exit 1
    fi

    # Purge old log files (>30 days)
    purge_old_logs

    # Update server admin list in serveradmin.xml
    update_server_admins

    # Apply configuration to serverconfig.xml
    if apply_config_to_serverconfig; then
        log "Server configuration applied"
    else
        log_warning "WARNING: Failed to apply configuration (continuing anyway)"
    fi

    log_section "Script Completed Successfully"
}

# Run main function
main
exit 0
