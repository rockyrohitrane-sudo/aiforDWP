# Triage Summary - T-1003

## Summary (one line)
AVD session disconnects after about 10 minutes and then reconnects, indicating potential session stability, network path, or policy timeout behavior (to-verify).

## Impact (who/how many/business urgency)
- Who: At least one AVD user; productivity affected by repeated session interruption (to-verify).
- How many: Currently reported as 1 user/session pattern; wider host pool impact unknown (to-verify).
- Business urgency: Medium-High if recurring during active work; higher if multiple users in same host pool are affected (to-verify).

## Known Facts
- Ticket ID: T-1003.
- Platform: Azure Virtual Desktop session.
- Symptom: Disconnect around 10 minutes, then reconnects.
- Pattern: Repeating timing behavior is reported (to-verify).

## Missing Information to Gather
- Whether issue occurs for one user or multiple users in same host pool.
- Whether disconnect happens on different networks (office/home/VPN) (to-verify).
- Client details: app vs web client and client version (to-verify).
- Time correlation: exact timestamps and whether pattern matches idle or active use.
- Whether only one session host is involved or issue follows user across hosts (to-verify).
- Any recent policy/session timeout changes in AVD environment (to-verify).

## Likely Category
Virtual desktop session reliability issue (connection stability or timeout policy) (to-verify).

## First Diagnostic Step
Capture exact disconnect timestamps and compare with session host/user activity to determine whether the trigger is idle timeout, network interruption, or host-specific instability (to-verify).

## Event Details Review (2024-03-15 07:00-07:30)
- Affected host: `SHFIN-01-A`.
- 07:02:10: TerminalServices-LocalSessionManager Event 21 shows successful session logon for `FINBRIDGE\mlopez`, Session ID 3, source `10.10.1.55`.
- 07:02:14: Kernel-General Event 1 states system boot time was `2024-03-15 02:03:11`, consistent with host restart after overnight image update.
- 07:02:16: Application Error Event 1000 shows `dwm.exe` faulting in `igdumd64.dll`, exception `0xc0000005`.
- 07:02:17: TerminalServices-LocalSessionManager Event 40 shows `FINBRIDGE\mlopez` disconnected, Session ID 3, reason code 0.
- 07:02:18: Desktop Window Manager Event 9009 reports DWM exited with code `0x40010004`.
- 07:02:44: TerminalServices-LocalSessionManager Event 21 shows successful reconnect for `FINBRIDGE\mlopez`, Session ID 3.
- 07:02:46: Application Error Event 1000 again shows `dwm.exe` faulting in `igdumd64.dll`.
- 07:02:47: TerminalServices-LocalSessionManager Event 40 shows second disconnect for `FINBRIDGE\mlopez`, Session ID 3.
- 07:03:01: Desktop Window Manager Event 9009 again reports DWM exit with code `0x40010004`.
- 07:03:10: TerminalServices-LocalSessionManager Event 21 shows second reconnect for `FINBRIDGE\mlopez`, now Session ID 4.
- 07:08:22: TerminalServices-LocalSessionManager Event 21 shows successful logon for `FINBRIDGE\akapoor`, Session ID 5, source `10.10.1.61`.
- 07:08:24: Application Error Event 1000 again shows `dwm.exe` faulting in `igdumd64.dll` on the same host.
- Comparison host `SHFIN-02-A` shows normal behavior: 07:01:44 Event 21 successful logon and 07:01:46 Desktop Window Manager Event 9011 started successfully, with no Application Error Event 1000 entries in the same window.

## Reviewed Hypotheses
1. Graphics driver regression introduced by the overnight image update on `SHFIN-01-A`.
	Judgement: Support.
	Determining evidence: Event 1000 at 07:02:16, 07:02:46, and 07:08:24 shows `dwm.exe` crashing in `igdumd64.dll`; Event 1 at 07:02:14 ties the host state to a post-update reboot.

2. General host-specific instability on `SHFIN-01-A`.
	Judgement: Support.
	Determining evidence: Event 21 at 07:02:10 is followed by Event 1000 at 07:02:16 and Event 40 at 07:02:17; the same pattern repeats at 07:02:44, 07:02:46, and 07:02:47, and also affects `FINBRIDGE\akapoor` at 07:08:22 to 07:08:24.

3. Session timeout or idle-policy driven disconnect.
	Judgement: Contradicts.
	Determining evidence: Event 21 at 07:02:10 is followed by disconnect Event 40 at 07:02:17, and Event 21 at 07:02:44 is followed by Event 40 at 07:02:47, which is too immediate for idle or session timeout behavior.

4. Network path or client connectivity issue.
	Judgement: Contradicts.
	Determining evidence: Event 1000 at 07:02:16 and 07:02:46, plus DWM Event 9009 at 07:02:18 and 07:03:01, show a host-side graphics/session compositor failure immediately before disconnect.

5. User-specific issue limited to `FINBRIDGE\mlopez`.
	Judgement: Contradicts.
	Determining evidence: Event 21 at 07:08:22 for `FINBRIDGE\akapoor` is followed by the same Event 1000 crash at 07:08:24 on `SHFIN-01-A`.

6. Broad AVD platform or pool-wide issue affecting all hosts equally.
	Judgement: Contradicts.
	Determining evidence: Comparison host `SHFIN-02-A` shows Event 9011 at 07:01:46 with successful DWM start and no Application Error Event 1000 during the same window.

## Surviving Hypothesis
Graphics driver regression introduced by the overnight host image update on `SHFIN-01-A`, specifically the Intel graphics component `igdumd64.dll` causing `dwm.exe` to crash during AVD session initialization.

## Detailed Resolution Steps
1. Place `SHFIN-01-A` in drain mode or remove it from load balancing so no new user sessions land on the affected host.
2. Move active affected users to healthy session hosts or a known-good pool while remediation is performed.
3. Compare the overnight image update on `SHFIN-01-A` against the healthy baseline on `SHFIN-02-A`, focusing on Intel graphics driver version, display stack components, and any optional Windows updates packaged into the image.
4. Roll back the affected host to the last known-good image version, or if image rollback is not immediately possible, roll back or remove the Intel graphics driver package associated with `igdumd64.dll` and restart the host.
5. If the host is image-based and non-persistent, prefer redeploying `SHFIN-01-A` from the last known-good image rather than performing manual in-place repair.
6. Validate with controlled test sign-ins after rollback or redeploy: confirm successful session logon, confirm no new Application Error Event 1000 entries for `dwm.exe`, and confirm no new Desktop Window Manager Event 9009 exits.
7. Return the host to service gradually only after clean validation, initially allowing limited sessions and monitoring the next active login window for recurrence.
8. Remove or replace the regressed graphics driver in the gold image, then test the corrected image in a pre-production or limited host subset before wider deployment.
9. Record a known-error entry documenting the symptom, affected image state, workaround of moving users to healthy hosts, and permanent fix of image/driver rollback and validation before redeployment.