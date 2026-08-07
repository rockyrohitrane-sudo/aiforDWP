# Version Header

| Field | Value |
|------|-------|
| Title | RCA - Shared Drives Inaccessible - Finance Users (All DESKTOP-FB*) |
| Version | 1.0 |
| Date | 07/08/2026 |
| Author | Rohit |
| Reviewed | Self |
| Status | Draft |
| Change | Initial version from RCA |

# RCA - Shared Drives Inaccessible - Finance Users (All DESKTOP-FB*) - 2026-08-07

## Incident Summary
- **Incident:** All Finance users unable to access shared drive S: (`\\finbridge-fs01\Finance`) on logon.
- **Affected users:** 45 Finance users (all DESKTOP-FB* devices, OU=Finance).
- **Start time:** ~08:00 (coincides with peak morning logon window).
- **Recovery confirmed:** 09:09.
- **Final status:** Resolved.

---

## Impact Assessment
- **Affected users:** 45 Finance users — full Finance department.
- **Affected resource:** Shared drive S: mapped to `\\finbridge-fs01\Finance`.
- **Scope:** All Finance devices (DESKTOP-FB*) — platform-wide for this OU.
- **Business impact:** Complete loss of shared drive access for the Finance team from ~08:00 until resolution at 09:09. Duration approximately 69 minutes. All users reliant on S: for morning work were blocked.
- **Data loss:** None confirmed. Drive mapping failure only; the underlying share and data remained intact.

---

## Problem Statement
At approximately 08:00, all 45 Finance users lost access to their shared drive (S:) on logon. Investigation revealed that the Intune PowerShell script responsible for mapping the drive (`Map-FinBridgeDrives.ps1`) was executing under the SYSTEM account before the Windows Workstation service had entered a running state. UNC path access requires the Workstation service; because the script executed 2 seconds before the service was ready, every drive mapping attempt failed silently with exit code 1. No change was declared on the day — the underlying fault was introduced by a migration change on 2024-03-14 that moved the drive mapping from a GPO logon script (USER context) to an Intune PowerShell script (SYSTEM context) without updating the script to handle the new execution environment.

---

## Supporting Evidence

### Failure Evidence During Incident

1. **08:00:01 — ScriptRunner Info**
   - `Executing: Map-FinBridgeDrives.ps1`
   - Confirms Intune Management Extension triggered the script at the start of the logon sequence.

2. **08:00:02 — ScriptRunner Info**
   - `Script context: SYSTEM account`
   - Confirms the script ran under SYSTEM, not the logged-on user.

3. **08:00:03 — ScriptRunner Warning**
   - `Network path \\finbridge-fs01\Finance not accessible from SYSTEM context at execution time`
   - Key evidence: failure is explicitly attributed to SYSTEM context, not server unavailability.

4. **08:00:03 — ScriptRunner Error**
   - `Script Map-FinBridgeDrives.ps1 failed. Exit code: 1. Error: Network name cannot be found.`
   - `No retry configured.` (08:00:04)
   - Script terminates with no retry; drive mapping is abandoned for the session.

5. **08:00:05 — System Log, Service Control Manager, Event 7036**
   - `Workstation service entered running state.`
   - Critical timing: the Workstation service — required for UNC path resolution — came online **2 seconds after** the script had already failed and exited.

6. **08:00:06 — System Log, GroupPolicy, Event 1500**
   - `Group Policy settings processed successfully.`
   - Eliminates GPO failure, AD connectivity failure, and Kerberos issues as contributing causes.

7. **08:00:07 — System Log, Ntfs, Event 98 Warning**
   - `File system could not map drive letter S: Drive letter has not been assigned.`
   - End-state confirmation: S: was never assigned to the user session.

### Prior Change Record (Contributing Cause)

- **Date:** 2024-03-14 23:30
- **Change:** Drive mapping script migrated from GPO logon script (runs as USER, post-desktop) to Intune PowerShell script (runs as SYSTEM, early logon sequence).
- **Gap:** Script was not updated to handle SYSTEM context. No verification was performed that UNC paths were accessible at the point of SYSTEM-context execution. This change was not declared as a live change on 2026-08-07 but is the root configuration fault enabling the incident.

