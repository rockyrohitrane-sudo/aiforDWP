# Runbook - AVD Immediate Disconnect Loop (POOL-FIN-01)

| Field | Value |
|---|---|
| Title | Runbook - AVD Immediate Disconnect Loop (POOL-FIN-01) |
| Version | 1.0 |
| Date | 07/08/2026 |
| Author | Rohit |
| Reviewed | self |
| Status | draft |
| Change | initial version from RCA |

## What This Guide Is For
Use this guide when users can sign in to the company virtual desktop service but are kicked out within a few seconds and then reconnect again and again.

## Prerequisites

Complete every checkbox before you start.

### Access Checklist

- [ ] Confirm the correct company Azure environment (tenant) and subscription for this incident.
- [ ] Confirm you can open the Azure website: https://portal.azure.com.
- [ ] Confirm your account has permission to manage Azure Virtual Desktop host pools (Contributor level or higher). [ELEVATED]
- [ ] Confirm your account can change Allow new sessions in host pool POOL-FIN-01. [ELEVATED]
- [ ] Confirm your account can sign out user sessions from hosts in POOL-FIN-01. [ELEVATED]
- [ ] Confirm your account is a local administrator on the affected host computer. [ELEVATED]
- [ ] Confirm you have an approved remote admin path to the host (Azure Bastion, jump server, or approved Remote Desktop route).

### Tools Checklist

- [ ] Browser is open and already signed in to Azure portal.
- [ ] Windows Event Viewer is available on the host (command: eventvwr.msc).
- [ ] Elevated Command Prompt is available on the host for driver listing command pnputil. [ELEVATED]
- [ ] Incident ticket and change record are open for notes and screenshots.

### Mandatory Information From End User

- [ ] At least one impacted user account (email-style username or domain username).
- [ ] Exact time the issue started (with local time zone).
- [ ] Exact symptom text from user (example: connects then disconnects within 10 seconds).
- [ ] Whether one user or multiple users are affected.
- [ ] Last successful login time for one impacted user (if known).
- [ ] Whether problem happens on more than one device or network.
- [ ] Screenshot or exact text of any virtual desktop error message.
- [ ] Confirmed affected host pool name from service desk note (must be POOL-FIN-01 for this runbook).

### Mandatory Platform Information

- [ ] Affected host name (example: SHFIN-01-A).
- [ ] Healthy comparison host name (example: SHFIN-02-A).
- [ ] Last known-good image version ID or snapshot ID for quick recovery.
- [ ] Change reference for the latest image or driver update.

## Procedure

1. Open https://portal.azure.com and sign in to the correct company Azure environment.
Expected result: Azure portal home page opens in the right environment.

2. In the top search bar, type Host pools and open the Host pools page.
Expected result: You can see the list of host pools.

3. Select host pool POOL-FIN-01.
Expected result: POOL-FIN-01 overview page opens.

4. In the left menu, select Session hosts.
Expected result: You can see all virtual desktop host computers in this pool.

5. Select host SHFIN-01-A.
Expected result: Details for SHFIN-01-A open.

6. Set Allow new sessions to No. [ELEVATED]
Expected result: New users are blocked from landing on SHFIN-01-A.

7. Select Sessions in the SHFIN-01-A details pane.
Expected result: Active user session list opens.

8. Select one active session.
Expected result: Session action buttons become available.

9. Click Sign out for that selected session after user notification. [ELEVATED]
Expected result: That session disappears from the list.

10. Repeat Sign out for remaining active sessions until the count is 0. [ELEVATED]
Expected result: SHFIN-01-A has zero active sessions.

11. Use Azure search to open Virtual machines.
Expected result: Virtual machine list page opens.

12. Select virtual machine SHFIN-01-A.
Expected result: SHFIN-01-A virtual machine overview opens.

13. Click Connect, then click Bastion (or your approved company remote admin method).
Expected result: Remote admin session to SHFIN-01-A starts.

14. On SHFIN-01-A, press Win + R, type eventvwr.msc, then press Enter.
Expected result: Event Viewer opens.

15. In Event Viewer, open Windows Logs > Application.
Expected result: Application error log entries are visible.

16. Click Filter Current Log and enter Event IDs: 1000.
Expected result: Only Event 1000 application crash entries are shown.

17. Open the newest Event 1000 and check for Faulting application name: dwm.exe and Faulting module name: igdumd64.dll.
Expected result: If both names appear, the issue matches this known pattern.

18. In Event Viewer, open Applications and Services Logs > Microsoft > Windows > TerminalServices-LocalSessionManager > Operational.
Expected result: Sign-in and disconnect activity log opens.

19. Click Filter Current Log and enter Event IDs: 21,40.
Expected result: Only sign-in and disconnect events are shown.

20. Check that user sign-in events (21) are followed within seconds by disconnect events (40).
Expected result: Repeated quick disconnect pattern is confirmed.

21. In Event Viewer, open Applications and Services Logs > Microsoft > Windows > Desktop Window Manager > Operational.
Expected result: Desktop display manager activity log opens.

22. Click Filter Current Log and enter Event IDs: 9009.
Expected result: Abnormal desktop display manager exit events are shown if present.

23. Connect to comparison host SHFIN-02-A and repeat steps 14 to 22.
Expected result: SHFIN-02-A does not show the same repeated crash and disconnect pattern.

24. On SHFIN-01-A, open Command Prompt as administrator and run: pnputil /enum-drivers > C:\Temp\drivers-before-fix.txt. [ELEVATED]
Expected result: Driver list file is created at C:\Temp\drivers-before-fix.txt.

