# Structured Triage Summary

## Summary (one line)
User reports laptop performance is very slow since this morning, and Outlook will not open (spinning only) on a new Windows 11 machine from last week.

## Impact (who/how many/business urgency)
- Affected user: single end user (to confirm).
- Scope: appears to be one device/user only (to confirm).
- Business urgency: not stated; impact likely on email access and productivity (to confirm).

## Known facts
- Issue started: this morning.
- Device is described as a new Windows 11 machine received last week.
- Laptop is reported as "really slow".
- Outlook cannot be opened; it "just spins".
- User states other applications are "ok I think" (to confirm).

## Missing information to gather
- User identity, team, and contact details.
- Exact error behavior in Outlook (any message, hang at splash screen, how long it spins).
- Whether issue is reproducible after reboot.
- Whether Outlook Web Access works.
- Network status (wired/Wi-Fi/VPN) and whether other Microsoft 365 services are affected.
- Whether only Outlook is impacted or multiple Microsoft apps are slow.
- Device name/asset ID, current uptime, and available disk space.
- Any recent changes since last working state (updates, software installs, policy changes).
- Number of other users affected in same location/team.

## Likely catagory
- Endpoint performance and Outlook client incident (to confirm).
- Possible categories for ticket routing: "Desktop/Laptop Performance" and "Email/Outlook Client" (to confirm).

## Suggest first diagnostic step
Confirm scope and isolate Outlook vs system issue by asking the user to reboot once, then immediately test:
1. Launch Outlook desktop client.
2. Access Outlook on the web.
3. Confirm whether non-Outlook apps remain responsive.
Record outcomes to determine whether to triage as Outlook-client-specific or wider endpoint performance incident.
