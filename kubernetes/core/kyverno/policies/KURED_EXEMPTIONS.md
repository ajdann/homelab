# Kured Security Policy Exemptions

## Overview
Kured (Kubernetes Reboot Daemon) is a system-level tool that requires elevated privileges to function properly. As such, it is exempted from certain security policies while maintaining audit visibility.

## Exempted Policies
The following policies are expected to fail for Kured pods, which is acceptable:

1. **Prevent Privileged Containers** - Kured requires `privileged: true` to access host processes
2. **Pod Security Standards (Baseline/Restricted)** - Kured requires:
   - `hostPID: true` for access to host processes
   - `hostPath` volumes for reboot sentinel files
   - Elevated capabilities for signal-based reboots

## Justification
- Kured needs to monitor host reboot requirements (`/var/run/reboot-required`)
- Kured needs to send signals to host processes for reboots
- Kured needs access to host namespaces to interact with system processes
- These are legitimate system administration functions

## Compliance Status
Kured violations in policy reports are **expected and acceptable**. The tool is properly configured with minimal required privileges while maintaining its core functionality.

## Alternative Approaches
1. **Signal-based reboots** (currently configured) - Uses `CAP_KILL` instead of full privileges
2. **Command-based reboots** - Requires full privileges but is more direct
3. **Manual node management** - Bypasses Kured entirely but requires manual intervention

## Current Configuration
- Uses signal-based reboot method (`rebootMethod: "signal"`)
- Requires only `CAP_KILL` capability
- Runs as non-root user (1000)
- Maintains audit visibility in policy reports 