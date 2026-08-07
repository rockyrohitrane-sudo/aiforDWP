# Known Error Record - RDP Account Lockout (FINBRIDGE\bwalker)

- Knowledge base reference: KE-ACC-001
- Incident date: 2024-03-15
- Platform: Remote Desktop / Active Directory (FINBRIDGE domain)
- Status: Resolved

---

**Symptom**
The user `FINBRIDGE\bwalker` is unable to establish a Remote Desktop session and receives authentication failure messages. After three failed attempts the account is locked out and access is blocked entirely until an administrator intervenes.

**Cause**
Stale RDP credentials saved in Windows Credential Manager on client `10.10.5.44` continued submitting an outdated password on every connection attempt. Three consecutive failed RemoteInteractive logons within approximately four minutes triggered the domain account lockout threshold.

**Scope**
Single user account (`FINBRIDGE\bwalker`) and single source client (`10.10.5.44`). The affected access path is Remote Desktop (Logon Type 10); no broader host or network outage was evidenced.

**Workaround**
Unlock the account in Active Directory, verify the current password with the user, and have the user remove the saved RDP credentials for the target host via **Control Panel → Credential Manager**. The user can then retry sign-in with confirmed current credentials.

**Permanent Fix**
Remove stale saved credentials from Credential Manager immediately after any password change. Audit scheduled tasks and services running under `FINBRIDGE\bwalker` for cached credentials that could replay outdated passwords and trigger future lockouts.

**How to Spot It**
Look for three or more Security **Event ID 4625** (Audit Failure, Logon Type 10) in rapid succession for the same account and source IP, with failure reason "Unknown username or bad password", followed immediately by Security **Event ID 4740** (account lockout). System **Event ID 140** (Source: `RemoteDesktopServices-RdpCoreTS`) confirms the RDP credential rejection, and System **Event ID 56** (Source: `TermDD`) may appear as secondary noise during the failed handshake.
