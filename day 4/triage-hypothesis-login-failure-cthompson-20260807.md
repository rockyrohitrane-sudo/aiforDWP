# Triage Hypothesis - User Logon Failure (cthompson)

## Scope Facts Used
- Symptom: User `cthompson` not able to log in.
- Who: `cthompson` only (single user impact).
- Since: Around 08:40 this morning.
- Change: None reported.

## Ranked Top 5 Most Likely Causes (Most Probable First)

### 1) Account lockout or bad password attempts (user-specific authentication block)
Why this fits scope facts:
- Single-user impact strongly matches a user account state issue rather than a platform-wide outage.
- Sudden start time (~08:40) is consistent with lockout threshold being hit after repeated failed attempts (manual, mobile client, or stale saved credential).
- No declared environment change is required for this to occur.

Single fastest check:
- Check AD/Azure AD sign-in/authentication events for `cthompson` around 08:40 for lockout, bad password, or account disabled indicators.

### 2) Password expired, changed recently, or stale cached credentials on one client
Why this fits scope facts:
- Still single-user scoped.
- Can begin abruptly at first logon attempt in the morning.
- "No change" can be true from reporter perspective even when password expiry policy date is reached or another device keeps old credentials.

Single fastest check:
- Have `cthompson` attempt sign-in via a known-clean web sign-in portal (InPrivate browser) to confirm whether credentials are accepted outside the primary endpoint.

### 3) Conditional Access/MFA failure specific to this user session
Why this fits scope facts:
- User-only impact aligns with per-user MFA device issues, token drift, Authenticator app prompt failure, or policy condition hit only for that user context.
- Time-specific onset can map to token expiry or policy evaluation at first login after 08:40.
- No infrastructure change is needed for this pattern.

Single fastest check:
- Review the latest Entra sign-in log entry for `cthompson` and inspect the failure reason/code (especially CA block vs MFA requirement/failure).

### 4) User object state issue (disabled, expired, restricted sign-in hours, or missing group/license assignment)
Why this fits scope facts:
- Isolated user impact is consistent with user object attributes or assignments.
- Can appear suddenly if time-based restrictions (account expiry/sign-in hours) become active in the morning.
- "No change" may still hold if an automated process modified assignment/state.

Single fastest check:
- Open the user object and verify enabled status, account expiry, sign-in restrictions, and required group/license assignments in one admin view.

### 5) Endpoint-specific local profile/credential cache problem on cthompson's device
Why this fits scope facts:
- Single affected user often means device-local issue if backend auth is healthy.
- Morning onset can follow reboot/wake, credential provider glitch, or corrupted local token cache.
- No central change needed.

Single fastest check:
- Test sign-in for `cthompson` from a second known-good device (or web-only route); success there quickly eliminates central identity failure and points to endpoint-local fault.

## Note
This is a ranked hypothesis list from scope facts only. It does not commit to a final root cause yet.

## Evidence Assessment Against Incident Event Logs

### Hypothesis 1) Account lockout or bad password attempts (user-specific authentication block)
Judgement: Support.

Determining evidence:
- 08:44:01 - Security Event 4776 shows credential validation failure with error `0xC000006A` (wrong password) for `FINBRIDGE\cthompson` from `DESKTOP-FB022`.
- 08:44:03, 08:44:28, 08:44:55 - Security Event 4625 shows repeated bad password interactive failures.
- 08:44:56 - Security Event 4740 shows the account was locked out.
- 08:45:10 - Security Event 4625 shows failure reason `Account locked out` on unlock attempt.

### Hypothesis 2) Password expired, changed recently, or stale cached credentials on one client
Judgement: Support (specifically the stale/wrong credential path), neutral on password-expired from this data alone.

