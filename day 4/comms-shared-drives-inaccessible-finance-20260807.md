# Communications - Shared Drives Inaccessible - Finance Users (2026-08-07)

---

## Audience 1 — Non-technical Executive

Your team's access and data are safe — no data was lost or put at risk. This morning, 45 colleagues in Finance were unable to open their shared drive from around 08:00 because a background setup tool ran slightly too early before Windows was fully ready. The issue was identified and fixed; full access was confirmed at 09:09. This was caused by an incomplete update made during a previous system migration. No action is required from you or your team.

---

## Audience 2 — Affected End-user Team (Finance)

Hi team, this morning from around 08:00 you may have found your shared drive (S:) was missing when you logged in — this happened because a background tool that sets up your drive ran a moment too early before Windows was fully ready to connect it. The fix was applied and access was fully restored at 09:09. Your files were never at risk. If you sign in and the S: drive is still missing, please sign out and back in once. If the problem persists, contact the Service Desk straight away.

---

## Audience 3 — Engineer-to-Engineer Internal Note

**Incident:** Shared drive S: (`\\finbridge-fs01\Finance`) not mapped on logon — all Finance users  
**Scope:** 45 users, all DESKTOP-FB* devices (OU=Finance)  
**Window:** ~08:00 – 09:09, 2026-08-07  
**Declared change:** None on day. Root config fault introduced 2024-03-14.

---

### Root Cause

`Map-FinBridgeDrives.ps1` deployed via Intune Management Extension with *"Run using logged on credentials"* = **No** (SYSTEM context). Script executes at 08:00:03 during early logon. UNC path `\\finbridge-fs01\Finance` requires the Workstation service (LanmanWorkstation); that service entered running state at 08:00:05 — 2 seconds after the script had already failed and exited with code 1. No retry configured. Drive letter never assigned for the session.

**Contributing cause:** Migration change on 2024-03-14 23:30 moved this script from a GPO logon script (USER context, runs post-desktop) to Intune PowerShell (SYSTEM context, runs early logon sequence). Script body was not updated; execution context setting was left at default (SYSTEM). No post-deployment validation was performed on an affected device. Fault was latent from 2024-03-14 until surfaced at scale on 2026-08-07.

**Hypotheses eliminated by evidence:**

| Hypothesis | Eliminated by |
|-----------|--------------|
| File server / DFS unavailable | ScriptRunner Warning 08:00:03 — error is SYSTEM-context qualified, not server-down |
| DNS resolution failure | No DNS client Event 1014/1015; SYSTEM context provides complete alternative explanation |
| AD / Kerberos failure | GP Event 1500 08:00:06 — Group Policy processed successfully |
| Network path break | GP Event 1500 08:00:06 — DC reachability confirmed; ScriptRunner error is context-scoped |

---

### Evidence (all from DESKTOP-FB022, representative of all DESKTOP-FB*)

```
08:00:01  ScriptRunner  Info     Executing: Map-FinBridgeDrives.ps1
08:00:02  ScriptRunner  Info     Script context: SYSTEM account
08:00:03  ScriptRunner  Warning  Network path \\finbridge-fs01\Finance not accessible from SYSTEM context at execution time
08:00:03  ScriptRunner  Error    Script Map-FinBridgeDrives.ps1 failed. Exit code: 1. Error: Network name cannot be found.
08:00:04  ScriptRunner  Info     No retry configured.
08:00:05  SCM           Event 7036   Workstation service entered running state.
08:00:06  GroupPolicy   Event 1500   Group Policy settings processed successfully.
08:00:07  Ntfs          Event 98     Warning — File system could not map drive letter S: Drive letter has not been assigned.
```

---

### Action Taken

**Intune portal — `Map-FinBridgeDrives.ps1` properties edited:**
- *Run this script using the logged on credentials* → **Yes**
- *Run script in 64-bit PowerShell Host* → **Yes**
- Script re-assigned to Finance device group (DESKTOP-FB*)

This restores the same execution context and timing the original GPO logon script used. No changes to the script body were required.

---

### Verification

- Intune portal script result for Finance group: **Success**
- `net use` on pilot device: `S: \\finbridge-fs01\Finance  OK`
- NTFS Event 98 **absent** from System log post-fix
- No ScriptRunner Warning/Error entries present
- User confirmed shared drive accessible and no further issues at **09:09**

---

### Preventive Actions Required

1. **Annotate script in Intune portal** — add description: *"Must run as logged-on user. Do not set 'Run using logged on credentials' to No — SYSTEM context cannot access UNC paths before Workstation service is ready."* Owner: Endpoint Engineering. Due: 5 business days.

2. **Update GPO→Intune migration runbook** — add mandatory pre-go-live checklist item: for any script accessing network resources (UNC, mapped drives, shares), verify execution context is USER or include explicit Workstation service readiness check. Owner: Endpoint Engineering lead. Due: 10 business days.

3. **Enforce post-deployment validation gate** — all Intune script deployments to production groups must include a sign-out/sign-in test on one representative device with explicit confirmation of expected outcome before full rollout. Add to CAB template. Owner: Change Advisory / Endpoint Engineering. Due: 10 business days.

4. **Add Proactive Remediation for missing S: on Finance devices** — detection only (alert, no auto-remap) to provide early warning of regression before it becomes service-affecting. Owner: Endpoint Engineering. Due: 15 business days.

5. **Audit all other Intune scripts for SYSTEM context + network resource access** — identify any scripts in the same misconfigured state across the estate and remediate proactively. Owner: Endpoint Engineering. Due: 20 business days.

---

### If This Recurs

1. Check ScriptRunner entries in Intune Management Extension log — look for SYSTEM context warning against `Map-FinBridgeDrives.ps1`.
2. Verify Intune portal: *Run using logged on credentials* setting — if reverted to **No**, re-apply fix above.
3. Check Event 7036 timestamp vs. script execution timestamp — if Workstation service starts after script, context mismatch is back.
4. Confirm Event 98 absence post-fix.
5. Cross-reference any recent Intune script property changes in the audit log.

---
*Author: DWP Engineer | Incident Date: 2026-08-07 | Document Date: 2026-08-07*
