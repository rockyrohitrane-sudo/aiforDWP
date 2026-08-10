# KB — Shared Drives Inaccessible: Finance Users — Intune Script SYSTEM Context Fault

| Field | Value |
|-------|-------|
| Version | 1.0 |
| Date | 07/08/2026 |
| Author | Rohit |
| Reviewed | Self |
| Status | Draft |
| Change | Initial version from RCA |
| Audience | L2 / L3 Endpoint Engineers |
| Related RCA | rca-shared-drives-inaccessible-finance-20260807.md |
| Related Runbook | runbook-shared-drives-inaccessible-finance-intune-system-context.md |
| Related Incident | 2026-08-07 |

---

## 1. Background

Finance department devices (all hostnames `DESKTOP-FB*`, OU=Finance in Active Directory) have their shared drive S: mapped to `\\finbridge-fs01\Finance` by a PowerShell script deployed through Microsoft Intune.

The script is named `Map-FinBridgeDrives.ps1`. It is deployed as an Intune Platform Script (Windows) and is assigned to the Finance device group in Entra ID.

**History that matters:** On 2024-03-14, this drive mapping was migrated from a **GPO logon script** (which executes as the logged-on USER, after the full desktop environment is ready) to an **Intune Management Extension PowerShell script** (which by default executes as the SYSTEM account, early in the logon sequence — before all Windows services are available). The script was not updated to handle the new execution context, and no post-deployment validation was performed.

The Workstation service (LanmanWorkstation) provides the Windows redirector that resolves UNC paths such as `\\finbridge-fs01\Finance`. It is not guaranteed to be in a running state at the point when an Intune SYSTEM-context script executes early in logon. If the script runs before the Workstation service is ready, every `net use` command in the script fails silently, no drive letter is assigned, and there is no retry.

This fault is latent and reproducible at every morning logon. It affects all 45 Finance users simultaneously.

---

## 2. Symptom

### What the user reports

- "My S: drive has disappeared."
- "I can't find the Finance folder."
- "S: was there yesterday but it's gone this morning."
- Reports arrive in bulk at approximately 08:00–08:15, coinciding with the peak morning logon window.

### What the engineer observes

- `net use` on any affected Finance device returns no S: mapping.
- File Explorer shows no S: drive under **This PC**.
- All affected devices have hostnames matching `DESKTOP-FB*`.
- No affected devices outside the Finance OU — other device groups are unaffected.
- No change was declared on the day (the triggering configuration fault was introduced in 2024).
- The file server `finbridge-fs01` is reachable from affected devices — this is not a server-down incident.

### Scope comparison: Finance vs non-Finance devices

| Check | Finance devices (DESKTOP-FB*) | Non-Finance devices |
|-------|-------------------------------|---------------------|
| S: drive present after logon | No | N/A — S: not mapped on non-Finance devices |
| `Map-FinBridgeDrives.ps1` assigned in Intune | Yes | No |
| Intune script runs as SYSTEM | Yes (default, unfixed) | N/A |
| AD/Kerberos healthy | Yes (GP processes successfully) | Yes |
| File server reachable | Yes | Yes |

If non-Finance devices are also missing mapped drives, this is a different fault — do not use this KB article.

---

## 3. Root Cause

### Primary root cause

`Map-FinBridgeDrives.ps1` is configured to run under the **SYSTEM account** (Intune default: *"Run this script using the logged on credentials"* = **No**). During the logon sequence, the Intune Management Extension triggers the script at approximately 08:00:03. The Windows **Workstation service** (LanmanWorkstation) does not enter running state until 08:00:05 — two seconds later.

The `net use \\finbridge-fs01\Finance` command in the script requires the Workstation service to resolve the UNC path. Because the service is not yet running when the script executes, the command fails with:

```
Error: Network name cannot be found.
Exit code: 1
```

No retry is configured. The script exits. Drive letter S: is never assigned for the session.

### Contributing cause

