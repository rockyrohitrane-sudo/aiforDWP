# Known Error Record - Shared Drive Not Mapped at Logon (Intune SYSTEM Context) - 2026-08-07

**Knowledge Base Reference:** KE-ENDPOINT-20260807-001

---

**Symptom:**
Users log in and find their shared drive letter (S:) is missing — `net use` shows no mapping and the drive is not visible in File Explorer. The issue affects all users in the impacted device group simultaneously at morning logon and does not resolve on its own within the session.

---

**Cause:**
The Intune PowerShell drive mapping script (`Map-FinBridgeDrives.ps1`) is configured to run as SYSTEM, which causes it to execute during the early logon sequence before the Windows Workstation service (LanmanWorkstation) is running. UNC path access requires the Workstation service; the script fails with "Network name cannot be found" and exits with code 1 before the service becomes available. No retry is configured, so the drive is never mapped for that session.

---

**Scope:**
All devices in the Finance OU (DESKTOP-FB*) running the affected Intune script assignment — confirmed across 45 users on 2026-08-07. Any other device group assigned a drive mapping script via Intune with *"Run using logged on credentials"* set to **No** is subject to the same failure pattern.

---

**Workaround:**
Ask the affected user to open a Run prompt (`Win+R`) and enter `\\finbridge-fs01\Finance` to confirm the share is reachable, then run `net use S: \\finbridge-fs01\Finance /persistent:yes` to map the drive manually for the current session. This restores access immediately without requiring a sign-out and is valid until the permanent fix is deployed.

---

**Permanent Fix:**
In the Intune portal navigate to Devices → Scripts → `Map-FinBridgeDrives.ps1` → Properties → Edit; set *"Run this script using the logged on credentials"* to **Yes** and *"Run script in 64-bit PowerShell Host"* to **Yes**; save and re-assign to the affected device group. Verify by having a user sign out and back in — Intune should report script result **Success**, `net use` should show `S: \\finbridge-fs01\Finance  OK`, and NTFS Event 98 should be absent from the System log.

---

**How to Spot It:**
Look for ScriptRunner Warning in the Intune Management Extension log reading *"Network path not accessible from SYSTEM context at execution time"* at logon time, followed immediately by ScriptRunner Error exit code 1 with message *"Network name cannot be found"*. Cross-reference with System log Event **7036** (Workstation service entering running state) — if Event 7036 timestamp is later than the ScriptRunner failure timestamp, the timing race is confirmed. NTFS Event **98** (*"File system could not map drive letter S:"*) in the System log is the end-state confirmation that the drive was never assigned.

---
*Record created: 2026-08-07 | Source incident: Shared Drives Inaccessible — 45 Finance Users | RCA reference: rca-shared-drives-inaccessible-finance-20260807.md*
