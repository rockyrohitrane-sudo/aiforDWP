# RCA - AVD Session Disconnect Incident (POOL-FIN-01)

- Incident date: 2024-03-15
- Analysis window: 07:00 to 10:00
- Platform: Azure Virtual Desktop
- Affected host: `SHFIN-01-A`
- Comparison host: `SHFIN-02-A` (`POOL-FIN-02`, unaffected)
- Primary symptom: Users could log on to AVD, then disconnect almost immediately and reconnect repeatedly.
- Recovery status: Resolved at 10:00 AM after the recommended remediation path was applied.

## 1) Incident Summary

Users connecting through `POOL-FIN-01` experienced immediate post-logon disconnect behavior on session host `SHFIN-01-A`. Event correlation shows successful user logon, followed within seconds by `dwm.exe` crashes in `igdumd64.dll`, then Remote Desktop session disconnects. A comparison host on the pre-update image did not show the same failure pattern. The evidence supports a graphics driver regression introduced by the overnight host image update. Remediation was applied and service was verified as restored by 10:00 AM, with users successfully logging in to hosts in `POOL-FIN-01` and no further issues reported.

## 2) Scope and Impact

- Impacted service: Azure Virtual Desktop sessions in `POOL-FIN-01`.
- Confirmed affected host: `SHFIN-01-A`.
- Confirmed affected users in supplied evidence: `FINBRIDGE\mlopez` and `FINBRIDGE\akapoor`.
- User impact: Users were able to authenticate but were disconnected during desktop initialization, causing session instability and lost productivity.
- Business impact: Finance users in the affected pool had impaired access to their virtual desktops until remediation completed.

## 3) Supporting Evidence

### Host State Evidence
- 07:02:14: Kernel-General Event 1 on `SHFIN-01-A` shows system boot time `2024-03-15 02:03:11`.
- This aligns with the note that the host restarted after an overnight image update.

### Failure Evidence on Affected Host
- 07:02:10: TerminalServices-LocalSessionManager Event 21 shows successful session logon for `FINBRIDGE\mlopez`, Session ID 3.
- 07:02:16: Application Error Event 1000 shows `dwm.exe` faulting in `igdumd64.dll`, exception `0xc0000005`.
- 07:02:17: TerminalServices-LocalSessionManager Event 40 shows `FINBRIDGE\mlopez` disconnected.
- 07:02:18: Desktop Window Manager Event 9009 shows DWM exited with code `0x40010004`.
- 07:02:44: Event 21 shows `FINBRIDGE\mlopez` reconnecting successfully.
- 07:02:46: Event 1000 repeats the same `dwm.exe` and `igdumd64.dll` crash pattern.
- 07:02:47: Event 40 shows a second disconnect.
- 07:03:01: Event 9009 again shows DWM exiting abnormally.
- 07:03:10: Event 21 shows second reconnect for `FINBRIDGE\mlopez`, now Session ID 4.
- 07:08:22: Event 21 shows successful session logon for `FINBRIDGE\akapoor`, Session ID 5.
- 07:08:24: Event 1000 again shows `dwm.exe` faulting in `igdumd64.dll` on the same host.

### Comparison Evidence from Healthy Host
- 07:01:44: `SHFIN-02-A` shows TerminalServices-LocalSessionManager Event 21 for successful session logon.
- 07:01:46: `SHFIN-02-A` shows Desktop Window Manager Event 9011 stating DWM started successfully.
- No Application Error Event 1000 entries were reported on `SHFIN-02-A` in the same time window.

### Recovery Evidence
- The recommended remediation path was applied.
- Service was confirmed restored at 10:00 AM.
- Users were verified logging in to hosts in `POOL-FIN-01` with no issues reported after remediation.

## 4) Hypothesis Review and Elimination

### Hypothesis 1: Graphics driver regression introduced by the overnight image update
Judgement:
- Supported.