The 2024-03-14 migration change moved the script from GPO logon script (USER context, runs post-desktop) to Intune Platform Script (SYSTEM context, runs early in logon). The engineer who made the change did not:
- Update the script to verify service readiness before executing `net use`
- Change the Intune script setting to run as logged-on user
- Perform post-deployment validation on a Finance device

The fault was latent from 2024-03-14 until the 2026-08-07 morning logon triggered it at scale.

### Why other causes are excluded

| Hypothesis | Excluded by |
|------------|-------------|
| File server `finbridge-fs01` unavailable | ScriptRunner Warning at 08:00:03 is context-specific (*"not accessible from SYSTEM context"*), not a server-unreachable error. Server is pingable. |
| DNS resolution failure | No DNS client Event ID 1014 or 1015 present in System log. SYSTEM context failure provides a complete alternative explanation. |
| AD / Kerberos failure | Event ID 1500 (GroupPolicy) at 08:00:06 confirms GP processed successfully — AD connectivity and Kerberos both healthy. |
| Network path break / VLAN issue | Event ID 1500 confirms DC connectivity. ScriptRunner error is scoped to SYSTEM context, not network layer. |
| GPO drive mapping conflict | Drive mapping was removed from GPO in 2024. No GPO drive mapping policy is active for Finance devices. |

---

## 4. Detection

Work through each check in order. All checks must point to the same cause before applying the fix.

---

### Detection Check 1 — Confirm scope is Finance devices only

**Where:** Command Prompt on any affected endpoint.

**Action:** Run:
```
hostname
```

**What to look for:** Hostname starts with `DESKTOP-FB`. If the affected device does NOT start with `DESKTOP-FB`, stop — this is a different fault.

**Then confirm in Intune:** `https://intune.microsoft.com` → **Devices → Scripts and remediations → Platform scripts → Windows → `Map-FinBridgeDrives.ps1` → Assignments**. Confirm the Finance device group is listed under Included groups. If the script is not assigned to this device, the fault is elsewhere.

---

### Detection Check 2 — Confirm S: drive is absent (not inaccessible)

**Where:** Command Prompt on affected Finance endpoint.

**Action:** Run:
```
net use
```

**What to look for:** S: does not appear anywhere in the output. If S: appears but shows `Unavailable` or `Disconnected`, this may be a different fault (share or network layer). If S: is completely absent from the output, continue.

---

### Detection Check 3 — Confirm script failed in the IME log

**Where:** On the affected Finance endpoint, open the file:
```
C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log
```

Open with Notepad. Press `Ctrl + End` to go to the bottom. Press `Ctrl + F` and search for `Map-FinBridgeDrives`.

**What to look for — all three of these must be present to confirm this fault:**

| Line to find | Meaning |
|---|---|
| `Script context: SYSTEM account` | Confirms the script ran as SYSTEM, not as the logged-on user |
| `Network path \\finbridge-fs01\Finance not accessible from SYSTEM context at execution time` | Confirms the failure is context-specific, not a server issue |
| `Exit code: 1` with `No retry configured` | Confirms the script failed and did not retry |

If `Script context: SYSTEM account` is absent and instead shows a user account, the execution context has already been changed — check whether the fix was previously applied.

---

### Detection Check 4 — Confirm service timing with Event ID 7036

**Where:** On the affected Finance endpoint, press `Win + R`, type `eventvwr.msc`, press Enter.
Navigate to: **Windows Logs → System**.
In the right-hand Actions panel select **Filter Current Log...** Enter Event ID: `7036`. Select OK.

**What to look for:**

Find the Event 7036 entry where **Description** reads:
```
The Workstation service entered the running state.
```

Note its **Date and Time** timestamp. Compare it to the timestamp of the `Exit code: 1` entry in the IME log (Check 3).

**Confirmation:** The Workstation service Event 7036 timestamp must be **after** the IME log `Exit code: 1` timestamp. If it is earlier, the timing dependency was not the issue — do not apply this fix.

