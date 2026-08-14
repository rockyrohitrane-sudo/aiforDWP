# RCA - Legal Floor 6 Missing Desktop Shortcuts Incident

Date: 2026-08-14
Prepared by: DWP Service Desk
Incident scope: Missing desktop shortcuts on Legal Floor 6 (separate from login/performance and Copilot access tracks)

## 1) Executive Summary
The Legal Floor 6 missing-shortcuts incident is reported as resolved after the suggested resolution was applied. Resolution is stated as of [confirmed time] (to confirm timezone and exact timestamp format), verified by [confirmed verification detail] (to confirm exact validation wording and evidence source).

Current RCA position:
- Service restoration is reported complete.
- Most likely technical trigger remains deployment-related, with exact mechanism still to confirm.

## 2) Incident Statement
Users on Legal Floor 6 reported desktop shortcuts were missing.

This incident is handled as a distinct track from:
- Login failures / slow logon.
- Potential Copilot unauthorized matter exposure.

## 3) Impact
- Who: At least one affected user reported; potential broader Floor 6 pattern.
- How many: Unknown (to confirm).
- Business urgency: Medium; users can often still work but with reduced efficiency and confidence.

## 4) Confirmed Facts Used in This RCA
Only facts present in triage, hypothesis, mitigation/evidence-review notes, plus the closure statement in this request are used.

1. A new document management app was rolled out Friday afternoon to Legal Floor 6 scope.
2. Missing-shortcuts symptoms were reported Monday morning in the same overall incident window.
3. Triage treated missing shortcuts as a separate endpoint configuration/profile incident track.
4. Triage documented likely categories for this symptom: deployment action, policy overwrite, or profile/path redirection behavior.
5. Suggested mitigation path documented: identify and disable offending deployment/post-install behavior and restore shortcuts via remediation.
6. Closure statement confirms the suggested resolution was applied and issue is resolved as of [confirmed time], verified by [confirmed verification detail].

## 5) Evidence Register

E-01
- Source: triage-summary-floor6-multi-incident-20260814.md
- Evidence: missing desktop shortcuts identified as a distinct issue; first checks focused on deleted vs hidden/repointed state and recent GPO/Intune/app actions.
- Confidence: high.

E-02
- Source: triage-summary-floor6-multi-incident-ops-20260814.md
- Evidence: shortcut incident impact recorded as at least one user, potentially broader; immediate actions include validating endpoint paths and reviewing Friday deployment/policy deltas.
- Confidence: high.

E-03
- Source: hypothesis-missing-shortcuts-floor6-20260814.md
- Evidence: ranked hypotheses led by deployment-side shortcut action from Friday app rollout, then Intune policy/profile effects, then profile/path redirection.
- Confidence: high for hypothesis ranking; still non-final root cause pending confirmation.

E-04
- Source: floor6-missing-shortcuts-mitigation-action-and-message-20260814.md
- Evidence: corrective plan documented to disable offending script/assignment behavior and deploy remediation to restore shortcuts.
- Confidence: high for planned action; execution artifacts to confirm in admin/status logs.

E-05
- Source: closure statement in current request
- Evidence: suggested resolution applied; incident resolved at [confirmed time]; verification recorded as [confirmed verification detail].
- Confidence: high for closure intent; exact timestamp/verification artifact wording to confirm.

## 6) Timeline (local time/UTC to confirm)

- Friday afternoon (to confirm exact datetime): document management app rollout applied to Legal Floor 6 scope.
- Monday morning (to confirm exact datetime): missing-shortcuts reports raised.
- 2026-08-14 during triage: shortcut issue separated into its own incident track and investigated as endpoint/deployment/policy related.
- 2026-08-14 (to confirm exact datetime): suggested mitigation action executed (disable/remove offending deployment behavior and/or shortcut restoration remediation).
- [confirmed time] (to confirm timezone): issue marked resolved.
- [confirmed time or shortly after] (to confirm): verification captured as [confirmed verification detail].

## 7) Root Cause Analysis

### 7.1 Root Cause Statement
Most likely root cause: Friday deployment behavior for the document management app altered or removed desktop shortcuts for affected Floor 6 users.

