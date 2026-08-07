# Communications - Account Lockout Incident: cthompson (2026-08-07)

---

## Audience 1 - Non-technical Executive

Your access and data are safe. One user, cthompson, had a login issue from about 08:40 after repeated incorrect sign-in attempts caused a security lock, with continued attempts from another saved sign-in source. The account was re-enabled at 09:08:14 by helpdesk-admin, and a successful login was recorded at 09:09:01 from DESKTOP-FB022. The user confirmed no further issues. No action is required.

---

## Audience 2 - Affected End-user Team (10 people)

Hi team, one colleague (cthompson) could not log in from around 08:40 because repeated incorrect saved sign-in details triggered a security lock, and another saved sign-in source kept retrying. The account was re-enabled at 09:08:14 by helpdesk-admin, and login succeeded at 09:09:01 from DESKTOP-FB022; the user then confirmed no further issues. If you see the same problem, stop retrying and contact the Service Desk immediately.

---

## Audience 3 - Engineer-to-engineer Internal Note

Incident: FINBRIDGE\\cthompson login failure / account lockout
Window: ~08:40 to 09:09
Scope: Single user only

Root cause:
- Repeated bad password submissions caused account lockout, with continued stale credential replay from a second source.
- Supporting evidence:
  - 08:44:01 Event 4776, 0xC000006A wrong password, source DESKTOP-FB022.
  - 08:44:03 / 08:44:28 / 08:44:55 Event 4625 bad password, Logon Type 2, source DESKTOP-FB022.
  - 08:44:56 Event 4740 account locked out, caller DESKTOP-FB022.
  - 08:45:10 Event 4625 account locked out, Logon Type 7.
  - 08:45:44 / 08:46:01 / 08:46:33 Event 4771, 0x18 wrong password, source IP 10.10.8.112.

Exact action taken:
- Applied lockout recovery sequence.
- Reconciled account state and administrative controls.
- Account was enabled at 09:08:14 (Event 4722) by FINBRIDGE\\helpdesk-admin.

Config/detail:
- Primary failing endpoint: DESKTOP-FB022.
- Secondary replay source: 10.10.8.112.
- Failure pattern: local interactive bad password attempts plus Kerberos pre-auth failures from secondary source.

Verification:
- 09:09:01 Event 4624 success for FINBRIDGE\\cthompson, Logon Type 2, source DESKTOP-FB022.
- User confirmed successful host login and no further issues.

Preventive action required:
1. Enforce lockout containment checklist: identify and stop all credential replay sources before enable/unlock.
2. Standardize credential source sweep for every lockout (workstation plus any secondary IP/source in 4771/4776).
3. Add monitoring alert for clustered 4771/4776 failures for one account across multiple sources.
4. Reinforce user/admin guidance to update saved credentials on all apps/devices after password changes.
5. Update known-error and runbook with this pattern: single-user lockout with secondary source replay.
