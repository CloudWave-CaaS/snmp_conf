#!/bin/bash

# Check if SNMP community string is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <SNMP_COMMUNITY_STRING>"
    exit 1
fi

# Define variables
SNMP_COMMUNITY="$1"
SNMP_CONF="/etc/snmp/snmpd.conf"
BACKUP_CONF="/etc/snmp/snmpd.conf.bak"

# Install SNMP and required packages
echo "Installing SNMP and dependencies..."
sudo apt install snmp snmpd snmp-mibs-downloader -y

# Backup existing snmpd.conf
echo "Backing up existing SNMP configuration..."
sudo cp "$SNMP_CONF" "$BACKUP_CONF"

# Replace agentaddress directive
echo "Configuring SNMP to listen on UDP:161..."
sudo sed -i 's/^agentaddress.*/agentAddress udp:161/' "$SNMP_CONF"

# Set community string with localhost restriction
echo "Updating SNMP community string..."
echo "rocommunity $SNMP_COMMUNITY" | sudo tee -a "$SNMP_CONF" > /dev/null

# Append the required SNMP process monitoring directives
echo "Adding required SNMP process monitoring directives..."
cat <<EOL | sudo tee -a "$SNMP_CONF" > /dev/null

## TEST THESE SERVICES WITH:  
##  snmpwalk -v1 -c public localhost 1.3.6.1.2.1.25.4.2.1.2

# Forwarder Core Services
proc dwagent
proc start_up #used by nsm, ng
proc Agent.Listener #used by AzureVSTS

# Google Chronicle Core Services
proc dockerd
proc chronicle_forwa
proc python3.11 

# OSSEC HID Core Services
proc ossec-analysisd 1 0
proc ossec-csyslogd 1 0
proc ossec-execd 1 0
proc ossec-logcollec 1 0
proc ossec-monitord 1 0
proc ossec-syscheckd 1 0
file /var/ossec/logs/alerts/alerts.log

# VSCAN processes
proc python3 10 2  # For Python processes (used by notus-scanner and ospd-openvas)
proc gvmd 1 0      # Greenbone Vulnerability Manager
proc gsad 1 0      # Greenbone Security Assistant
proc postgres 1 0 # PostgreSQL database for GVM
proc observiq-otel-collector 1 0 # BindPlaneAgent *also used for HPs*

## Confirm with:  snmpwalk -v1 -c public localhost 1.3.6.1.4.1.2021.2.1.2

# Zeek+FileSizeMonitors
proc zeek 1 0
proc zeek_run 1 0
file /usr/local/zeek/logs/current/conn.log
file /usr/local/zeek/logs/current/dns.log
file /usr/local/zeek/logs/current/files.log
file /usr/local/zeek/logs/current/ssl.log
file /usr/local/zeek/logs/current/http.log
file /usr/local/zeek/logs/current/weird.log
EOL

# Restart SNMP service
echo "Restarting SNMP service..."
sudo systemctl restart snmpd

# Verify SNMP status
echo "Checking SNMP service status..."
sudo systemctl status snmpd --no-pager

echo "SNMP configuration updated successfully!"
