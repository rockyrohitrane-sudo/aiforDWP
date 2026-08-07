# RCA - Account Lockout and Login Failure (cthompson) - 2026-08-07

## Incident Summary
- Incident: User `FINBRIDGE\cthompson` unable to log in.
- Start time: Approximately 08:40.
- Recovery confirmed: 09:09.
- Final status: Resolved.

## Impact Assessment
- Affected user(s): `cthompson` only.
- Scope: Single-user authentication impact.
- Business impact: User productivity interruption during incident window; no evidence of wider service outage.

## Problem Statement
User `cthompson` experienced login failure due to account lockout after repeated bad password attempts, followed by continued wrong-password authentication traffic from more than one source.

## Supporting Evidence

### Failure Evidence During Incident
1. 08:44:01 - Security Event 4776 (Audit Failure)
- Account: `FINBRIDGE\cthompson`
- Error: `0xC000006A` (wrong password)
- Source workstation: `DESKTOP-FB022`

2. 08:44:03 - Security Event 4625 (Audit Failure)
- Failure reason: Unknown user name or bad password
- Logon type: 2 (Interactive)
- Source: `DESKTOP-FB022`

3. 08:44:28 - Security Event 4625 (Audit Failure)
- Failure reason: Unknown user name or bad password
- Logon type: 2 (Interactive)
- Source: `DESKTOP-FB022`

4. 08:44:55 - Security Event 4625 (Audit Failure)
- Failure reason: Unknown user name or bad password
- Logon type: 2 (Interactive)
- Source: `DESKTOP-FB022`

5. 08:44:56 - Security Event 4740 (Audit Failure)
- Event: Account locked out
- Account: `FINBRIDGE\cthompson`
- Caller computer: `DESKTOP-FB022`

6. 08:45:10 - Security Event 4625 (Audit Failure)
- Failure reason: Account locked out
- Logon type: 7 (Unlock attempt)
- Source: `DESKTOP-FB022`

7. 08:45:44 - Security Event 4771 (Audit Failure)
- Event: Kerberos pre-authentication failed
- Failure code: `0x18` (wrong password)
- Source IP: `10.10.8.112` (different from `DESKTOP-FB022`)

8. 08:46:01 - Security Event 4771 (Audit Failure)
- Failure code: `0x18` (wrong password)
- Source IP: `10.10.8.112`

9. 08:46:33 - Security Event 4771 (Audit Failure)
- Failure code: `0x18` (wrong password)
- Source IP: `10.10.8.112`

### Recovery and Validation Evidence
10. 09:08:14 - Security Event 4722 (Audit Success)
- Event: User account enabled
- Account: `FINBRIDGE\cthompson`
- Action by: `FINBRIDGE\helpdesk-admin`

11. 09:09:01 - Security Event 4624 (Audit Success)
- Event: Successful logon
- Account: `FINBRIDGE\cthompson`
- Logon type: 2 (Interactive)
- Source: `DESKTOP-FB022`

12. User validation
- User successfully logged in to host at/after 09:09 and reported no further issues.

## Incident Timeline (Detailed)
- ~08:40: User first unable to log in (reported start).
- 08:44:01: First confirmed wrong-password validation failure (Event 4776).
- 08:44:03 to 08:44:55: Multiple interactive bad-password attempts (Event 4625).
- 08:44:56: Account transitions to locked state (Event 4740).
- 08:45:10: Unlock attempt blocked due to locked account (Event 4625).
- 08:45:44 to 08:46:33: Continued Kerberos wrong-password attempts from second source IP `10.10.8.112` (Event 4771).
- 09:08:14: Account enabled by helpdesk-admin (Event 4722).
- 09:09:01: Successful interactive logon (Event 4624).
- 09:09 onward: User confirmed normal access; incident resolved.

## Root Cause Determination
Primary root cause:
- Account lockout triggered by repeated wrong-password submissions for `FINBRIDGE\cthompson`.

Contributing cause:
- Continued stale/incorrect credential replay from an additional source (`10.10.8.112`) after the initial lockout sequence.

Why alternatives were excluded:
- Evidence pattern is password/lockout specific (4776 `0xC000006A`, 4771 `0x18`, 4740), not Conditional Access/MFA policy denial.
- Single-user scope and successful recovery post-account action contradicts platform-wide service failure.

## 5 Whys Analysis
1. Why could `cthompson` not log in?
- Because the account was locked out and subsequent attempts were denied.

2. Why was the account locked out?
- Because repeated bad-password attempts occurred in a short time window.

3. Why were repeated bad-password attempts occurring?
- Because one or more endpoints/services were submitting stale or incorrect credentials.

4. Why did bad-password attempts continue after initial lockout?
- Because at least one additional source (`10.10.8.112`) continued automated or background authentication attempts with wrong credentials.

5. Why was stale credential replay not prevented before lockout impact?
- Because credential hygiene and lockout-containment steps (identify/reconcile all credential sources before account re-enable) were not completed early enough in the incident sequence.

## Resolution Actions Applied
- Followed lockout containment and recovery sequence.
- Reconciled account state and administrative controls to restore user access.
- Account enabled by helpdesk-admin at 09:08:14 (Event 4722).
- Successful user interactive sign-in at 09:09:01 (Event 4624).
- User confirmed access and no ongoing issue.

## Preventive Actions
1. Implement lockout containment checklist for Service Desk.
- Required steps before unlock/enable: identify all authenticating sources, stop background retries, then recover account.

2. Credential source sweep standard.
- For lockouts, always inspect primary workstation plus secondary IP/device sources from 4771/4776 logs.

3. Monitoring and alerting enhancement.
- Add alert for repeated 4771/4776 failures across multiple source hosts for one account within short interval.

4. User and admin guidance.
- Reinforce process to update saved credentials on all devices/apps immediately after password changes.

5. Known error/runbook update.
- Add this pattern to known-error records: "single user lockout + secondary source replay" with prescribed triage sequence.

## Verification of Effectiveness
- Technical verification: Event 4624 success at 09:09:01 for `cthompson` from `DESKTOP-FB022`.
- Functional verification: User confirmed successful login to host and no further issues.

## Closure Statement
Incident is closed as resolved. Root cause was account lockout from repeated wrong-password attempts with evidence of continued stale credential replay from a secondary source. Recovery was validated by successful security events and user confirmation.