Root cause confidence: medium-high, based on timing/scope alignment and reported post-mitigation recovery; exact technical mechanism remains to confirm.

### 7.2 Causality Assessment
Why this is supported:
- Temporal correlation: Friday rollout followed by Monday symptom appearance.
- Scope correlation: issue occurred in the same Floor 6 cohort affected by recent change.
- Symptom fit: app deployment or post-install actions can create, replace, remove, or relocate shortcut artifacts.
- Corrective signal: incident is reported resolved after applying the suggested mitigation.

What remains unconfirmed:
- Whether the primary mechanism was app post-install script behavior, Intune profile assignment effect, or path/redirection mismatch.
- Exact affected user/device count.
- Direct log evidence of the specific step that removed/altered shortcut visibility.

## 8) 5-Why Analysis

Problem: Legal Floor 6 users reported missing desktop shortcuts.

Why 1:
- Because shortcut artifacts were not visible/available in expected desktop context on affected endpoints (confirmed symptom category; exact artifact state to confirm).

Why 2:
- Because a recent floor-scoped deployment/policy change likely modified shortcut state or desktop path behavior (to confirm exact mechanism).

Why 3:
- Because deployment or configuration behavior may have interacted with the recently migrated Win11 + Intune endpoint baseline in an unintended way (to confirm via assignment and execution logs).

Why 4:
- Because pre-rollout validation appears not to have detected this desktop shortcut side effect for the target cohort (to confirm test scope and test cases used).

Why 5:
- Because change governance likely lacked an explicit desktop-artifact integrity gate and rollback checkpoint for this app rollout type (to confirm governance standard and exceptions).

5-Why output classification:
- Immediate technical trigger: likely rollout-related endpoint shortcut modification behavior.
- Process contributors: probable gaps in rollout guardrails, cohort testing depth, and closure evidence controls (to confirm).

## 9) Corrective and Preventive Actions (CAPA)

### 9.1 Corrective Actions Already Applied
1. Suggested resolution applied to stop/neutralize suspected shortcut-impacting deployment behavior (confirmed by closure statement; exact admin audit entry to confirm).
2. Shortcut restoration outcome verified as [confirmed verification detail] (to confirm exact sample size, who validated, and timestamp).

### 9.2 Preventive Actions
1. Add desktop-artifact validation to deployment gates:
- Validate presence/targets of required shortcuts before and after rollout for pilot and ring cohorts.
- Owner: Endpoint Engineering (to confirm).
- Target date: to confirm.

2. Require explicit review of app/post-install scripts for file-system actions:
- Flag and approve any shortcut create/delete/move logic before production assignment.
- Owner: Application Packaging Team (to confirm).
- Target date: to confirm.

3. Stage rollout with hold points and measurable exit criteria:
- Ringed deployment with pause/rollback if shortcut integrity checks fail.
- Owner: Change Management + Endpoint Engineering (to confirm).
- Target date: to confirm.

4. Improve closure evidence standard:
- Closure packet must include assignment-change audit log, remediation status output, and user confirmation evidence.
- Owner: Incident Manager (to confirm).
- Target date: immediate process update (to confirm).

5. Cohort risk handling for recently migrated Win11 + Intune users:
- Apply additional observation window and expanded pilot coverage before broad floor rollout.
- Owner: Modern Workplace Platform (to confirm).
- Target date: to confirm.

## 10) Open Items (To Confirm)
1. Exact resolved timestamp/timezone for [confirmed time].
2. Exact verification details for [confirmed verification detail].
3. Final mechanism: post-install script vs Intune profile vs path/redirection behavior.
4. Final affected user/device count and whether impact extended beyond initial reporter(s).
5. Admin and endpoint logs showing precise causal event and restoration evidence.

## 11) Partner-Ready Plain Language Summary
A recent software rollout to Legal Floor 6 is the most likely reason some desktop shortcuts disappeared. The corrective action has been applied, and service is reported restored as of [confirmed time], verified by [confirmed verification detail]. We are finalizing the supporting technical evidence and tightening rollout checks to prevent similar desktop-impact issues in future changes.