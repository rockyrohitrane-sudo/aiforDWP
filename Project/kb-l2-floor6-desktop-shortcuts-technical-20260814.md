# KB: Floor 6 Desktop Shortcuts Restoration — Technical Deep Dive
**Version:** 1.0  
**Date:** 2026-08-14  
**For:** L2/L3 engineers, Intune administrators  

---

## Overview

Floor 6 users experienced missing desktop shortcuts following Friday's document management app deployment. Root cause: post-install script removed `*.lnk` files from user profiles. This KB provides technical investigation, remediation execution, and preventive control guidance based on the master runbook (runbook-floor6-desktop-shortcuts-restoration-20260814.md).

---

## Root Cause Analysis

### Confirmed Finding
Document management app post-install script executed with elevated privileges and removed or altered `.lnk` (shortcut) files in user profile directories (`%USERPROFILE%\Desktop`).

### Investigation Path
1. **Deployment Package Source:** App package deployed via Intune contains embedded post-install script OR separate Intune configuration profile contains post-deployment task
2. **Script Execution Scope:** Script ran in system context (SYSTEM) with no user-specific profile checks; deleted/modified all `.lnk` files matching retention/cleanup logic
3. **Affected User Set:** All Floor 6 users with devices that received Friday's deployment; scope to confirm via Intune deployment report

### Evidence Trail
- Intune app deployment audit log: document management app deployment timestamp and target group
- Device-side: Verify `C:\Windows\Temp\` and system event logs for script execution records (Event ID 4688 for process creation if auditing enabled)
- User report: Paralegal reported missing shortcuts immediately post-deployment Friday morning

---

## Technical Remediation Strategy

### Phase 1: Root Cause Elimination

#### Option A: Embedded Script in App Package
**If script is bundled within the app package:**
1. Contact app vendor (to confirm: specific contact and SLA)
2. Request patched app package that excludes shortcut-removal logic
3. Stage corrected package in Intune app library
4. Deploy Phase 2 remediation (below) while awaiting corrected package
5. Once corrected package available, supersede existing deployment

**Vendor Validation Checklist:**
- Confirm post-install script behavior in package documentation
- Obtain patched package version and MD5/SHA256 hash for verification
- Validate patched version in test environment before Fleet rollout

#### Option B: Separate Configuration Profile
**If script is deployed via Intune configuration profile or startup task:**
1. Navigate **Intune admin center** → **Devices** → **Configuration profiles**
2. Identify profile assigned to Floor 6 device group (e.g., "Floor 6 post-deployment tasks")
3. Edit profile and remove PowerShell script or startup task step that targets `*.lnk` removal
4. Save and trigger redeployment to Floor 6 device group
5. Confirm updated profile deployment status within 30 minutes

### Phase 2: Shortcut Restoration via Remediation Script

#### Detection Script
```powershell
$deskPath = [System.Environment]::GetFolderPath('Desktop')
$shortcuts = Get-ChildItem -Path $deskPath -Filter "*.lnk" -ErrorAction SilentlyContinue
$shortcutCount = ($shortcuts | Measure-Object).Count

# Threshold: 3+ shortcuts expected for Floor 6 baseline
# Adjust per actual baseline count (to confirm exact Floor 6 standard)
if ($shortcutCount -lt 3) {
    Write-Output "Shortcut deficiency detected: $shortcutCount found; expected 3+"
    exit 1  # Remediation required
} else {
    Write-Output "Shortcut count baseline met: $shortcutCount"
    exit 0  # Compliant
}
```

**Execution Model:**
- Runs in user context (no elevation required)
- Scans `%USERPROFILE%\Desktop` for `.lnk` files
- Executes evaluation at device check-in; triggers remediation if count below threshold

#### Remediation Script
```powershell
$deskPath = [System.Environment]::GetFolderPath('Desktop')
$appInstallPath = "C:\Program Files\DocumentManagementApp"  # To confirm exact path
$appExecutable = "DocumentApp.exe"  # To confirm exact executable name
$shortcutDisplayName = "Document Management App"