Determining evidence:
- 08:44:01 - Security Event 4776 `0xC000006A` (wrong password) supports use of invalid credentials.
- 08:44:03, 08:44:28, 08:44:55 - Security Event 4625 bad password failures support repeated invalid secret submission.
- 08:45:44, 08:46:01, 08:46:33 - Security Event 4771 failure code `0x18` (wrong password) from source IP `10.10.8.112` supports stale credentials being replayed from another endpoint/service path.
- No explicit password-expired event (for example, password expired status code) is present in the provided entries.

### Hypothesis 3) Conditional Access/MFA failure specific to this user session
Judgement: Contradicts.

Determining evidence:
- 08:44:01 - Security Event 4776 indicates wrong password at primary credential validation stage.
- 08:45:44, 08:46:01, 08:46:33 - Security Event 4771 `0x18` indicates Kerberos pre-auth wrong password.
- 08:44:56 - Security Event 4740 confirms account lockout after bad-password sequence.
- The provided events show password and lockout failures, not CA/MFA challenge or policy-deny indicators.

### Hypothesis 4) User object state issue (disabled, expired, restricted sign-in hours, or missing group/license assignment)
Judgement: Neutral to partial contradict.

Determining evidence:
- 08:44:01 - Security Event 4776 wrong password (`0xC000006A`) points away from disabled/expired/sign-in-hours as the initial trigger.
- 08:44:56 - Security Event 4740 shows lockout as a resulting account state change, which is a user object state but appears consequential to repeated wrong password attempts.
- Provided logs do not show explicit disabled account, account expired, or logon-hours restriction event/status.

### Hypothesis 5) Endpoint-specific local profile/credential cache problem on cthompson's device
Judgement: Support.

Determining evidence:
- 08:44:01, 08:44:03, 08:44:28, 08:44:55 - Security Events 4776/4625 show repeated wrong password attempts sourced from `DESKTOP-FB022`.
- 08:45:44, 08:46:01, 08:46:33 - Security Event 4771 wrong-password failures from source IP `10.10.8.112`, which differs from `DESKTOP-FB022` (`10.10.1.88`), supports additional stored/stale credentials on another endpoint or service path continuously submitting bad credentials.

## Assessment Constraint
All five hypotheses have been evaluated against evidence. No final winner is selected in this step.

## Surviving Hypothesis
Account lockout caused by repeated bad password submissions for `FINBRIDGE\cthompson`, likely including stale saved credentials from one or more sources.

Why this survives elimination:
- 08:44:01 Event 4776 shows wrong password (`0xC000006A`).
- 08:44:03, 08:44:28, 08:44:55 Event 4625 shows repeated interactive bad password attempts.
- 08:44:56 Event 4740 confirms account lockout.
- 08:45:44, 08:46:01, 08:46:33 Event 4771 (`0x18`) from `10.10.8.112` shows ongoing wrong-password replay from an additional source even after initial lockout sequence.

## Detailed Resolution Steps
1. Contain active lockout traffic before unlocking account.
- Isolate credential replay sources identified in logs: `DESKTOP-FB022` and endpoint/service at `10.10.8.112`.
- Temporarily disconnect affected user sessions on those sources or stop scheduled/background processes that may authenticate as `cthompson`.

2. Identify and remove stale credentials on each source.
- On `DESKTOP-FB022`, clear saved Windows credentials for `FINBRIDGE\cthompson` in Credential Manager.
- Check mapped drives, Outlook/Teams/OneDrive prompts, browser-saved enterprise credentials, and any "Run as" saved context.
- On source `10.10.8.112`, inspect services, scheduled tasks, scripts, mobile mail profiles, or legacy app pools using old credentials.

3. Reset password in a controlled manner.
- Perform a password reset for `cthompson` and force next sign-in password change if policy requires.
- Ensure new password is entered only after stale credential sources are cleaned to avoid immediate relock.

4. Unlock account after cleanup is complete.
- Unlock `FINBRIDGE\cthompson` in AD only when steps 1 and 2 are complete.
- Wait 60-120 seconds for AD replication if multiple DCs are in scope.

