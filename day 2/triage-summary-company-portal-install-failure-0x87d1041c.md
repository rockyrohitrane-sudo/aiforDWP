# Triage Summary - T-1004

## Summary (one line)
Company app fails to install from Company Portal with reported error 0x87D1041C, indicating app deployment or assignment evaluation failure (to-verify).

## Impact (who/how many/business urgency)
- Who: At least one end user needing the company app (to-verify).
- How many: Reported as one case; population impact unknown until assignment scope is checked (to-verify).
- Business urgency: Medium to High depending on whether app is required for core job tasks (to-verify).

## Known Facts
- Ticket ID: T-1004.
- Channel: Company Portal.
- Symptom: App installation fails.
- Reported code: 0x87D1041C (as provided in ticket).

## Missing Information to Gather
- App name/version and whether problem is new or ongoing.
- Whether failure is on one device or multiple devices/users.
- Whether device is compliant/healthy in management platform at failure time (to-verify).
- Whether user is in correct app assignment group(s) (to-verify).
- Whether required prerequisites/dependencies are present on affected device(s) (to-verify).
- Timestamp of latest failed install attempt.

## Likely Category
Endpoint app deployment issue via Company Portal / device management policy path (to-verify).

## First Diagnostic Step
Confirm scope by checking if another in-scope user/device can install the same app, then verify assignment targeting and device state for the affected user at the time of failure (to-verify).