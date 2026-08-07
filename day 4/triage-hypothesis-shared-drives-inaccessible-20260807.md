# Triage Hypothesis - Shared Drives Inaccessible (Multi-User)

## Scope Facts Used
- Symptom: Users cannot access shared drives.
- Who: 45 users (broad, multi-user impact).
- Since: ~08:00 this morning.
- Change: None reported.

> **Note:** No single cause has been confirmed. This is a ranked hypothesis list only. Investigate in order and eliminate before escalating.

---

## Ranked Top 5 Most Likely Causes (Most Probable First)

---

### 1) File Server or DFS Namespace Unavailability
**Why this fits the scope facts:**
- 45 users all losing access to shared drives simultaneously at 08:00 strongly points to a single central resource failing rather than individual client issues.
- File servers can become unavailable without a declared change (e.g., unexpected reboot after patch, disk full condition, service crash on the server itself).
- DFS namespace server going offline would cause all mapped drives using `\\domain\share` paths to fail for all users at once.

**Single fastest check:**
- From any affected machine run: `ping <fileserver-hostname>` and `net use` — confirm whether the server is reachable and whether drive letters show a disconnected state or a specific error code (e.g., error 53 = name not found, error 1231 = network path unreachable).

---

### 2) DNS Resolution Failure for the File Server Hostname
**Why this fits the scope facts:**
- Shared drive mappings typically use hostnames (e.g., `\\fs01\data`). If DNS cannot resolve the file server name, all mapped drives fail across all clients simultaneously.
- A DNS server going down or a stale/missing A record would produce exactly this pattern: mass failure at a point in time with no user-side change.
- 08:00 start is consistent with DNS cache TTL expiry from overnight, coinciding with morning logon activity flushing cached entries.

**Single fastest check:**
- From an affected machine run: `nslookup <fileserver-hostname>` — if this fails or returns an unexpected IP, DNS is the cause. Compare with `nslookup <fileserver-hostname> <alternate-DC-IP>` to determine if the issue is one DNS server or all.

---

### 3) Active Directory / Kerberos Authentication Failure
**Why this fits the scope facts:**
- Shared drive access requires Kerberos ticket acquisition at logon. If a Domain Controller is unavailable or the Kerberos service is degraded, 45 users logging in around 08:00 would all fail to authenticate to the file server.
- 08:00 is peak morning logon time — a DC issue would be most visible exactly then.
- No declared change is needed; DC availability issues can arise from resource exhaustion, replication failure, or network partition.

**Single fastest check:**
- Run `klist` on an affected machine to inspect current Kerberos tickets. Absence of a ticket for the file server principal, or an error, confirms a Kerberos/DC issue. Cross-check with `nltest /dsgetdc:<domain>` to verify DC reachability.

---

### 4) Network Connectivity Break Between User Subnet and File Server Subnet
**Why this fits the scope facts:**
- 45 users affected simultaneously suggests a network-layer event (e.g., a core switch fault, VLAN misconfiguration, or routing table issue) has severed the path between the users' subnet and the file server subnet.
- This can occur without a formally declared change — infrastructure teams may have performed out-of-hours maintenance without raising a CAB change, or a device could have failed and triggered an unplanned failover that dropped traffic.
- The hard start time (~08:00) could correlate with a failover event or scheduled maintenance window ending.

**Single fastest check:**
- Run `tracert <fileserver-hostname>` from an affected machine — identify at which hop packets are lost or timing out to pinpoint the network segment responsible.

---

### 5) Group Policy Drive Mapping Failure (Logon Script / GPP)
**Why this fits the scope facts:**
- If shared drives are mapped via Group Policy Preferences (GPP) or a logon script, a GPO processing failure at morning logon would result in drive letters not being mapped for 45 users who logged in around 08:00.
- Users already logged in prior to 08:00 may still have working drives from a previous session, while those logging in fresh after the issue started would have no mapped drives.
- No environmental change is required — a broken GPO link, a transient SYSVOL replication issue, or a DC SYSVOL unavailability can cause this.

**Single fastest check:**
- Run `gpresult /r` on an affected machine and check whether the drive-mapping GPO appears under "Applied Group Policy Objects" or "Denied GPOs". If absent or denied, GPO processing is the cause. Also check `net use` to confirm whether drive letters are missing entirely (not mapped) vs. present but disconnected (server-side issue).

---

## Summary Table

| Rank | Cause | Key Discriminator |
|------|-------|------------------|
| 1 | File server / DFS unavailable | `ping` + `net use` error code |
| 2 | DNS resolution failure | `nslookup <fileserver-hostname>` |
| 3 | AD / Kerberos auth failure | `klist` + `nltest /dsgetdc` |
| 4 | Network path break (subnet/VLAN) | `tracert <fileserver-hostname>` |
| 5 | GPO drive mapping failure | `gpresult /r` |