---

### Detection Check 5 — Confirm drive letter was never assigned with Event ID 98

**Where:** Event Viewer → **Windows Logs → System**. Filter for Event ID: `98`.

**What to look for:** An entry with:
- **Source:** Ntfs
- **Level:** Warning
- **Description containing:** `File system could not map drive letter S:` or `Drive letter has not been assigned`
- **Timestamp:** within seconds of the Event 7036 entry found in Check 4

**Confirmation:** Event ID 98 for drive S: present in the same logon sequence as the IME failure. This is the end-state proof — S: was never assigned.

---

### Detection Check 6 — Eliminate AD / Kerberos as a cause with Event ID 1500

**Where:** Event Viewer → **Windows Logs → System**. Filter for Event ID: `1500`.

**What to look for:** An entry with:
- **Source:** GroupPolicy
- **Description containing:** `Group Policy settings were applied successfully` or `Group Policy settings processed successfully`
- **Timestamp:** within 10 seconds of the logon sequence being examined

**Confirmation:** Event ID 1500 present and successful. AD connectivity and Kerberos are healthy. If Event ID 1500 is absent or shows failure, AD/Kerberos must be investigated before applying this fix.

---

### Detection summary — all six checks must pass before applying the fix

| Check | Confirms |
|-------|----------|
| 1 — Hostname starts DESKTOP-FB, script assigned in Intune | Correct scope |
| 2 — S: completely absent from `net use` | Drive never mapped (not disconnected) |
| 3 — IME log: SYSTEM context + Exit code 1 + no retry | Script failure due to execution context |
| 4 — Event 7036: Workstation service started AFTER IME failure | Service timing is the mechanism |
| 5 — Event 98: S: drive letter never assigned | End-state confirmed |
| 6 — Event 1500: GP processed successfully | AD/Kerberos eliminated |

---

## 5. Resolution

> All steps must be performed in order. Do not skip steps. ⚠️ marks steps that require Intune Administrator role.

---

### Step 1 — Sign in to Intune admin centre

**Portal path:** Open browser → `https://intune.microsoft.com` → sign in with admin credentials.

**Expected result:** Dashboard loads. Left navigation bar visible. Your account shown top-right.

---

### Step 2 — Navigate to the script

**Portal path:** Left navigation bar → **Devices** → **Scripts and remediations** → **Platform scripts** → **Windows** tab.

**Expected result:** A table of Windows platform scripts is displayed. `Map-FinBridgeDrives.ps1` is visible. If not visible, clear the search filter and type `Map-Fin`.

---

### Step 3 — Open the script record

**Portal path:** Select `Map-FinBridgeDrives.ps1` (blue hyperlink in the Name column).

**Expected result:** Script overview page loads. Left-side panel shows: Overview, Properties, Assignments, Device status, User status.

---

### Step 4 — Open Properties ⚠️ *Intune Administrator role required*

**Portal path:** Left-side panel → **Properties**.

**Expected result:** Properties page shows three sections: Basics, Script settings, Scope tags. Each has an Edit link. Current value of **"Run this script using the logged on credentials"** shows **No**. If Edit links are greyed out, your account lacks the required role — stop.

---

### Step 5 — Edit Script settings ⚠️

**Portal path:** Script settings section header → **Edit** (right side of the header row).

**Expected result:** Script settings fields become editable dropdowns/toggles.

---

### Step 6 — Change execution context

**Portal path:** Field **"Run this script using the logged on credentials"** → change from **No** to **Yes**.

**Expected result:** Field shows **Yes**.

---

### Step 7 — Set 64-bit PowerShell host

**Portal path:** Field **"Run script in 64-bit PowerShell Host"** → set to **Yes** if not already.

**Expected result:** Field shows **Yes**.

---

### Step 8 — Save

**Portal path:** Select **Review + save** → confirm both fields on the review page → select **Save**.

