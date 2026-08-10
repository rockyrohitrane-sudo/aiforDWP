# Runbook — Shared Drives Inaccessible: Finance Users (Intune SYSTEM Context Fix)

| Field | Value |
|-------|-------|
| Title | Runbook — Shared Drives Inaccessible: Finance Users (Intune SYSTEM Context Fix) |
| Version | 1.0 |
| Date | 07/08/2026 |
| Author | Rohit |
| Reviewed | Self |
| Status | Draft |
| Change | Initial version from RCA |
| Related RCA | rca-shared-drives-inaccessible-finance-20260807.md |
| Related Incident | 2026-08-07 |

---

## Symptom

All Finance users on DESKTOP-FB* devices cannot access shared drive S: (`\\finbridge-fs01\Finance`) after logon. The drive letter is absent from File Explorer and `net use` shows no mapping.

---

## 1. Prerequisites

Complete every checkbox before moving to the Procedure. If any item cannot be checked, stop and resolve it first.

### Access — confirm before starting

- [ ] ⚠️ **Intune Administrator role confirmed** — sign in to `https://intune.microsoft.com`. If you can see **Devices → Scripts and remediations** in the left navigation bar, your role is sufficient. If that menu is missing, raise an access request before continuing.
- [ ] **Finance endpoint available** — identify a Finance test device (hostname starts `DESKTOP-FB`). Confirm you can either sit at the console or connect via remote session (RDP / remote assistance tool).
- [ ] **Local administrator rights on the Finance endpoint confirmed** — you will need to open Event Viewer and read files under `C:\ProgramData`. To verify: open Command Prompt on the endpoint, run `whoami /groups`, and confirm the word `Administrators` appears in the output. If it does not, request local admin access before continuing.

### Tools — confirm each is accessible

- [ ] **Browser signed in to Intune** — navigate to `https://intune.microsoft.com` and confirm the dashboard loads under your admin account. Your account name or initials must appear in the circle in the top-right corner.
- [ ] **Event Viewer accessible on Finance endpoint** — press `Win + R`, type `eventvwr.msc`, press Enter. Confirm it opens without an access-denied error.
- [ ] **Command Prompt accessible on Finance endpoint** — press `Win + R`, type `cmd`, press Enter. Confirm a black terminal window opens.
- [ ] **Intune Management Extension log file present on Finance endpoint** — open File Explorer and navigate to `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\`. Confirm the folder exists and the file `IntuneManagementExtension.log` is listed. If the folder does not exist, Intune Management Extension has not run on this device — pick a different Finance test device.

### Information — collect from the end user before touching anything

- [ ] **Affected user's Windows logon name confirmed** — ask the user for the name they type at the Windows sign-in screen (e.g. `jsmith` or `firstname.lastname`). Record it: `____________________`
- [ ] **Affected device hostname confirmed** — ask the user for their device name. They can find it at **Settings → System → About → Device name**. It must start with `DESKTOP-FB`. Record it: `____________________`
- [ ] **Time the problem first appeared confirmed** — ask the user: *"What time did you first notice the S: drive was missing — was it when you logged in this morning?"* Record the time: `____________________` (you will use this to filter event logs by timestamp)
- [ ] **Problem confirmed as S: drive absent (not a permissions error)** — ask the user: *"When you open File Explorer, is the S: drive listed at all, even if you cannot open it?"* If S: is listed but they get **Access Denied** when opening it, this is a share permissions fault — do not use this runbook, escalate to the file server team.
- [ ] **Post-fix test user and device identified** — confirm a willing Finance user on a DESKTOP-FB* device who can sign out and back in to validate the fix. Record name and device: `____________________`

---

## 2. Procedure

> Work through steps in order. Do not skip steps. Each step includes the exact location in the portal or on the endpoint. If you do not see the expected result at any step, stop and escalate before continuing.

---

### Step 1 — Sign in to the Intune admin centre

**Action:** Open a browser and go to `https://intune.microsoft.com`. Enter your admin credentials when prompted.

