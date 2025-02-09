#!/bin/bash

# Network interface to monitor
INTERFACE="ens33"
# Sleep interval in seconds
SLEEP=1

# Check if interface exists
if ! grep -q "$INTERFACE" /proc/net/dev; then
    exit 1
fi

# Get initial RX bytes
RX1=$(awk -v I="$INTERFACE" '$1 ~ I {print $2}' /proc/net/dev)

# Wait for the interval
sleep $SLEEP

# Get RX bytes after the interval
RX2=$(awk -v I="$INTERFACE" '$1 ~ I {print $2}' /proc/net/dev)

# Calculate RX throughput (Bytes/sec)
RX_BPS=$(( RX2 >= RX1 ? (RX2 - RX1) / SLEEP : 0 ))

# Return RX value to SNMP
if [ "$1" = "-g" ]; then
    echo ".1.3.6.1.4.1.999999.51.1"
    echo "integer"
    echo "$RX_BPS"
    exit 0
else
    exit 1
fi
