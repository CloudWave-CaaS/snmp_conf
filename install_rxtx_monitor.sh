#!/bin/bash

# Default network interface
DEFAULT_INTERFACE="ens33"
INTERFACE="${1:-$DEFAULT_INTERFACE}"

# Define script URLs
RX_SCRIPT_URL="https://raw.githubusercontent.com/CloudWave-CaaS/snmp_conf/refs/heads/main/calc-rx-int.sh"
TX_SCRIPT_URL="https://raw.githubusercontent.com/CloudWave-CaaS/snmp_conf/refs/heads/main/calc-tx-int.sh"

# Define installation paths
RX_SCRIPT_PATH="/usr/local/bin/calc-rx-int.sh"
TX_SCRIPT_PATH="/usr/local/bin/calc-tx-int.sh"
SNMP_CONFIG="/etc/snmp/snmpd.conf"

# Function to download scripts
download_scripts() {
    echo "Downloading RX script..."
    curl -o "$RX_SCRIPT_PATH" -s "$RX_SCRIPT_URL"
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to download calc-rx-int.sh"
        exit 1
    fi

    echo "Downloading TX script..."
    curl -o "$TX_SCRIPT_PATH" -s "$TX_SCRIPT_URL"
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to download calc-tx-int.sh"
        exit 1
    fi
}

# Function to set interface in scripts
set_interface() {
    echo "Setting interface to $INTERFACE in scripts..."

    sed -i "s/^INTERFACE=\".*\"/INTERFACE=\"$INTERFACE\"/" "$RX_SCRIPT_PATH"
    sed -i "s/^INTERFACE=\".*\"/INTERFACE=\"$INTERFACE\"/" "$TX_SCRIPT_PATH"
}

# Function to set permissions
set_permissions() {
    echo "Setting executable permissions..."
    chmod +x "$RX_SCRIPT_PATH"
    chmod +x "$TX_SCRIPT_PATH"
}

# Function to update SNMP configuration
update_snmp_config() {
    echo "Updating SNMP configuration..."
    
    # Backup the existing SNMP config
    cp "$SNMP_CONFIG" "$SNMP_CONFIG.bak"

    # Ensure there are at least two newlines before appending pass directives
    echo -e "\n\n" >> "$SNMP_CONFIG"

    # Add the pass directives if they don’t already exist
    grep -qxF "pass .1.3.6.1.4.1.999999.51.1 $RX_SCRIPT_PATH" "$SNMP_CONFIG" || echo "pass .1.3.6.1.4.1.999999.51.1 $RX_SCRIPT_PATH" >> "$SNMP_CONFIG"
    grep -qxF "pass .1.3.6.1.4.1.999999.51.2 $TX_SCRIPT_PATH" "$SNMP_CONFIG" || echo "pass .1.3.6.1.4.1.999999.51.2 $TX_SCRIPT_PATH" >> "$SNMP_CONFIG"
}

# Function to restart SNMP service
restart_snmpd() {
    echo "Restarting SNMP service..."
    systemctl restart snmpd
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to restart snmpd service"
        exit 1
    fi
}

# Execute functions
download_scripts
set_interface
set_permissions
update_snmp_config
restart_snmpd

echo "Installation complete! RX/TX SNMP monitoring is now active on interface: $INTERFACE"