Reasoning:
- Event 1000 at 07:02:16, 07:02:46, and 07:08:24 consistently shows `dwm.exe` crashing in `igdumd64.dll`.
- Kernel-General Event 1 at 07:02:14 ties the affected host state to a recent reboot after the overnight image update.
- The unaffected comparison host on the pre-update image does not show the same pattern.

### Hypothesis 2: General host-specific instability on `SHFIN-01-A`
Judgement:
- Supported, but subordinate to the graphics driver finding.

Reasoning:
- Multiple users on the same host experience the same failure sequence.
- The instability is real, but the event pattern indicates the instability is driven by the graphics stack failure rather than a generic, unexplained host condition.

### Hypothesis 3: Session timeout or idle-policy disconnect
Judgement:
- Contradicted.

Reasoning:
- Disconnects occur within seconds of successful logon: 07:02:10 to 07:02:17 and 07:02:44 to 07:02:47.
- That timing does not fit idle timeout, max session duration, or policy-based logoff behavior.

### Hypothesis 4: Network path or client connectivity issue
Judgement:
- Contradicted.

Reasoning:
- Host-side crash events appear immediately before disconnects.
- The same server-side application fault appears for more than one user, which is inconsistent with a single-client or network-only explanation.

### Hypothesis 5: User-specific issue limited to `FINBRIDGE\mlopez`
Judgement:
- Contradicted.

Reasoning:
- `FINBRIDGE\akapoor` also triggers the same Event 1000 failure at 07:08:24 on the same host.

### Hypothesis 6: Broad pool-wide or AVD platform-wide outage affecting all hosts equally
Judgement:
- Contradicted.

Reasoning:
- `SHFIN-02-A` remains healthy in the same window, showing successful DWM startup and no application crash evidence.

## 5) Root Cause Statement

Primary root cause:
- A graphics driver regression introduced by the overnight image update on `SHFIN-01-A` caused `dwm.exe` to crash in `igdumd64.dll` during session initialization, which in turn disconnected user AVD sessions.

Contributing factors:
- The updated image was active on the affected host before sufficient validation of desktop initialization behavior under user logon.
- The issue was host/image-state specific rather than pool-wide, which delayed narrowing until event correlation was reviewed.

## 6) Resolution Applied

The recommended remediation path for the identified graphics/image regression was applied to the affected service path. Based on the available evidence and recovery confirmation, the operational resolution consisted of removing the faulty host/image state from active user impact, restoring the host or pool path to a known-good state, and validating user logon behavior afterward.

Resolution outcome:
- Issue resolved at 10:00 AM.
- Users were verified logging in successfully to hosts in `POOL-FIN-01`.
- No issues were reported after validation.

## 7) Detailed Resolution Steps

1. Isolate the affected host from new user traffic so additional sessions do not land on the unstable image state.
2. Redirect or keep users on healthy hosts while the affected host or image path is remediated.
3. Compare the affected host image state with the healthy baseline, specifically the graphics driver and display stack components.
4. Roll back or correct the regressed graphics/image state to the last known-good baseline.
5. Restart or redeploy the affected host so the corrected state is active.
6. Perform controlled validation logons and confirm no new Event 1000 `dwm.exe` faults and no new Event 9009 DWM exits occur.
7. Return the host or corrected pool capacity to service.
8. Confirm live users can log in to `POOL-FIN-01` without disconnect or reconnect symptoms.

## 8) Reconstructed Timeline

1. 02:03:11: `SHFIN-01-A` boots after the overnight image update.
2. 07:02:10: `FINBRIDGE\mlopez` logs on successfully to `SHFIN-01-A`.
3. 07:02:16: `dwm.exe` crashes in `igdumd64.dll` on `SHFIN-01-A`.
4. 07:02:17: `FINBRIDGE\mlopez` is disconnected.
5. 07:02:18: DWM exits abnormally.
6. 07:02:44: `FINBRIDGE\mlopez` reconnects.
7. 07:02:46: The same `dwm.exe` crash reoccurs.
8. 07:02:47: The session disconnects again.
9. 07:03:01: DWM exit is recorded again.
10. 07:03:10: `FINBRIDGE\mlopez` reconnects on Session ID 4.
11. 07:08:22: `FINBRIDGE\akapoor` logs on successfully to the same host.
12. 07:08:24: The same `dwm.exe` and `igdumd64.dll` crash occurs again.
13. 10:00:00: Remediation is complete and user validation confirms successful logons in `POOL-FIN-01` with no further issues reported.

