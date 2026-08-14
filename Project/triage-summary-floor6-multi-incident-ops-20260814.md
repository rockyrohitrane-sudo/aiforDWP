# Triage Summary - Floor 6 Multi-Incident (Operations Runbook)

Date: 2026-08-14
Analyst: DWP Service Desk
Audience: Service Desk, Identity, Endpoint, Network, InfoSec

## Separate the tangled problems in that one Slack message

Distinct incidents to track separately:

1. Potential unauthorized Copilot data exposure (security/privacy).
2. Users cannot log in (access outage).
3. Users can log in but sign-in is very slow (performance).
4. Desktop shortcuts disappeared (endpoint configuration/profile).

## Priority order (highest to lowest)

1. Copilot possible unauthorized matter exposure.
2. Login failures for multiple users.
3. Slow logins.
4. Missing shortcuts.

## Incident 1 - Potential unauthorized Copilot data exposure

## Summary (one line)
Possible confidentiality breach: Copilot returned a client matter the user says they should not see.

## Impact (who/how many/business urgency)
- Who: At least one paralegal; unknown broader scope.
- How many: Unknown.
- Business urgency: Critical (legal/confidentiality risk).

## What to check first and why
- First check: Reproduce with the same user/context and correlate Copilot response with DMS permission logs (current and historical).
- Why first: Confirms whether this is true unauthorized access versus indexing/context artifact; determines containment scope.

## Immediate actions right now
- Open Priority 1 security incident and preserve evidence.
- Restrict Copilot scope for affected repository/workspace pending validation.
- Engage InfoSec + DMS owner + Legal duty contact.

## Incident 2 - Multiple users cannot log in

## Summary (one line)
At least a dozen users on Floor 6 report login failures.

## Impact (who/how many/business urgency)
- Who: Floor 6 users.
- How many: At least 12.
- Business urgency: High (work blocked).

## What to check first and why
- First check: Determine if failures follow identity path, network segment, or device policy by A/B testing affected and unaffected users across floor and network.
- Why first: Quickly narrows from broad outage to floor/path-specific fault and accelerates correct resolver handoff.

## Immediate actions right now
- Start major incident bridge.
- Capture exact errors, timestamps, device build, network location.
- Parallel engage identity and network teams.

## Incident 3 - Logins taking forever

## Summary (one line)
Some users authenticate but sign-in is unusually slow.

## Impact (who/how many/business urgency)
- Who: Subset of Floor 6 users.
- How many: Unknown.
- Business urgency: Medium-High (productivity loss).

## What to check first and why
- First check: Compare pre/post Friday rollout sign-in telemetry (profile load, GPO/Intune processing, startup apps/scripts).
- Why first: Timing correlation to rollout is strong; telemetry identifies whether delay is policy, profile, or application startup.

## Immediate actions right now
- Pull affected vs unaffected sign-in traces.
- Pilot temporary disable/defer of new app startup component.
- Prepare phased rollback hold if confirmed.

## Incident 4 - Desktop shortcuts vanished

## Summary (one line)
Users report missing desktop shortcuts.

## Impact (who/how many/business urgency)
- Who: At least one user; may be broader.
- How many: Unknown.
- Business urgency: Medium (not full outage, but high friction).

## What to check first and why
- First check: Verify whether shortcuts were deleted, moved, hidden, or policy-overwritten (user desktop, public desktop, OneDrive Known Folder Move, GPO/Intune actions).
- Why first: Determines correct recovery path: restore visibility, rollback policy, or redeploy links.

## Immediate actions right now
- Validate files/targets on affected endpoints.
- Review Friday deployment + policy deltas scoped to Floor 6.
- Script restore of critical shortcuts if needed.

## First 90-minute command plan

1. Create one parent incident and four child tickets, one per symptom.
2. Assign Incident Commander and Communications owner.
3. Run security containment track first.
4. Run login outage diagnostics in parallel with performance and shortcut tracks.
5. Publish 30-minute status updates with facts only.

## Success criteria before next stakeholder update

- Security track: true/false determination on unauthorized access with audit evidence.
- Access track: confirmed failing layer (identity/network/device/policy) and mitigation in progress.
- Performance track: baseline comparison and one validated mitigation.
- Shortcut track: root category identified and restore path initiated.