**Expected result:** Green confirmation banner: *"Script updated successfully"*. Properties page returns to read-only view with both settings showing **Yes**. **Note the save timestamp — required for Verification.**

---

### Step 9 — Confirm Finance group assignment

**Portal path:** Left-side panel → **Assignments** tab → **Included groups** section.

**Expected result:** Finance device group (contains `Finance` or `DESKTOP-FB` in the name) is listed.

> **If missing:** Select **Edit** → **Add groups** → search `Finance` → select the group → **Select** → **Review + save** → **Save**.

---

### Step 10 — Force Intune sync on test device

**On Finance endpoint:** Press `Win + I` → **Accounts** → **Access work or school** → select the work account → **Info** → **Sync**.

**Expected result:** Sync status updates. Last sync timestamp refreshes to current time within 30 seconds.

---

### Step 11 — Sign out and sign in as test user

**On Finance endpoint:** **Start** → user name → **Sign out** (not Lock, not Restart). Wait for sign-in screen. Sign back in as the test user.

**Expected result:** Desktop loads. After 3 minutes, S: drive appears in File Explorer under **This PC**.

---

## 6. Verification

Use the save timestamp from Resolution Step 8 as your reference time for all log and portal checks.

---

### Verification 1 — Intune Device status

**Portal path:** `https://intune.microsoft.com` → **Devices → Scripts and remediations → Platform scripts → Windows → `Map-FinBridgeDrives.ps1` → Device status**.

Filter the device table by the test device hostname (type it in the search box above the table).

**Pass:** Row shows **Installation status: Success** and **Last run time** is after your save timestamp.
**Fail:** Status is Failed or Pending — check IME log (Verification 3) before escalating.

---

### Verification 2 — `net use` on endpoint

**On Finance endpoint:** Press `Win + R` → `cmd` → Enter. Run:
```
net use s:
```

**Pass:**
```
Local name        S:
Remote name       \\finbridge-fs01\Finance
Status            OK
```
**Fail:** Output says "The network connection could not be found" — proceed to Verification 3.

---

### Verification 3 — IME log: no new failure entries

**Log location on Finance endpoint:**
```
C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log
```
Open in Notepad. Press `Ctrl + End`. Press `Ctrl + F`, search `Map-FinBridgeDrives`.

**Pass:** Most recent entry timestamp is after save timestamp. Entry contains `Exit code: 0` or success path. No `Exit code: 1`, no `Network name cannot be found`, no `SYSTEM account` context line.
**Fail:** `Exit code: 1` appears after the save timestamp — the script is still running as SYSTEM. Confirm the portal setting saved correctly (Verification 1) and that the device synced (force re-sync via Step 10 of Resolution).

---

### Verification 4 — Event ID 98 absent after fix

**On Finance endpoint:** `Win + R` → `eventvwr.msc` → **Windows Logs → System** → **Filter Current Log...** → Event ID: `98`.

**Pass:** No Event ID 98 entry with a timestamp after the current logon.
**Fail:** Event 98 present after logon — drive still not mapping. Check IME log and escalate to Endpoint Engineering.

---

### Verification 5 — User confirmation

Ask the test user to:
1. Open S: in File Explorer.
2. Open a Finance file.
3. Edit and save it (`Ctrl + S`).

**Pass:** All three complete without error.

**Record in ticket:** user name, device name, time of confirmation.

---

## 7. Rollback

> **Use only if** the fix causes login instability, incorrect drive mappings, or new errors not present before. Target time: under 3 minutes.

---

### Rollback Step 1 — Navigate to the script (45 seconds)

**Portal path:** `https://intune.microsoft.com` → **Devices → Scripts and remediations → Platform scripts → Windows** tab → select `Map-FinBridgeDrives.ps1`.

---

### Rollback Step 2 — Revert execution context ⚠️ (45 seconds)

**Portal path:** Left-side panel → **Properties** → Script settings section → **Edit**.

Change **"Run this script using the logged on credentials"** from **Yes** back to **No**.

