#!/bin/bash
set -e  # Exit on error
# set -x  # Debug mode

TARGET_IP="100....." # REPLACE WITH YOUR EXIT NODE IP
LOG_PREFIX="[$(date '+%Y-%m-%d %H:%M:%S')]"

# 1. Check if the Target is reachable (Ping with 2s timeout)
echo "$LOG_PREFIX Checking if $TARGET_IP is reachable..."
if ping -c 1 -W 2 "$TARGET_IP" > /dev/null 2>&1; then
    IS_REACHABLE=1
    echo "$LOG_PREFIX Target is REACHABLE"
else
    IS_REACHABLE=0
    echo "$LOG_PREFIX Target is UNREACHABLE"
fi

# 2. Check if we are CURRENTLY using this specific Target as our Exit Node
echo "$LOG_PREFIX Checking current exit node status..."

# The active exit node will show as "active; exit node" (not "offers exit node")
# We need to match the exact pattern to distinguish between:
# - "active; exit node" = USING this as exit node
# - "active; offers exit node" = NOT using, but available
if /usr/bin/tailscale status | grep "$TARGET_IP" | grep -q "active; exit node;"; then
    IS_ACTIVE=1
    echo "$LOG_PREFIX Exit node IS being used"
else
    IS_ACTIVE=0
    echo "$LOG_PREFIX Exit node is NOT being used"
fi

# 3. Logic: Match connectivity to state
if [ "$IS_REACHABLE" -eq 1 ] && [ "$IS_ACTIVE" -eq 0 ]; then
    # --- Target is UP, but we are NOT using it. Enable it. ---
    echo "$LOG_PREFIX ACTION: Target $TARGET_IP is UP but not active. Enabling exit node..."
    # REMOVED --reset flag which was clearing the exit node configuration
    /usr/bin/tailscale up \
        --ssh \
        --advertise-routes=192.168.1.0/24 \
        --exit-node="$TARGET_IP" \
        --exit-node-allow-lan-access \
        --accept-routes
    echo "$LOG_PREFIX Exit node enabled successfully"
    
elif [ "$IS_REACHABLE" -eq 0 ] && [ "$IS_ACTIVE" -eq 1 ]; then
    # --- Target is DOWN, but we ARE using it. Disable it. ---
    echo "$LOG_PREFIX ACTION: Target $TARGET_IP is DOWN but still active. Disabling exit node..."
    /usr/bin/tailscale up \
        --ssh \
        --advertise-routes=192.168.1.0/24 \
        --accept-routes \
        --exit-node=""
    echo "$LOG_PREFIX Exit node disabled successfully"
    
elif [ "$IS_REACHABLE" -eq 1 ] && [ "$IS_ACTIVE" -eq 1 ]; then
    # --- Target is UP and ACTIVE. Everything is good. ---
    echo "$LOG_PREFIX STATUS: Target is UP and exit node is ACTIVE. No action needed."
    
elif [ "$IS_REACHABLE" -eq 0 ] && [ "$IS_ACTIVE" -eq 0 ]; then
    # --- Target is DOWN and NOT ACTIVE. Already in correct state. ---
    echo "$LOG_PREFIX STATUS: Target is DOWN and exit node is NOT ACTIVE. No action needed."
    
fi

echo "$LOG_PREFIX Script completed"