# Validate app installation before creating shortcut
if (Test-Path -Path $appInstallPath) {
    $shortcutTarget = "$deskPath\$shortcutDisplayName.lnk"
    
    # Check if shortcut already exists to prevent duplicates
    if (-not (Test-Path -Path $shortcutTarget)) {
        try {
            # Create shortcut using COM object (WScript.Shell)
            $wshShell = New-Object -ComObject WScript.Shell
            $shortcut = $wshShell.CreateShortcut($shortcutTarget)
            
            # Set shortcut properties
            $shortcut.TargetPath = "$appInstallPath\$appExecutable"
            $shortcut.WorkingDirectory = $appInstallPath
            $shortcut.IconLocation = "$appInstallPath\$appExecutable,0"
            $shortcut.Description = "Restores Floor 6 document management app shortcut"
            
            # Save shortcut
            $shortcut.Save()
            
            Write-Output "Shortcut created successfully: $shortcutTarget"
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($wshShell) | Out-Null
            exit 0  # Success
        } 
        catch {
            Write-Output "Error creating shortcut: $($_.Exception.Message)"
            exit 1  # Failure
        }
    } 
    else {
        Write-Output "Shortcut already exists: $shortcutTarget (no action required)"
        exit 0  # Already compliant
    }
} 
else {
    Write-Output "App installation path not found: $appInstallPath"
    exit 1  # Failure (app not installed)
}
```

**Execution Model:**
- Runs in system context during device compliance check
- Creates `.lnk` file in user profile desktop directory
- Executes once per device; creates shortcut only if not present
- Returns exit code 0 (compliant) or 1 (remediation required/failed)

#### Deployment in Intune
1. **Intune admin center** → **Devices** → **Remediation scripts** → **Create script**
2. Enter detection script (above)
3. Enter remediation script (above), with customizations:
   - Replace `C:\Program Files\DocumentManagementApp` with actual install path
   - Replace `DocumentApp.exe` with actual executable name
   - Adjust shortcut threshold in detection script to match Floor 6 baseline count
4. **Assignments:** Select Floor 6 device group
5. **Schedule:** Deploy immediately (standard Intune assignment)
6. **Monitoring:** Navigate to **Remediation scripts** → [script name] → **Device status** to track execution

---

## Monitoring & Troubleshooting

### Execution Monitoring
- **Success Metrics:** ≥95% of Floor 6 devices show "Compliance: Remediated" within 90 minutes
- **Tracking:** Intune dashboard → Devices → Remediation scripts → Device status report
- **Expected Timeline:** 
  - Deployment queued: immediate
  - Device check-in and execution: 15–30 minutes per device
  - Full Floor 6 scope: 60–90 minutes

### Failure Investigation
| Failure Signal | Diagnosis | Resolution |
|---|---|---|
| Device status shows "Failed" | Script execution error; review error message | Validate app path, executable name, user permissions; re-run script or manual deployment |
| Shortcut not appearing on user desktop after script success | Script executed but user logon not yet triggered; cache/profile not refreshed | Instruct user to manually sync via Settings → Accounts → Sync or restart device |
| Detection script returns "1" (non-compliant) after remediation "Success" | Shortcut threshold misconfigured in detection script | Review and adjust threshold in detection script; redeploy corrected script |
| Duplicate shortcuts created | Script ran multiple times for same user; insufficient duplicate prevention logic | Rollback and refine deduplication logic in remediation script; increment version and redeploy |

### Device-Side Verification
Connect to affected Floor 6 device via RDP or remote support; execute diagnostic script:
```powershell
# Check desktop shortcuts
$deskPath = [System.Environment]::GetFolderPath('Desktop')
Get-ChildItem -Path $deskPath -Filter "*.lnk" | Select-Object Name, FullPath, LastWriteTime

# Verify app installation
Test-Path "C:\Program Files\DocumentManagementApp"
Get-ChildItem "C:\Program Files\DocumentManagementApp" -ErrorAction SilentlyContinue

# Check Intune remediation script execution logs (if available)
Get-ChildItem "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\" -Filter "*Remediation*" | 
  Select-Object Name, LastWriteTime | Sort-Object LastWriteTime -Descending | Select-Object -First 5
```

---

## Rollback Procedure

### Trigger Criteria
- Script causing unintended side effects (performance, app conflicts, duplicate shortcuts >5% of devices)
- Success rate drops below 80% after first 90 minutes
- User complaints of functionality degradation post-remediation

### Rollback Steps
1. **Suspend Intune Script:** **Devices** → **Remediation scripts** → Select script → **Unassign** from Floor 6 device group
2. **Notify IT Teams:** Communicate rollback status; pause user-facing communications
3. **Preserve Shortcuts:** Unassignment does NOT remove already-created shortcuts; users retain restored shortcuts
4. **Alternative Remediation:** Deploy Group Policy (if AD-joined Floor 6 devices) to restore shortcuts via GPO instead:
   ```powershell
   # GPO: Set registry or run startup script to create standard shortcuts
   # Apply to Floor 6 OU; force gpupdate /force on affected devices
   ```
5. **Root Cause Review:** Re-validate app path, executable name, user permissions; correct script; re-test in pilot
6. **Redeploy:** Version script as 1.1; redeploy with corrected configuration

---

## Preventive Controls

### Immediate (Post-Incident)
1. **App Vendor Review:** Obtain commitment from document management app vendor to exclude shortcut-removal from future releases
2. **Deployment Dry-Run:** Implement pre-deployment test lab run on representative Floor 6 device before fleet deployment
3. **Change Review Requirement:** Require peer review and sign-off for any Intune profile changes targeting Floor 6

### Medium-Term
1. **Effective-Access Audits:** Quarterly audit of Floor 6 user desktop configurations against approved baseline
2. **Remediation Script Versioning:** Maintain version control and change log for remediation scripts; document Floor 6 baseline in IT system of record
3. **Detection Threshold Tuning:** Update Floor 6 shortcut baseline in detection script based on post-remediation validation

### Long-Term
1. **Governance Process:** Enforce change control for app deployments that modify user profiles or desktop configurations
2. **Alerting & Monitoring:** Implement proactive monitoring for anomalous desktop configuration changes across high-risk user groups (e.g., legal, finance)
3. **Vendor SLA:** Document vendor post-install script behavior in procurement/evaluation criteria for future app selections

---

## Related Documentation
- **Master Runbook:** runbook-floor6-desktop-shortcuts-restoration-20260814.md (step-by-step implementation)
- **User KB (L1):** kb-l1-floor6-desktop-shortcuts-self-service-20260814.md (Floor 6 user guidance)
- **Related RCA:** rca-legal-floor6-copilot-access-20260814.md (incident context and governance findings)

---

## Change Log
| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0 | 2026-08-14 | DWP Service Desk | Initial technical KB creation; comprehensive remediation and troubleshooting guidance |