**Where you land:** The Intune overview page. The left-hand navigation bar shows: Home, Dashboard, Devices, Apps, Endpoint security, and others. Your account name or initials appear in a circle in the top-right corner.

**Expected result:** Dashboard loads with no "You don't have access" or "Request access" banner.

---

### Step 2 — Navigate to Windows Platform Scripts

**Action:** In the left navigation bar select **Devices**. The Devices submenu expands — select **Scripts and remediations**. A secondary menu appears — select **Platform scripts**. On the Platform scripts page select the **Windows** tab near the top of the content area.

**Where you land:** A table listing all Windows PowerShell scripts deployed via Intune. Columns: Name, Created date, Last modified, Assigned.

**Expected result:** The script `Map-FinBridgeDrives.ps1` is visible in the list. If it is not visible, clear any existing filter in the search box above the table and type `Map-Fin` to locate it.

---

### Step 3 — Open the script record

**Action:** Select the script name `Map-FinBridgeDrives.ps1` (blue hyperlink text in the Name column).

**Where you land:** The script overview page. A left-side panel shows tabs: Overview, Properties, Assignments, Device status, User status.

**Expected result:** The page header reads `Map-FinBridgeDrives.ps1`. The Overview tab is active and shows a summary including fields for Script file, Run as account, and Enforce script signature check.

---

### Step 4 — Open the Properties tab ⚠️ *Requires Intune Administrator role*

**Action:** In the left-side panel of the script page, select **Properties**.

**Where you land:** The Properties page shows three collapsible sections: **Basics**, **Script settings**, and **Scope tags**. Each section has an **Edit** link on the right side of the section header.

**Expected result:** You can see the Script settings section. It shows the current value of **Run this script using the logged on credentials** as **No**. If the **Edit** links are greyed out or missing, your account does not have the required role — stop and raise an access request before proceeding.

---

### Step 5 — Enter edit mode for Script settings

**Action:** In the **Script settings** section header row, select the **Edit** link on the right-hand side.

**Where you land:** The Script settings section expands into an editable form. The fields that were read-only text now show dropdowns or toggle controls.

**Expected result:** Both settings below are now interactive (not greyed out): "Run this script using the logged on credentials" and "Run script in 64-bit PowerShell Host".

---

### Step 6 — Change execution context to logged-on user

**Action:** Locate the field **"Run this script using the logged on credentials"**. The current value is **No**. Open the dropdown and select **Yes**.

**Expected result:** The field displays **Yes**.

> **Why this matters:** When set to No, the script runs as the Windows SYSTEM account during early logon — before the Workstation service is available. UNC paths like `\\finbridge-fs01\Finance` cannot be resolved without the Workstation service. Changing to Yes makes the script run as the signed-in user, after the full desktop environment is ready.

---

### Step 7 — Set PowerShell host to 64-bit

**Action:** Locate the field **"Run script in 64-bit PowerShell Host"**. If it shows **No**, open the dropdown and select **Yes**. If it already shows **Yes**, leave it unchanged.

**Expected result:** The field shows **Yes**.

---

### Step 8 — Save the script settings

**Action:** Scroll to the bottom of the Script settings form and select **Review + save**. On the review summary page confirm both values:
- Run this script using the logged on credentials: **Yes**
- Run script in 64-bit PowerShell Host: **Yes**

Then select **Save**.

**Expected result:** The portal returns to the Properties read-only view. A green confirmation banner appears at the top: *"Script updated successfully"* or similar. No red error banners appear. **Note the current time — you will need this timestamp in the Verification section.**

---

### Step 9 — Confirm the Finance device group is still assigned

**Action:** In the left-side panel of the script page, select the **Assignments** tab. Look at the **Included groups** section in the content area.

**Expected result:** A group representing Finance devices (the group name contains `Finance` or `DESKTOP-FB`) is listed under Included groups.

> **If the group is missing:** Select **Edit** at the top of the Assignments page. In the Included groups section select **Add groups**. In the search box type `Finance`. Select the correct Finance device group from the results. Select **Select** at the bottom. Select **Review + save** → **Save**. Confirm the group now appears in the Included groups list before continuing.

