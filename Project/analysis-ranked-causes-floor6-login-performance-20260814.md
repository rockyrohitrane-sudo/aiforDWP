# Ranked Cause Analysis - Legal Floor 6 Login and Slow Logon Incident

Date: 2026-08-14
Analyst: DWP Engineer
Scope basis: only the provided facts

## Scope facts used
- At least 12 of 45 users on Legal Floor 6 are affected.
- Symptom pattern is mixed: some cannot log in, others can log in but logon is very slow.
- The cohort was recently migrated to Windows 11 and enrolled in Intune.
- A new document management app was deployed to this floor on Friday afternoon.
- The issue appeared Monday morning.

## Ranked top 3 likely causes (most probable first)

### 1) Change impact from Friday app deployment (app package, startup component, or deployment dependency)

Why this cause fits the scope facts:
- The strongest timing signal is change-followed-by-incident: deployment Friday afternoon, user impact Monday morning.
- The issue appears concentrated to one floor cohort that was explicitly targeted for that change.
- Mixed symptoms (hard login failures plus very slow logon) are consistent with a change that can fail differently by device state or assignment result.

Single fastest check to confirm or eliminate:
- Compare affected vs unaffected Floor 6 devices for app deployment/assignment status and install result state, then run one controlled rollback/disable test on a small affected subset to see whether sign-in behavior normalizes.

Timing-weight note:
- This ranks first because temporal proximity and scope alignment both point to a potentially causal change.

Evidence that would confirm app deployment as the cause:
- Affected users consistently show failed/pending/problematic app deployment state while unaffected users do not.
- Login performance/failure begins after app assignment window and improves after app removal, rollback, or disabling startup integration.
- Reproduced impact on test device when app deployment is applied, and no impact when withheld.

Evidence that would rule out app deployment as the cause:
- Affected and unaffected users show identical healthy app deployment state with no correlation to symptoms.
- Impact persists unchanged after controlled app rollback/disable.
- Similar failures are found in users/devices outside the deployment scope.

### 2) Windows 11 + Intune policy/configuration processing issue in the recently migrated cohort

Why this cause fits the scope facts:
- The impacted group is explicitly described as recently migrated to Win11 and Intune-enrolled, which introduces policy and configuration convergence risk.
- Slow logon is compatible with heavy or failing policy processing; inability to log in can occur if policy/compliance gates fail in some subset.
- Floor-level concentration can occur if assignment filters, dynamic groups, or staged rollout targeted this cohort.

Single fastest check to confirm or eliminate:
- Review Intune device/user policy and compliance results for affected vs unaffected Floor 6 users at login time, focusing on failed or long-running policy/app assignments.

Timing-weight note:
- Ranked second because it fits the known cohort characteristics, but the Friday app timing signal is more direct.

Evidence that would support this cause over app deployment:
- Correlation is stronger to specific policy/compliance failures than to app install state.
- Remediation of policy/compliance issues improves login without changing the new app state.

Evidence that would weaken this cause:
- Policy/compliance states are healthy and similar across affected and unaffected users.

### 3) Floor-specific identity or network path issue coinciding with Monday business start

Why this cause fits the scope facts:
- The impact is floor-scoped and occurs during morning login surge, which can expose localized identity-path or network-path faults.
- Mixed outcomes (fail vs very slow) can reflect intermittent connectivity or dependency latency during authentication/logon.

Single fastest check to confirm or eliminate:
- Run side-by-side sign-in tests using one affected Floor 6 user on the normal Floor 6 path and a known-good alternate path, while collecting exact authentication outcomes and latency timestamps.

Timing-weight note:
- Ranked third because there is no explicit direct fact tying this to the Friday change, and current evidence for this hypothesis is broader and less specific.

Evidence that would raise this cause in probability:
- Clear correlation between symptom occurrence and a specific Floor 6 network/identity path, independent of app deployment state.

Evidence that would lower this cause in probability:
- No meaningful difference in outcomes across network/identity paths.

## Reflection: Initial Hypothesis Correction

**First Instinct (Later Re-Evaluated):**
During initial scoping, we weighted the Windows 11 + Intune policy/configuration issue (now ranked #2) as potentially equivalent to the deployment hypothesis. The reasoning was sound: the cohort is explicitly described as recently migrated to Win11 and Intune-enrolled, and logon issues are common after such migrations. This seemed like a plausible standalone root cause independent of Friday's deployment.

**Evidence That Changed Our Ranking:**
However, three specific facts shifted our analysis:

1. **Temporal Precision:** The deployment occurred Friday afternoon; symptoms appeared Monday morning. A native Win11 + Intune policy issue would have surfaced during the migration window (weeks ago), not synchronized to a specific Friday change.

2. **Symptom Concentration:** The mixed failure pattern (some hard failures, some slow logons) correlates directly to the Friday deployment scope, not to a pre-existing policy convergence issue.

3. **Scope Alignment:** The issue is isolated to Floor 6 (the explicit deployment target), not spread across the entire Win11 + Intune migrated population elsewhere. This rules out a general migration-related policy problem.

**Why This Mattered:**
This discipline prevented us from diffusing investigation effort across generic policy review and forced focus on the change delta—Friday's deployment—as the primary vector. Had we treated both hypotheses equally, we would have delayed the targeted investigation path.

## Current position
- No single cause is confirmed yet.
- The Friday deployment remains the lead hypothesis due to timing and scope fit, but confirmation requires direct correlation and rollback/test evidence.
