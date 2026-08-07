# Incident Analysis: Print Spooler Service Crash Loop
**Date of Incident:** 2024-03-15  
**Analysis Window:** 10:01:14 – 10:03:50  
**Analyst:** DWP Analyst  
**Document Created:** 2026-08-06  

---

## 1. Event ID Reference — What Each ID Records

| Event ID | Source | Level | What It Records |
|----------|--------|-------|-----------------|
| **7034** | Service Control Manager | Error | A service terminated unexpectedly. No recovery action is configured, or the recovery threshold has not yet been reached. Records how many times the crash has occurred in the current cycle. |
| **7031** | Service Control Manager | Error | A service terminated unexpectedly AND a configured recovery action (e.g. restart) has been triggered. Includes the delay before the corrective action is taken. This fires when the failure count crosses the threshold defined in the service's recovery settings. |
| **7023** | Service Control Manager | Error | A service terminated with a specific Windows error code. In this case the error is **"The specified module could not be found"** — meaning a required DLL or driver file is missing or inaccessible when the service attempts to start. |
| **7038** | Service Control Manager | Error | A service failed to log on under its configured account. Records the account name and the logon failure reason. Here the account is **NT AUTHORITY\SYSTEM** and the reason is a denied logon type, which is anomalous because SYSTEM has unrestricted local logon rights by default. |

---

## 2. Sequence of Events — Plain English Reconstruction

**10:01:14** — The Print Spooler service crashes for the **first time**. Windows records the unexpected termination but takes no automatic corrective action yet (Event 7034, count 1).

**10:01:45** — The Spooler crashes again (~31 seconds later), for the **second time**. Still no recovery action triggered (Event 7034, count 2).

**10:02:16** — A **third crash** occurs, ~31 seconds after the second. The consistent interval suggests the service is being restarted automatically at the OS or recovery-settings level between each failure, and is failing every time it comes up (Event 7034, count 3).

**10:02:47** — The Spooler crashes a **fourth time**. This time the service's built-in recovery policy fires: Windows will attempt a service restart after a 60-second delay (Event 7031, count 4).

**10:03:49** — After the 60-second restart delay, the Spooler attempts to start but terminates immediately with the error **"The specified module could not be found"** (Event 7023). This is a hard dependency failure — a DLL or driver component required by the Spooler cannot be located.

**10:03:50** — One second later, a second failure is logged: the Spooler is also **unable to log on as NT AUTHORITY\SYSTEM** due to a denied logon type (Event 7038). This is highly abnormal; the SYSTEM account should always have local logon rights.

---

## 3. Root Cause Analysis

### Most Likely Primary Cause: Corrupt or Missing Printer Driver DLL

**Evidence:**
- Event 7023 explicitly states *"The specified module could not be found"* — this is Windows error code 126 (`ERROR_MOD_NOT_FOUND`). The Print Spooler loads printer driver DLLs dynamically at startup from `%SystemRoot%\System32\spool\drivers\`. If a driver DLL is corrupt, deleted, or moved, the Spooler will fail immediately on restart with this exact error.
- The crash loop prior to Event 7023 (Events 7034 × 3 + 7031) shows the service failing repeatedly before recovery logic escalated — consistent with the Spooler loading successfully to a point and then hitting a bad DLL at runtime rather than at service start.

### Contributing Factor: Logon Rights Misconfiguration (Event 7038)

**Evidence:**
- Event 7038 reports that **NT AUTHORITY\SYSTEM** was denied the requested logon type. This is abnormal under standard Windows configuration — SYSTEM holds all local privileges by default.
- Possible causes:
  - A **Group Policy Object (GPO)** has been applied or modified that restricts the *"Log on as a service"* or *"Allow log on locally"* rights, inadvertently excluding or overriding the SYSTEM account.
  - A **security hardening script or CIS/NCSC baseline** was applied and incorrectly overwrote the `SeServiceLogonRight` policy, removing SYSTEM.
  - **Malware or a third-party tool** modified the Local Security Policy.
- This is a secondary blocker: even if the missing DLL were restored, the service would still fail to start until logon rights are corrected.

### Alternative Hypothesis: PrintNightmare-Related Artefact

The combination of missing DLL + SYSTEM logon denial in the Spooler context is consistent with post-exploitation artefacts from **CVE-2021-34527 (PrintNightmare)**. An attacker or a remediation script could have:
1. Removed malicious driver DLLs (leaving missing module references in the spooler registry)
2. Applied hardening that restricted SYSTEM logon rights as a mitigation

This should be investigated if the machine had recent security scans or if other indicators of compromise are present.

---

## 4. Impact Assessment

| Factor | Detail |
|--------|--------|
| **Service affected** | Print Spooler (spoolsv.exe) |
| **User impact** | All local and shared printing from this machine is unavailable |
| **Risk of persistence** | High — service cannot recover automatically due to two independent blockers |
| **Data loss risk** | Low — print jobs in queue may be lost; no data integrity impact |

---

## 5. Recommended Remediation Steps

**Step 1 — Identify the missing DLL**
```powershell
# Check Spooler driver registry for orphaned entries
Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Environments" -Recurse |
    Where-Object { $_.Name -like "*Drivers*" }
```
Cross-reference DLL paths in the registry against files present in `C:\Windows\System32\spool\drivers\`.

**Step 2 — Remove or repair orphaned printer driver**
```powershell
# List installed printer drivers
Get-PrinterDriver

# Remove a specific orphaned driver (replace 'DriverName' accordingly)
Remove-PrinterDriver -Name "DriverName"
```

**Step 3 — Restore missing system DLLs if applicable**
```cmd
sfc /scannow
DISM /Online /Cleanup-Image /RestoreHealth
```

**Step 4 — Restore SYSTEM logon rights via Group Policy**
- Open `gpedit.msc` → Computer Configuration → Windows Settings → Security Settings → Local Policies → User Rights Assignment
- Verify **"Log on as a service"** includes `NT AUTHORITY\SYSTEM` (or is not explicitly set, allowing default)
- If controlled by domain GPO, review the GPO applying to this OU in Group Policy Management Console

**Step 5 — Start the Spooler and validate**
```powershell
Start-Service Spooler
Get-Service Spooler | Select-Object Status, StartType
```

**Step 6 — Review for security indicators**
- Check `C:\Windows\System32\spool\drivers\` for unexpected or recently added DLLs
- Review Security event log for Event ID 4698 (scheduled task created) and 4688 (new process) around 10:01
- Cross-reference with EDR/AV logs for the same window

---

## 6. Evidence Summary

| Timestamp | Event ID | Key Evidence |
|-----------|----------|--------------|
| 10:01:14 | 7034 | Spooler crash #1 — no recovery yet |
| 10:01:45 | 7034 | Spooler crash #2 — ~31s interval confirms restart-then-crash loop |
| 10:02:16 | 7034 | Spooler crash #3 — loop continues |
| 10:02:47 | 7031 | Spooler crash #4 — recovery action triggered; 60s restart delay |
| 10:03:49 | 7023 | **Missing module** — root cause of crash loop confirmed |
| 10:03:50 | 7038 | **SYSTEM logon denied** — secondary blocker preventing recovery |

---

*Analysis produced as part of DWP IT analyst training — Day 3 incident reconstruction exercise.*
