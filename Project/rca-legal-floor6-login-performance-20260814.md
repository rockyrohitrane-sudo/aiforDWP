# RCA - Legal Floor 6 Login and Slow Logon Incident

Date: 2026-08-14
Prepared by: DWP Service Desk
Incident scope: Legal Floor 6 login failures and slow logons (separate from Copilot access concern and shortcut issue)

## 1) Executive Summary
The Legal Floor 6 login/performance incident is reported as resolved after applying the suggested mitigation (remove/suspend Friday document management app deployment for Floor 6). Resolution is stated as of [confirmed time] (to confirm exact timestamp format), with verification noted as [confirmed verification detail] (to confirm exact evidence statement).

Current RCA position:
- Operationally, the mitigation appears effective.
- Technical root cause attribution is strongly indicated as deployment-related, but the exact failure mechanism remains to confirm.

## 2) Incident Statement
Users on Legal Floor 6 experienced a mixed symptom pattern:
- Some users could not log in.
- Some users could log in but with unusually slow sign-in.

This incident is treated as a distinct track from:
- Potential Copilot unauthorized matter exposure.
- Missing desktop shortcuts.

## 3) Impact
- Affected population: Legal Floor 6 users.
- Reported count: at least 12 users impacted.
- Additional scope signal from prior triage: one analysis note references at least 12 of 45 users affected.
- Business effect: high urgency due to inability or major delay in starting work.

## 4) Confirmed Facts Used in This RCA
Only facts found in existing triage/hypothesis/evidence-review notes plus the closure update provided in request are included.

1. A new document management app was deployed to Legal Floor 6 on Friday afternoon.
2. Incident symptoms were observed Monday morning.
3. Symptom pattern was mixed: hard login failures and very slow logons.
4. At least a dozen Floor 6 users were reported impacted.
5. The Floor 6 cohort is described as recently migrated to Windows 11 and enrolled in Intune.
6. During triage, the Friday deployment was treated as the leading hypothesis for this login/performance track.
7. Suggested mitigation documented: remove or suspend Floor 6 app deployment assignment (Intune/SCCM rollback style action).
8. Closure update states the suggested resolution was applied and issue is resolved as of [confirmed time], verified by [confirmed verification detail].

## 5) Evidence Register

E-01
- Source: triage-summary-floor6-multi-incident-20260814.md
- Evidence: incident split into separate tracks; login failures and slow logons treated as distinct but related symptoms.
- Confidence: high.

E-02
- Source: triage-summary-floor6-multi-incident-ops-20260814.md
- Evidence: at least 12 users reported unable to log in on Floor 6; slow logon track opened in parallel.
- Confidence: high.

E-03
- Source: analysis-ranked-causes-floor6-login-performance-20260814.md
- Evidence: scope facts include at least 12 of 45 users affected, Friday app deployment, Monday morning onset, Win11 + Intune cohort.
- Confidence: high for what was documented as scope facts; to confirm against system-of-record exports.

E-04
- Source: floor6-mitigation-action-and-message-20260814.md
- Evidence: primary mitigation documented as changing Floor 6 app deployment assignment to uninstall/remove (Intune), with expected recovery window after check-in/logon.
- Confidence: high for planned action; execution proof to confirm in admin logs.

E-05
- Source: closure statement in current request
- Evidence: suggested mitigation was applied and issue resolved as of [confirmed time]; verification recorded as [confirmed verification detail].
- Confidence: high for incident closure intent; exact timestamp and validation artifact wording to confirm.

## 6) Timeline (UTC/local timezone to confirm)

- Friday afternoon (to confirm exact datetime): new document management app deployed to Legal Floor 6.
- Monday morning (to confirm exact datetime): incident reported with mixed login failure and slow logon symptoms.
- 2026-08-14 during triage: deployment change identified as lead hypothesis for login/performance track.
- 2026-08-14 (to confirm exact datetime): suggested mitigation action applied (deployment removed/suspended for Floor 6).
- [confirmed time] (to confirm timezone): incident marked resolved.
- [confirmed time or shortly after] (to confirm): verification captured as [confirmed verification detail].

## 7) Root Cause Analysis

### 7.1 Root Cause Statement
Most likely root cause: a Friday deployment change (document management app assignment/startup impact) introduced a Floor 6-scoped login and sign-in performance degradation.

