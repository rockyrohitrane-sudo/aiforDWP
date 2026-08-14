# KB: Floor 6 Login/Performance Recovery — Technical Deep Dive
**Version:** 1.0  
**Date:** 2026-08-14  
**For:** L2/L3 engineers, Intune administrators  

---

## Overview

Legal Floor 6 users (recently migrated to Windows 11 and Intune-enrolled) experienced login failures and severe sign-in latency following Friday's document management app deployment. Root cause: deployment change introduced contention or compatibility issue in user sign-in flow on Win11 + Intune cohort. Mitigation: remove/suspend app assignment for Floor 6. This KB provides technical investigation, execution, monitoring, and preventive control guidance based on the master runbook (runbook-floor6-login-performance-recovery-20260814.md).

---

## Root Cause Analysis

### Confirmed Finding
Friday's document management app deployment introduced a login/sign-in path issue affecting Floor 6 users on recently migrated Windows 11 + Intune devices.

### Investigation Indicators
1. **Temporal correlation:** Deployment Friday afternoon → incident symptoms Monday morning (overnight Intune policy sync)
2. **Scope correlation:** Symptoms concentrated in Floor 6 device cohort; not observed elsewhere
3. **Symptom pattern:** Mixed hard login failures and extreme sign-in latency (not uniform)
   - Hard failures: users unable to reach desktop after password entry
   - Slow logons: users able to sign in but 5–10 minutes to reach functional desktop
4. **Cohort specificity:** Win11 + Intune recently migrated; likely limited pre-deployment validation on this configuration
5. **Mitigation efficacy:** Reverting app assignment resolves symptoms (strong corrective signal)

### Likely Technical Mechanisms (To Confirm)
- **Startup task contention:** App post-install script running in user context during sign-in, blocking logon completion or policy processing
- **Policy processing delay:** App deployment profile interacting with Windows 11 Group Policy extension or Intune policy refresh, causing sign-in timeout
- **Dependency/library conflict:** App or its dependencies conflicting with Win11 logon processes or Intune client agent
- **ACL or permission issue:** App installation or startup changing file permissions on logon-critical registry/file paths

### Evidence Collection (Diagnostic)
If repeating this incident, collect on affected devices:
```powershell
# Event log indicators of login issues
Get-EventLog -LogName Security -InstanceId 4625, 4771 -Newest 50 | 
  Select-Object TimeGenerated, Message | Where-Object { $_.TimeGenerated -gt [datetime]::Now.AddDays(-1) }

# Slow logon events (if diagnostic tracing enabled)
Get-EventLog -LogName "System" | 
  Select-Object TimeGenerated, Source, EventID, Message | 
  Where-Object { $_.Source -match "Logon|Group Policy" -and $_.TimeGenerated -gt [datetime]::Now.AddDays(-1) }

# Windows logon timing (from telemetry/Event ID 4692)
Get-EventLog -LogName "Security" -InstanceId 4692 -Newest 10 | 
  Select-Object TimeGenerated, Message

# Check startup delay log (Win11)
Get-Content "C:\Windows\System32\winevt\Logs\System.evtx" | 
  Select-String "Logon took.*seconds" | Select-Object -First 5

# Verify app installation and post-install script status
Get-ChildItem "C:\Program Files\DocumentManagementApp" -ErrorAction SilentlyContinue
Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | 
  Where-Object { $_.DisplayName -match "DocumentManagementApp" }
```

---

## Technical Mitigation: App Assignment Removal

### Intune Deployment Context
**Affected Deployment:**
- App: Document management app (to confirm: [exact name and product ID])
- Deployment platform: Intune (to confirm: Win32 app vs LOB vs SaaS)
- Target group: Floor 6 devices (to confirm: [exact Intune group name])
- Deployment date/time: Friday (to confirm: [exact timestamp])
- Assignment type: Required or Available (to confirm: [assignment setting])

### Mitigation Execution (Two Paths)

#### Path A: Permanent Removal (Recommended for Extended Recovery)
**Scenario:** App requires vendor patch before re-deployment; Floor 6 needs full removal and uninstall.

**Steps:**
1. Intune admin center → **Apps** → **All apps** → document management app
2. **Assignments** tab → Locate Floor 6 device group row
3. Click **...** (more options) → **Remove**
4. Confirm "Remove Floor 6 from assignment"
5. Intune queues uninstall for next device check-in

**Client-Side Effect:**
- App uninstalled from all Floor 6 devices
- Registry entries and files removed (if uninstaller is clean)
- Intune assignment removed; app will not re-install until explicitly re-assigned

#### Path B: Deployment Pause (Temporary Suspension)
**Scenario:** Vendor working on fix; Floor 6 needs near-term suspension while corrected package is prepared.

**Steps:**
1. Intune admin center → **Apps** → **All apps** → document management app
2. **Assignments** tab → Click **Edit** pencil on Floor 6 assignment
3. Change **Assignment intent** from "Required"/"Available" to **"Uninstall"**
4. **Save** and confirm
5. Intune queues app uninstall for Floor 6 devices

**Client-Side Effect:**
- App uninstalled from Floor 6 devices within 5–30 minutes
- Once uninstall completes, devices show "App available but not assigned"
- Reassignment can be triggered at any time (when corrected package ready)

### Device Check-In and Execution Timeline

**Trigger:** Devices check in to Intune within 5–15 minutes of policy change (varies by connectivity/network)

**Sync Acceleration (Optional):**
```powershell
# Force immediate sync on specific device (from Intune remote actions)
# OR manually on device:
# Settings → Accounts → Access work or school → [work account] → Sync

# PowerShell (device-side, admin):
Start-Process "C:\Program Files\Microsoft Intune Management Extension\Microsoft.Management.Services.IntuneWindowsAgent.exe" -ArgumentList "/DoSyncCycleAndReportOnSuccess"
```

