# L2/L3 Knowledge Base - AVD Immediate Disconnect Loop (POOL-FIN-01)

| Field | Value |
|---|---|
| Version | v1.0 |
| Date | 07/08/2026 |
| Status | Draft |

## Background
Azure Virtual Desktop (AVD) host pools provide virtual desktops to business users. Each user session depends on successful desktop initialization on the assigned session host. If desktop initialization fails on a host, users may sign in successfully but still lose access within seconds.

Why this matters:
- Finance and operations teams can be blocked from line-of-business applications even when identity and network authentication appear normal.
- The issue can look like a user or network problem, but in this incident it is host-side and can affect multiple users rapidly.

## Symptom
What users report:
- "I can log in, then the desktop disconnects right away."
- "It reconnects automatically, then drops again."

What the engineer observes:
- Impacted pool: POOL-FIN-01.
- Impacted host: SHFIN-01-A.
- Typical sequence: successful sign-in, disconnect within seconds, reconnect loop.
- Multiple users affected on same host (for example FINBRIDGE\mlopez and FINBRIDGE\akapoor).

## Root Cause
Specific technical cause:
- A regressed Intel graphics component on updated host image state caused dwm.exe to crash in igdumd64.dll during session startup on SHFIN-01-A.

Evidence that confirms root cause:
- Application Event ID 1000 on SHFIN-01-A shows:
	- Faulting application name: dwm.exe
	- Faulting module name: igdumd64.dll
	- Exception code: 0xc0000005
- TerminalServices-LocalSessionManager Event ID 21 (logon success) is followed within seconds by Event ID 40 (disconnect).
- Desktop Window Manager Event ID 9009 is recorded immediately after crashes.
- Kernel-General Event ID 1 confirms recent boot after overnight image update.
- Comparison host SHFIN-02-A in POOL-FIN-02 shows healthy behavior, including Desktop Window Manager Event ID 9011 and no matching Event ID 1000 crash pattern.

## Detection
Confirm this exact issue before acting.

1. In Azure portal, open path: Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > SHFIN-01-A > Sessions.
Expected result: You can identify active and recently disconnected users on SHFIN-01-A.

2. On SHFIN-01-A, open Event Viewer with Win + R > eventvwr.msc.
Expected result: Event Viewer opens for host-side investigation.

3. In Event Viewer, open log location: Windows Logs > Application.
Action: Click Filter Current Log and set Event IDs to 1000.
Field check in each matching event:
- Source: Application Error
- Event ID: 1000
- Faulting application name: dwm.exe
- Faulting module name: igdumd64.dll
- Exception code: 0xc0000005
Expected result: Repeated Event ID 1000 entries with same crash signature are present.

4. In Event Viewer, open log location: Applications and Services Logs > Microsoft > Windows > TerminalServices-LocalSessionManager > Operational.
Action: Click Filter Current Log and set Event IDs to 21,40.
Field check:
- Event ID 21: successful session logon
- Event ID 40: session disconnected
- Time relationship: Event ID 40 occurs within seconds of Event ID 21 for same user/session period
Expected result: Immediate post-logon disconnect sequence is visible.

5. In Event Viewer, open log location: Applications and Services Logs > Microsoft > Windows > Desktop Window Manager > Operational.
Action: Click Filter Current Log and set Event IDs to 9009,9011.
Field check:
- Event ID 9009 on SHFIN-01-A with abnormal DWM exit
- Event ID 9011 on healthy comparison host indicates normal DWM start
Expected result: Affected host shows 9009 failures; healthy host shows 9011 startup.

6. In Event Viewer on SHFIN-01-A, open log location: Windows Logs > System.
Action: Click Filter Current Log and set Event IDs to 1.
Field check:
- Source: Kernel-General
- Event ID: 1
- Boot timestamp aligns with overnight image update window
Expected result: Boot timing supports image-update correlation.

7. Perform comparison check across pools.
Action: Repeat Detection steps 3 to 5 on SHFIN-02-A in POOL-FIN-02.
Expected result: SHFIN-02-A does not show repeated Event ID 1000 dwm.exe/igdumd64.dll crashes and does show healthy DWM behavior.

Decision point:
- If Event IDs 1000 plus 21/40 plus 9009 are present on SHFIN-01-A and absent on SHFIN-02-A, treat as confirmed graphics/image regression on affected host path.

## Resolution
Apply the fix only after Detection confirms this pattern.

1. In Azure portal, go to Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > SHFIN-01-A.
Action: Set Allow new sessions to No.
Expected result: No new users are placed on SHFIN-01-A.

2. In same Azure portal path, open Sessions for SHFIN-01-A.
Action: Sign out each active session after user notification.
Expected result: Active session count on SHFIN-01-A becomes zero.

3. In Azure portal, go to Virtual machines > SHFIN-01-A > Connect > Bastion (or approved admin path).
Expected result: Administrative session to SHFIN-01-A is established.