---

### Step 10 — Force an Intune sync on the Finance test endpoint

**Action:** On the Finance test device, open **Settings** (press `Win + I`). In the left panel select **Accounts**. Select **Access work or school**. Select the work account entry (shows your organisation name or email address). Select **Info**. On the Account info page, select the **Sync** button.

**Expected result:** A "Syncing" status message appears briefly under the Sync button. The last sync timestamp updates to the current time within 30 seconds.

> This forces the device to pull the updated script configuration from Intune immediately instead of waiting up to 15 minutes for the next scheduled check-in.

---

### Step 11 — Sign the test user fully out of the Finance endpoint

**Action:** Select **Start** (Windows logo, bottom-left of screen). Select the user account icon or the displayed username shown above the Power button. Select **Sign out** from the options that appear.

> Do not select Lock, Sleep, or Restart. The Intune script only runs during a full sign-in sequence.

**Expected result:** The screen shows the Windows sign-in page with the user's name, a password field, and no desktop visible behind it.

---

### Step 12 — Sign the test user back in

**Action:** On the sign-in screen, type the test user's Windows password into the password field and press **Enter** (or select the arrow button to the right of the field).

**Expected result:** The Windows loading animation plays. The user's desktop loads fully — taskbar visible at the bottom, desktop icons or background visible. No error dialogues appear.

---

### Step 13 — Wait for the Intune Management Extension to execute the script

**Action:** At the desktop, wait **3 minutes** without opening any applications. Do not click anything.

**Expected result:** After 3 minutes, open **File Explorer** (select the folder icon on the taskbar, or press `Win + E`). In the left panel under **This PC**, the **S:** drive appears, labelled `Finance` or similar.

> If S: does not appear after 5 minutes, do not sign out again. Go directly to the Verification section — the Intune log will show whether the script ran and what the result was.

---

## 3. Verification

Complete all five checks before closing the incident. Use the timestamp you noted when you saved the fix in Step 8 of the Procedure to filter log entries.

---

### Check 1 — Confirm script result in Intune portal

**Action:**
1. In the browser, go to `https://intune.microsoft.com`.
2. In the left navigation bar select **Devices**.
3. In the Devices submenu select **Scripts and remediations**, then **Platform scripts**.
4. Select the **Windows** tab.
5. Select `Map-FinBridgeDrives.ps1` (blue hyperlink in the Name column).
6. In the left-side panel of the script page select **Device status**.
7. In the search/filter box above the device table, type the test device hostname (e.g. `DESKTOP-FB0123`) to filter the list to that one device.

**Expected result:** The row for the test device shows:
- **Installation status:** Success
- **Last run time:** a timestamp that is **after** the time you saved the fix in Procedure Step 8

> If the Last run time is older than your fix, the device has not yet synced. Go back to Procedure Step 10 and force a sync, then wait 3 minutes and refresh this page.

---

### Check 2 — Confirm S: drive is mapped on the endpoint

**Action:**
1. On the Finance test endpoint, press `Win + R` to open the Run dialogue.
2. Type `cmd` and press Enter. A black Command Prompt window opens.
3. Type the following command exactly and press Enter:
```
net use s:
```

**Expected result:** The output shows all three of these lines:
```
Local name        S:
Remote name       \\finbridge-fs01\Finance
Status            OK
```

> If the output says *"The network connection could not be found"*, the drive was not mapped. Check the IME log in Check 3 before escalating.

---

### Check 3 — Confirm no script failure in the Intune Management Extension log

**Action:**
1. On the Finance test endpoint, press `Win + R`, type `notepad`, press Enter.
2. In Notepad, select **File → Open**.
3. In the file path bar at the top of the Open dialogue, paste exactly:
```
C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log
```
Press Enter. The log file opens (it may be large — several MB).
4. Press `Ctrl + End` to jump to the bottom of the file (most recent entries).
5. Press `Ctrl + F` to open Find. Type `Map-FinBridgeDrives` and select **Find Next** to locate the most recent run entry.