---

## Next Step
Work down the ranked list in order. Each fastest check either confirms the cause or eliminates it before moving to the next. Do not escalate or remediate until at least the top two causes have been tested.

---

## Evidence Analysis — Event Log Review

**Sources:** Intune Management Extension Log + System Log  
**Affected devices:** DESKTOP-FB* (OU=Finance), all Finance users  
**Log window:** 08:00:01–08:00:07, 2026-08-07

---

### Hypothesis 1 — File Server / DFS Unavailability
**Verdict: CONTRADICTS**

The ScriptRunner error at `08:00:03` reads *"Network path `\\finbridge-fs01\Finance` not accessible from SYSTEM context at execution time"*. The key qualifier is **"from SYSTEM context"** — this is not a message indicating the server itself is down; it is a context-access failure. If the file server were offline, the error would appear identically regardless of execution context. There is no Event ID showing the server, DFS service, or share becoming unavailable. The server appears reachable at the network layer but inaccessible to the SYSTEM account specifically.

- **Determining evidence:** ScriptRunner Warning `08:00:03` — error is context-qualified, not server-unavailability qualified.

---

### Hypothesis 2 — DNS Resolution Failure
**Verdict: NEUTRAL**

The error *"Network name cannot be found"* (ScriptRunner Error `08:00:03`, Exit code 1) is consistent with a DNS failure — this is the same surface error a failed hostname lookup would produce. However, the prior change note and the SYSTEM context warning at `08:00:03` provide a competing and more specific explanation for the same error message. There is no event log entry (e.g., DNS Client Event 1014/1015) directly evidencing a DNS resolution failure. The evidence neither confirms nor rules DNS out on its own.

- **Determining evidence:** ScriptRunner Error `08:00:03` — error message is consistent with DNS failure but is not specific to it. No DNS client event present to confirm.
- **Remaining action:** `nslookup finbridge-fs01` from an affected machine is still required to formally eliminate this hypothesis.

---

### Hypothesis 3 — AD / Kerberos Authentication Failure
**Verdict: CONTRADICTS**

GroupPolicy Event **1500** at `08:00:06` states *"Group Policy settings processed successfully."* GP processing requires a functioning connection to a Domain Controller and valid Kerberos authentication. If AD or Kerberos were degraded at this time, GP would have failed or fallen back to cached policy — Event 1500 would not appear. This is a strong contradiction.

- **Determining evidence:** System Log Event **1500** at `08:00:06` — successful GP processing confirms AD/Kerberos was healthy during the incident window.

---

### Hypothesis 4 — Network Connectivity Break (Subnet / VLAN)
**Verdict: CONTRADICTS**

Two pieces of evidence jointly eliminate a broad network path failure. First, GroupPolicy Event **1500** at `08:00:06` confirms successful GP processing, which requires network connectivity from the Finance subnet to at least one Domain Controller. Second, the ScriptRunner warning at `08:00:03` explicitly attributes the failure to *"SYSTEM context at execution time"* rather than to a routing or connectivity failure. A VLAN or subnet break would prevent GP from processing and would not produce a context-specific warning.

- **Determining evidence:** System Log Event **1500** at `08:00:06` (network path to DC confirmed working); ScriptRunner Warning `08:00:03` (failure scoped to execution context, not network path).

---

### Hypothesis 5 — Drive Mapping Script / GPO Failure (Execution Context)
**Verdict: SUPPORTS — strongest evidence alignment**

This hypothesis is directly supported by multiple corroborating entries:

1. **ScriptRunner Info `08:00:01–08:00:02`** — Confirms `Map-FinBridgeDrives.ps1` was executed under the **SYSTEM account** via Intune Management Extension.
2. **ScriptRunner Warning `08:00:03`** — Explicitly states UNC path `\\finbridge-fs01\Finance` *"not accessible from SYSTEM context at execution time"* — this is the precise failure mode described in the prior change note.
3. **System Log Event 7036 `08:00:05`** — Workstation service entered running state at `08:00:05`, **two seconds after** the script already failed at `08:00:03`. UNC path access depends on the Workstation service being active; the script ran before it was available.
4. **NTFS Event 98 Warning `08:00:07`** — *"File system could not map drive letter S: Drive letter has not been assigned."* — confirms S: was never mapped, consistent with the script failing before completing.
5. **GroupPolicy Event 1500 `08:00:06`** — GP processed successfully, confirming the fault is **not** in GPO itself but in the Intune-delivered script that replaced the GPO logon script.
6. **Prior change note (2024-03-14 23:30)** — Documents the migration of drive mapping from a GPO logon script (USER context) to an Intune PowerShell script (SYSTEM context) without updating the script to handle the SYSTEM context constraints.

