# Runbook: Floor 6 Missing Shortcuts — Disable Script and Restore Shortcuts
**Version:** 1.0  
**Date:** 2026-08-14  
**Prepared by:** DWP Service Desk  
**Related Incident:** Legal Floor 6 missing desktop shortcuts (post-Friday app deployment)  

---

## Overview

This runbook resolves missing desktop shortcuts on Legal Floor 6 devices caused by Friday's document management app deployment. The fix disables the offending post-install script or Intune profile behavior and deploys a remediation script to restore shortcuts. This applies to recently migrated Windows 11 + Intune-enrolled devices in the Floor 6 cohort.

---

## Prerequisites

- **Access Level:** Intune global admin, Application Administrator, or Device Administrator role
- **Permissions Verification:** Confirm access to Intune admin center → Apps, Devices, and Remediation scripts
- **Scope Confirmation:** Identify Floor 6 device group in Intune (to confirm: floor6-devices or equivalent AD sync group)
- **Baseline Knowledge:** Document expected baseline shortcut count for Floor 6 (typical: 3–5 system/app shortcuts; to confirm exact standard)
- **Symptom Validation:** Confirm shortcut state on affected devices before remediation:
  - Are shortcuts deleted, hidden, or path-redirected? (to confirm mechanism)
  - Affected user/device count (to confirm scope)
- **Vendor Investigation:** Determine if post-install script is embedded in app package or deployed via separate Intune profile
- **User Notification:** Prepare and schedule Floor 6 notification before remediation deployment (copy provided in step 2.1)

---

## Procedure

### **Phase 1: Investigate and Disable Offending Behavior**

