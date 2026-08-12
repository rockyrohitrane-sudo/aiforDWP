# Root Cause Analysis (RCA) - Autopilot Enrolment Failure (Legacy MDM Conflict)
Author: DWP Analyst  
Date: 2026-08-11  
Incident Date: 2024-03-15  
Device: DESKTOP-FB099  
User: FINBRIDGE\rthomas  
Service Area: Endpoint Management (Intune / Autopilot)

---

## 1. Executive Summary

Autopilot enrolment failed because the device already had an active legacy manual MDM enrolment record (dated 2023-11-04). This created a conflicting management state that blocked new Autopilot-driven enrolment. As a downstream effect, policy application did not proceed (0 of 4 profiles applied) and compliance evaluation could not run.

Confirmed primary error: 0x80180014 (device already enrolled in MDM).  
Observed downstream policy error: 0x80070005 (Access denied).

---

## 2. Incident Scope and Impact

- Affected endpoint: DESKTOP-FB099
- Enrolment type attempted: Autopilot
- Outcome: Enrolment failed
- Immediate impact:
- Device did not complete target-state Intune enrolment via Autopilot
- Required security baseline profile failed to apply
- Compliance engine could not evaluate device posture
- Business impact:
- Device could not progress through standard secure provisioning workflow
- Increased manual support effort and delayed user readiness

---

## 3. Supporting Evidence

### 3.1 Evidence from MDM Diagnostic Export

- EnrollmentState: Failed
- ErrorCode: 0x80180014
- ErrorDescription: The device is already enrolled in MDM
- MDMEnrolled: Yes (previous enrolment)
- EnrolmentSource: Legacy (manual MDM enrolment, 2023-11-04)
- ProfilesAttempted: 4
- ProfilesApplied: 0
- LastError: 0x80070005 (Access denied)
- ComplianceEngine EvaluationResult: Could not evaluate
- ComplianceEngine Reason: Enrolment not complete
- AzureADJoined: Yes
- IntuneP1License: Yes
- AutopilotLicense: Yes
- Network endpoint checks: OK
- ProxyDetected: No

### 3.2 Evidence Interpretation

- The enrolment failure message directly states an existing MDM enrolment conflict.
- Azure AD join, licensing, and network checks were healthy, reducing likelihood of identity, license, or connectivity as primary causes.
- Policy and compliance failures occurred after enrolment failure and are consistent downstream symptoms.

---

## 4. Incident Timeline

All times are from the diagnostic export on 2024-03-15.

| Time | Event | Evidence | Interpretation |
|---|---|---|---|
| 09:18:44 | Autopilot enrolment attempt processed | EnrollmentType: Autopilot | Enrolment workflow started |
| 09:18:44 | Enrolment failed | EnrollmentState: Failed, ErrorCode: 0x80180014 | Primary failure condition reached |
| 09:18:44 | Reason surfaced | ErrorDescription: device already enrolled in MDM | Conflict with existing legacy enrolment |
| 09:19:01 | Policy phase attempted | ProfilesAttempted: 4 | Policy processing initiated post-failure state |
| 09:19:01 | Policy phase failed | ProfilesApplied: 0, LastError: 0x80070005 | Downstream inability to apply profiles |
| 09:19:45 | Compliance engine evaluated state | EvaluationResult: Could not evaluate | Compliance blocked by incomplete enrolment |
| 09:22:00 | Diagnostic snapshot captured | Export metadata | Incident state preserved for analysis |

Historical context from export:
- 2023-11-04: Legacy manual MDM enrolment existed before this Autopilot attempt.

---

## 5. Root Cause Statement

Primary root cause:
- Pre-existing legacy manual MDM enrolment record from 2023-11-04 remained active for the device and conflicted with the 2024-03-15 Autopilot enrolment attempt.

Contributing factors:
- No enforced pre-Autopilot clean-state validation to detect and remove legacy/manual enrolment before provisioning.
- No hard gate in deployment process to block Autopilot attempts when conflicting enrolment state exists.

Not causal based on available evidence:
- Licensing (present)
- Network reachability (healthy)
- Azure AD join state (present)

---

## 6. 5 Whys Analysis

Problem statement: Autopilot enrolment failed for DESKTOP-FB099.

1. Why did Autopilot enrolment fail?
- Because enrolment returned 0x80180014 and stated the device was already enrolled in MDM.

2. Why was the device already enrolled?
- Because a prior legacy manual MDM enrolment from 2023-11-04 still existed.

3. Why was the legacy enrolment still present at redeployment time?
- Because stale enrolment records/artifacts were not removed before initiating Autopilot.

4. Why were stale records not removed before Autopilot?
- Because the process lacked a mandatory pre-flight clean-state check for legacy/manual enrolment conflicts.

5. Why was there no mandatory clean-state gate?
- Because the deployment standard did not enforce object hygiene controls (retire/delete stale device objects and validate single authoritative Autopilot identity) as a release criterion.

Process-level root cause:
- Missing governance control in endpoint reprovision workflow to prevent Autopilot execution on devices with pre-existing conflicting MDM enrolment state.

---

## 7. Corrective Actions (Incident-Specific)

1. Remove stale Intune managed device object for DESKTOP-FB099
- Retire then delete stale record in Intune admin center.

2. Validate Autopilot device record
- Ensure single authoritative Autopilot record for target hardware identity and correct profile assignment.

3. Clear device-side legacy MDM registration
- Disconnect legacy work/school account registration and remove local enrolment artifacts.

4. Re-run Autopilot from clean OOBE state
- Reprovision device and complete Autopilot workflow.

5. Verify enrolment and profile application
- Confirm no repeat of 0x80180014 and confirm profiles apply successfully.

---

## 8. Preventive Actions

### 8.1 Process Controls

1. Implement mandatory Pre-Enrolment Clean-State Check for every Autopilot (re)provision
- Validate no active legacy/manual MDM enrolment exists.
- Validate no duplicate stale managed device records exist.
- Validate one authoritative Autopilot record per hardware identity.

2. Add deployment gate
- Do not start Autopilot until clean-state checklist passes.

3. Standardize lifecycle workflow
- On redeployment/reuse: Retire then delete stale device object before reassignment.

### 8.2 Operational Monitoring

1. Weekly hygiene report
- Flag devices with legacy/manual enrolment source and those with duplicate identity records.

2. KPI
- Track percentage of Autopilot-targeted devices that pass clean-state gate before wave start.

3. Exception handling
- Route flagged devices to L2 pre-staging queue for cleanup before user assignment.

### 8.3 Documentation and Training

1. Update runbooks
- Add explicit stale-enrolment cleanup sequence and verification points.

2. Engineer enablement
- Brief L1/L2 teams on 0x80180014 conflict triage path and required cleanup order.

---

## 9. Validation Criteria After Preventive Rollout

Preventive rollout is considered effective when:

- Autopilot failures with existing-enrolment conflicts trend to near zero.
- Devices in Autopilot waves no longer show legacy/manual MDM source at start.
- First-pass profile application success rate increases.
- Helpdesk escalations for Autopilot enrolment conflicts decline measurably.

---

## 10. Final Resolution Status

Status: Root cause confirmed and remediation path defined.  
Closure condition: Device successfully re-enrolled via Autopilot after stale enrolment cleanup, with policy application and compliance evaluation functioning normally.