Root cause confidence: medium-high (mitigation success aligns with hypothesis), with exact technical failure mode still to confirm.

### 7.2 Causality Assessment
Why this is supported:
- Strong temporal correlation: deployment on Friday, user impact on next business start.
- Scope correlation: symptoms concentrated in targeted Floor 6 cohort.
- Symptom fit: mixed hard failures and slow sign-in can occur when deployment/policy/startup behavior diverges by device state.
- Corrective signal: issue reportedly resolved after applying rollback-style mitigation.

What remains unconfirmed:
- Exact failing component (app package behavior vs startup integration vs dependency vs assignment anomaly).
- Exact assignment/result-state deltas between affected and unaffected devices.
- Exact pre/post telemetry values showing normalization.

## 8) 5-Why Analysis

Problem: Multiple Legal Floor 6 users could not log in or had very slow logon.

Why 1:
- Because user sign-in flow on affected devices was degraded or blocked after recent change (confirmed symptom, inferred mechanism to confirm).

Why 2:
- Because a newly deployed document management app change likely introduced sign-in path contention/failure conditions for the Floor 6 cohort (to confirm exact mechanism).

Why 3:
- Because deployment behavior may have interacted with endpoint startup/policy processing in a recently migrated Win11 + Intune cohort (to confirm through device telemetry and assignment results).

Why 4:
- Because pre-production validation appears not to have fully detected this floor-specific mixed-failure pattern before broad floor deployment (to confirm test evidence and go-live checklist outcomes).

Why 5:
- Because change governance controls likely did not require a sufficiently instrumented pilot/hold-point with explicit login SLO gates for this cohort and app type (to confirm governance baseline and exceptions).

5-Why output classification:
- Immediate technical trigger: likely deployment change to Floor 6.
- Process contributors: probable gaps in staged rollout controls, telemetry-based acceptance criteria, and rollback guardrails (to confirm).

## 9) Corrective and Preventive Actions (CAPA)

### 9.1 Corrective Actions Already Applied
1. Mitigation applied: remove/suspend Floor 6 deployment assignment for the new document management app (confirmed applied per closure statement; to confirm exact admin audit record).
2. Service verification performed: [confirmed verification detail] (to confirm exact wording and sample size).

### 9.2 Preventive Actions
1. Enforce staged deployment rings for floor-scoped app changes:
- Ring 0 pilot (small sample), Ring 1 limited floor subset, then full floor.
- Progression gate requires no increase in login failure rate and no sign-in latency breach.
- Owner: Endpoint Engineering (to confirm).
- Target date: to confirm.

2. Add mandatory pre/post login health checks to change process:
- Capture sign-in success rate and sign-in duration before rollout and after each ring.
- Block promotion if thresholds are exceeded.
- Owner: Endpoint + Service Desk MI (to confirm).
- Target date: to confirm.

3. Require explicit rollback criteria in deployment record:
- Define trigger conditions (for example: impacted users > threshold, or sign-in p95 latency breach).
- Define rollback command path and approver.
- Owner: Change Management (to confirm).
- Target date: to confirm.

4. Add cohort-risk flag for recently migrated Win11 + Intune users:
- Treat as higher sensitivity cohort for app rollout change windows.
- Require additional observation window before full-floor rollout.
- Owner: Modern Workplace Platform (to confirm).
- Target date: to confirm.

5. Evidence discipline for closure:
- Closure pack must include timestamped deployment audit, affected-user sample validation, and post-mitigation metric snapshot.
- Owner: Incident Manager (to confirm).
- Target date: immediate process update (to confirm).

## 10) Open Items (To Confirm)
1. Exact resolved timestamp and timezone for [confirmed time].
2. Exact verification artifact details for [confirmed verification detail].
3. Intune/SCCM audit entries proving assignment change time and target scope.
4. Affected vs unaffected comparative telemetry demonstrating post-mitigation normalization.
5. Final technical failure mechanism inside the deployment/startup chain.

## 11) Partner-Ready Plain Language Summary
A software change made Friday for Legal Floor 6 is the most likely cause of Monday morning login failures and slow sign-ins. We reversed that change for the affected floor, and service is now reported as restored as of [confirmed time], verified by [confirmed verification detail]. We are now completing evidence validation and adding stronger rollout safeguards to prevent repeat disruption.