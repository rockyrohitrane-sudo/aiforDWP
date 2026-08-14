# KB: Floor 6 Missing Shortcuts — Technical Deep Dive
**Version:** 1.0  
**Date:** 2026-08-14  
**For:** L2/L3 engineers, Intune administrators  

---

## Overview

Legal Floor 6 users (recently migrated to Windows 11 and Intune-enrolled) reported missing desktop shortcuts following Friday's document management app deployment. Root cause: deployment-scoped post-install script or Intune profile action removed or failed to create `.lnk` (shortcut) artifacts in user profile desktop directories. This KB provides technical investigation, remediation execution, monitoring, and preventive control guidance based on the master runbook (runbook-floor6-missing-shortcuts-remediation-20260814.md).

---

## Root Cause Analysis

### Confirmed Finding
Friday's document management app deployment introduced desktop shortcut removal or suppression on Floor 6 devices (recently migrated Win11 + Intune cohort).

### Investigation Indicators
1. **Temporal correlation:** Deployment Friday afternoon → symptoms reported Monday morning (overnight Intune policy sync window)
2. **Scope correlation:** Symptom isolated to Floor 6 cohort; not observed on other floors
3. **Artifact state:** User reports missing `.lnk` files in `%USERPROFILE%\Desktop` directory
4. **Cohort specificity:** Affects recently migrated Win11 + Intune fleet (limited pre-migration testing)
5. **Mitigation efficacy:** Restoring shortcuts via remediation script resolves complaint

### Likely Technical Mechanisms (To Confirm Per Investigation)
- **Post-install script action:** App installer's post-install script runs in elevated context and deletes `*.lnk` files matching cleanup/retention logic
- **Intune profile override:** Configuration profile or device enrollment action removes or redirects known shortcut locations
- **Path conflict:** Deployment changes desktop path settings or profile redirection, hiding shortcuts instead of deleting them
- **Policy processing:** Windows logon policy or Intune policy refresh deletes shortcuts as part of profile hardening or cache clear

### Evidence Collection (For Incident Recurrence)
If troubleshooting similar future incident, collect diagnostic data from affected devices:
```powershell
# Check for .lnk files in desktop directory
$deskPath = [System.Environment]::GetFolderPath('Desktop')
Get-ChildItem -Path $deskPath -Filter "*.lnk" | 
  Select-Object Name, FullPath, CreationTime, LastWriteTime

# List all user profile paths on device
Get-ChildItem "C:\Users" -Directory | 
  Select-Object Name, FullName

# Check file system ACLs on desktop directory
Get-Acl "$deskPath" | Format-List

# Query Intune app deployment history for this device
Get-ChildItem "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs" -Filter "*app*" | 
  Select-Object Name, LastWriteTime | Sort-Object LastWriteTime -Descending | Select-Object -First 5

# Check for recent file deletions via Event Log (Audit Policy required)
Get-EventLog -LogName "Security" -InstanceId 4663 -Newest 50 | 
  Where-Object { $_.Message -match "Desktop.*\.lnk" } | 
  Select-Object TimeGenerated, Message
```

---

## Technical Mitigation: Disable Script and Restore Shortcuts

### Intune Deployment Context
**Affected Deployment:**
- App: Document management application (to confirm: [exact product name and version])
- Deployment platform: Intune (to confirm: Win32, MSI, LOB type)
- Target: Floor 6 device group (to confirm: [exact Intune security group])
- Deployment date/time: Friday (to confirm: [exact timestamp and UTC offset])
- Assignment state: Required or Available (to confirm: [original assignment setting])

### Phase 1: Root Cause Elimination

#### Identifying Script Source

**Path A: Embedded Post-Install Script**
- Script bundled within app package installer
- Executes during app installation (system context or user context depending on app type)
- Action: post-install cleanup deletes `*.lnk` files or reconfigures desktop profile

**Investigation:**
```powershell
# Check app installation registry
Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | 
  Where-Object { $_.DisplayName -match "DocumentManagement" } | 
  Select-Object DisplayName, DisplayVersion, InstallLocation, UninstallString

# Check for post-install script residue in app folder
Get-ChildItem "C:\Program Files\DocumentManagementApp" -Filter "*script*", "*setup*", "*install*" -Recurse | 
  Select-Object FullName
```

**Remediation for Embedded Script:**
1. Contact app vendor → request corrected package that preserves shortcuts
2. While awaiting vendor fix, deploy shortcut restoration remediation script (Phase 2, below)
3. When corrected package available, update Intune app assignment for Floor 6

