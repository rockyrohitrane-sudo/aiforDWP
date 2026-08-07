# Communications — Account Lockout Incident: bwalker (2024-03-15)

---

## Audience 1 — Non-Technical Executive

Your account access and data are safe. On 15 March 2024, one staff member was briefly unable to log in remotely for approximately 21 minutes after their system attempted to sign in using an outdated saved password. The system automatically blocked access as a security precaution. Access was restored once the correct password was confirmed. No data was lost and no other accounts were affected. No action is required from you.

---

## Audience 2 — Affected End-User Team

Hi team,

On 15 March, one of your colleagues (bwalker) was temporarily locked out of their remote desktop session for about 21 minutes because their computer kept trying to log in with an old saved password.

If you ever find yourself suddenly unable to log in remotely, don't keep retrying — contact the service desk straight away so your account can be checked and unlocked quickly.

If you recently changed your password, make sure your saved sign-in details are updated too (your support team can walk you through this).

**Contact the service desk** if you experience any login issues: raise a ticket or call the IT helpdesk.

---

## Audience 3 — Engineer-to-Engineer Internal Note

**Incident:** RDP authentication lockout — FINBRIDGE\bwalker  
**Date:** 2024-03-15 | **Window:** 14:01:02–14:22:09  
**Source client IP:** 10.10.5.44

### Root Cause

Stale credentials cached in Windows Credential Manager on 10.10.5.44 submitted an outdated password against the RDP endpoint. Three consecutive Logon Type 10 (RemoteInteractive) failures triggered the domain lockout policy threshold.

- Event 140 (RdpCoreTS) + Event 56 (TermDD) at 14:01:02 — initial failed handshake/auth; TermDD 56 is secondary noise from the failed auth flow, not primary cause.
- Events 4625 at 14:01:04, 14:03:18, 14:05:33 — three `Unknown username or bad password` failures, all same account + same source IP.
- Event 4740 at 14:05:34 — lockout triggered, caller source confirmed as 10.10.5.44.

### Actions Taken

1. Unlocked FINBRIDGE\bwalker in Active Directory and confirmed current password with user.
2. Cleared stale RDP saved credentials on 10.10.5.44 via **Control Panel → Credential Manager → Windows Credentials** — removed the entry for the target RDP host.
3. User reattempted RDP with confirmed current credentials.

### Verification

- Event 131 (RdpCoreTS) at 14:22:07 — TCP session accepted from 10.10.5.44:52341.
- Event 4624 at 14:22:09 — Logon Type 10 success for FINBRIDGE\bwalker from 10.10.5.44.
- No further 4625 or 4740 events observed post-remediation.

### Config Detail

- Lockout threshold reached after **3 failed attempts** (policy threshold confirmed by 4740 firing immediately after third 4625).
- Total outage duration: **~21 minutes** (14:01:02 to 14:22:09).
- Scope: single account, single source IP — no lateral spread in available evidence.

### Preventive Actions Required

- **User education:** Advise all users to update saved credentials in Credential Manager immediately after any password change.
- **Alerting:** Tune SIEM/lockout alerting to fire on clustered 4625 events (e.g., 2+ within 5 min for same account/source) *before* the lockout threshold is hit — allows pre-emptive intervention.
- **Scheduled task/service audit:** Review 10.10.5.44 for any scheduled tasks, services, or scripts running as FINBRIDGE\bwalker that could be silently replaying stale credentials. Check Task Scheduler and `Get-WmiObject Win32_Service | Where-Object { $_.StartName -like "*bwalker*" }`.
- **TermDD 56 follow-up:** If Event 56 recurs in isolation (without accompanying auth failures), capture Schannel and Terminal Services ETL traces for protocol-level diagnosis — it would indicate a different, non-credential issue.