#### Step 1.1: Identify Post-Install Script Source
**Action:**
1. Open **Intune admin center** (https://intune.microsoft.com)
2. Navigate to **Apps** → **All apps** → select the **document management app** deployed Friday
3. Review **Properties** and **Package information** to determine script source:
   - **Option A:** Script is embedded in app package (vendor-provided deployment)
   - **Option B:** Script is deployed via separate Intune configuration profile or startup task
4. Document which option applies in incident record

**Expected Result:**
- Script source identified and documented
- Decision path clear: proceed to Step 1.2a (embedded) or 1.2b (separate profile)

#### Step 1.2a: Embedded Post-Install Script Path
**Condition:** Post-install script is bundled within the app package.

**Action:**
1. Document the app package version, vendor, and description of shortcut-impacting behavior (e.g., "post-install script deletes .lnk files")
2. Contact the document management app vendor:
   - Report that the deployment removes/modifies desktop shortcuts
   - Request corrected package version that preserves shortcuts
   - Request ETA for patched release
3. While awaiting corrected package, proceed to Phase 2 to restore shortcuts immediately (remediation script)
4. When corrected package available, update Intune app assignment for Floor 6

**Expected Result:**
- Vendor acknowledgment received; corrected package identified or ETA provided
- Immediate workaround (Phase 2 remediation) deployed to restore user access
- Permanent fix path established (corrected package)

#### Step 1.2b: Separate Configuration Profile or Startup Task Path
**Condition:** Shortcut-removal behavior is deployed via Intune configuration profile, startup script, or task assignment.

**Action:**
1. Navigate to **Intune admin center** → **Devices** → **Configuration profiles**
2. Search for profiles assigned to Floor 6 device group containing:
   - PowerShell startup scripts
   - Scheduled tasks for post-deployment
   - Device configuration changes post-Friday deployment
3. Identify the specific profile (e.g., "Floor 6 post-deployment tasks")
4. Click **Edit** and locate the shortcut-removal step/script:
   - Look for PowerShell commands removing `*.lnk` files
   - Look for task deletions targeting user desktop paths
5. Remove or disable the shortcut-removal logic
6. Save changes; profile redeploys to Floor 6 within 30 minutes

**Expected Result:**
- Profile edited and shortcut-removal behavior disabled/removed
- Intune shows redeployment status for Floor 6 device group
- Shortcut-removal step no longer executes on Floor 6 devices

---

### **Phase 2: Deploy Remediation Script to Restore Shortcuts**

#### Step 2.1: Notify Floor 6 of Remediation Action
**Action:**
1. Send the following message to Floor 6 manager, team lead, and optionally user distribution list:
   ```
   Subject: Floor 6 Desktop Shortcuts — Automatic Restoration in Progress
   
   We identified why some of you are missing desktop shortcuts 
   (related to Friday's software update) and we're fixing it now.
   
   We're deploying an automatic fix that will restore your shortcuts. 
   You don't need to do anything—it will happen on its own.
   
   Expected timeline: restored within 1–2 hours.
   
   If shortcuts are still missing after 1 hour:
   - Restart your device, OR
   - Go to Settings → Accounts → Sync to trigger manual sync
   
   Contact the Service Desk if issues persist beyond 2 hours.
   Thank you for your patience.
   ```
2. Send at least 15 minutes before deploying remediation script
3. Log send timestamp in incident record

**Expected Result:**
- Floor 6 stakeholders notified of remediation action and expected timeline
- Users prepared for automatic restoration process

#### Step 2.2: Create Detection Script in Intune
**Action:**
1. In **Intune admin center**, navigate to **Devices** → **Remediation scripts**
2. Click **Create script**
3. Copy and paste the following detection script:
   ```powershell
   $deskPath = [System.Environment]::GetFolderPath('Desktop')
   $shortcuts = Get-ChildItem -Path $deskPath -Filter "*.lnk" -ErrorAction SilentlyContinue
   $shortcutCount = ($shortcuts | Measure-Object).Count
   
   # Threshold: expect 3+ shortcuts for Floor 6 baseline
   # Adjust per actual Floor 6 standard (to confirm exact number)
   if ($shortcutCount -lt 3) {
       Write-Output "Shortcut deficit detected: $shortcutCount found; expected 3+"
       exit 1  # Remediation required
   } else {
       Write-Output "Shortcut count compliant: $shortcutCount"
       exit 0  # No remediation needed
   }
   ```
4. Review script; adjust threshold (`-lt 3`) to match Floor 6 baseline (to confirm exact expected count)
5. Click **Next** to proceed to remediation script entry

**Expected Result:**
- Detection script entered and validated (no syntax errors)
- Script will scan user desktops and flag for remediation if shortcut count is below baseline

#### Step 2.3: Create Remediation Script in Intune
**Action:**
1. In the same script creation dialog, copy and paste the following remediation script into the **Remediation script** field:
   ```powershell
   $deskPath = [System.Environment]::GetFolderPath('Desktop')
   $appInstallPath = "C:\Program Files\DocumentManagementApp"  # To confirm: actual install path
   $appExecutable = "DocumentApp.exe"  # To confirm: actual executable name
   $shortcutDisplayName = "Document Management App"  # To confirm: user-friendly name
   
   # Validate app installation
   if (Test-Path -Path $appInstallPath) {
       $shortcutTarget = "$deskPath\$shortcutDisplayName.lnk"
       
       # Prevent duplicate shortcuts
       if (-not (Test-Path -Path $shortcutTarget)) {
           try {
               $wshShell = New-Object -ComObject WScript.Shell
               $shortcut = $wshShell.CreateShortcut($shortcutTarget)
               $shortcut.TargetPath = "$appInstallPath\$appExecutable"
               $shortcut.WorkingDirectory = $appInstallPath
               $shortcut.IconLocation = "$appInstallPath\$appExecutable,0"
               $shortcut.Description = "Shortcut restored by Floor 6 remediation"
               $shortcut.Save()
               Write-Output "Shortcut restored: $shortcutTarget"
               [System.Runtime.Interopservices.Marshal]::ReleaseComObject($wshShell) | Out-Null
               exit 0
           } catch {
               Write-Output "Error creating shortcut: $($_.Exception.Message)"
               exit 1
           }
       } else {
           Write-Output "Shortcut already exists: $shortcutTarget"
           exit 0
       }
   } else {
       Write-Output "App path not found: $appInstallPath; no shortcut created"
       exit 1
   }
   ```
2. Customize variables:
   - Replace `C:\Program Files\DocumentManagementApp` with actual app install path
   - Replace `DocumentApp.exe` with actual executable name
   - Set `$shortcutDisplayName` to user-friendly name (e.g., "Document Management App")
3. Review and click **Next** to assign to Floor 6

**Expected Result:**
- Remediation script validated (no syntax errors)
- Script will create shortcut for each Floor 6 user if missing

#### Step 2.4: Assign Remediation Script to Floor 6 Device Group
**Action:**
1. On the **Assignments** page, click **Add groups**
2. Select **Floor 6 device group** (or equivalent Floor 6 AD sync group)
3. Confirm assignment scope shows Floor 6 only
4. Click **Save** and then **Create**
5. Script deployment queued for Floor 6

**Expected Result:**
- Remediation script created and assigned to Floor 6
- Deployment status shows "Pending" or "Deploying"
- Floor 6 devices will execute script within 15–30 minutes of check-in

#### Step 2.5: Monitor Remediation Script Execution
**Action:**
1. Navigate to **Devices** → **Remediation scripts**
2. Select the remediation script just created
3. Click **Device status** to view execution results by device
4. Monitor for 90 minutes:
   - **Green (Success):** Shortcut created/restored on that device
   - **Red (Failed):** Investigation required; review error message
   - **Gray (Pending):** Device has not yet checked in
5. Expected outcome: ≥95% of Floor 6 devices show "Success" within 90 minutes

**Expected Result:**
- Majority of Floor 6 devices report successful shortcut restoration within 90 minutes
- Failed devices logged for follow-up investigation
- User desktop shortcuts visible at next logon or after manual sync

---

### **Phase 3: Validate User Access**

#### Step 3.1: Notify Floor 6 of Remediation Completion
**Action:**
1. Once remediation status shows ≥90% success, send completion message to Floor 6:
   ```
   Subject: Floor 6 Desktop Shortcuts — Restoration Complete
   
   Your desktop shortcuts have been restored. 
   You should see them now, or after you next log in.
   
   If you don't see your shortcuts:
   - Try restarting your device
   - Or sync manually: Settings → Accounts → Access work or school → Sync
   
   Contact the Service Desk if shortcuts are still missing after 1 hour.
   ```
2. Send notification to Floor 6 management, team lead, and optional distribution list
3. Log send timestamp in incident record

**Expected Result:**
- Floor 6 notified that remediation is complete
- Users directed to verify and self-help options provided
- Service Desk alerted for follow-up on remaining issues

---

## Verification

### User-Facing Verification

#### Step V.1: Spot-Check User Desktops
**Action:**
1. Contact 5–10 Floor 6 users (representative sample)
2. Ask each to check their desktop for:
   - Document Management App shortcut visible? (yes/no)
   - Shortcut launches app correctly? (test by clicking)
   - Any error messages? (record if present)
3. Record results for each user
4. Document count of users with successfully restored shortcuts

**Expected Result:**
- ≥90% of sampled users report visible, functional shortcuts
- <10% report missing or non-functional shortcuts (escalate to Phase 3 follow-up)

#### Step V.2: Service Desk Ticket Trend
**Action:**
1. Query Service Desk ticketing system for Floor 6 shortcut-related tickets:
   - Created in the last 2 hours
   - Filter by: "missing shortcut," "no shortcut," "shortcut gone," "restored," etc.
2. Compare to baseline opened during incident window (before remediation)
3. Expected outcome: reduction from initial incident spike to near-zero

**Expected Result:**
- Shortcut-related tickets drop significantly post-remediation
- Incident operationally resolved

### Technical Verification

#### Step V.3: Intune Remediation Status Validation
**Action:**
1. In **Intune admin center**, go to **Devices** → **Remediation scripts**
2. Select remediation script deployed to Floor 6
3. Click **Device status**
4. Verify:
   - ≥90% of assigned Floor 6 devices show "Success" status
   - <10% show "Failed" status (investigate exceptions)
   - All devices have executed (no "Pending" after 90 minutes)
5. Screenshot and attach to incident record

**Expected Result:**
- High success rate (≥90%) across Floor 6 device fleet
- Failed devices identified for manual follow-up
- Clear evidence of remediation effectiveness

#### Step V.4: Device-Level Spot Check
**Action:**
1. RDP or remote-connect to 2–3 Floor 6 devices (varied sample)
2. On each device, verify:
   - Desktop contains expected shortcut file(s): `Get-ChildItem "$env:USERPROFILE\Desktop" -Filter "*.lnk"`
   - Shortcut points to correct app: Shortcut properties → Target path matches app location
   - No duplicate shortcuts created
3. Document device names and verification results

**Expected Result:**
- Sample Floor 6 devices confirm shortcut files present and correctly configured
- No unexpected duplicates or broken links
- Shortcut count matches baseline expectation

#### Step V.5: Post-Remediation Metrics
**Action:**
1. Capture end-state metrics:
   - Intune device compliance for Floor 6 (should remain ≥85%)
   - Service Desk shortcut-related ticket count for Floor 6 (should be ~0)
   - Date/time of verification
2. Compare to pre-remediation baseline (captured in prerequisites)
3. Document improvement and analysis in incident record

**Expected Result:**
- Post-remediation metrics show clear improvement or resolution
- Quantitative evidence supports incident closure

---

## Rollback Procedure

### Trigger Conditions
Rollback is executed if:
- Remediation script causes unintended side effects (performance issues, duplicate shortcuts, app conflicts)
- Floor 6 users report new problems after shortcut restoration
- Script success rate falls below 80%

### Rollback Steps

#### Step R.1: Suspend Remediation Script
**Action:**
1. In **Intune admin center**, go to **Devices** → **Remediation scripts**
2. Select the remediation script deployed to Floor 6
3. Click **Delete** or **Unassign** from Floor 6 device group
4. Confirm removal

**Expected Result:**
- Remediation script unassigned from Floor 6
- Script no longer executes on new device check-ins
- Already-restored shortcuts remain (no reverse action)

#### Step R.2: Communicate Rollback
**Action:**
1. Notify Floor 6 management and Service Desk:
   ```
   Subject: Floor 6 Shortcut Remediation — Paused for Review
   
   We've paused the automatic shortcut restoration while we investigate 
   unexpected issues. Your shortcuts created so far remain; 
   we're working on a corrected approach.
   ```
2. Escalate to platform owner and engineering for root-cause analysis

**Expected Result:**
- Stakeholders informed of pause and investigation status

#### Step R.3: Root Cause Investigation
**Action:**
1. Review remediation script execution logs on failed devices
2. Identify error pattern or unintended behavior
3. Correct script configuration or approach
4. Test corrected script in pilot environment before re-deployment

**Expected Result:**
- Root cause of issues documented
- Corrected approach prepared for re-deployment

#### Step R.4: Re-Deploy Corrected Remediation (If Applicable)
**Action:**
1. Update remediation script with corrections (e.g., path adjustment, duplicate prevention enhancement)
2. Re-assign to Floor 6
3. Monitor execution and verify success

**Expected Result:**
- Corrected remediation deployed with improved success rate

---

## Contacts & Escalation

- **Intune Administration:** [Intune admin team contact — to confirm]
- **Document Management App Vendor:** [Vendor support contact — to confirm]
- **Floor 6 Management:** [Floor 6 manager contact — to confirm]
- **Service Desk Escalation:** [L2/L3 contact — to confirm]

---

## Post-Incident Actions

1. Complete all verification steps and document results
2. Obtain Floor 6 management sign-off that issue is resolved
3. Close incident record with:
   - Incident ID and resolution timestamp
   - Verification summary and evidence
   - Remediation script version/ID used
4. Archive remediation script and device status snapshots for reference
5. Schedule post-incident preventive action tracking (per RCA Section 9.2):
   - Vendor to provide corrected package or confirm script removal safe (to confirm: ETA)
   - Endpoint Engineering to review Win11 + Intune interaction (to confirm: due date)
   - Change Management to implement deployment rings and health gates (to confirm: due date)

---

## Change Log
| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0 | 2026-08-14 | DWP Service Desk | Initial runbook creation; desktop shortcut remediation for Floor 6 |