Select **Review + save** → confirm field shows **No** → **Save**.

**Expected result:** Green confirmation banner. Properties page shows **Run using logged on credentials: No**.

---

### Rollback Step 3 — Remove Finance group from assignments (30 seconds)

**Portal path:** Left-side panel → **Assignments** tab → **Edit**.

In the Included groups section, select the **X** or **Remove** on the Finance device group row.

Select **Review + save** → **Save**.

**Expected result:** Included groups section is empty. Script will not run on Finance devices at next sync.

---

### Rollback Step 4 — Document and escalate (15 seconds)

Add a ticket note with: rollback timestamp, what failed, your name. Escalate to Endpoint Engineering lead immediately. Do not attempt a second fix without guidance.

---

### Rollback Verification

**Check 1 — Portal:**
`https://intune.microsoft.com` → **Devices → Scripts and remediations → Platform scripts → Windows → `Map-FinBridgeDrives.ps1` → Properties → Script settings**.
Confirm: **Run using logged on credentials: No**.

**Check 2 — IME log on Finance endpoint:**
```
C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log
```
Open in Notepad → `Ctrl + End` → `Ctrl + F` → search `Map-FinBridgeDrives`.
Confirm: no new run entries appear after the rollback timestamp (allow 5 minutes). If a new run appears, the device already re-synced and executed the old SYSTEM-context config — escalate immediately.

---

## 8. Preventive Actions

All controls below are listed with: owner role, timing in the release process, pass/fail criteria, and what happens on failure. Controls marked **[MANUAL]** are human-executed. Controls marked **[AUTOMATED]** run without engineer action once configured. Where a manual control could be automated, a one-line note is included.

---

### PA-1 — Annotate the Intune script to lock the execution context setting

**What:** Add a guardrail description to `Map-FinBridgeDrives.ps1` in the Intune portal so any engineer who opens the script sees the context constraint before editing.

**Portal path:** `https://intune.microsoft.com` → **Devices → Scripts and remediations → Platform scripts → Windows → `Map-FinBridgeDrives.ps1` → Properties → Basics → Edit** → Description field.

**Text to add:**
> *"CRITICAL: Must run as logged-on user. SYSTEM context cannot access UNC paths before Workstation service is ready. Do not set 'Run using logged on credentials' to No. See incident 2026-08-07 and KB kb-l2-l3-shared-drives-inaccessible-finance-intune-system-context.md."*

**Owner:** DWP Engineer (Endpoint Engineering team) | **Timing:** Post-incident, before next change window | **Due:** Within 5 business days.
**Pass:** The Description field at the portal path above contains the specified text — verify by opening Properties and reading the Basics section.
**Fail:** If not completed within 5 business days, the Endpoint Engineering lead must block any further edits to `Map-FinBridgeDrives.ps1` until the annotation is in place.
**Type:** [MANUAL] — Automation note: Intune Graph API (`PATCH /deviceManagement/deviceManagementScripts/{id}`) can set the description field in one command; add to onboarding script if the team manages scripts via API.

---

### PA-2 — Add mandatory execution context checklist to the GPO-to-Intune migration runbook

**What:** Insert two mandatory pre-go-live gate items into the existing GPO-to-Intune migration runbook. The gate fires before any script is assigned to a production group.

**Gate items to add:**
1. *Does this script access a UNC path, mapped drive, or network share?* If yes: set *"Run using logged on credentials"* = **Yes** and document the rationale in the script Description field before proceeding.
2. *Sign-out/sign-in test on one representative device completed?* Pass = Intune Device status shows **Success** and expected outcome is confirmed (drive mapped, file accessible). Evidence screenshot saved to change record.

