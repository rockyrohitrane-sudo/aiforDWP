# Runbook: Floor 6 Login/Performance Recovery — App Deployment Rollback
**Version:** 1.0  
**Date:** 2026-08-14  
**Prepared by:** DWP Service Desk  
**Related Incident:** Legal Floor 6 login failures and slow logon (post-Friday app deployment)  

---

## Overview

This runbook restores normal login functionality and sign-in performance for Legal Floor 6 users affected by Friday's document management app deployment. The mitigation removes or suspends the problematic app assignment from Floor 6 devices, allowing affected users to log in successfully and at normal speed. This is a rollback-style action executed via Intune endpoint management.

---

## Prerequisites

- **Access Level:** Intune global admin, Device Administrator, or Application Administrator role
- **Permissions Verification:** Confirm access to Intune admin center → Apps → All apps and Devices → Device assignments
- **Deployment Identification:** Confirm the exact app name and deployment ID for Friday's document management app (to confirm: [app name and ID])
- **Scope Definition:** Confirm Floor 6 device group membership in Intune (to confirm: floor6-devices or equivalent AD sync group)
- **Baseline Metrics:** Document current login failure count and average sign-in duration for Floor 6 users (to confirm baseline values)
- **Rollback Approval:** Obtain approval from platform owner or change management to remove Floor 6 assignment (to confirm approval path)
- **User Communication:** Prepare and schedule Floor 6 user notification before mitigation deployment (copy provided in step 2.1)

---

## Procedure

### **Phase 1: Prepare for Rollback**