4. On SHFIN-01-A, open elevated Command Prompt.
Action: Run pnputil /enum-drivers > C:\Temp\drivers-before-fix.txt.
Expected result: Pre-fix driver inventory is saved for audit and rollback traceability.

5. On SHFIN-01-A, open Device Manager (devmgmt.msc) > Display adapters > Intel display adapter > Properties > Driver tab.
Action: Select Roll Back Driver and complete wizard.
Expected result: Intel graphics driver reverts to previous known-good version.

6. On SHFIN-01-A, restart the host.
Expected result: Host boots with rolled-back graphics driver state.

7. In Azure portal, return to Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > SHFIN-01-A.
Action: Confirm Allow new sessions is still No.
Expected result: Host remains isolated for validation.

8. Perform one controlled test login to SHFIN-01-A.
Expected result: Session remains connected for at least 5 minutes.

9. On SHFIN-01-A, re-check logs:
- Windows Logs > Application, Event ID 1000
- Desktop Window Manager > Operational, Event ID 9009
Expected result: No new crash entries after rollback.

10. In Azure portal, go to Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > SHFIN-01-A.
Action: Set Allow new sessions to Yes.
Expected result: Host returns to production rotation.

11. Monitor Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > SHFIN-01-A > Sessions for 30 minutes.
Expected result: No immediate disconnect loop recurrence.

## Verification
Use all checks before closure.

1. In Event Viewer on SHFIN-01-A, verify Windows Logs > Application with Event ID 1000 filter for last 30 minutes.
Expected result: Zero new events with dwm.exe and igdumd64.dll crash signature.

2. In Event Viewer on SHFIN-01-A, verify Desktop Window Manager > Operational with Event ID 9009 filter for last 30 minutes.
Expected result: Zero new abnormal DWM exit events.

3. In Event Viewer on SHFIN-01-A, verify TerminalServices-LocalSessionManager > Operational with Event IDs 21,40 for last 30 minutes.
Expected result: Event ID 21 logons are not followed immediately by Event ID 40 disconnects.

4. In Azure portal path Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > SHFIN-01-A > Sessions, validate at least two user sessions remain Active for 10 minutes.
Expected result: Stable sessions with no reconnect loop.

5. Comparison re-check:
Action: Verify SHFIN-02-A in POOL-FIN-02 remains healthy and unchanged while SHFIN-01-A is restored.
Expected result: No cross-pool spread pattern.

## Rollback
Use this if the fix worsens behavior or introduces new instability.

1. In Azure portal path Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > SHFIN-01-A, set Allow new sessions to No immediately.
Expected result: New user impact is contained.

2. In same path, open Sessions and sign out active users on SHFIN-01-A after user notice.
Expected result: Active sessions drain to zero.

3. In Azure portal path Virtual machines > SHFIN-01-A, select Stop (Deallocate).
Expected result: Faulty host is removed from live service path.

4. Restore SHFIN-01-A to last known-good VM snapshot or redeploy from last known-good image version ID recorded in prerequisites.
Expected result: Host image state returns to pre-change baseline.

5. Start SHFIN-01-A and keep Allow new sessions set to No.
Expected result: Host is available for controlled validation only.

6. Run Detection steps 3 to 5 again before reopening host.
Expected result: Crash signature no longer appears.

7. If crash signature remains, keep host out of service and escalate to platform engineering with collected logs and driver inventory file.
Expected result: Safe containment with clear technical handoff.

## Preventive
Implement the following process and tooling changes.

1. Add release gate in image pipeline for graphics stack changes.
Specific change:
- Block production rollout unless pilot host passes scripted logon test and zero Event ID 1000 dwm.exe crashes in 15-minute validation.

2. Add automated detection rule in Azure Monitor for AVD host crash clusters.
Specific change:
- Alert when same host records three or more Application Event ID 1000 entries in 10 minutes where FaultingApplicationName equals dwm.exe and FaultingModulePath contains igdumd64.dll.

3. Add DWM health guardrail.
Specific change:
- Alert when Desktop Window Manager Event ID 9009 appears more than twice in 10 minutes on any session host.

4. Enforce phased deployment model by pool ring.
Specific change:
- Deploy image first to pilot ring (for example one host in non-critical pool), then business pool only after signed validation checklist.

5. Add mandatory comparison-host validation step to change process.
Specific change:
- For each incident after image change, compare affected host against at least one healthy host from separate pool and record Event IDs 1000, 9009, 9011 result in ticket template.

6. Maintain ready rollback artifact registry.
Specific change:
- Store and validate last known-good image version ID, snapshot ID, and driver package version per host pool on every approved release.

## Related
- RCA: day 4/rca-avd-session-disconnect-pool-fin-01-20240315.md
- Runbook: day 5/runbook-avd-session-disconnect-loop-pool-fin-01.md
- Triage summary: day 4/triage-summary-avd-disconnect-reconnect.md