### Recovery and Validation Evidence

8. **09:09 — User verification**
   - Resolution applied (Intune script set to run as logged-on user credentials).
   - User signed out and back in to a Finance device (DESKTOP-FB*).
   - Intune portal confirmed script result: **Success**.
   - `net use` confirmed: `S: \\finbridge-fs01\Finance — OK`.
   - NTFS Event 98 absent from System log.
   - User confirmed successful access to shared drive; no issues reported.

---

## Incident Timeline

| Time | Event |
|------|-------|
| 2024-03-14 23:30 | **Root cause introduced:** Drive mapping migrated from GPO logon script (USER) to Intune script (SYSTEM). Script not updated to handle SYSTEM context or service dependency ordering. |
| 2026-08-07 ~08:00 | Finance users begin morning logon. Intune script executes. |
| 08:00:01 | `Map-FinBridgeDrives.ps1` triggered by Intune Management Extension. |
| 08:00:02 | Script confirmed running as SYSTEM account. |
| 08:00:03 | Script attempts UNC path `\\finbridge-fs01\Finance` — **fails**. Workstation service not yet running. Error: "Network name cannot be found." |
| 08:00:04 | Script exits with code 1. No retry configured. Drive mapping abandoned. |
| 08:00:05 | Workstation service enters running state — **2 seconds too late**. |
| 08:00:06 | GP processes successfully — confirms AD/Kerberos and network path to DC healthy. |
| 08:00:07 | NTFS Event 98 logged — S: drive letter not assigned. |
| ~08:00 onwards | 45 Finance users complete logon with no S: drive. Incident begins. |
| ~08:00–08:xx | Incident reported to service desk. Triage initiated. |
| ~08:xx | Scope confirmed: all Finance users on DESKTOP-FB* devices affected. No change declared. |
| ~08:xx | Hypothesis analysis performed. Event log evidence reviewed. Four hypotheses eliminated. H5 (script execution context) identified as root cause. |
| ~09:00 | Resolution applied: Intune portal — `Map-FinBridgeDrives.ps1` set to *"Run using logged on credentials"* → **Yes**. Script re-assigned to Finance group. |
| 09:09 | User signs back in. S: drive maps successfully. User confirms access. **Incident resolved.** |

---

## Root Cause Determination

### Primary Root Cause
The Intune PowerShell script `Map-FinBridgeDrives.ps1` was configured to execute under the **SYSTEM account** during the early logon sequence, before the Windows **Workstation service** had entered a running state. UNC path access (`\\finbridge-fs01\Finance`) is dependent on the Workstation service. The script executed at 08:00:03; the service was not ready until 08:00:05. Every drive mapping attempt failed deterministically with no retry.

### Contributing Cause
The migration change on 2024-03-14 moved the drive mapping from a GPO logon script (which runs as the logged-on USER after the full desktop environment is available) to an Intune Management Extension PowerShell script (which runs as SYSTEM early in the logon sequence). The script was not updated to handle SYSTEM context constraints, and no pre-go-live check was performed to verify that UNC paths were accessible at the point of execution.

### Why Alternatives Were Excluded

| Hypothesis | Excluded By |
|-----------|-------------|
| File server / DFS unavailable | ScriptRunner Warning `08:00:03` is context-specific, not a server-down error |
| DNS resolution failure | No DNS client event (1014/1015) present; SYSTEM context issue provides a complete alternative explanation |
| AD / Kerberos failure | Event 1500 `08:00:06` — GP processed successfully; AD/Kerberos confirmed healthy |
| Network path break | Event 1500 `08:00:06` — DC connectivity confirmed; ScriptRunner error is context-scoped |

---

## 5 Whys Analysis

**1. Why could Finance users not access shared drive S:?**
Because drive letter S: was not mapped during their logon session — `net use` showed no mapping and NTFS Event 98 confirmed the drive letter was never assigned.