**Path B: Separate Intune Profile/Task**
- Post-deployment or startup task deployed via Intune configuration profile
- PowerShell script or scheduled task targets shortcut deletion/modification
- Executes at device startup or policy refresh cycle

**Investigation:**
```powershell
# List all Intune assignments and profiles on device
Get-ChildItem "HKEY_LOCAL_MACHINE\Software\Microsoft\Enrollment" -Recurse | 
  Select-Object Name

# Check for custom startup/scheduled tasks
Get-ScheduledTask | 
  Where-Object { $_.TaskPath -match "Microsoft\Windows|Custom" } | 
  Select-Object TaskName, TaskPath, State | 
  Format-Table -AutoSize

# Look for post-deployment scripts
Get-ChildItem "C:\Windows\Temp" -Filter "*Floor6*", "*Shortcut*", "*Deploy*" | 
  Select-Object Name, LastWriteTime
```

**Remediation for Separate Profile:**
1. In Intune admin center → **Devices** → **Configuration profiles** → find Floor 6 profile
2. Edit profile and remove or disable shortcut-deletion step/script
3. Save changes; updated profile deploys to Floor 6 within 30 minutes

### Phase 2: Shortcut Restoration via Remediation Script

#### Detection Script Deployment
Runs in Intune's compliance/remediation cycle; evaluates shortcut state:

```powershell
$deskPath = [System.Environment]::GetFolderPath('Desktop')
$shortcuts = Get-ChildItem -Path $deskPath -Filter "*.lnk" -ErrorAction SilentlyContinue
$shortcutCount = ($shortcuts | Measure-Object).Count

# Floor 6 baseline: 3+ shortcuts expected
# Adjust threshold per actual Floor 6 standard (to confirm: document baseline)
if ($shortcutCount -lt 3) {
    Write-Output "Shortcut deficit: $shortcutCount found (expected 3+)"
    exit 1  # Trigger remediation on this device
} else {
    Write-Output "Shortcut count OK: $shortcutCount"
    exit 0  # Device compliant; no remediation needed
}
```

**Execution Model:**
- Runs in user context (non-elevated) at device check-in
- Scans user's desktop (`%USERPROFILE%\Desktop`)
- Returns exit code 1 if below threshold → triggers remediation script

#### Remediation Script Deployment
Runs when detection script returns exit code 1 (shortcut deficit detected):

```powershell
$deskPath = [System.Environment]::GetFolderPath('Desktop')
$appInstallPath = "C:\Program Files\DocumentManagementApp"  # To confirm: actual path
$appExecutable = "DocumentApp.exe"  # To confirm: actual executable
$shortcutDisplayName = "Document Management App"  # User-facing name

# Verify app is installed
if (Test-Path -Path $appInstallPath) {
    $shortcutTarget = "$deskPath\$shortcutDisplayName.lnk"
    
    # Create shortcut only if not already present (deduplication)
    if (-not (Test-Path -Path $shortcutTarget)) {
        try {
            # Use WScript.Shell COM object for .lnk file creation
            $wshShell = New-Object -ComObject WScript.Shell
            $shortcut = $wshShell.CreateShortcut($shortcutTarget)
            
            # Configure shortcut properties
            $shortcut.TargetPath = "$appInstallPath\$appExecutable"
            $shortcut.WorkingDirectory = $appInstallPath
            $shortcut.IconLocation = "$appInstallPath\$appExecutable,0"
            $shortcut.Description = "Restored by Floor 6 shortcut remediation"
            
            # Save shortcut file
            $shortcut.Save()
            
            # Clean up COM object reference
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($wshShell) | Out-Null
            
            Write-Output "Shortcut successfully created: $shortcutTarget"
            exit 0  # Success
        } 
        catch {
            Write-Output "ERROR creating shortcut: $($_.Exception.Message)"
            exit 1  # Failure; log for manual investigation
        }
    } 
    else {
        # Shortcut already exists; no action needed
        Write-Output "Shortcut exists: $shortcutTarget (no action)"
        exit 0  # Compliant
    }
} 
else {
    # App not installed; cannot create shortcut
    Write-Output "ERROR: App path not found: $appInstallPath"
    exit 1  # Failure
}
```

**Execution Model:**
- Runs in system context at Intune device compliance check
- Creates `.lnk` file in each user's desktop directory
- Handles missing app gracefully (app uninstalled scenario)
- Deduplication prevents shortcut creation if already present

#### Intune Deployment Configuration
1. **Intune admin center** → **Devices** → **Remediation scripts** → **Create script**
2. Enter detection and remediation scripts (above)
3. Customize variables:
   - Set `$appInstallPath` to actual app installation directory
   - Set `$appExecutable` to actual executable filename
   - Adjust shortcut baseline threshold in detection script (currently `3`)
