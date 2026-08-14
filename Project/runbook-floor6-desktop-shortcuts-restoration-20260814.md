# Runbook: Floor 6 Desktop Shortcuts Restoration
**Version:** 1.0  
**Date:** 2026-08-14  
**Prepared by:** DWP Service Desk  
**Related Incident:** Copilot access concern (legal Floor 6 shortcut visibility)  

---

## Overview
This runbook restores missing desktop shortcuts on Floor 6 devices caused by post-install script behavior during Friday's document management app deployment. The fix disables the offending script and deploys a remediation script to restore shortcuts across affected user profiles.

---

## Prerequisites

- **Access Level:** Intune global admin, Application Administrator, or Device Administrator role
- **Permissions Verification:** Confirm access to Intune admin center → Apps and Devices → Remediation scripts
- **Scope Confirmation:** Identify Floor 6 device group membership in Intune (to confirm: floor6-devices or equivalent AD sync group)
- **Baseline Reference:** Document expected baseline shortcut count for Floor 6 user profiles (default: 3–5 system/app shortcuts; to confirm exact standard)
- **Notification:** Prepare user communication before beginning (copy provided in step 3)
- **Vendor Contact (if needed):** Document management app vendor support channel open (if corrected package is required)

---

## Procedure

### **Phase 1: Disable Offending Post-Install Script**