**2. Why was S: not mapped?**
Because the Intune script `Map-FinBridgeDrives.ps1` failed at 08:00:03 with exit code 1 and no retry was configured. The script exited before completing the `net use` mapping command.

**3. Why did the script fail?**
Because the script ran under the SYSTEM account at 08:00:03, attempted to access `\\finbridge-fs01\Finance` via UNC path, and the Windows Workstation service was not yet running. The Workstation service — which provides the redirector required for UNC path resolution — only entered running state at 08:00:05, two seconds after the script had already failed and exited.

**4. Why was the script running as SYSTEM at a point when the Workstation service was not available?**
Because when the drive mapping was migrated from a GPO logon script to an Intune Management Extension script on 2024-03-14, the execution context was changed from USER (runs after desktop is fully loaded) to SYSTEM (runs early in the logon sequence). The Intune script setting *"Run this script using the logged on credentials"* was left at **No** (the default). No adjustment was made to the script or its deployment to account for the different timing and context of SYSTEM execution.

**5. Why was the SYSTEM context issue not caught during or after the migration?**
Because there was no verification step in the migration process to confirm that the script functioned correctly end-to-end in the new execution context. The migration change was implemented without a post-deployment validation of drive mapping on an affected device, and no documentation or annotation was added to the script or Intune record to flag the context dependency. The fault remained latent until it produced a service-affecting incident at the next large-scale morning logon.

---

## Resolution Actions Applied

1. **Intune portal configuration change:**
   - Navigated to: Devices → Scripts → `Map-FinBridgeDrives.ps1` → Properties → Edit.
   - Set *"Run this script using the logged on credentials"* → **Yes**.
   - Set *"Run script in 64-bit PowerShell Host"* → **Yes**.
   - Saved and re-assigned to Finance device group (DESKTOP-FB*).

2. **Validation on pilot device:**
   - User signed out and back in on one Finance device.
   - Intune portal confirmed script result: **Success**.
   - `net use` output confirmed: `S: \\finbridge-fs01\Finance — OK`.
   - NTFS Event 98 absent from System log.
   - No ScriptRunner Warning or Error entries present.

3. **User confirmation at 09:09:**
   - Affected user logged in to Finance host.
   - Shared drive S: accessible.
   - No further issues reported.

---

## Preventive Actions

### 1 — Annotate the Intune script with execution context requirement
- Add a description note to `Map-FinBridgeDrives.ps1` in the Intune portal: *"Must run as logged-on user — SYSTEM context cannot access UNC paths before Workstation service is ready. Do not change 'Run using logged on credentials' to No."*
- **Owner:** Endpoint Engineering | **Due:** Within 5 business days.

### 2 — Update the GPO-to-Intune script migration runbook
- Add a mandatory pre-go-live checklist item: **verify execution context and service dependency ordering**.
- Specifically: for any script that accesses network resources (UNC paths, mapped drives, network shares), confirm the script runs as logged-on user OR includes an explicit service-readiness check before proceeding.
- **Owner:** Endpoint Engineering lead | **Due:** Within 10 business days.

### 3 — Post-deployment validation gate for all Intune script changes
- Mandate a sign-off test on one representative device before rolling out any Intune script change to a production group. Test must include: sign out, sign in, confirm expected outcome, review Intune script result status.
- **Owner:** Change Advisory process / Endpoint Engineering | **Due:** Add to CAB template within 10 business days.

### 4 — Add Proactive Remediation to detect missing S: drive
- Create an Intune Proactive Remediation that detects absence of S: on Finance devices and raises an alert (not auto-remap, to avoid masking future recurrence).
- Provides early warning if this regression appears again before it becomes a service-affecting incident.
- **Owner:** Endpoint Engineering | **Due:** Within 15 business days.

### 5 — Review all other Intune scripts for the same SYSTEM context pattern
- Audit all Intune PowerShell scripts in the estate for scripts that access network resources while running as SYSTEM. Remediate any found to have the same misconfiguration.
- **Owner:** Endpoint Engineering | **Due:** Within 20 business days.

---

