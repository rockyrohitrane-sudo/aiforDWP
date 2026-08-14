# Triage Summary - Floor 6 Multi-Incident (Partner Brief)

Date: 2026-08-14
Prepared by: DWP Service Desk
Audience: Partners and Business Leaders

## Separate the tangled problems in that one Slack message

This is not one outage. It is four separate issues being handled in parallel:

1. A possible confidentiality concern in Copilot results.
2. A login failure issue affecting multiple users.
3. A slow-login issue affecting some users.
4. A missing-desktop-shortcuts issue.

## Priority order and plain-language triage

### 1) Possible confidentiality concern in Copilot (highest priority)

## Summary (one line)
One report suggests Copilot showed a client matter the user may not be authorized to view.

## Impact (who/how many/business urgency)
- Who: At least one user, with potential wider impact still being checked.
- How many: Unknown.
- Business urgency: Critical.

## What we check first and why
- First check: Validate whether the user truly had no permission, using audit logs and permission history.
- Why first: This is the highest legal and trust risk and needs confirmation or containment immediately.

## What we are doing now
- Security investigation opened and evidence preserved.
- Temporary containment controls applied where necessary.
- Legal/compliance informed of active investigation.

### 2) Users unable to log in (high priority)

## Summary (one line)
A group of Floor 6 users cannot sign in.

## Impact (who/how many/business urgency)
- Who: Floor 6 users.
- How many: At least a dozen reported.
- Business urgency: High.

## What we check first and why
- First check: Confirm whether this is identity-system, floor network, or device-policy related.
- Why first: The fastest way to restore access is identifying the failing layer quickly.

## What we are doing now
- Incident bridge active with identity and network teams.
- Scope and error pattern validation underway.
- Workarounds being prepared where possible.

### 3) Very slow logins (medium-high priority)

## Summary (one line)
Some users can sign in but only after long delays.

## Impact (who/how many/business urgency)
- Who: Subset of Floor 6 users.
- How many: Unknown.
- Business urgency: Medium-High.

## What we check first and why
- First check: Compare login performance before and after Friday's software rollout.
- Why first: The timing indicates a possible deployment side effect.

## What we are doing now
- Performance telemetry comparison in progress.
- Safe mitigation tests underway to reduce startup delay.

### 4) Missing desktop shortcuts (medium priority)

## Summary (one line)
Some users report desktop shortcuts disappeared.

## Impact (who/how many/business urgency)
- Who: At least one user, potentially more.
- How many: Unknown.
- Business urgency: Medium.

## What we check first and why
- First check: Determine whether shortcuts were removed, hidden, or relocated by profile/policy changes.
- Why first: Fix method depends on the exact cause.

## What we are doing now
- Endpoint and policy checks underway.
- Rapid restore plan prepared for critical shortcuts.

## What we can say by lunch

- We have separated the incident into four tracks to avoid mixing causes.
- Highest risk item (possible confidentiality issue) is contained and being validated first.
- Access restoration work is active in parallel for login failures.
- Performance and shortcut issues are being addressed as likely rollout-related change impacts.
- We will provide a verified root-cause and remediation update later today.