**Owner:** Endpoint Engineering lead | **Timing:** Pre-deployment — gate must be signed off before the production group assignment step of any future migration | **Due:** Runbook updated within 10 business days; applied from the next migration onwards.
**Pass:** The next GPO-to-Intune change record contains a completed, signed-off version of both gate items with evidence attached.
**Fail:** If a change record for a future migration lacks the gate sign-off, the change manager must reject the change until evidence is provided.
**Type:** [MANUAL] — Automation note: enforce as a required field in the change management tool so the change record cannot be submitted without the checklist entry [REQUIRES: change management tool mandatory field configuration].

---

### PA-3 — Add post-deployment validation evidence as a mandatory CAB field for all Intune script changes

**What:** Add the following as a mandatory, non-optional CAB checklist field for any Intune PowerShell script change type. The field must be populated before the change can be marked as successfully implemented.

**Field text:**
> *"Post-deployment test: sign-out/sign-in completed on one representative device. Intune Device status = Success. Expected outcome confirmed (state what was confirmed). Screenshot reference: [attach or paste link]."*

**Owner:** Change manager | **Timing:** Post-deployment, before the change is closed | **Due:** CAB template updated within 10 business days; enforced from the next change window.
**Pass:** Every Intune script change record closed after the due date contains a populated evidence field. Measurable signal: zero Intune script changes closed without evidence — reviewable in the change management system by filtering change type = "Intune script" and evidence field = empty.
**Fail:** Any change closed without evidence = change manager reopens the record and blocks the engineer from marking it complete until evidence is attached.
**Type:** [MANUAL] — Automation note: configure the change management tool to make the evidence field mandatory on the "Intune Platform Script" change template [REQUIRES: change management tool template configuration].

---

### PA-4 — Deploy Intune Proactive Remediation to detect missing S: drive on Finance devices

**What:** Create a detection-only Proactive Remediation that runs hourly on all Finance devices and surfaces any device where S: is absent — providing early warning before a full incident recurs.

| Field | Value |
|-------|-------|
| Name | `Detect-MissingSDrive-Finance` |
| Detection script | `if (-not (Test-Path "S:\")) { exit 1 } else { exit 0 }` |
| Remediation script | None — detection only; do not auto-remap (auto-remap would mask recurrence) |
| Run as account | Logged on credentials |
| Run frequency | Every 1 hour |
| Assignment | Finance device group (DESKTOP-FB*) |

**Portal path:** `https://intune.microsoft.com` → **Devices → Scripts and remediations → Remediations** → **+ Create**.

**Owner:** DWP Engineer (Endpoint Engineering) | **Timing:** Post-deployment (ongoing monitoring after fix is applied) | **Due:** Within 15 business days.
**Pass:** All DESKTOP-FB* devices show **Device status = Success** (exit 0) in Intune Proactive Remediations. Measurable signal: filter the remediation Device status page for **Status = Failed** — expected count = 0 under normal operation.
**Fail threshold:** Any single device showing **Status = Failed** must trigger investigation within 1 business day. Open the IME log on that device (`C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\AgentExecutor.log`) and check for the same `Exit code: 1` / SYSTEM context pattern.
**Type:** [AUTOMATED] (detection runs automatically once deployed) — Alerting for failures is [MANUAL] unless an alert rule is configured [REQUIRES: Intune alert rule or Log Analytics workspace with Intune data connector to automate failure notification].

---

### PA-5 — Audit all Intune scripts for SYSTEM context + network resource pattern

**What:** One-time estate-wide audit to identify all Intune scripts at risk of the same Workstation service timing fault, followed by remediation of any matches found.

**Audit criteria — a script is at risk if both are true:**
1. Script content contains any of: `net use`, `New-PSDrive`, `\\` (UNC prefix), or mapped drive operations.
2. Intune script property *"Run using logged on credentials"* = **No** (SYSTEM context).

**How to run the audit:**
1. Export the script list: `https://intune.microsoft.com` → **Devices → Scripts and remediations → Platform scripts → Windows** → **Export** button (top of table, downloads CSV).
2. Open CSV, filter the **Run as account** column for `System`.
3. For each SYSTEM-context script: download the script content and search for the UNC/drive-mapping keywords above.
4. For every match: open the script record → Properties → Script settings → Edit → change **"Run using logged on credentials"** to **Yes** → save → validate on one device before re-assigning to production.