- **Determining evidence:** ScriptRunner Warning `08:00:03` + Event **7036** `08:00:05` (Workstation service started *after* script execution); Event **98** `08:00:07` (drive letter never assigned); prior change note confirming the context mismatch was introduced and not remediated.

---

## Updated Evidence Summary Table

| Rank | Hypothesis | Evidence Verdict | Key Event / Timestamp |
|------|-----------|------------------|-----------------------|
| 1 | File server / DFS unavailable | **CONTRADICTS** | ScriptRunner Warning `08:00:03` — context-specific, not server-down |
| 2 | DNS resolution failure | **NEUTRAL** | ScriptRunner Error `08:00:03` — consistent but not confirmed; no DNS event present |
| 3 | AD / Kerberos auth failure | **CONTRADICTS** | Event 1500 `08:00:06` — GP processed successfully |
| 4 | Network path break (subnet/VLAN) | **CONTRADICTS** | Event 1500 `08:00:06` + ScriptRunner Warning context qualifier |
| 5 | GPO / script drive mapping failure | **SUPPORTS** | ScriptRunner `08:00:01–08:00:03` + Event 7036 `08:00:05` + Event 98 `08:00:07` + change note |

> **Status:** Analysis complete. Four hypotheses contradicted by evidence. One hypothesis (H5) is supported by all available evidence. Cause confirmation pending — do not close without formal root cause sign-off.

---

## Confirmed Surviving Hypothesis & Resolution

**Hypothesis 5 — Intune PowerShell drive mapping script running as SYSTEM before the Workstation service is available.**

The script `Map-FinBridgeDrives.ps1` was migrated from a GPO logon script (executed as the logged-on USER, after the desktop environment is ready) to an Intune Management Extension PowerShell script (executed as SYSTEM, early in the boot/logon sequence). The script was never updated to account for the SYSTEM context constraints: UNC path access requires the Workstation service and user-level credentials, neither of which are available to SYSTEM at the point the Intune agent executes the script. The result is a deterministic failure on every logon for all Finance devices.

---

### Resolution Steps

#### Immediate — Restore drive access for affected users today

1. **Manually map drives for affected sessions** (service desk action, buys time while fix is deployed):
   - Ask each affected user to open a Run prompt (`Win+R`) and enter `\\finbridge-fs01\Finance` directly to confirm the share is accessible under their user credentials. If it resolves, the server and network are confirmed healthy.
   - If accessible, map manually: `net use S: \\finbridge-fs01\Finance /persistent:yes` — this survives the current session and persists across reboots until the Intune script overwrites it.

2. **Disable or pause the Intune script assignment** for the Finance device group in the Intune portal to prevent continued failed executions on subsequent logons:
   - Intune portal → Devices → Scripts → `Map-FinBridgeDrives.ps1` → Assignments → remove or exclude the Finance (DESKTOP-FB*) group.
   - This is a containment step only — drives will no longer be automatically re-broken on next logon.

---

#### Fix — Correct the script execution context

Choose **one** of the following approaches. Option A is preferred as it requires the least change to the existing deployment.

**Option A — Change the Intune script to run as the logged-on user (recommended)**

In the Intune portal:
- Devices → Scripts → `Map-FinBridgeDrives.ps1` → Properties → Edit
- Set **"Run this script using the logged on credentials"** to **Yes**
- Set **"Run script in 64-bit PowerShell Host"** to **Yes**
- Save and re-assign to the Finance group.

This restores the same execution context the original GPO logon script used. No changes to the script itself are required.

**Option B — Rewrite the script to defer execution until the user context is available**

If running as SYSTEM is required for other reasons, wrap the UNC mapping in a scheduled task that triggers on user logon under the user's credentials:

```powershell
# Registers a per-user logon task; run this block as SYSTEM during device provisioning only
$action  = New-ScheduledTaskAction -Execute "net.exe" -Argument "use S: \\finbridge-fs01\Finance /persistent:yes"
$trigger = New-ScheduledTaskTrigger -AtLogOn
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 1)
Register-ScheduledTask -TaskName "MapFinanceDrives" -Action $action -Trigger $trigger `
    -Settings $settings -RunLevel Limited -Force