## 9) Timeline Table

| Time     | Event ID | Result        | Key Detail |
|----------|----------|---------------|------------|
| 02:03:11 | 1        | Information   | `SHFIN-01-A` boot time following overnight image update |
| 07:02:10 | 21       | Success       | `FINBRIDGE\mlopez` session logon succeeded on `SHFIN-01-A` |
| 07:02:16 | 1000     | Error         | `dwm.exe` faulting application; module `igdumd64.dll`; exception `0xc0000005` |
| 07:02:17 | 40       | Disconnect    | `FINBRIDGE\mlopez` session disconnected |
| 07:02:18 | 9009     | Error         | Desktop Window Manager exited with code `0x40010004` |
| 07:02:44 | 21       | Success       | `FINBRIDGE\mlopez` reconnect logon succeeded |
| 07:02:46 | 1000     | Error         | Repeat `dwm.exe` crash in `igdumd64.dll` |
| 07:02:47 | 40       | Disconnect    | Second disconnect for `FINBRIDGE\mlopez` |
| 07:03:01 | 9009     | Error         | Repeat DWM abnormal exit |
| 07:03:10 | 21       | Success       | Second reconnect for `FINBRIDGE\mlopez`, Session ID 4 |
| 07:08:22 | 21       | Success       | `FINBRIDGE\akapoor` session logon succeeded |
| 07:08:24 | 1000     | Error         | Same `dwm.exe` crash pattern on same host |
| 07:01:44 | 21       | Success       | `SHFIN-02-A` comparison host logon succeeded |
| 07:01:46 | 9011     | Information   | `SHFIN-02-A` DWM started successfully; no app crash observed |
| 10:00:00 | N/A      | Resolved      | Remediation validated; users logging in to `POOL-FIN-01` with no issues reported |

## 10) 5 Whys Analysis

1. Why were users disconnected immediately after logging on to AVD?
- Because the desktop initialization process on `SHFIN-01-A` failed and their sessions were disconnected.

2. Why did desktop initialization fail on `SHFIN-01-A`?
- Because `dwm.exe` crashed during session startup.

3. Why did `dwm.exe` crash during session startup?
- Because it faulted in the Intel graphics module `igdumd64.dll`, recorded repeatedly in Application Error Event 1000.

4. Why was the faulty graphics module active on the host?
- Because the affected host had been restarted onto the overnight updated image state before the issue was detected.

5. Why did the updated image state introduce user impact?
- Because the graphics/display stack change was not fully validated for user session startup behavior before the host accepted production user logons.

## 11) Corrective and Preventive Actions

### Corrective Actions Taken
- The recommended remediation path for the affected host/image state was applied.
- User access was revalidated in `POOL-FIN-01` and confirmed stable by 10:00 AM.

### Preventive Actions
- Add a post-image-update validation step that performs real AVD user logon testing and confirms DWM startup health before opening hosts to production traffic.
- Add monitoring or alerting for clustered Application Error Event 1000 entries involving `dwm.exe` and graphics modules on session hosts.
- Add a release gate for image changes affecting graphics, display, or optimization components.
- Keep a documented rollback path to the last known-good host image for each AVD pool.
- Use phased deployment for host image updates so a small subset of hosts is validated before broad rollout.

## 12) Final Determination

The incident was caused by a graphics driver regression on `SHFIN-01-A` introduced by the overnight image update. The regression caused `dwm.exe` to crash in `igdumd64.dll`, leading to repeated AVD disconnects immediately after user logon. After the recommended remediation was applied, service was confirmed restored at 10:00 AM, and users were able to log in successfully to hosts in `POOL-FIN-01` with no further reported issues.