**Expected result:** The most recent entry for `Map-FinBridgeDrives.ps1` has a timestamp **after your fix time** and contains none of the following strings:
- `Exit code: 1`
- `Script execution failed`
- `Network name cannot be found`

The entry should contain: `Exit code: 0` or `Script execution succeeded`.

> If you see `Exit code: 1` after your fix time, note the exact error message text and escalate — do not attempt the fix a second time without guidance.

---

### Check 4 — Confirm no NTFS drive assignment failure in Event Viewer

**Action:**
1. On the Finance test endpoint, press `Win + R`, type `eventvwr.msc`, press Enter. Event Viewer opens.
2. In the left panel, expand **Windows Logs** and select **System**.
3. In the right-hand **Actions** panel, select **Filter Current Log...** A filter dialogue opens.
4. In the **\<All Event IDs\>** field, type `98` (replacing the placeholder text). Select **OK**.
5. The System log now shows only Event ID 98 entries. Look at the timestamps in the **Date and Time** column.

**Expected result:** No Event ID 98 entries appear with a **Date and Time** value that is after your fix timestamp from Procedure Step 8.

> Event ID 98 source is `Ntfs`. Each entry means Windows could not assign a drive letter — in this incident that was S:. If a new Event 98 appears after your fix, the drive mapping is still failing. Check the IME log (Check 3) and escalate.

---

### Check 5 — End user confirmation

**Action:** Ask the test user to perform the following three steps and confirm each one to you verbally:
1. Open File Explorer (`Win + E`) and double-click the **S:** drive under **This PC**.
2. Open any Finance file from S: (a Word document, Excel spreadsheet, or PDF).
3. Make a minor edit and save the file (`Ctrl + S`) to confirm write access.

**Expected result:** All three steps complete without error dialogs. The user verbally confirms the drive is working.

**Record in the incident ticket before closing:**
- User name: `____________________`
- Device name (DESKTOP-FB*): `____________________`
- Time of confirmation: `____________________`

---

## 4. Rollback

> **Use this section only if** the Procedure causes broader login instability, incorrect drive mappings, or errors that were not present before the change.
> **Target time: under 3 minutes. Follow the steps in exact order — do not skip any.**

---

### Rollback Step 1 — Navigate to the script in Intune (45 seconds)

**Action:**
1. In the browser go to `https://intune.microsoft.com`.
2. In the left navigation bar select **Devices**.
3. Select **Scripts and remediations**, then **Platform scripts**.
4. Select the **Windows** tab.
5. Select `Map-FinBridgeDrives.ps1` (blue hyperlink in the Name column).

**Where you land:** The script overview page with a left-side panel showing Overview, Properties, Assignments, Device status, User status.

---

### Rollback Step 2 — Revert execution context to SYSTEM ⚠️ *Requires Intune Administrator role* (45 seconds)

**Action:**
1. In the left-side panel select **Properties**.
2. In the **Script settings** section header, select **Edit** on the right.
3. Locate **"Run this script using the logged on credentials"** — currently showing **Yes**. Open the dropdown and change it to **No**.
4. Select **Review + save**.
5. On the review page confirm the field shows **No**, then select **Save**.

**Expected result:** A green confirmation banner appears. The Properties page now shows **Run using logged on credentials: No**.

---

### Rollback Step 3 — Remove the Finance group from assignments (45 seconds)

**Action:**
1. In the left-side panel select **Assignments**.
2. Select **Edit** at the top of the Assignments page.
3. In the **Included groups** section, find the Finance device group row. Select the **X** or **Remove** icon on that row to remove it.
4. Select **Review + save**, then **Save**.

**Expected result:** The Assignments page shows no groups listed under **Included groups** for the Finance device group. The script will not be pushed to Finance devices on the next Intune sync.

---

### Rollback Step 4 — Record the rollback (15 seconds)

