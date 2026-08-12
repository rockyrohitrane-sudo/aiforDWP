# Detailed Analysis – Autopilot Enrolment Failure (Legacy MDM Conflict)
Author: DWP Analyst  
Date: 2026-08-11  
Incident Device: DESKTOP-FB099  
Incident User: FINBRIDGE\rthomas  
Incident Timestamp: 2024-03-15 09:18-09:22

---

## 1) Scope Facts Extracted

- Enrolment result: Failed
- Enrolment type: Autopilot
- Enrolment error: 0x80180014
- Error description: The device is already enrolled in MDM
- Existing enrolment: Yes (legacy manual MDM enrolment dated 2023-11-04)
- Azure AD joined: Yes
- Policy application: Failed (0 of 4 profiles applied)
- Policy error: 0x80070005 (Access denied)
- Licensing: Present (M365, Intune P1, Autopilot)
- Network: Healthy (required endpoints reachable, no proxy)

---

## 2) Confirmed Root Cause

The device already had an existing legacy manual MDM enrolment record from 2023-11-04.  
Autopilot enrolment attempted on top of that conflicting enrolment context and failed with 0x80180014.

Status: Confirmed by direct evidence in the diagnostic export.

---

## 3) Remediation Goal

Remove stale enrolment state from both management plane and device, then re-run Autopilot from a clean enrolment state so MDM enrolment and policy application complete successfully.

---

## 4) Correct Order of Operations (Runbook)

### Step 1: Record identity values before cleanup
Access type: Admin center only

1. In Intune admin center, open Devices > All devices.
2. Search for DESKTOP-FB099.
3. Record the following for audit and object matching:
- Device name
- Serial number
- Azure AD device ID
- Intune managed device ID
- Last check-in time
- Enrolment date
4. Open Devices > Windows > Windows enrollment > Devices (Autopilot devices) and confirm the same serial/hardware identity is present.

Outcome: You have a reliable mapping to avoid deleting the wrong object.

### Step 2: Remove stale Intune managed device record
Access type: Admin center only

1. In Intune admin center, go to Devices > All devices > DESKTOP-FB099.
2. Select Retire and confirm.
3. Wait for retire action completion.
4. After retire completes, select Delete to remove the stale managed device object.

Outcome: The conflicting historical Intune enrolment record is removed.

### Step 3: Validate Autopilot object health
Access type: Admin center only

1. Go to Devices > Windows > Windows enrollment > Devices.
2. Locate the Autopilot record for the device.
3. Confirm there is only one active Autopilot record for this hardware.
4. Confirm assigned profile is correct (FinBridge-Autopilot-Standard).
5. Confirm assignment status is valid and profile assignment is complete.

If duplicate Autopilot records exist:
- Remove duplicate stale record(s), keeping only the authoritative current hardware record.

Outcome: Autopilot targeting is clean and unambiguous.

### Step 4: Remove old MDM enrolment artifacts on device
Access type: Device access required (physical or remote interactive session)

1. Sign in to the device with local admin or authorized support account.
2. Open Settings > Accounts > Access work or school.
3. If legacy organizational connection exists, select it and choose Disconnect.
4. Remove legacy Company Portal based manual enrolment traces if present (uninstall or disconnect account context as per DWP standard).
5. Reboot device.

Outcome: Legacy client-side MDM registration context is removed.

### Step 5: Reprovision into OOBE for clean Autopilot
Access type: Admin center only for remote wipe OR device access required for local reset

Preferred (admin center remote action):
1. In Intune admin center, target the active device object (if still present) and issue Wipe.
2. Use standard wipe options aligned with DWP process.

Alternative (device-side):
1. Locally reset Windows to OOBE state using approved DWP reset method.

Outcome: Device returns to first-run state required for clean Autopilot flow.

### Step 6: Run Autopilot enrolment again
Access type: Device access required (physical or remote hands at OOBE)

1. Boot to OOBE.
2. Connect to network.
3. Complete organization sign-in when prompted.
4. Allow Enrollment Status Page phases to complete without interruption.

Outcome: Device performs fresh AAD join and Intune MDM enrolment under Autopilot.

### Step 7: Post-enrolment policy sync and validation
Access type: Admin center only plus optional device access for forced sync

1. In Intune admin center, open Devices > All devices > DESKTOP-FB099.
2. Confirm management channel is active and check-in updates.
3. Trigger Sync from the device record if required.
4. Verify targeted profiles begin applying.

Outcome: Policy channel is active and baseline profiles can apply.

---

## 5) Verification Checks (Success Criteria)

Autopilot remediation is successful only when all checks below pass:

1. Enrolment completion
- Intune shows device as successfully enrolled under current Autopilot attempt.
- No recurrence of 0x80180014.

2. Device identity and ownership
- Device is Azure AD joined and MDM-managed by Intune under current enrolment timestamp.

3. Policy application health
- ProfilesApplied moves from 0 of 4 to expected applied state.
- 0x80070005 does not recur for baseline profile processing.

4. Compliance engine readiness
- Compliance can evaluate (not blocked by incomplete enrolment state).

5. Autopilot profile confirmation
- Device is mapped to FinBridge-Autopilot-Standard and assignment is successful.

Recommended verification locations:
- Intune admin center > Devices > All devices > DESKTOP-FB099
- Intune admin center > Devices > Windows > Windows enrollment > Devices
- Intune admin center > Devices > Windows > Compliance policies > Device status

---

## 6) Preventive Action (to stop recurrence)

Implement a pre-Autopilot legacy-enrolment hygiene gate in staging:

1. Before assigning/reassigning Autopilot devices, run a scheduled admin review that identifies devices with:
- Existing managed device records older than current deployment wave
- Enrolment source tagged as manual or legacy
- Duplicate device objects for same serial/hardware identity

2. Enforce a standard cleanup workflow before Autopilot re-use:
- Retire then delete stale Intune managed device objects
- Remove duplicate Autopilot records
- Confirm only one authoritative record remains per hardware identity

3. Add a deployment checklist control:
- Autopilot wave cannot start until device passes Pre-Enrolment Clean-State check.

4. Track compliance metric:
- Percentage of Autopilot-targeted devices with zero legacy enrolment conflicts at start of wave.

---

## 7) Operational Notes

- 0x80180014 and 0x80070005 interpretations were taken from the provided diagnostic evidence and are consistent with the export text.
- Licensing and network were not causal in this incident and should remain in scope only as exclusion checks.
- Device-side cleanup and OOBE reprovision are mandatory when legacy enrolment artifacts persist locally.

---

## 8) Final Resolution Statement

Incident resolution path is finalized: remove stale legacy MDM enrolment record, clear device-side legacy enrolment context, re-run Autopilot from clean OOBE state, and verify successful enrolment plus profile application.
