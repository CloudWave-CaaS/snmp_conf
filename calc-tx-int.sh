#!/bin/bash

# Network interface to monitor
INTERFACE="ens33"
# Sleep interval in seconds
SLEEP=1

# Check if interface exists
if ! grep -q "$INTERFACE" /proc/net/dev; then
    exit 1
fi

# Get initial TX bytes
TX1=$(awk -v I="$INTERFACE" '$1 ~ I {print $10}' /proc/net/dev)

# Wait for the interval
sleep $SLEEP

# Get TX bytes after the interval
TX2=$(awk -v I="$INTERFACE" '$1 ~ I {print $10}' /proc/net/dev)

# Calculate TX throughput (Bytes/sec)
TX_BPS=$(( TX2 >= TX1 ? (TX2 - TX1) / SLEEP : 0 ))

# Return TX value to SNMP
if [ "$1" = "-g" ]; then
    echo ".1.3.6.1.4.1.999999.51.2"
    echo "integer"
    echo "$TX_BPS"
    exit 0
else
    exit 1
fi