**Action:** In the incident ticket, add a note containing exactly:
- Rollback timestamp (current time)
- What went wrong (one sentence)
- Your name

Do not close the ticket. Escalate to the Endpoint Engineering lead immediately after recording.

---

### Rollback Verification — confirm the revert took effect

**Verification 1 — Intune portal (do this first):**
1. In the browser, stay on `https://intune.microsoft.com`.
2. Go to **Devices → Scripts and remediations → Platform scripts → Windows → `Map-FinBridgeDrives.ps1` → Properties**.
3. Look at **Script settings**.

**Expected:** **Run this script using the logged on credentials** shows **No**. If it still shows **Yes**, repeat Rollback Step 2.

---

**Verification 2 — Intune Management Extension log on Finance endpoint (do this second):**
1. On the Finance test endpoint, press `Win + R`, type `notepad`, press Enter.
2. In Notepad select **File → Open**. In the file path bar paste:
```
C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log
```
Press Enter.
3. Press `Ctrl + End` to go to the bottom of the file.
4. Press `Ctrl + F`, type `Map-FinBridgeDrives`, select **Find Next**.

**Expected:** The most recent entry for `Map-FinBridgeDrives.ps1` has a timestamp **before** your rollback time. No new execution entries appear after the rollback timestamp (allow 5 minutes for Intune sync to settle). If a new run appears after rollback, the device has already checked in and re-run the old config — escalate immediately, do not attempt to fix again.

---

## 5. Notes

### Edge Cases

- **Script not appearing in Intune after fix:** Intune policy sync can take up to 15 minutes. To force an immediate sync on the Finance endpoint: **Settings** → **Accounts** → **Access work or school** → select the account → **Info** → **Sync**. Then sign out and back in.

- **Only some DESKTOP-FB* devices affected after fix:** Intune deployment is not instantaneous. Devices that have not yet synced will still be missing S:. Advise affected users to sync manually (see above) or wait for the next scheduled Intune check-in before signing out and back in.

- **User reports S: present but cannot open files:** This is a permissions or share-level issue on `\\finbridge-fs01\Finance`, not the script context problem. Escalate to the file server team; do not re-run this runbook.

- **Rollback causes login loop or Group Policy errors:** Stop. Do not re-apply the script. Escalate to Endpoint Engineering lead and raise a P1.

### Warnings

> ⚠️ Do **not** change "Run this script using the logged on credentials" back to **No** unless rolling back. The SYSTEM context was the root cause of this incident.

> ⚠️ This runbook addresses the Finance drive mapping script only. Other Intune scripts in the estate may have the same misconfiguration — do not assume this fix covers them (see Preventive Action 5 in the RCA).

> ⚠️ The Workstation service dependency is the critical timing constraint. Any future script that maps network drives must run as logged-on user or explicitly check for service readiness.

### Related Incidents and Records

| Reference | Detail |
|-----------|--------|
| `rca-shared-drives-inaccessible-finance-20260807.md` | Full root cause analysis for this incident |
| `known-error-shared-drives-inaccessible-intune-system-context-20260807.md` | Known error record |
| `triage-hypothesis-shared-drives-inaccessible-20260807.md` | Triage hypotheses and elimination |
| Change record 2024-03-14 | GPO logon script → Intune script migration (contributing cause) |

### Related Preventive Actions (from RCA — track separately)

| # | Action | Owner | Due |
|---|--------|-------|-----|
| 1 | Annotate `Map-FinBridgeDrives.ps1` in Intune portal with SYSTEM context warning | Endpoint Engineering | +5 business days |
| 2 | Update GPO-to-Intune migration runbook with execution context checklist | Endpoint Engineering lead | +10 business days |
| 3 | Mandate post-deployment validation gate for all Intune script changes | Change Advisory / Endpoint Engineering | +10 business days |
| 4 | Add Proactive Remediation to detect missing S: on Finance devices | Endpoint Engineering | +15 business days |
| 5 | Audit all Intune scripts for SYSTEM context + network resource pattern | Endpoint Engineering | +20 business days |
