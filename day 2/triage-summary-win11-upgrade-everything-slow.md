# Triage Summary - T-1006

## Summary (one line)
User reports broad system slowness two days after upgrading to Windows 11, suggesting post-upgrade performance contention or configuration issue (to-verify).

## Impact (who/how many/business urgency)
- Who: Single user currently, with potential concern for other recent upgrade users (to-verify).
- How many: Reported as 1 user.
- Business urgency: Medium; may become high if performance blocks critical tasks or if trend appears across recent upgrades (to-verify).

## Known Facts
- Ticket ID: T-1006.
- Change event: Windows 11 upgrade completed two days ago.
- Symptom: User reports "everything is slow".
- Scope: No additional affected users stated yet (to-verify).

## Missing Information to Gather
- Specific slow workflows: login, app launch, browser, file access, video calls, etc.
- Whether slowness is constant or time-of-day/after-boot dependent.
- Whether device was performing normally immediately after upgrade (to-verify).
- Available disk space and any heavy background activity at symptom time (to-verify).
- Whether issue persists on clean reboot and after idle stabilization period (to-verify).
- Whether similar complaints exist from other recently upgraded users.

## Likely Category
Post-upgrade endpoint performance degradation (resource pressure, startup load, or compatibility) (to-verify).

## First Diagnostic Step
Baseline the symptom by reproducing one specific slow task and capturing current CPU, memory, disk, and startup load indicators to determine whether bottleneck is resource-bound or app-specific (to-verify).