4. **Assignments:** Select Floor 6 device group
5. **Deployment mode:** Standard (no special timing required)
6. **Create** to deploy

**Client-Side Execution Timeline:**
- Assignment received: immediate in Intune
- Device policy sync: 5–15 minutes per device (varies by connectivity)
- Detection script runs: at next Intune compliance check
- Remediation trigger: if detection returns exit code 1
- Shortcut creation: within minutes of remediation script execution
- User visibility: next logon or after manual device sync

---

## Monitoring & Troubleshooting

### Success Signals
| Signal | Expected Value | Interpretation |
|--------|---|---|
| Intune remediation device status | ≥95% "Success" within 90 minutes | Scripts executed successfully; shortcuts created |
| Floor 6 shortcut support tickets | Drop to <1/hour after remediation | User reports indicate resolution |
| Affected device sample check | Shortcuts present and functional | Remediation effective across sample |
| App launch via shortcut | Works without error | Shortcuts properly configured and linked |

### Failure Investigation

| Failure Signal | Diagnosis | Resolution |
|---|---|---|
| Device status "Failed" (>10% of Floor 6) | Script error or environment issue | Review error message in Intune logs; check app path correctness; re-run manually on failing device |
| Shortcut not visible despite "Success" | Cache/profile not refreshed at user logon | Instruct user to restart device or log out/back in |
| Duplicate shortcuts created | Script ran multiple times or deduplication failed | Verify shortcut already-exists check in script; manual cleanup if needed |
| Script returns "1" (not installed app) | App uninstalled or path changed | Update script with correct app path; reverify app deployment state |
| Shortcut created but broken/non-functional | Incorrect app path or executable name in script | Correct script variables; redeploy remediation; test shortcut manually |

### Device-Level Verification (RDP/Remote Support)

```powershell
# Verify shortcut presence and properties
$deskPath = [System.Environment]::GetFolderPath('Desktop')
$shortcutPath = "$deskPath\Document Management App.lnk"

if (Test-Path $shortcutPath) {
    Get-Item $shortcutPath | Select-Object FullPath, CreationTime, LastWriteTime
    
    # Read shortcut target
    $shell = New-Object -ComObject WScript.Shell
    $link = $shell.CreateShortcut($shortcutPath)
    Write-Output "Target: $($link.TargetPath)"
    Write-Output "Working Dir: $($link.WorkingDirectory)"
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null
} else {
    Write-Output "Shortcut NOT found: $shortcutPath"
}

# Test app launch capability
Invoke-Item $shortcutPath  # Verify app launches without error

# Check Intune remediation execution logs
Get-ChildItem "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs" | 
  Where-Object { $_.Name -match "Remediation" } | 
  Sort-Object LastWriteTime -Descending | Select-Object -First 3
```

---

## Preventive Controls

### Immediate (This Week)
1. **Vendor Review:** Obtain commitment from document management app vendor to exclude shortcut-removal behavior from future releases
2. **Pre-Deployment Testing:** Establish test run on representative Floor 6 device configuration (Win11 + Intune) before fleet deployment
3. **Desktop Artifact Validation:** Add shortcut presence/count check to deployment acceptance criteria

### Medium-Term (30 Days)
1. **Deployment Rings:** Implement staged rollout (Ring 0 pilot → Ring 1 subset → full floor) with hold points
2. **Exit Criteria Gates:** Define measurable desktop integrity checks at each ring promotion
3. **Baseline Documentation:** Update Floor 6 device configuration standard to include expected shortcut count and list

### Long-Term (90 Days)
1. **Governance Enhancement:** Require peer review and sign-off for app deployments that modify user profiles or desktop
2. **Proactive Monitoring:** Implement alerting for anomalous desktop configuration changes on high-risk cohorts (legal, finance)
3. **Vendor SLA:** Document vendor post-install script behavior in procurement requirements for future app evaluations

---

## Related Documentation
- **Master Runbook:** runbook-floor6-missing-shortcuts-remediation-20260814.md (step-by-step implementation)
- **User KB (L1):** kb-l1-floor6-missing-shortcuts-self-service-20260814.md (Floor 6 user guidance)
- **Related RCA:** rca-legal-floor6-missing-shortcuts-20260814.md (incident context and CAPA tracking)

---

## Change Log
| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0 | 2026-08-14 | DWP Service Desk | Initial technical KB; shortcut remediation, monitoring, and preventive controls |

