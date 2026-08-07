# RCA - RDP Authentication Failures and Account Lockout (bwalker)

- Incident date: 2024-03-15
- Analysis window: 14:01:02 to 14:22:09
- User account: FINBRIDGE\bwalker
- Source client IP: 10.10.5.44
- Affected access path: Remote Desktop (Logon Type 10 - RemoteInteractive)

## 1) Event ID Explanations

### Event ID 56 (System, Source: TermDD, Error)
What it records:
- The Terminal Services security layer detected a protocol stream issue and disconnected the RDP client.

How it appears here:
- 14:01:02: Client 10.10.5.44 disconnected due to protocol/security-layer stream error.

### Event ID 140 (System, Source: RemoteDesktopServices-RdpCoreTS, Warning)
What it records:
- RDP connection failed because supplied user credentials were not accepted.

How it appears here:
- 14:01:02: Same client IP failed sign-in because username/password was not correct.

### Event ID 4625 (Security, Audit Failure)
What it records:
- Failed authentication attempt.
- Includes account, failure reason, logon type, and source IP.

How it appears here:
- 14:01:04, 14:03:18, 14:05:33: Three failed RemoteInteractive logons for FINBRIDGE\bwalker from 10.10.5.44 with reason "Unknown username or bad password."

### Event ID 4740 (Security, Account Lockout)
What it records:
- Account lockout occurred after policy threshold was reached.
- Includes caller computer/source.

How it appears here:
- 14:05:34: FINBRIDGE\bwalker account locked out, triggered by source 10.10.5.44.

### Event ID 131 (System, Source: RemoteDesktopServices-RdpCoreTS, Info)
What it records:
- RDP listener accepted a new TCP session from a client.

How it appears here:
- 14:22:07: New TCP connection accepted from 10.10.5.44:52341.

### Event ID 4624 (Security, Audit Success)
What it records:
- Successful authentication and logon session creation.

How it appears here:
- 14:22:09: FINBRIDGE\bwalker successfully logged on with Logon Type 10 from 10.10.5.44.

## 2) Reconstructed Sequence

1. At 14:01:02, the RDP stack reports a security/protocol disconnect (TermDD 56) and, at the same second, RDP auth failure due to invalid credentials (RdpCoreTS 140) from 10.10.5.44.
2. Three failed RemoteInteractive logons follow for FINBRIDGE\bwalker (4625 at 14:01:04, 14:03:18, 14:05:33), all indicating bad username/password.
3. One second after the third failure, account lockout is triggered (4740 at 14:05:34), source 10.10.5.44.
4. After a gap, the client reconnects (131 at 14:22:07) and successfully authenticates (4624 at 14:22:09).

## 3) Root Cause Determination

Primary root cause:
- Repeated invalid credential submission over RDP from client 10.10.5.44 caused the FINBRIDGE\bwalker account to hit lockout threshold.

Supporting evidence:
- Multiple sequential 4625 failures (same account, same source IP, same failure reason).
- Immediate 4740 lockout after repeated failures.
- Later successful 4624 from same IP indicates connectivity path was viable and account credentials were eventually corrected/unlocked.

Likely trigger patterns:
- Stale saved credentials in the RDP client (Credential Manager).
- User password recently changed but old password kept retrying.
- Scripted/background reconnect attempts using outdated credentials.

About TermDD Event 56 in this timeline:
- In this incident context, Event 56 is most likely secondary noise during failed authentication/handshake flow, not the primary cause of outage.

## 4) Impact Assessment

- User impact: Temporary inability to establish Remote Desktop session.
- Duration: Approximately 21 minutes from first failure to successful remote logon.
- Scope: Single user account and single source IP in provided evidence.
- Business impact: Short access interruption; no evidence of broader host/network outage from these events alone.

## 5) Corrective and Preventive Actions

Immediate corrective actions:
- Unlock account and verify current password with user.
- Remove saved credentials for target host on source client (`Control Panel -> Credential Manager`).
- Reattempt RDP sign-in with confirmed current password.

Preventive actions:
- Educate users to update stored credentials after password changes.
- Tune lockout alerting for clustered 4625 events before threshold lockout.
- Review endpoint for scheduled tasks/services using FINBRIDGE\bwalker credentials.
- If Event 56 recurs without auth failures, capture Schannel/terminal service traces for protocol-level troubleshooting.

## 6) Timeline

| Time     | Log | Event ID | Result         | Key Detail |
|----------|-----|----------|----------------|------------|
| 14:01:02 | System (TermDD) | 56   | Error          | Security layer protocol stream error; client disconnected |
| 14:01:02 | System (RdpCoreTS) | 140 | Warning        | Connection failed due to invalid username/password |
| 14:01:04 | Security | 4625 | Audit Failure  | FINBRIDGE\\bwalker failed RDP logon; bad password; source 10.10.5.44 |
| 14:03:18 | Security | 4625 | Audit Failure  | Repeated failed RDP logon; same account/source |
| 14:05:33 | Security | 4625 | Audit Failure  | Third failed RDP logon; same account/source |
| 14:05:34 | Security | 4740 | Audit Failure  | Account locked out; caller/source 10.10.5.44 |
| 14:22:07 | System (RdpCoreTS) | 131 | Information | New TCP connection accepted from 10.10.5.44:52341 |
| 14:22:09 | Security | 4624 | Audit Success  | Successful RDP logon for FINBRIDGE\\bwalker from 10.10.5.44 |

## 7) Final Conclusion

The incident is a classic RDP authentication lockout sequence: repeated bad credentials from one source IP caused account lockout, followed by successful access once credentials/account state were corrected. No direct evidence in this data set indicates server-side service failure as the primary cause.
