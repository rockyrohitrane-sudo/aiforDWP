# RCA - User Lockout Incident (jsmith)

- Incident date: 2026-08-06
- Analysis window: 08:02:14 to 08:23:44 (about 21 minutes of events within the provided 30-minute period)
- User account: jsmith
- Endpoint: DESKTOP-FB001
- Analyst context: Windows Security Event Log review

## 1) Event ID Explanations

### Event ID 4625 (Audit Failure) - Failed Logon
What it records:
- A logon attempt that failed authentication.
- Includes reason (for example bad password or locked account), account name, source system, and logon type.

How it appears in this incident:
- 08:02:14: Failed logon for `jsmith`, reason: unknown username or bad password, logon type 2 (interactive).
- 08:04:22: Failed logon for `jsmith`, same reason, logon type 2.
- 08:07:45: Failed logon for `jsmith`, reason changed to account locked out, logon type 7 (unlock).

### Event ID 4740 (Audit Failure) - Account Lockout
What it records:
- The account lockout event itself.
- Indicates that the account reached lockout threshold and was locked.
- Includes caller computer that originated the triggering authentication attempt.

How it appears in this incident:
- 08:06:01: `jsmith` account locked out, called from DESKTOP-FB001.

### Event ID 4722 (Audit Success) - Account Enabled
What it records:
- A user account was enabled (or re-enabled) by an administrator or delegated operator.
- Includes actor identity and target account.

How it appears in this incident:
- 08:22:10: Account `jsmith` enabled by `FINBRIDGE\helpdesk-admin`.

### Event ID 4624 (Audit Success) - Successful Logon
What it records:
- A successful authentication and logon session creation.
- Includes logon type and account details.

How it appears in this incident:
- 08:23:44: `jsmith` successful logon, logon type 2 (interactive).

## 2) Reconstructed Sequence (Plain English)

1. At 08:02, `jsmith` tried to sign in interactively on DESKTOP-FB001, but the credentials were rejected as bad username/password.
2. At 08:04, a second interactive sign-in attempt from the same machine also failed for bad username/password.
3. At 08:06, the account lockout threshold was reached, generating event 4740 and locking `jsmith`.
4. At 08:07, the user attempted to unlock the session (logon type 7), but this failed because the account was already locked.
5. At 08:22, helpdesk administrator `FINBRIDGE\helpdesk-admin` enabled/re-enabled the account.
6. At 08:23, `jsmith` signed in successfully using interactive logon.

## 3) Most Likely Cause of Lockout (with Evidence)

Most likely cause:
- Repeated incorrect password entry during local interactive sign-in attempts on DESKTOP-FB001 caused the account to hit lockout threshold.

Evidence:
- Two pre-lockout failed interactive logons (event 4625 at 08:02:14 and 08:04:22) both report bad username/password.
- Lockout event 4740 occurs shortly after (08:06:01), same user and same source machine (DESKTOP-FB001), consistent with threshold-based lockout behavior.
- Post-lockout failed unlock attempt (4625 at 08:07:45, logon type 7) confirms account state had transitioned to locked.
- Administrative intervention (4722 at 08:22:10) is followed by immediate successful interactive sign-in (4624 at 08:23:44), indicating credentials were valid once account state was remediated.

Confidence level:
- High, based on event ordering, reason codes, and single-source endpoint attribution.

## 4) Detailed RCA

### Incident Summary
`jsmith` became unable to access DESKTOP-FB001 due to account lockout after multiple failed authentication attempts. Helpdesk restored account availability, and user access was recovered.

### Scope and Impact
- Impacted user: `jsmith`
- Impacted asset: DESKTOP-FB001
- User impact: Unable to sign in/unlock session for approximately 16-21 minutes (from lockout to successful post-remediation login).
- Business impact: Temporary productivity loss for one user; no broader service outage evidenced in provided logs.

### Detection
- Security log indicators:
  - 4625 failures with bad password reason.
  - 4740 lockout event.
  - 4722 administrative enablement.
  - 4624 successful recovery login.

### Root Cause Statement
Primary root cause:
- Incorrect credential attempts on interactive logon from DESKTOP-FB001 triggered Active Directory/domain lockout threshold for account `jsmith`.

Contributing factors:
- No evidence of preemptive user warning before threshold was reached.
- User attempted unlock after lockout, which cannot succeed until account state is restored.

### 5 Whys Analysis
1. Why was `jsmith` locked out?
- Because the account exceeded failed authentication threshold and generated event 4740.

2. Why was the threshold exceeded?
- Because multiple logon attempts failed with "unknown username or bad password" (events 4625 at 08:02 and 08:04, with subsequent lockout at 08:06).

3. Why were logon attempts failing?
- Most likely incorrect password was entered for interactive sign-in on DESKTOP-FB001.

4. Why did the user remain unable to access immediately after lockout?
- Because after lockout, an unlock logon attempt (type 7) still failed due to account status being locked (4625 at 08:07).

5. Why was service restored only later?
- Account access required admin action (4722 by `FINBRIDGE\helpdesk-admin`), after which successful sign-in occurred (4624).

### Corrective Actions Taken
- Helpdesk re-enabled/recovered account access (event 4722).
- User authenticated successfully afterward (event 4624), confirming incident closure.

### Preventive Actions (Recommended)
- Provide end-user guidance for password entry and lockout thresholds during sign-in failures.
- Enable proactive lockout warning prompts before threshold is reached where supported.
- Review account lockout policy balance (security vs usability) with security governance.
- Verify whether cached/remembered credentials on endpoint or mapped resources are repeatedly submitting stale passwords.
- Implement alerting for clustered 4625 failures from a single endpoint before lockout occurs.

### Validation Checks for Follow-up
- Confirm no continued 4625 failures for `jsmith` after 08:23:44.
- Confirm endpoint DESKTOP-FB001 has no scheduled task/service using stale credentials for `jsmith`.
- Confirm user performed password verification/change workflow if needed.

## 5) Timeline Table

| Time     | Event ID | Result         | Key Detail |
|----------|----------|----------------|------------|
| 08:02:14 | 4625     | Audit Failure  | Interactive logon failed; bad username/password |
| 08:04:22 | 4625     | Audit Failure  | Second interactive failure; bad username/password |
| 08:06:01 | 4740     | Audit Failure  | Account locked out; caller DESKTOP-FB001 |
| 08:07:45 | 4625     | Audit Failure  | Unlock attempt failed; account locked out |
| 08:22:10 | 4722     | Audit Success  | Account enabled by FINBRIDGE\helpdesk-admin |
| 08:23:44 | 4624     | Audit Success  | Interactive logon successful |

## 6) Final Determination
Most probable lockout trigger is repeated incorrect password entry by user `jsmith` during interactive sign-in attempts on DESKTOP-FB001, resulting in threshold lockout, followed by helpdesk administrative recovery and normal access restoration.