**Owner:** DWP Engineer (Endpoint Engineering) | **Timing:** Pre-deployment gate for future scripts — audit must be re-run before any new SYSTEM-context script is added to the estate | **Due:** Initial audit within 20 business days; recurring check before each new script deployment.
**Pass:** Zero scripts in the estate match both conditions simultaneously. Measurable signal: audit produces a findings report with a "Scripts at risk" count — pass = 0.
**Fail:** One or more matches found = engineer must remediate all matches before the audit is closed. If remediation cannot be completed within the due date, Endpoint Engineering lead must approve a risk-accepted exception in writing.
**Type:** [MANUAL] — Automation note: a PowerShell script using the Intune Graph API (`GET /deviceManagement/deviceManagementScripts`) can enumerate all scripts, retrieve their content and `runAsAccount` property, and output a CSV of at-risk scripts in under 2 minutes [REQUIRES: Intune Graph API access (DeviceManagementConfiguration.Read.All permission)].

---

### PA-6 — Pre-deployment smoke test gate for all Intune script changes *(new — gap: pre-deployment test)*

**What:** Before any Intune Platform Script is assigned to a production device group, it must pass a smoke test on a dedicated test device (or a single device temporarily removed from the production group for testing).

**Test steps:**
1. Assign the script to a single test device only (not the full production group).
2. Force Intune sync on the test device (Settings → Accounts → Access work or school → Info → Sync).
3. Sign out and sign back in. Wait 3 minutes.
4. Confirm Intune Device status = **Success** and the expected outcome is present on the device.
5. Only on confirmed pass: assign the script to the full production group.

**Owner:** Release engineer | **Timing:** Pre-deployment — this gate must be completed before the production group assignment step | **Due:** Apply to all Intune script changes from the next change window.
**Pass:** Intune Device status on the test device = **Success** and expected outcome confirmed by the release engineer before the production assignment is made.
**Fail:** Any failure on the test device = deployment is blocked. Release engineer raises a fault investigation before retrying. Production group assignment must not proceed.
**Type:** [MANUAL] — Automation note: Intune Proactive Remediations can be used to validate expected state on a test device automatically post-assignment [REQUIRES: test device group defined in Intune].

---

### PA-7 — In-flight monitoring during rollout window *(new — gap: in-flight monitoring)*

**What:** During the rollout window of any Intune script change to Finance devices, the release engineer must monitor Intune Device status at 15-minute intervals for the first hour after production group assignment.

**Portal path to monitor:** `https://intune.microsoft.com` → **Devices → Scripts and remediations → Platform scripts → Windows → [script name] → Device status** — filter by Finance device group, sort by Last run time descending.

**Measurable signal:** Track two counters every 15 minutes: **Success count** (should increase) and **Failed count** (must remain 0). If the Failed count is non-zero at any check interval, pause the rollout immediately.

**Owner:** Release engineer | **Timing:** During deployment — starts from the moment the production group assignment is saved | **Due:** Apply from the next change window.
**Pass:** Failed count = 0 at all check intervals for the first hour.
**Fail:** Failed count ≥ 1 at any check interval = release engineer pauses rollout (removes production group from Assignments), collects IME log from a failed device, and escalates to Endpoint Engineering lead before continuing.
**Type:** [MANUAL] — Automation note: configure an Intune alert rule or Log Analytics alert to notify the release engineer if any device reports a script failure during the rollout window [REQUIRES: Log Analytics workspace with Intune data connector and an alert rule on `IntuneDevices` table].

---

### PA-8 — Rollback trigger threshold *(new — gap: rollback trigger)*

**What:** Define the specific threshold at which a rollout must be automatically stopped and rollback initiated, removing subjective judgement from the decision under pressure.

