# Runbook - AVD Session Disconnect (POOL-FIN-01) - RCA Conversion

## 1. Prerequisites
- Confirm the incident matches this pattern: users can log on to AVD and are disconnected within seconds, then reconnect repeatedly.
- Confirm affected host is SHFIN-01-A in host pool POOL-FIN-01.
- Confirm at least one healthy comparison host is available (SHFIN-02-A in POOL-FIN-02 during this incident pattern).
- [ELEVATED] Confirm Azure RBAC access to manage AVD host pool session hosts and user sessions.
- [ELEVATED] Confirm Azure RBAC access to manage VM state for SHFIN-01-A.
- [ELEVATED] Confirm local admin access to SHFIN-01-A for Event Viewer and host checks.
- Confirm access to Azure portal: https://portal.azure.com.
- Confirm access to the incident ticket for recording timestamps and evidence.
- Confirm last known-good image or rollback target for SHFIN-01-A is identified before remediation starts.

## 2. Procedure
1. Open https://portal.azure.com.
Expected result: Azure portal landing page is displayed.

2. Sign in to the correct tenant and subscription.
Expected result: You can see the subscription that contains POOL-FIN-01.

3. Open Host pools in Azure portal.
Expected result: Host pool list is displayed.

4. Select host pool POOL-FIN-01.
Expected result: POOL-FIN-01 overview page is displayed.

5. Open Session hosts for POOL-FIN-01.
Expected result: Session host list is displayed.

6. Select SHFIN-01-A.
Expected result: SHFIN-01-A host details are displayed.

7. [ELEVATED] Set Allow new sessions to No on SHFIN-01-A.
Expected result: New user sessions are blocked from landing on SHFIN-01-A.

8. Open Sessions for SHFIN-01-A.
Expected result: Active session list is displayed.

9. [ELEVATED] Sign out one active user session on SHFIN-01-A.
Expected result: Selected session is removed from the active list.

10. [ELEVATED] Repeat sign-out for the next active user session on SHFIN-01-A.
Expected result: Active session count decreases again.

11. [ELEVATED] Continue session sign-outs until active session count is zero.
Expected result: SHFIN-01-A has no active user sessions.

12. Connect to SHFIN-01-A using the approved admin path.
Expected result: Interactive admin session to SHFIN-01-A is established.

13. Open Event Viewer on SHFIN-01-A.
Expected result: Event Viewer console is open.

14. Filter Windows Logs > Application for Event ID 1000.
Expected result: Application crash entries are shown.

15. Open the newest Event 1000 entry.
Expected result: Entry shows faulting application dwm.exe and module igdumd64.dll in this incident pattern.

16. Open Microsoft-Windows-TerminalServices-LocalSessionManager/Operational log.
Expected result: Session logon and disconnect events are visible.

17. Filter that log for Event IDs 21 and 40.
Expected result: Repeating logon (21) followed by near-immediate disconnect (40) is visible.

18. Open Microsoft-Windows-Desktop Window Manager/Operational log.
Expected result: DWM operational events are visible.

19. Filter that log for Event ID 9009.
Expected result: DWM abnormal exit events are visible during the failure window.

20. Compare the same three checks on SHFIN-02-A (Event 1000, 21/40, 9009).
Expected result: SHFIN-02-A does not show the same repeated crash/disconnect pattern in the same window.

21. [ELEVATED] Roll back SHFIN-01-A to the last known-good image or equivalent known-good host state.
Expected result: SHFIN-01-A is moved off the regressed graphics/image state.

22. [ELEVATED] Restart or redeploy SHFIN-01-A after rollback/correction.
Expected result: SHFIN-01-A returns online with corrected state active.

23. Keep Allow new sessions = No on SHFIN-01-A for controlled validation.
Expected result: No production users are routed to SHFIN-01-A during testing.

24. Start one controlled test logon to SHFIN-01-A.
Expected result: Test session remains connected without immediate disconnect.

25. Re-check Windows Logs > Application for new Event 1000 entries after the test logon.
Expected result: No new dwm.exe crash in igdumd64.dll is present.

26. Re-check Desktop Window Manager log for new Event 9009 entries after the test logon.
Expected result: No new DWM abnormal exit is present.

27. [ELEVATED] Set Allow new sessions to Yes on SHFIN-01-A.
Expected result: SHFIN-01-A is returned to normal user traffic.

28. Monitor live sessions on SHFIN-01-A for 30 minutes.
Expected result: Users remain connected without reconnect loop behavior.

29. Update the incident ticket with captured event evidence and remediation timestamps.
Expected result: Ticket contains complete technical record for closure.

## 3. Verification
1. Confirm at least two user sessions on SHFIN-01-A remain active for 10 minutes each.
Expected result: No immediate disconnect loop occurs.

2. Confirm no new Event 1000 entries with dwm.exe faulting in igdumd64.dll after remediation.
Expected result: Crash signature from the incident window is absent.

3. Confirm no new Event 9009 entries after remediation.
Expected result: DWM abnormal exit pattern is absent.

4. Confirm Event 21 entries are not followed within seconds by Event 40 entries.
Expected result: Session flow is stable.

5. Confirm users can log in to hosts in POOL-FIN-01 and no new issues are reported.
Expected result: Service is stable and incident can be closed.

## 4. Rollback
Use this immediately if disconnect behavior worsens after step 21 or step 22.

1. [ELEVATED] Set Allow new sessions to No on SHFIN-01-A.
Expected result: New affected sessions stop landing on SHFIN-01-A.

2. [ELEVATED] Sign out all active sessions on SHFIN-01-A.
Expected result: Active session count reaches zero.

3. [ELEVATED] Deallocate SHFIN-01-A from Azure VM controls.
Expected result: Host is removed from service and cannot accept sessions.

4. [ELEVATED] Keep user traffic on healthy hosts only.
Expected result: Users can continue working on non-impacted hosts.

5. [ELEVATED] Revert SHFIN-01-A to the previous known-good image state.
Expected result: Last known-good graphics/image baseline is restored.

6. [ELEVATED] Start SHFIN-01-A after baseline restore.
Expected result: Host boots with restored baseline.

7. Run one controlled validation logon on SHFIN-01-A before reopening traffic.
Expected result: Session remains connected and failure signature does not recur.

8. [ELEVATED] Set Allow new sessions to Yes only after successful validation.
Expected result: Host safely re-enters production.

## 5. Notes
- Warning: Do not reopen SHFIN-01-A to production traffic before validation confirms no new Event 1000 (dwm.exe/igdumd64.dll) and no new Event 9009.
- Edge case: If SHFIN-02-A also shows the same crash signature, treat as broader image/pool regression and keep all newly updated hosts blocked pending coordinated rollback.
- Edge case: If Event 1000 appears with a different faulting module, use a different runbook because this runbook is specific to igdumd64.dll pattern.
- Related incident record: day 4/rca-avd-session-disconnect-pool-fin-01-20240315.md.
- Related known error: day 4/known-error-avd-session-disconnect-pool-fin-01-20240315.md.
