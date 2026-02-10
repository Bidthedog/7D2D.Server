#!/bin/bash

################################################################################
# 7 Days to Die Dedicated Server - Systemd Service Setup
#
# This script creates and configures the 7d2d.service systemd unit file
# for automatic server startup, updates, and management.
#
# This script:
# 1. Creates /etc/systemd/system/7d2d.service with proper configuration
# 2. Runs update-server.sh before starting the server (ExecStartPre)
# 3. Starts the server with the startserver.sh script
# 4. Configures automatic restart on failure
# 5. Reloads the systemd daemon
# 6. Enables the service to auto-start on boot
# 7. Creates convenient aliases for service management
#
# Deployment: Copy this script to ~/ on the Linux box
# Execution: Run from ~/ with elevated permissions (sudo)
# Example: sudo ~/setup-service.sh
#
# Service aliases created (add to ~/.bashrc or /root/.bashrc):
#   7d2d_start='systemctl start 7d2d.service'
#   7d2d_restart='systemctl restart 7d2d.service'
#   7d2d_stop='systemctl stop 7d2d.service'
#   7d2d_log='journalctl -u 7d2d.service -f'
#
################################################################################

set -e  # Exit on error

# Source shared configuration
source "$(dirname "$0")/7d2d-config.sh"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}7 Days to Die Service Setup${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}ERROR: This script must be run as root (use sudo)${NC}"
    exit 1
fi

echo "Creating systemd service file..."
echo "Service file: ${SERVICE_FILE}"
echo ""

# Ensure scripts have execute permissions
echo "Setting execute permissions on scripts..."
chmod +x "${HOME}/update-server.sh" 2>/dev/null || log_warning "Warning: Could not set permissions on update-server.sh"
echo -e "${GREEN}✓ Script permissions set${NC}"
echo ""

# Create the systemd service file
cat > "${SERVICE_FILE}" << 'SYSTEMD_EOF'
[Unit]
Description=7 Days to Die Dedicated Server
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/7d2d-server
Restart=on-failure
#Restart=no
#RestartSec=10
TimeoutStartSec=10min

# Run update script before starting server
# This handles: system updates, steamcmd updates, and 7D2D server updates
ExecStartPre=/root/update-server.sh

# Start the 7 Days to Die server
# -logfile /dev/stdout redirects output_log to stdout for journalctl capture
ExecStart=/opt/7d2d-server/startserver.sh -configfile=serverconfig.xml -logfile /dev/stdout

# Graceful shutdown timeout (30 seconds)
TimeoutStopSec=30
KillMode=mixed

[Install]
WantedBy=multi-user.target
SYSTEMD_EOF

echo -e "${GREEN}✓ Service file created${NC}"
echo ""

# Verify the server script will have execute permissions
echo "Verifying script permissions..."
if [ -f "/opt/7d2d-server/startserver.sh" ]; then
    chmod +x "/opt/7d2d-server/startserver.sh"
    echo -e "${GREEN}✓ Server script permissions verified${NC}"
else
    echo -e "${YELLOW}⚠ Note: Server will be installed on first update-server.sh run${NC}"
fi
echo ""

# Reload systemd daemon to recognize new service
echo "Reloading systemd daemon..."
systemctl daemon-reload
echo -e "${GREEN}✓ Systemd daemon reloaded${NC}"
echo ""

# Enable the service so it starts on boot
echo "Enabling service to start on boot..."
systemctl enable ${SERVICE_NAME}.service
echo -e "${GREEN}✓ Service enabled${NC}"
echo ""

# Add convenient aliases to bashrc
echo "Adding service management aliases (overwriting if they exist)..."

ALIASES_BLOCK=$(cat << 'ALIASES_EOF'

# 7 Days to Die service management aliases
alias 7d2d_start='systemctl start 7d2d.service'
alias 7d2d_restart='systemctl restart 7d2d.service'
alias 7d2d_stop='systemctl stop 7d2d.service'
alias 7d2d_status='systemctl status 7d2d.service'
alias 7d2d_log='journalctl -u 7d2d.service -f'

# Function to tail the most recent server log
7d2d_serverlog() {
    local logfile=$(ls -t /opt/7d2d-server/output_log__*.txt 2>/dev/null | head -1)
    if [ -n "$logfile" ]; then
        tail -f "$logfile"
    else
        echo "Server log not found. Is the server running? Check: systemctl status 7d2d.service"
        return 1
    fi
}
ALIASES_EOF
)

# Remove old aliases if they exist
if grep -q "7d2d_start=" "${BASHRC_FILE}"; then
    echo "Removing old aliases..."
    sed -i '/# 7 Days to Die service management aliases/,/^}$/d' "${BASHRC_FILE}"
fi

# Add the new aliases
echo "${ALIASES_BLOCK}" >> "${BASHRC_FILE}"
echo -e "${GREEN}✓ Aliases added to ${BASHRC_FILE}${NC}"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Available service management commands:"
echo -e "  ${YELLOW}7d2d_start${NC}     - Start the 7 Days to Die server"
echo -e "  ${YELLOW}7d2d_stop${NC}      - Stop the 7 Days to Die server"
echo -e "  ${YELLOW}7d2d_restart${NC}   - Restart the 7 Days to Die server"
echo -e "  ${YELLOW}7d2d_status${NC}    - Show service status"
echo -e "  ${YELLOW}7d2d_log${NC}       - View live systemd logs (startup/errors)"
echo -e "  ${YELLOW}7d2d_serverlog${NC} - View live server logs (players/game events)"
echo ""
echo "Manual commands (if aliases not loaded):"
echo -e "  ${YELLOW}systemctl start 7d2d.service${NC}"
echo -e "  ${YELLOW}systemctl stop 7d2d.service${NC}"
echo -e "  ${YELLOW}systemctl restart 7d2d.service${NC}"
echo -e "  ${YELLOW}systemctl status 7d2d.service${NC}"
echo -e "  ${YELLOW}journalctl -u 7d2d.service -f${NC}"
echo ""
echo "Checking if service is already running..."
if systemctl is-active --quiet ${SERVICE_NAME}.service; then
    echo -e "${YELLOW}✓ Service is running. Restarting to apply new configuration...${NC}"
    systemctl restart ${SERVICE_NAME}.service
    echo -e "${GREEN}✓ Service restarted${NC}"
    echo ""
    echo "Waiting for service to stabilize (5 seconds)..."
    sleep 5
    systemctl status ${SERVICE_NAME}.service --no-pager
else
    echo -e "${YELLOW}✓ Service is not currently running${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Review the service configuration: systemctl cat 7d2d.service"
    echo "2. Start the server: 7d2d_start"
    echo "3. Check logs: 7d2d_log"
fi
echo ""
