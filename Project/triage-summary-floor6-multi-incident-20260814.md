# Triage Summary - Floor 6 Multi-Incident Report

Date: 2026-08-14
Analyst: DWP Service Desk
Audience: Service Desk, IT Operations, Information Security, Partners (non-technical update)

## Separate the tangled problems in that one Slack message

The single message contains four distinct problems that must be tracked separately:

1. Potential unauthorized data exposure in Copilot (possible security/privacy incident).
2. Users cannot log in (authentication/access outage symptom).
3. Users can log in but logon is very slow (performance/deployment symptom).
4. Desktop shortcuts disappeared (endpoint configuration/profile symptom).

A likely cross-incident link is the Friday rollout of the new document management app on Floor 6, but we should not assume one cause until evidence confirms it.

## Urgency order and triage summaries

### 1) Potential unauthorized data exposure in Copilot (Highest urgency)

## Summary (one line)
A user reports Copilot surfaced a client matter they believe they never had access to; treat as a potential confidentiality incident until disproven.

## Impact (who/how many/business urgency)
- Who: At least one paralegal report; could involve additional users if permission scoping changed.
- How many: Unknown at this stage.
- Business urgency: Critical due to possible client confidentiality and legal/regulatory exposure.

## What to check first and why
- First check: Reproduce and capture the exact prompt/response/audit trail for the reported Copilot output, then verify current and historical permissions on the referenced matter.
- Why first: This confirms whether it is true unauthorized access, stale indexing/cache behavior, inherited group permission drift, or user misunderstanding. It is the highest legal risk item.

## Immediate actions right now
- Open a Priority 1 security incident and assign InfoSec + DMS owner.
- Preserve audit evidence (Copilot interaction logs, document access logs, permission change history).
- Temporarily restrict Copilot access to the affected repository/workspace if risk cannot be quickly ruled out.
- Notify legal/compliance duty contact that investigation is underway (fact-based, no speculation).

## Partner update by lunch (non-technical)
"We identified and prioritized one potential confidentiality concern in AI search results. We have contained risk while we verify whether this was a true permission issue or a display/indexing mismatch. We are preserving evidence and will provide a confirmed status and any required corrective action this afternoon."

### 2) Multiple users cannot log in (High urgency)

## Summary (one line)
At least a dozen Floor 6 users report login failure, indicating a likely site/floor-scoped access disruption.

## Impact (who/how many/business urgency)
- Who: Floor 6 users.
- How many: At least 12, possibly more.
- Business urgency: High, because users are blocked from starting work.

## What to check first and why
- First check: Validate whether failures are concentrated by identity path (AD/Azure AD), endpoint policy state, or a specific Floor 6 network segment by testing one affected user on known-good network and one unaffected user on Floor 6.
- Why first: Fastest way to distinguish account service outage from location/network/policy issue, which drives different fix paths.

## Immediate actions right now
- Declare a major incident bridge for Floor 6 access disruption.
- Collect quick scope snapshot: affected count, common error messages, common device build/version, connection path.
- Engage identity team and network team in parallel.
- Provide temporary workarounds where possible (known-good network path, spare device, alternate sign-in route).

## Partner update by lunch (non-technical)
"A Floor 6 login disruption is affecting a group of users. We are actively restoring access and have engineering teams working in parallel on identity and network paths. We will share the confirmed root cause and recovery timeline as soon as validation completes."

### 3) Logins taking forever for some users (Medium-High urgency)

## Summary (one line)
Some users can authenticate but experience very slow logon, suggesting profile, policy processing, or startup app impact.

## Impact (who/how many/business urgency)
- Who: Floor 6 users who can sign in but wait excessively.
- How many: Unknown subset of affected floor.
- Business urgency: Medium-High due to major productivity drag and user backlog.

## What to check first and why
- First check: Compare sign-in duration telemetry before/after Friday app rollout, including startup tasks, policy processing, profile load, and script time.
- Why first: The timing and floor-specific change strongly suggest deployment side effects; telemetry pinpoints whether delay is app initialization, policy recursion, or profile mount latency.

## Immediate actions right now
- Pull sign-in performance logs from affected and unaffected devices for comparison.
- Temporarily disable or defer non-essential startup component(s) of the new app on a pilot subset.
- If confirmed, stage rollback or phased pause of the rollout for Floor 6.

## Partner update by lunch (non-technical)
"We see a separate performance issue where some users can log in but startup is much slower than normal. Early checks indicate this may be linked to Friday's software rollout, and we are testing a safe mitigation to speed user access while we complete root-cause validation."

### 4) Desktop shortcuts vanished (Medium urgency)

## Summary (one line)
Users report missing desktop shortcuts, likely due to profile reset, policy preference overwrite, or application deployment action.

## Impact (who/how many/business urgency)
- Who: At least one user; potential broader Floor 6 pattern.
- How many: Unknown.
- Business urgency: Medium, because work can continue but user efficiency and confidence drop.

## What to check first and why
- First check: Determine whether shortcuts are actually deleted versus hidden/repointed by policy by checking user profile path, OneDrive/known-folder state, and recent GPO/Intune/app package actions.
- Why first: Recovery method differs completely (restore path visibility, undo policy item-level targeting, or redeploy shortcuts).

## Immediate actions right now
- Validate shortcut presence in profile and public desktop locations.
- Check recent policy and endpoint management changes scoped to Floor 6.
- Restore critical shortcuts for impacted teams via scripted redeploy if needed.

## Partner update by lunch (non-technical)
"We are investigating missing desktop shortcuts as a separate desktop configuration issue. This appears recoverable and lower risk than the access and confidentiality items, and we are preparing a rapid restore for key shortcuts if required."

## What we do right now (operationally, next 90 minutes)

1. Start one incident command thread with four linked child incidents so evidence does not get mixed.
2. Handle the Copilot confidentiality report as the top-priority security track with containment first.
3. Run login outage triage in parallel with identity and network teams.
4. Run performance and shortcut checks as change-impact tracks linked to Friday deployment.
5. Assign one communications owner to publish a single plain-language status update every 30 minutes.

## What we tell partners by lunch (single plain-language brief)

"This morning's Floor 6 disruption is not one problem; it is four separate issues, and we are handling them in priority order. The highest-priority item is a potential confidentiality concern in AI results, which is being contained and investigated with security oversight. In parallel, we are restoring user access for those who cannot log in, and we are addressing slower logins and missing shortcuts that may be linked to Friday's software rollout. We will provide a verified root-cause summary, business impact, and confirmed remediation plan later today."

## Current assumptions and gaps (to verify)

- Exact user count per symptom is still being validated.
- We do not yet have confirmed common error codes for login failures.
- We have not yet confirmed whether the Copilot report is true unauthorized access or indexing/context mismatch.
- Correlation to Friday rollout is strong but not yet proven as causal for all tracks.