## Verification of Effectiveness

### Immediate Verification (first 10 minutes)

1. **Confirm script succeeded in Intune (portal path):**
   - Open **Intune admin center**: `https://intune.microsoft.com`
   - Go to: **Devices** -> **Scripts and remediations** -> **Platform scripts** -> **Windows** -> `Map-FinBridgeDrives.ps1`
   - Open **Device status**.
   - Filter device name starts with `DESKTOP-FB`.
   - Expected result: target test device shows **Success** and the **Last run time** is after the fix timestamp.

2. **Confirm S: drive exists in user session (endpoint console):**
   - On the affected Finance endpoint, sign in as the user.
   - Open **Command Prompt** and run:
     - `net use s:`
   - Expected result: `Remote name` = `\\finbridge-fs01\Finance` and `Status` = `OK`.

3. **Confirm no script failure in Intune Management Extension logs (file path):**
   - On the endpoint, open:
     - `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log`
   - Search for `Map-FinBridgeDrives.ps1` and `Exit code`.
   - Expected result: no new `Exit code: 1` entries after fix time; run shows success path.

4. **Confirm required Windows services/log events (Event Viewer path):**
   - Open **Event Viewer** -> **Windows Logs** -> **System**.
   - Use **Filter Current Log...** and check Event IDs: `7036`, `98`.
   - Validate:
     - Event `7036` exists showing **Workstation service entered running state** during logon.
     - No new Event `98` entries for failed assignment of drive `S:` after fix time.

### User Validation (same session)

1. Ask user to open `S:` in File Explorer.
2. Ask user to open one known Finance file from `S:` and save a copy to confirm read/write.
3. Record user name, endpoint name, and validation time in ticket notes.

### Sustained Verification (5 business days)

1. Daily at 09:30, open Intune path:
   - **Devices** -> **Scripts and remediations** -> **Platform scripts** -> **Windows** -> `Map-FinBridgeDrives.ps1` -> **Device status**.
2. Confirm no `DESKTOP-FB*` device reports **Failed**.
3. If any failure appears, collect logs from:
   - `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log`
   - Event Viewer -> Windows Logs -> System (Event IDs `98`, `7036`)

---

## Rollback Procedure (under 3 minutes)

**Use this only if the new script setting causes broader login instability or incorrect drive mappings.**

### 3-Minute Rollback Steps

1. Open **Intune admin center**: `https://intune.microsoft.com`.
2. Go to: **Devices** -> **Scripts and remediations** -> **Platform scripts** -> **Windows** -> `Map-FinBridgeDrives.ps1`.
3. Select **Properties** -> **Edit**.
4. Set **Run this script using the logged on credentials** to **No** (reverts to pre-fix state).
5. Select **Review + save** -> **Save**.
6. Open **Assignments** and remove Finance target group (`DESKTOP-FB*` devices or Finance mapped group), then **Save**.
7. Document rollback timestamp in the incident ticket.

### Rollback Verification (2 checks)

1. In Intune, verify path:
   - **Devices** -> **Scripts and remediations** -> **Platform scripts** -> **Windows** -> `Map-FinBridgeDrives.ps1` -> **Properties**.
   - Confirm setting now shows **Run using logged on credentials: No**.
2. On one Finance endpoint, verify no new execution attempt after rollback:
   - `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log`
   - Search for latest `Map-FinBridgeDrives.ps1` run time; confirm no additional runs after unassignment window.

---

## Closure Statement

Incident is closed as resolved. Root cause was the Intune PowerShell script `Map-FinBridgeDrives.ps1` executing as SYSTEM before the Workstation service was available, causing all shared drive mapping to fail for 45 Finance users. The fault was introduced by a migration change on 2024-03-14 that changed execution context without updating the script or verifying end-to-end function. Resolution was confirmed at 09:09 by user logon validation. Five preventive actions have been raised to prevent recurrence and improve deployment practice.

---
*RCA Author: DWP Engineer | Incident Date: 2026-08-07 | Resolution Time: 09:09 | Document Date: 2026-08-07*
