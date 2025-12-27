# Tailscale Exit Node Monitor

## Overview

This script automatically monitors and manages a Tailscale exit node based on its availability. It ensures that your system uses the exit node when it's reachable and automatically disables it when it's down, preventing connectivity issues.

## What It Does

The script performs three main functions:

1. **Checks Exit Node Availability**: Pings the target exit node to verify it's reachable
2. **Checks Current State**: Determines if the exit node is currently active on your system
3. **Takes Corrective Action**: Automatically enables or disables the exit node based on availability

## How It Works

### State Logic

The script handles four possible scenarios:

| Exit Node Status | Currently Active | Action Taken |
|-----------------|------------------|--------------|
| ✅ Reachable | ❌ Not Active | **Enable** exit node |
| ❌ Unreachable | ✅ Active | **Disable** exit node |
| ✅ Reachable | ✅ Active | No action (working correctly) |
| ❌ Unreachable | ❌ Not Active | No action (already correct) |

### Detection Method

The script uses `tailscale status` output to determine if an exit node is active:

- **Active exit node**: Shows as `active; exit node;` in status output
- **Available but not used**: Shows as `active; offers exit node;` in status output

## Configuration

Edit the script to customize these settings:

```bash
TARGET_IP="100...."  # Your exit node's Tailscale IP
```

The script also configures these Tailscale settings when enabling the exit node:

- `--ssh`: Enables SSH access over Tailscale
- `--advertise-routes=192.168.1.0/24`: Advertises local network routes
- `--exit-node-allow-lan-access`: Allows access to local LAN while using exit node
- `--accept-routes`: Accepts routes advertised by other peers

## Installation

1. Make the script executable:
   ```bash
   chmod +x tailscale_monitor.sh
   ```

2. Test the script manually:
   ```bash
   sudo ./tailscale_monitor.sh
   ```

## Automated Monitoring with Cron

To run the script automatically every 5 minutes:

1. Edit your crontab:
   ```bash
   sudo crontab -e
   ```

2. Add this line:
   ```cron
   */5 * * * * /path/to/tailscale_monitor.sh >> /var/log/tailscale_monitor.log 2>&1
   ```

3. Check the logs:
   ```bash
   sudo tail -f /var/log/tailscale_monitor.log
   ```

## Use Cases

This script is particularly useful when:

- Your exit node is on a device that may lose power or network connectivity
- You want automatic failover when the exit node becomes unavailable
- You're running the exit node on a home server or Raspberry Pi
- You need to prevent routing failures when the exit node goes down

## Example Output

### When enabling exit node:
```
[2025-12-27 12:43:56] Checking if 100.103.31.15 is reachable...
[2025-12-27 12:43:56] Target is REACHABLE
[2025-12-27 12:43:56] Checking current exit node status...
[2025-12-27 12:43:56] Exit node is NOT being used
[2025-12-27 12:43:56] ACTION: Target 100.103.31.15 is UP but not active. Enabling exit node...
[2025-12-27 12:43:56] Exit node enabled successfully
```

### When no action needed:
```
[2025-12-27 12:48:56] Checking if 100.103.31.15 is reachable...
[2025-12-27 12:48:56] Target is REACHABLE
[2025-12-27 12:48:56] Checking current exit node status...
[2025-12-27 12:48:56] Exit node IS being used
[2025-12-27 12:48:56] STATUS: Target is UP and exit node is ACTIVE. No action needed.
```

## Troubleshooting

### Script says exit node is not active but it should be

Check the actual Tailscale status:
```bash
sudo tailscale status | grep "exit node"
```

Look for the pattern `active; exit node;` (not `offers exit node`)

### Exit node keeps getting disabled

- Verify the target IP is correct
- Check network connectivity to the exit node
- Review the ping timeout (currently set to 2 seconds)

### Permission errors

The script must be run with sudo/root privileges:
```bash
sudo ./tailscale_monitor.sh
```

## Requirements

- Tailscale installed and authenticated
- Root/sudo access
- Network connectivity to ping the exit node
- Bash shell

## License

This script is provided as-is for managing your Tailscale infrastructure.