5. Validate successful authentication path.
- Test interactive sign-in once from a known-clean path.
- Confirm success event (for example, 4624 logon success) and absence of new 4625/4771/4776 failures for at least 10-15 minutes.

6. Reintroduce normal clients one at a time.
- Reconnect `DESKTOP-FB022`, then validate no fresh bad-password events.
- Re-enable the `10.10.8.112` source last, while monitoring authentication events in real time.

7. Prevent recurrence.
- Document the replay source (device/service/task) and owner.
- Update runbook: "clear stale credentials before unlock" for future lockout incidents.
- If applicable, enforce modern auth and reduce legacy/basic auth paths that often replay stale passwords.

## Addendum - Updated Event Details, Surviving Hypothesis, and Resolution

### Updated Event Details (Chronological)
- 08:44:01 - Security Event 4776 (Audit Failure): `0xC000006A` wrong password for `FINBRIDGE\cthompson` from `DESKTOP-FB022`.
- 08:44:03 - Security Event 4625 (Audit Failure): interactive logon failure, bad username/password, source `DESKTOP-FB022`.
- 08:44:28 - Security Event 4625 (Audit Failure): repeat interactive bad password, source `DESKTOP-FB022`.
- 08:44:55 - Security Event 4625 (Audit Failure): repeat interactive bad password, source `DESKTOP-FB022`.
- 08:44:56 - Security Event 4740 (Audit Failure): account `FINBRIDGE\cthompson` locked out, caller `DESKTOP-FB022`.
- 08:45:10 - Security Event 4625 (Audit Failure): unlock attempt blocked, failure reason `Account locked out`, source `DESKTOP-FB022`.
- 08:45:44 - Security Event 4771 (Audit Failure): Kerberos pre-auth failed, `0x18` wrong password, source IP `10.10.8.112`.
- 08:46:01 - Security Event 4771 (Audit Failure): repeat Kerberos pre-auth failure, `0x18`, source IP `10.10.8.112`.
- 08:46:33 - Security Event 4771 (Audit Failure): repeat Kerberos pre-auth failure, `0x18`, source IP `10.10.8.112`.

### Surviving Hypothesis (Updated Statement)
Primary surviving hypothesis: repeated wrong-password submissions caused account lockout for `FINBRIDGE\cthompson`, with continued credential replay from at least one additional source after lockout.

Evidence chain determining survival:
- Wrong password sequence is established by Event 4776 at 08:44:01 and Event 4625 at 08:44:03/08:44:28/08:44:55.
- Lockout transition is explicitly confirmed by Event 4740 at 08:44:56.
- Post-lockout replay is shown by Event 4771 at 08:45:44/08:46:01/08:46:33 from `10.10.8.112`.

### Resolution (Execution Checklist)
1. Freeze lockout triggers before account unlock.
- Identify and pause authentication attempts from `DESKTOP-FB022` and `10.10.8.112`.

2. Remove stale credentials from all identified sources.
- On `DESKTOP-FB022`: clear Credential Manager entries, remove saved credentials in Office/Teams/OneDrive/browser, and check mapped resources using old creds.
- On `10.10.8.112`: inspect scheduled tasks, services, scripts, app pools, and stored service credentials for `cthompson` references.

3. Perform controlled credential recovery.
- Reset the user password; communicate exact sign-in sequencing so old credentials are not retried.

4. Unlock account after cleanup confirmation.
- Unlock only after both sources are verified clean; allow AD replication window if multi-DC.

5. Validate stabilization.
- Execute one clean interactive sign-in test.
- Monitor for success (for example Event 4624) and verify no new Event 4625/4771/4776 for a defined watch period.

6. Re-enable sources incrementally.
- Bring `DESKTOP-FB022` back first, then `10.10.8.112`, monitoring logs after each reintroduction.

7. Close with prevention controls.
- Record definitive replay source and ownership.
- Add/update known-error and runbook guidance: clean stale credentials first, then unlock/reset.