**Uninstall Execution:**
- Intune Management Extension fetches new policy (app assignment removed)
- Runs app uninstaller if app supports uninstall action
- On next device restart or immediate (depending on app type), app removed

**Post-Uninstall State:**
- `Test-Path "C:\Program Files\DocumentManagementApp"` returns `$false`
- App no longer appears in **Settings** → **Apps** → **Apps & features**
- Intune compliance records "App uninstalled successfully"

### Monitoring Deployment Status

**In Intune:**
1. **Devices** → **All devices** → Search Floor 6 device
2. **Managed apps** tab → Locate document management app
3. Check status:
   - "Uninstall in progress" → Device recognized assignment change, working to remove
   - "Not applicable" or "Not installed" → Uninstall complete on this device
   - "Failed" → Uninstall failed; review error message (usually permission/dependency issue)

**Bulk Status View:**
1. **Apps** → **All apps** → [document management app]
2. **Device status** → Filter by Floor 6 device group
3. Status breakdown shown (devices uninstalled, pending, failed)

**Expected Timeline:**
- Assignment removal: immediate in Intune console
- Device policy sync: 5–15 minutes per device
- Uninstall completion: 15–60 minutes depending on app size and device load
- Full Floor 6 scope (30–40 devices typical): 60–120 minutes for all to complete

---

## Monitoring & Troubleshooting

### Success Signals
| Signal | Expected Value | Interpretation |
|--------|---|---|
| Intune device compliance for Floor 6 | ≥85% devices "Compliant" within 2 hours | Devices successfully synced and executed policy |
| Login failure tickets from Floor 6 | Drop to <1 ticket/hour within 1 hour | User access restored; incident resolved |
| Average sign-in duration (Floor 6 sample) | Return to baseline ~30–45 seconds | Sign-in path unblocked |
| Device status for app | "Not installed" or "Not applicable" ≥90% | Successful uninstall across Floor 6 |

### Failure Investigation

| Failure Signal | Diagnosis | Resolution |
|---|---|---|
| Devices stuck in "Uninstall in progress" >2 hours | Device offline, policy sync stuck, or uninstaller hang | Manual RDP to device; check Intune agent status; run uninstall manually; restart device |
| Uninstall status shows "Failed" on >10% devices | Insufficient permissions, file locked, or missing uninstaller | Identify affected devices; check app uninstall registry; review Event logs for specific error code |
| Users report login still slow after app shows "Not installed" | App residue or policy cache not refreshed | Instruct users to restart device; cache clears on restart; re-verify sign-in time |
| "Not applicable" status but app still appears in Add/Remove Programs | Partial uninstall or registry corruption | Manual app removal via Control Panel; or script removal: `wmic product where name="DocumentManagementApp" call uninstall /nointeractive` |

### Device-Level Verification
Connect to Floor 6 device via RDP or remote support; run diagnostic:
```powershell
# Verify app removal
Test-Path "C:\Program Files\DocumentManagementApp"
Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | 
  Where-Object { $_.DisplayName -match "Document" }

# Check Intune agent status
Get-Service -Name "IntuneManagementExtension" | Select-Object Status, StartType
Get-ChildItem "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\" | 
  Sort-Object LastWriteTime -Descending | Select-Object -First 5

# Verify logon performance (baseline in seconds)
Get-EventLog -LogName "System" -Source "Microsoft-Windows-Diagnostics-Performance" | 
  Select-Object -First 1 TimeGenerated, Message

# Test manual sign-out/sign-in
# Manually sign out and back in; measure time from password entry to desktop ready
```

---

## Rollback of Rollback (Contingency)

### Reverse-Rollback Triggers
- App uninstall paradoxically worsens login issues (e.g., missing dependency)
- Users report new errors after app removal (e.g., "Application X cannot start")
- Device compliance drops below pre-mitigation baseline
- Platform owner requests reversal

### Reverse Steps
1. **Re-enable assignment:** Intune → **Apps** → **All apps** → [app] → **Assignments** → **Add groups** → Floor 6
2. **Set assignment to "Required"** (to re-install)
3. **Save** and confirm
4. Force device sync on sample Floor 6 devices
5. **Notify Floor 6:** "We've restored the original software. Please restart your device."
6. **Escalate:** Contact vendor, endpoint engineering, and change management immediately for root-cause investigation

### Preventive Actions from RCA

**Immediate (This Week)**
- Require staged deployment rings (Ring 0 pilot → Ring 1 subset → full floor) with health-check gates
- Add login success rate and sign-in latency metrics to pre/post rollout validation checklist
- Enforce explicit rollback criteria in change records (threshold triggers + approver path)

**Medium-Term (Next 30 Days)**
- Flag recently migrated Win11 + Intune cohorts as high-sensitivity for app rollouts
- Require additional observation window (2–4 hours) before full-floor promotion
- Update deployment validation runbook with Floor 6 baseline (sign-in duration, failure rate)

**Long-Term (Next 90 Days)**
- Implement proactive monitoring/alerting for cohort-specific login anomalies
- Add vendor SLA language for pre-deployment validation on newly migrated platforms
- Establish change governance requiring peer review and sign-off for floor-scoped app changes

---

## Related Documentation
- **Master Runbook:** runbook-floor6-login-performance-recovery-20260814.md (step-by-step execution)
- **User KB (L1):** kb-l1-floor6-login-performance-self-service-20260814.md (Floor 6 user guidance)
- **Related RCA:** rca-legal-floor6-login-performance-20260814.md (incident context and preventive measures)

---

## Change Log
| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0 | 2026-08-14 | DWP Service Desk | Initial technical KB; app rollback mitigation, monitoring, and preventive controls |