**Threshold:** If **≥ 10% of targeted Finance devices** report **Script status = Failed** within **30 minutes** of production group assignment, the release engineer must immediately execute the Rollback procedure (Section 7 of this KB).

**How to measure the threshold:**
```powershell
# Count total targeted devices and failed devices in Intune Device status
# Run at the 15-minute and 30-minute check intervals
# Threshold = (Failed count / Total assigned count) * 100 >= 10
```
Portal confirmation: **Device status** page → note the total row count (all devices) and the Failed row count (filter Status = Failed). Calculate percentage manually.

**Owner:** Release engineer | **Timing:** During deployment — evaluated at each 15-minute monitoring interval defined in PA-7 | **Due:** Document in release checklist within 10 business days.
**Pass:** Failed percentage remains below 10% at every check interval during the rollout window.
**Fail:** Failed percentage reaches or exceeds 10% = release engineer executes Section 7 Rollback immediately, without waiting for further approval. Documents rollback timestamp and failed device count in the change record.
**Type:** [MANUAL] — Automation note: an alert rule on the Intune data in Log Analytics can fire when the failed device count crosses the threshold [REQUIRES: Log Analytics workspace with Intune data connector].

---

### PA-9 — Knowledge update: propagate learnings to all related process documents *(new — gap: knowledge update)*

**What:** Update three specific documents with the exact learnings from this incident so the fault pattern is captured in the standard process, not just in this KB.

| Document | Specific addition required |
|---|---|
| GPO-to-Intune migration runbook | Add named section: *"Execution context and service dependency check"* — explains the Workstation service timing constraint and mandates logged-on credentials for all UNC-accessing scripts |
| Intune script deployment checklist | Add line item: *"If script accesses UNC path or mapped drive: confirm Run as = Logged on credentials. Reason: Workstation service may not be available at SYSTEM-context execution time (see incident 2026-08-07)"* |
| Endpoint Engineering onboarding guide | Add paragraph under *"Intune script deployment"*: explain the SYSTEM vs user context difference and reference this KB article |

**Owner:** Endpoint Engineering lead | **Timing:** Post-incident, before next migration or script deployment | **Due:** All three documents updated within 10 business days. Updated documents version-bumped and team notified via team channel.
**Pass:** All three documents contain the additions above and carry an updated version date after 2026-08-07. Measurable signal: Endpoint Engineering lead signs off that all three updates are complete in the incident closure record.
**Fail:** If not completed within 10 business days, the service owner must be notified and the next migration or Intune script deployment must be held until the documents are updated.
**Type:** [MANUAL].

---

## 9. Related Records

| Reference | Type | Detail |
|-----------|------|--------|
| `rca-shared-drives-inaccessible-finance-20260807.md` | RCA | Full root cause analysis, 5 Whys, timeline, evidence |
| `runbook-shared-drives-inaccessible-finance-intune-system-context.md` | Runbook | Step-by-step fix procedure with prerequisites checklist |
| `kb-l1-self-service-shared-drive-missing-finance.md` | KB L1 | End-user self-service article for S: drive missing |
| `known-error-shared-drives-inaccessible-intune-system-context-20260807.md` | Known Error | Known error record for this fault pattern |
| `triage-hypothesis-shared-drives-inaccessible-20260807.md` | Triage | Hypothesis elimination record from incident triage |
| Change record 2024-03-14 | Change | GPO logon script → Intune script migration (contributing cause) |

### Related fault patterns to be aware of

- **Any Intune PowerShell script that maps a network drive and runs as SYSTEM** is susceptible to the same Workstation service timing fault. See PA-5.
- **Intune scripts that write to UNC paths** (e.g. log files, configuration shares) will fail under the same conditions.
- **GPO drive mappings** (Item-level targeting, User context) are not affected by this fault — they run post-desktop, as the logged-on user.

---

*KB Author: Rohit | Incident Date: 2026-08-07 | Document Date: 07/08/2026*