25. On SHFIN-01-A, open Device Manager (devmgmt.msc) and expand Display adapters.
Expected result: Intel display adapter entry is visible.

26. Open Intel display adapter Properties.
Expected result: Device properties window opens.

27. Open the Driver tab.
Expected result: Current driver version and date are visible.

28. Click Roll Back Driver and complete the rollback wizard. [ELEVATED]
Expected result: Display driver returns to the previous version.

29. Restart SHFIN-01-A. [ELEVATED]
Expected result: Host restarts and comes back online.

30. In Azure portal, confirm SHFIN-01-A still has Allow new sessions = No.
Expected result: Host remains blocked for controlled testing.

31. Sign in to SHFIN-01-A with a designated test account.
Expected result: Session stays connected for at least 5 minutes.

32. In Event Viewer on SHFIN-01-A, reopen Windows Logs > Application and filter Event IDs: 1000.
Expected result: No new crash events showing dwm.exe with igdumd64.dll after the fix.

33. In Event Viewer on SHFIN-01-A, reopen Applications and Services Logs > Microsoft > Windows > Desktop Window Manager > Operational and filter Event IDs: 9009.
Expected result: No new Event 9009 entries after the fix.

34. In Azure portal at POOL-FIN-01 > Session hosts, set Allow new sessions to Yes for SHFIN-01-A. [ELEVATED]
Expected result: Host is returned to normal user traffic.

35. Watch live user sessions in Azure portal for 30 minutes.
Expected result: No immediate disconnect loop is seen.

36. Update the incident ticket with screenshots or copied details from steps 17, 20, 22, 32, and 33.
Expected result: Ticket contains full evidence and closure notes.

## Verification

1. Open https://portal.azure.com and go to Host pools > POOL-FIN-01 > Session hosts > SHFIN-01-A > Sessions.
Expected result: Live session list is visible.

2. Confirm at least two production users stay in Active state for 10 minutes.
Expected result: Sessions stay stable with no forced disconnect.

3. On SHFIN-01-A, press Win + R, type eventvwr.msc, and press Enter.
Expected result: Event Viewer opens.

4. In Event Viewer, go to Windows Logs > Application, click Filter Current Log, set Event IDs to 1000, and set Logged to Last 30 minutes.
Expected result: No new entries show dwm.exe crashing in igdumd64.dll.

5. In Event Viewer, go to Applications and Services Logs > Microsoft > Windows > Desktop Window Manager > Operational, click Filter Current Log, set Event IDs to 9009, and set Logged to Last 30 minutes.
Expected result: No new Event 9009 entries.

6. In Event Viewer, go to Applications and Services Logs > Microsoft > Windows > TerminalServices-LocalSessionManager > Operational, click Filter Current Log, set Event IDs to 21,40, and set Logged to Last 30 minutes.
Expected result: Sign-in events are not immediately followed by disconnect events.

7. In Azure portal, go to Host pools > POOL-FIN-01 > Session hosts and confirm SHFIN-01-A shows Available and Allow new sessions = Yes.
Expected result: Host is healthy and accepting users.

8. In the service desk tool, search incidents from the last 30 minutes using keyword POOL-FIN-01 disconnect.
Expected result: No new matching incident after the fix.

## Rollback (3-Minute Emergency Containment)

Target: stop user impact from SHFIN-01-A in under 3 minutes.

1. Open https://portal.azure.com and go to Host pools > POOL-FIN-01 > Session hosts.
Expected result: Session host list is visible.

2. Select SHFIN-01-A.
Expected result: Host details pane opens.

3. Set Allow new sessions to No. [ELEVATED]
Expected result: New user sessions stop landing on SHFIN-01-A.

4. Select Sessions in the SHFIN-01-A pane.
Expected result: Active session list is visible.

5. Click Sign out on each active session. [ELEVATED]
Expected result: Active session count becomes 0.

6. In Azure portal search, open Virtual machines, select SHFIN-01-A, click Stop (Deallocate), then confirm. [ELEVATED]
Expected result: VM power state changes to Stopped (deallocated).

7. Go back to Host pools > POOL-FIN-01 > Session hosts and confirm other healthy hosts still show Allow new sessions = Yes.
Expected result: Users can continue working on healthy hosts.

8. Check Host pools > POOL-FIN-01 > Session hosts > SHFIN-01-A > Sessions.
Expected result: SHFIN-01-A shows 0 active sessions.

9. Add rollback trigger reason and timestamp to the incident ticket.
Expected result: Containment action is fully time-stamped.

10. After containment, on SHFIN-01-A open Event Viewer (eventvwr.msc) and capture evidence from Windows Logs > Application (Event ID 1000) and Applications and Services Logs > Microsoft > Windows > Desktop Window Manager > Operational (Event ID 9009).
Expected result: Post-incident evidence is saved for follow-up analysis.

## Notes

- Edge case: If both SHFIN-01-A and SHFIN-02-A show the same pattern, treat this as a wider pool issue and keep recently updated hosts blocked from new sessions.
- Edge case: If Event ID 1000 exists but does not mention igdumd64.dll, use a separate troubleshooting runbook for the different module name.
- Warning: Do not set Allow new sessions back to Yes until post-fix checks are complete.
- Warning: Use a normal test account for validation, not a senior executive account.
- Related incident: See ../day 4/rca-avd-session-disconnect-pool-fin-01-20240315.md for full incident evidence.
- Related artifact: See ../day 4/known-error-avd-session-disconnect-pool-fin-01-20240315.md for known-error format alignment.