#### Step 1.1: Verify Incident Scope and Current Assignment
**Action:**
1. Open **Intune admin center** (https://intune.microsoft.com)
2. Navigate to **Apps** → **All apps**
3. Search for the **document management app** deployed Friday
4. Click on the app name to open app details
5. Select the **Assignments** tab
6. Review the assigned groups and confirm:
   - Floor 6 device group is listed as "Required" or "Available" assignment
   - Assignment dates show deployment occurred Friday (to confirm: [exact date/time])
   - Scope includes at least the Floor 6 cohort

**Expected Result:**
- App assignment details displayed; Floor 6 confirmed in assignment scope
- Deployment date/time documented; assignment status visible
- Screenshot captured for incident record (to confirm: evidence protocol)

#### Step 1.2: Capture Pre-Rollback Metrics
**Action:**
1. In **Intune admin center**, navigate to **Devices** → **Monitor** → **Device compliance**
2. Filter for **Floor 6 device group**
3. Record the following metrics as of time of rollback attempt:
   - Total devices in Floor 6 group
   - Devices with compliance status "Compliant" (should reflect current state)
   - Any devices showing "Non-compliant" or "Error" state (likely related to failed logons or startup issues)
4. Export or screenshot current device status list
5. Document in incident record with timestamp

**Alternative Metric Source (if compliance data unavailable):**
1. Query Service Desk ticketing system for:
   - Count of open Floor 6 login-related tickets (as of rollback time)
   - Average time-to-resolution for login issues in the past 6 hours
2. Document as baseline for post-rollback comparison

**Expected Result:**
- Pre-rollback device status snapshot captured; metrics documented
- Baseline login issue ticket count recorded
- Timestamp of metric capture noted for post-rollback validation

#### Step 1.3: Communicate Rollback Action to Floor 6
**Action:**
1. Send the following message to Floor 6 manager, team lead, and optionally Floor 6 email distribution list:
   ```
   Subject: Floor 6 System Update — Expected Service Restoration
   
   We identified that Friday's software deployment caused login and sign-in delays 
   for Floor 6. We are reversing that change right now to restore normal access.
   
   Expected impact:
   - You may be logged out during the next 30 minutes
   - Simply log back in; sign-in should be normal speed
   - If issues persist, contact the Service Desk immediately
   
   Thank you for your patience. We're working to restore service now.
   ```
2. Send at least 15 minutes before rolling back app assignment
3. Confirm send timestamp in incident log

**Expected Result:**
- Floor 6 stakeholders notified of upcoming mitigation and expected brief disruption
- Communication timestamp logged for correlation with rollback execution

---

### **Phase 2: Execute Rollback**

#### Step 2.1: Remove or Suspend App Assignment for Floor 6
**Action:**
1. In **Intune admin center**, navigate to **Apps** → **All apps** → select the document management app
2. Click **Assignments** tab
3. Locate the row showing Floor 6 device group assignment
4. Choose **one of two methods:**

**Method A: Remove Assignment (Permanent Uninstall)**
   - Click the **...** (more options) menu on the Floor 6 assignment row
   - Select **Remove**
   - Confirm removal: "Remove Floor 6 from app assignment"
   - Click **OK**
   - Status changes to "Removing"

**Method B: Change Assignment to "Uninstall" (If app supports uninstall action)**
   - Click the **Edit** pencil icon on the Floor 6 assignment row
   - Change **Assignment type** from "Required" or "Available" to **"Uninstall"**
   - Click **Save**
   - Status changes to "Deploying uninstall"

5. Note which method was selected in incident record

**Expected Result:**
- App assignment removed or changed to uninstall for Floor 6
- Intune shows assignment status as "Removing" or "Deploying uninstall" within 1–2 minutes
- Rollback action logged in Intune audit trail with timestamp

#### Step 2.2: Trigger Device Sync on Floor 6 Devices
**Action:**
1. In **Intune admin center**, navigate to **Devices** → **All devices**
2. Filter by **Floor 6 device group**
3. Select the first Floor 6 device in the list
4. Click **...** (more options) → **Sync**
5. Repeat for the next 5–10 Floor 6 devices (sample across different users if possible)
6. This triggers forced device check-in and app uninstall/removal within 5 minutes

**Alternative: Bulk Sync (If available in your Intune version)**
1. Select all Floor 6 devices (checkbox at top)
2. Click **Bulk device actions** → **Sync**
3. Confirm action; all Floor 6 devices will sync within 5 minutes

**Expected Result:**
- Selected Floor 6 devices show "Sync requested" or "Sync pending" status
- Device-side app removal/uninstall begins within 5 minutes of device sync
- Users may experience brief logoff/reboot cycle as app is removed from device

#### Step 2.3: Wait for Deployment Completion
**Action:**
1. Wait **30–60 minutes** for all Floor 6 devices to check in and remove the app
2. During wait period:
   - Monitor Intune app assignment status for Floor 6 (should transition from "Removing" → "Removed")
   - Monitor Service Desk ticket queue for continued login complaints from Floor 6
   - Prepare next verification step (see Verification section)
3. Do **not** proceed to verification until majority of Floor 6 devices have checked in

**Expected Result:**
- Intune app assignment status for Floor 6 shows "Removed" or "Uninstall complete"
- Device check-in logs confirm uninstall execution on Floor 6 devices
- No new login failure tickets from Floor 6 (or significant reduction in ticket rate)

---

### **Phase 3: Restore User Access**

#### Step 3.1: Notify Floor 6 of Rollback Completion
**Action:**
1. Once rollback status shows complete (Step 2.3), send the following message to Floor 6:
   ```
   Subject: Floor 6 System Update — Complete. Service Restored.
   
   We have successfully reversed Friday's software change. 
   Your systems should now be back to normal.
   
   Please log in or log out and back in if needed. 
   Sign-in should be fast again.
   
   If you still experience slow login or access issues, 
   contact the Service Desk with your device name.
   ```
2. Send communication to Floor 6 manager, team lead, and optionally distribution list
3. Log send timestamp in incident record

**Expected Result:**
- Floor 6 notified that mitigation is complete and service is restored
- Users encouraged to log out/in to clear cached app state
- Service Desk alerted that Floor 6 should report normal access within 1 hour

---

## Verification

### User-Facing Verification

#### Step V.1: Login Success Validation
**Action:**
1. Contact 5–10 Floor 6 users (representative sample across team if possible)
2. Ask each user to attempt login or log out/log in if already signed in
3. Record for each user:
   - Could they log in successfully (yes/no)?
   - Approximately how long did sign-in take (estimate in seconds)?
   - Any error messages or unexpected behavior (record details)?
4. Compare sign-in times to pre-incident baseline (to confirm: baseline duration is [X] seconds)

**Expected Result:**
- ≥90% of sampled users report successful login
- Average sign-in duration within baseline range (or within +10 seconds of baseline)
- No error messages reported

#### Step V.2: Service Desk Ticket Trend Check
**Action:**
1. Query Service Desk ticketing system:
   - Filter for Floor 6 user tickets created in the last 2 hours
   - Filter by category: "Login," "Logon," "Sign-in," "Access"
2. Compare count to pre-rollback baseline (captured in Step 1.2)
3. Expected outcome: significant reduction in login-related tickets (to confirm: target is <3 tickets/hour from Floor 6)

**Expected Result:**
- Login-related ticket volume from Floor 6 drops to near-zero or baseline operational level
- Incident reported as operationally resolved

### Technical Verification

#### Step V.3: Intune Assignment Status Confirmation
**Action:**
1. In **Intune admin center**, go to **Apps** → **All apps** → document management app
2. Click **Assignments** tab
3. Verify that Floor 6 device group no longer appears in the assignment list (if Method A was used) OR shows "Uninstall" status (if Method B was used)
4. Take screenshot and attach to incident record

**Expected Result:**
- Floor 6 assignment removed or marked as uninstall
- No active "Required" or "Available" assignments for Floor 6
- Audit log shows removal/change timestamp

#### Step V.4: Device-Level Confirmation (Sample)
**Action:**
1. RDP or remote-connect to 2–3 Floor 6 devices (varied sample)
2. On each device, verify:
   - App folder removed: `Test-Path "C:\Program Files\DocumentManagementApp"` returns `$false`
   - App removed from installed programs list: Check **Settings** → **Apps** → **Apps & features** (app should not appear)
3. Record device names and verification results

**Expected Result:**
- Sample Floor 6 devices confirm app removal
- No residual app files or registry entries remain (to confirm if deep clean required)
- Device startup and login process return to normal baseline

#### Step V.5: Post-Rollback Metrics Capture
**Action:**
1. Repeat the metrics capture from Step 1.2 (post-rollback):
   - Intune device compliance status for Floor 6
   - Service Desk login-related ticket count for Floor 6
   - Timestamp of measurement
2. Compare pre-rollback → post-rollback metrics:
   - Compliant device count should increase (devices completing uninstall)
   - Login-related tickets should drop ≥80% from pre-rollback volume
3. Document comparison in incident record with analysis

**Expected Result:**
- Post-rollback metrics show clear improvement in device compliance and reduced ticket volume
- Quantitative evidence supports incident resolution claim

---

## Rollback Procedure (Contingency)

### Trigger Conditions
Rollback of this rollback is triggered if:
- After removing the document management app, Floor 6 users report **worsening** login issues (paradoxical degradation)
- Device compliance score drops below pre-mitigation baseline
- New widespread errors appear (e.g., missing critical system components)
- Platform owner or change management requests immediate reverse

### Reverse Rollback Steps

#### Step R.1: Restore Original App Assignment
**Action:**
1. In **Intune admin center**, go to **Apps** → **All apps** → document management app
2. Click **Assignments** tab
3. Click **Add groups** or **Edit** (depending on Intune version)
4. Re-add the **Floor 6 device group** assignment with original settings:
   - Assignment type: "Required" (to confirm: was it Required or Available?)
   - Deployment intent: "Available" or "Required" (to confirm original setting)
5. Save assignment
6. Click **Save** to re-enable deployment to Floor 6

**Expected Result:**
- Floor 6 assignment re-added to app deployment
- Assignment status shows "Deploying" or "Assigned"
- App will re-install on Floor 6 devices at next check-in

#### Step R.2: Communicate Reverse Action
**Action:**
1. Notify Floor 6 management and Service Desk:
   ```
   Subject: Floor 6 — Rollback Mitigation Reversed (Contingency)
   
   We reversed our previous fix because it caused unexpected issues. 
   The original software is being re-deployed to Floor 6 devices.
   
   Expected timeline: installation complete within 1 hour.
   
   We are escalating to the vendor and engineering team to identify 
   a proper permanent fix.
   ```
2. Escalate to:
   - Document management app vendor (support ticket)
   - Endpoint Engineering (root cause investigation)
   - Change Management (process review for this deployment)

**Expected Result:**
- Stakeholders informed of contingency action and escalation
- Vendor and engineering engaged for permanent resolution

#### Step R.3: Investigate Root Cause of Reverse-Rollback Trigger
**Action:**
1. If reverse rollback was triggered, conduct brief analysis:
   - Collect error logs from 2–3 affected Floor 6 devices showing what worsened
   - Query Intune audit logs for unexpected policy/assignment changes during rollback window
   - Interview 2–3 users on what they experienced
2. Document findings; do not re-apply rollback until root cause is understood
3. Escalate findings to platform owner and engineering

**Expected Result:**
- Incident details captured for permanent RCA
- Platform owner and engineering have facts to diagnose issue
- Future mitigation strategy informed by reverse-rollback learnings

---

## Contacts & Escalation

- **Intune Administration:** [Intune admin team contact — to confirm]
- **Document Management App Vendor:** [Vendor support contact and SLA — to confirm]
- **Floor 6 Management:** [Floor 6 manager/lead contact — to confirm]
- **Change Management:** [Change lead or approval contact — to confirm]
- **Service Desk Escalation:** [L2/L3 contact for engineering escalation — to confirm]

---

## Post-Incident Actions

1. Complete all verification steps (Section: Verification) and document results
2. Obtain sign-off from Floor 6 management that service is restored
3. Close or update incident record with incident ticket ID, resolution timestamp, and verification summary
4. Archive rollback metrics and device status snapshots for root-cause analysis team
5. Update incident tracker with action items:
   - Vendor to provide corrected app package (to confirm: ETA)
   - Engineering to investigate deployment interaction with Win11 + Intune (to confirm: due date)
   - Process owner to implement deployment rings and health-check gates (to confirm: due date per RCA Section 9.2)

---

## Change Log
| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0 | 2026-08-14 | DWP Service Desk | Initial runbook creation; app deployment rollback for Floor 6 login recovery |