#### Step 1.1: Locate and Review the Document Management App Deployment
**Action:**
1. Open **Intune admin center** (https://intune.microsoft.com)
2. Navigate to **Apps** → **All apps**
3. Search for and select the **document management app** deployed Friday
4. Select **Properties** and review **Package information** and **App configuration** sections

**Expected Result:**
- App package properties displayed; presence or absence of post-install script behavior noted
- If script is embedded in app package, move to Step 1.2a
- If script is separate (Startup Task or Configuration Profile), move to Step 1.2b

#### Step 1.2a: Embedded Post-Install Script Path
**Condition:** Post-install script is bundled within the app package itself.

**Action:**
1. Document the app package version and vendor details
2. Contact the document management app vendor and request:
   - Confirmation that the current deployment removes or alters shortcuts
   - A corrected package version that does not modify desktop shortcuts
   - Estimated availability of corrected package
3. Stage corrected package in Intune when available (or defer; see Rollback section if urgent resolution needed)

**Expected Result:**
- Vendor acknowledgment received; corrected package identified (to confirm ETA)
- Interim rollback or remediation script deployed (per Phase 2 or Rollback) while awaiting corrected package

#### Step 1.2b: Separate Configuration Profile or Startup Task Path
**Condition:** Post-install shortcut-removal behavior is deployed via separate Intune configuration or startup task.

**Action:**
1. Navigate to **Intune admin center** → **Devices** → **Configuration profiles**
2. Search for profiles assigned to Floor 6 device group that contain post-deployment or startup script references
3. Identify the specific profile targeting Floor 6 devices (e.g., "Floor 6 post-deployment tasks" or equivalent)
4. Open the profile and locate the PowerShell script or task step that removes shortcuts
5. Click **Edit** and remove or disable the shortcut-removal step/script section
6. Save changes and confirm redeployment to Floor 6 device group

**Expected Result:**
- Profile edited; shortcut-removal step disabled or removed
- Status shows "Assignment pending" or "Deploying to Floor 6"
- Confirm floor 6 devices receive updated profile within 30 minutes (to confirm sync interval)

---

### **Phase 2: Deploy Remediation Script to Restore Shortcuts**

#### Step 2.1: Prepare Detection Script
**Action:**
1. In **Intune admin center**, go to **Devices** → **Remediation scripts** → **Create script**
2. Copy and paste the following PowerShell detection script into the **Detection script** field:
   ```powershell
   $deskPath = [System.Environment]::GetFolderPath('Desktop')
   $shortcuts = Get-ChildItem -Path $deskPath -Filter "*.lnk" -ErrorAction SilentlyContinue
   if ($shortcuts.Count -lt 3) { 
       Write-Output "Shortcuts missing: $($shortcuts.Count) found, expected 3+"
       exit 1 
   } else { 
       exit 0 
   }
   ```
3. Review and adjust the threshold (`-lt 3`) based on Floor 6 baseline expectation (to confirm exact count)
4. Click **Next**

**Expected Result:**
- Detection script syntax validated (no errors shown)
- Script saves and moves to remediation script entry

#### Step 2.2: Prepare and Deploy Remediation Script
**Action:**
1. In the same script creation dialog, copy and paste the following remediation PowerShell into the **Remediation script** field:
   ```powershell
   $deskPath = [System.Environment]::GetFolderPath('Desktop')
   $appPath = "C:\Program Files\DocumentManagementApp"
   $appExe = "DocumentApp.exe"
   
   if (Test-Path $appPath) {
       $shortcutName = "Document Management App"
       $shortcutPath = "$deskPath\$shortcutName.lnk"
       
       if (-not (Test-Path $shortcutPath)) {
           try {
               $shell = New-Object -ComObject WScript.Shell
               $link = $shell.CreateShortcut($shortcutPath)
               $link.TargetPath = "$appPath\$appExe"
               $link.WorkingDirectory = $appPath
               $link.IconLocation = "$appPath\$appExe,0"
               $link.Save()
               Write-Output "Shortcut restored: $shortcutPath"
               exit 0
           } catch {
               Write-Output "Error restoring shortcut: $_"
               exit 1
           }
       } else {
           Write-Output "Shortcut already exists: $shortcutPath"
           exit 0
       }
   } else {
       Write-Output "App path not found: $appPath"
       exit 1
   }
   ```
2. Update placeholder values:
   - `$appPath`: Verify actual installation path (to confirm exact path)
   - `$appExe`: Verify actual executable name (to confirm exact filename)
   - `$shortcutName`: Set to user-friendly display name (e.g., "Document Management App")
3. Click **Next** and proceed to assignment

**Expected Result:**
- Remediation script syntax validated; no errors
- Script configured to detect and restore shortcuts

#### Step 2.3: Assign Remediation Script to Floor 6 Devices
**Action:**
1. On the **Assignments** page, click **Add groups**
2. Select **Floor 6 device group** (or equivalent Floor 6 AD group synced to Intune)
3. Confirm assignment target shows Floor 6 only
4. Click **Save** and then **Create**
5. Script deployment queued for Floor 6 devices

**Expected Result:**
- Remediation script created with ID displayed (record for tracking)
- Script status shows "Deploying" or "Pending deployment"
- Floor 6 devices receive script within 30 minutes of check-in

#### Step 2.4: Monitor Remediation Execution
**Action:**
1. Navigate to **Devices** → **Remediation scripts**
2. Select the newly created remediation script
3. Click **Device status** or **Remediation status**
4. Monitor execution results:
   - Green (Success): Shortcuts restored on that device
   - Red (Failed): Investigation required; review error message
   - Gray (Pending): Device has not checked in yet
5. Allow 90 minutes for full deployment across all Floor 6 devices

**Expected Result:**
- Majority of Floor 6 devices show green status within 90 minutes
- Failed devices logged for manual follow-up (see Verification section)
- Confirm that shortcuts appear on user desktops at next logon or after user-triggered sync

---

## Verification

### User-Facing Verification
1. **Self-Check (for Floor 6 users):**
   - Users check desktop for restored shortcuts after remediation deployment completes
   - Expected outcome: Document Management App shortcut visible on desktop
   - Timeline: Visible within 1–2 hours post-deployment (after device sync or logon)

2. **Device Sync Trigger:**
   - Users can manually trigger sync if shortcuts do not appear immediately:
     - **Settings** → **Accounts** → **Access work or school** → Select work/school account → **Sync**
   - Expected outcome: Shortcuts appear within 15 minutes of manual sync

3. **Spot Check (Service Desk):**
   - Randomly select 3–5 Floor 6 devices and verify:
     - Shortcuts present on user desktops
     - Document Management App launches correctly from shortcut
     - No duplicate shortcuts created
   - Expected outcome: All spot-checked devices show restored, functional shortcuts

### Technical Verification
1. **Remediation Script Execution Report:**
   - In Intune, review **Device status** for remediation script
   - Verify that ≥95% of assigned Floor 6 devices show "Success" status
   - Expected outcome: Success rate ≥95%; document any failures for root-cause review

2. **Audit Log Check (to confirm if available):**
   - Query Intune audit logs for remediation script deployment and execution records
   - Expected output: Deployment timestamps, execution counts, success/failure breakdown

3. **Device Inventory Correlation:**
   - Confirm that Floor 6 device group membership in Intune matches expected roster
   - Expected outcome: No unexpected devices in remediation scope; Floor 6 only

---

## Rollback Procedure

### Condition
Rollback is triggered if:
- Remediation script causes unintended side effects (e.g., performance degradation, duplicate shortcuts, app conflicts)
- Floor 6 users report functionality issues after remediation deployment
- Script success rate falls below 80%

### Rollback Steps

#### Step R.1: Suspend Remediation Script
**Action:**
1. In **Intune admin center**, go to **Devices** → **Remediation scripts**
2. Select the deployed shortcut remediation script
3. Click **Delete** or **Unassign** from Floor 6 device group
4. Confirm removal; script will not execute on new device check-ins

**Expected Result:**
- Remediation script unassigned from Floor 6
- Devices already remediated keep restored shortcuts (no reverse action)
- No further script executions occur on new device syncs

#### Step R.2: Communicate Rollback to Floor 6
**Action:**
1. Notify Floor 6 users that remediation has been paused pending review
2. Inform Service Desk teams to expect follow-up communication
3. Reassess root cause and script configuration

**Expected Result:**
- Floor 6 users informed; incident status updated

#### Step R.3: Deploy Temporary Shortcut Restoration via Group Policy (Alternative)
**Condition:** If script rollback required and shortcuts must be restored immediately.

**Action:**
1. Create or update a Group Policy Object (GPO) that restores baseline desktop shortcuts for Floor 6
2. Apply GPO to Floor 6 Organizational Unit in Active Directory
3. Force Group Policy refresh via `gpupdate /force` on Floor 6 devices (if AD-joined) or through Intune device management

**Expected Result:**
- Shortcuts restored via GPO; independent of Intune remediation script
- Allow 2–4 hours for GPO propagation across Floor 6 devices

#### Step R.4: Root Cause Review
**Action:**
1. Review remediation script configuration and test results
2. Validate app path, executable name, and shortcut settings
3. Correct script and re-test in pilot environment before re-deployment
4. Document findings and corrected script in incident closure

**Expected Result:**
- Root cause of issues documented
- Corrected script ready for re-deployment (if applicable)

---

## Contacts & Escalation

- **Intune Administration:** [Intune admin team contact — to confirm]
- **Document Management App Vendor:** [Vendor support — to confirm]
- **Floor 6 Management:** [Floor 6 manager contact — to confirm]
- **Service Desk Escalation:** [L2/L3 contact — to confirm]

---

## Post-Incident Actions

1. Confirm completion of all Phase 1 and Phase 2 steps with sign-off from Intune admin
2. Document actual app path, executable name, and final remediation script version used
3. Archive remediation script configuration for future reference and re-use
4. Update Floor 6 device baseline documentation to include shortcut count and list
5. Schedule post-incident review within 3 business days

---

## Change Log
| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0 | 2026-08-14 | DWP Service Desk | Initial runbook creation |