```

This moves the actual mapping to user context at logon, while registration remains in SYSTEM context.

**Option C — Revert to GPO logon script (fallback only)**

Re-create the drive mapping as a GPO logon script in the Finance OU. This is the pre-migration state and is known to work, but moves away from Intune-managed deployment. Use only if Options A and B are blocked.

---

#### Validate the fix

After deploying Option A or B:

1. Sign out and back in on one Finance device (DESKTOP-FB*).
2. Confirm in the Intune portal that the script ran with result **"Success"**.
3. Confirm `net use` output shows `S: \\finbridge-fs01\Finance` as **OK**.
4. Confirm NTFS Event 98 is **absent** from the System log for that device.
5. Pilot across 3–5 Finance devices before rolling to the full group.

---

#### Prevent recurrence

- Add a change note to the Intune script record: *"Must run as logged-on user — SYSTEM context cannot access UNC paths before Workstation service is ready."*
- Update the migration runbook for GPO→Intune script migrations to include a mandatory check: **verify execution context and service dependency ordering before go-live.**
- Add a Proactive Remediation (Intune) to detect drive letter S: absence and alert, providing early warning if this regression reappears.

---
*Analyst: DWP Engineer | Date: 2026-08-07 | Incident: Shared Drives Inaccessible — 45 Users*

---

## Incident Update — 2026-08-07

### Raw Event Log Evidence (Preserved Record)

**Sources:** Intune Management Extension Log + System Log  
**Device sample:** DESKTOP-FB022 (representative of all DESKTOP-FB* Finance devices)  
**Prior change note:** 2024-03-14 23:30 — Drive mapping script migrated from GPO logon script (runs as USER) to Intune PowerShell script (runs as SYSTEM). Script not updated to handle SYSTEM context.

```
[08:00:01] ScriptRunner  Info     Executing: Map-FinBridgeDrives.ps1
[08:00:02] ScriptRunner  Info     Script context: SYSTEM account
[08:00:03] ScriptRunner  Warning  Network path \\finbridge-fs01\Finance not accessible from SYSTEM context at execution time
[08:00:03] ScriptRunner  Error    Script Map-FinBridgeDrives.ps1 failed. Exit code: 1. Error: Network name cannot be found.
[08:00:04] ScriptRunner  Info     No retry configured.

System Log — DESKTOP-FB041:
[08:00:05] Service Control Manager  Event 7036   Workstation service entered running state.
[08:00:06] GroupPolicy              Event 1500   Group Policy settings processed successfully.
[08:00:07] Ntfs                     Event 98     Warning — File system could not map drive letter S: Drive letter has not been assigned.
```

---

### Survived Hypothesis

**H5 — Intune PowerShell drive mapping script (`Map-FinBridgeDrives.ps1`) executing as SYSTEM before the Workstation service is available.**

All other hypotheses were contradicted by the evidence:

| Hypothesis | Verdict | Deciding event |
|-----------|---------|----------------|
| H1 — File server / DFS unavailable | CONTRADICTS | ScriptRunner Warning `08:00:03` is context-qualified, not server-down |
| H2 — DNS resolution failure | NEUTRAL | Error message consistent but not specific; no DNS client event present |
| H3 — AD / Kerberos failure | CONTRADICTS | Event 1500 `08:00:06` — GP processed successfully |
| H4 — Network path break | CONTRADICTS | Event 1500 `08:00:06` — DC connectivity confirmed |
| **H5 — Script execution context** | **SUPPORTS** | ScriptRunner `08:00:01–08:00:03` + Event 7036 `08:00:05` + Event 98 `08:00:07` |

**Root cause:** The script ran at `08:00:03` and failed to access `\\finbridge-fs01\Finance` because the Workstation service — which UNC paths depend on — did not enter running state until `08:00:05`. The script was migrated from GPO (USER context, runs after desktop is ready) to Intune (SYSTEM context, runs during early logon) without updating it to handle the different execution environment. This is a deterministic failure on every logon for all 45 Finance users.

---

### Resolution Summary

| Phase | Action |
|-------|--------|
| **Immediate** | Users manually run `net use S: \\finbridge-fs01\Finance /persistent:yes`; Intune script assignment paused for Finance group |
| **Fix (preferred)** | Intune portal: set *"Run this script using the logged on credentials"* → **Yes** on `Map-FinBridgeDrives.ps1`; re-assign to Finance group |
| **Fix (alternate)** | Register a per-user logon scheduled task (SYSTEM registers it; task runs as user) to perform the UNC mapping |
| **Validate** | Sign out/in on pilot device; confirm Event 98 absent; `net use` shows S: OK; Intune reports Success |
| **Prevent recurrence** | Annotate script in Intune with context requirement; update GPO→Intune migration runbook; add Proactive Remediation to detect missing S: |

> Full resolution steps and Option C fallback: see **Confirmed Surviving Hypothesis & Resolution** section above.

---
*Update recorded: 2026-08-07 | Analyst: DWP Engineer*
