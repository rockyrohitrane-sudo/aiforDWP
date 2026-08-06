# Structured Triage Summary

## Summary (one line)
User reports they cannot connect to VDI today, receiving a "cannot connect" message, after it worked on Friday while working from home on Wi-Fi.

## Impact (who/how many/business urgency)
- Affected user: single end user (to confirm).
- Scope: appears to be one user/session from home network (to confirm).
- Business urgency: not stated (to confirm).

## Known facts
- Issue is occurring today.
- User reports VDI "keeps saying cannot connect".
- User states VDI was working on Friday.
- User is at home on Wi-Fi.

## Missing information to gather
- User identity, team, and contact details.
- Exact VDI platform/client name and version.
- Full error text and any error code from the "cannot connect" message.
- Time issue started and whether failure is constant or intermittent.
- Whether other users are affected (same team/location) (to confirm).
- Whether internet access is otherwise normal (web browsing/Teams/other services).
- Whether VPN is required and, if so, current VPN connection status (to confirm).
- Device name/asset ID and whether reboot has been attempted.
- Whether connection succeeds on a different network/hotspot (to confirm).

## Likely catagory
- VDI remote access connectivity incident (to confirm).
- Possible routing category: "Remote Access/VDI" (to confirm).

## Suggest first diagnostic step
Confirm whether this is user connectivity or VDI service path issue by collecting the exact VDI error message/code, then immediately verify baseline connectivity:
1. Confirm internet is working on the same device.
2. If VPN is required, confirm VPN status (connected/not connected) (to confirm).
3. Retry VDI sign-in and capture timestamp and screenshot of the failure.
Use results to route either as user-side network/access issue or VDI platform incident.
