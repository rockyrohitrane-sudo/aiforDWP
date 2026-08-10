# KB: AVD Immediate Disconnect Loop on Host SHFIN-01-A (POOL-FIN-01)

| Field | Value |
|---|---|
| Version | v 1.0 |
| Date | 07/08/2026 |
| Status | Draft |
| Audience | L2/L3 DWP Engineer |
| Scope | Diagnose and resolve immediate disconnect loop from scratch |

## Background: what the system does and why it matters
Azure Virtual Desktop (AVD) host pool `POOL-FIN-01` delivers shared virtual desktop sessions for finance users. Session hosts (for example `SHFIN-01-A`, `SHFIN-02-A`) accept user sign-ins and maintain an active desktop session.

This matters because if one host enters an immediate disconnect loop, users are repeatedly signed in then disconnected within seconds. That causes productivity loss, repeated support calls, and can spread impact if session brokering continues placing users on the unstable host.

## Symptom: what the engineer observes and what users report
### What users report
- "I can connect, then I get kicked out in a few seconds."
- Repeating sign-in/disconnect cycle.
- Issue often affects multiple users assigned to the same host pool.

### What the engineer observes
- In Azure portal, users briefly appear in active sessions on `SHFIN-01-A` and then disappear.
- Session host appears available, but user sessions are unstable.
- Event logs on affected host show repeated desktop/session termination pattern.

## Root Cause: the specific technical cause with confirming evidence
**Root cause:** an unstable Intel display driver on `SHFIN-01-A` causes `dwm.exe` to crash in module `igdumd64.dll`, which terminates graphical session handling and leads to rapid user disconnects.

**Evidence pattern that confirms this cause:**
- Windows Application log Event ID `1000` contains:
  - Field `Faulting application name`: `dwm.exe`
  - Field `Faulting module name`: `igdumd64.dll`
- Terminal Services Local Session Manager Operational log shows Event ID `21` (sign-in) followed within seconds by Event ID `40` (disconnect) for impacted users.
- Desktop Window Manager Operational log shows Event ID `9009` during the same time window.
- Comparison host `SHFIN-02-A` does not show the same repeating `1000/9009` crash pattern.

## Detection: exactly how to confirm this is the issue before acting
Target time: under 3 minutes. Use command-first detection before making changes.

1. Confirm affected and control hosts.
    - Azure portal path: `Azure portal > Host pools > POOL-FIN-01 > Session hosts`
    - Confirm affected host: `SHFIN-01-A`
    - Confirm unaffected control host: `SHFIN-02-A` (control in POOL-FIN-02 baseline check below).

2. Pull required events from `SHFIN-01-A` using PowerShell (fast path).
    - Run from an admin workstation with remoting rights:
    - ```powershell
       $since = (Get-Date).AddHours(-2)
       Invoke-Command -ComputerName SHFIN-01-A -ScriptBlock {
          param($since)

          # Exact log location: Application log
          $app = Get-WinEvent -FilterHashtable @{ LogName='Application'; Id=1000; StartTime=$since } |
             Select-Object -First 10 TimeCreated, Id, ProviderName, Message

          # Exact log location: Microsoft-Windows-Desktop Window Manager/Operational
          $dwm = Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-Desktop Window Manager/Operational'; Id=9009; StartTime=$since } |
             Select-Object -First 10 TimeCreated, Id, ProviderName, Message

          [PSCustomObject]@{
             Host = $env:COMPUTERNAME
             App1000 = $app
             Dwm9009 = $dwm
          }
       } -ArgumentList $since
       ```
    - Required confirms from output:
       - Event `1000` exists in `Application` log.
       - Event `9009` exists in `Microsoft-Windows-Desktop Window Manager/Operational`.
       - Event `1000` message explicitly includes `Faulting module name: igdumd64.dll`.

3. If remoting is blocked, run equivalent pull via Azure CLI Run Command.
    - Azure path context: `Azure portal > Virtual machines > SHFIN-01-A`
   - ```powershell
      az vm run-command invoke `
         --resource-group <RG_NAME> `
         --name SHFIN-01-A `
         --command-id RunPowerShellScript `
         --scripts "Get-WinEvent -FilterHashtable @{LogName='Application';Id=1000;StartTime=(Get-Date).AddHours(-2)} | Select-Object -First 5 TimeCreated,Id,Message; Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Desktop Window Manager/Operational';Id=9009;StartTime=(Get-Date).AddHours(-2)} | Select-Object -First 5 TimeCreated,Id,Message"
      ```
    - Required confirms from output:
       - Event IDs `1000` and `9009` are both returned.
       - Event `1000` includes `igdumd64.dll` in message text.

4. Validate healthy baseline on control host using Event `9011`.
    - Control host: `SHFIN-02-A` in `POOL-FIN-02`.
    - Exact log location: `Microsoft-Windows-Desktop Window Manager/Operational`
    - ```powershell
       $since = (Get-Date).AddHours(-2)
       Invoke-Command -ComputerName SHFIN-02-A -ScriptBlock {
          param($since)
          Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-Desktop Window Manager/Operational'; Id=9011; StartTime=$since } |
             Select-Object -First 10 TimeCreated, Id, ProviderName, Message
       } -ArgumentList $since
       ```
    - Healthy baseline expectation:
       - Event `9011` is present on `SHFIN-02-A` as unaffected control behavior.
       - No repeated `1000` with `igdumd64.dll` and no `9009` spike pattern matching affected host.

5. Decision gate: confirm incident signature before acting.
    - Treat as this exact issue only when all are true:
       - `Application` log on `SHFIN-01-A` has Event `1000` with `Faulting module name: igdumd64.dll`.
       - `Microsoft-Windows-Desktop Window Manager/Operational` on `SHFIN-01-A` has Event `9009` in same time window.
       - Control baseline on `SHFIN-02-A` (`POOL-FIN-02`) shows expected Event `9011` and does not show the affected crash pattern.

## Resolution: step-by-step fix with expected result after each step
1. Set working variables (required for all fast commands).
   - PowerShell:
   - ```powershell
     $SubscriptionId = "<SUBSCRIPTION_ID>"
     $ResourceGroup  = "<RESOURCE_GROUP>"
     $HostPool       = "POOL-FIN-01"
     $SessionHost    = "SHFIN-01-A"
     $SessionHostFqdn = "SHFIN-01-A.contoso.local"
     az account set --subscription $SubscriptionId
     ```
   - Expected result: commands target the correct subscription and resources.

2. Drain affected host immediately.
   - Azure portal path and option: `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > SHFIN-01-A > Allow new sessions = Off`
   - Fast command:
   - ```powershell
     az desktopvirtualization session-host update `
       --resource-group $ResourceGroup `
       --host-pool-name $HostPool `
       --name $SessionHostFqdn `
       --allow-new-session false
     ```
   - Expected result: no new sessions are brokered to SHFIN-01-A.

3. Sign out all active sessions on the affected host.
   - Azure portal path and option: `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > SHFIN-01-A > Sessions > Sign out`
   - Fast commands:
   - ```powershell
     $sessions = az desktopvirtualization user-session list `
       --resource-group $ResourceGroup `
       --host-pool-name $HostPool `
       --session-host-name $SessionHostFqdn | ConvertFrom-Json

     foreach ($s in $sessions) {
       az desktopvirtualization user-session delete `
         --resource-group $ResourceGroup `
         --host-pool-name $HostPool `
         --session-host-name $SessionHostFqdn `
         --name $s.name
     }
     ```
   - Expected result: session count on SHFIN-01-A becomes 0.

4. Run display driver rollback on the VM using Run Command.
   - Azure portal path and option: `Azure portal > Virtual machines > SHFIN-01-A > Operations > Run command > RunPowerShellScript`
   - Fast command:
   - ```powershell
     az vm run-command invoke `
       --resource-group $ResourceGroup `
       --name $SessionHost `
       --command-id RunPowerShellScript `
       --scripts "pnputil /enum-drivers > C:\\Temp\\drivers-before-fix.txt; devmgmt.msc"
     ```
   - Expected result: driver inventory file is captured and host is ready for Intel Display Adapter rollback in Device Manager (Display adapters > Intel adapter > Properties > Driver > Roll Back Driver).

5. Restart VM after rollback.
   - Azure portal path and option: `Azure portal > Virtual machines > SHFIN-01-A > Overview > Restart`
   - Fast command:
   - ```powershell
     az vm restart --resource-group $ResourceGroup --name $SessionHost
     ```
   - Expected result: SHFIN-01-A returns to running state.

6. Validate post-fix logs while host is still drained.
   - Azure portal path: `Azure portal > Virtual machines > SHFIN-01-A > Operations > Run command > RunPowerShellScript`
   - Fast command:
   - ```powershell
     az vm run-command invoke `
       --resource-group $ResourceGroup `
       --name $SessionHost `
       --command-id RunPowerShellScript `
       --scripts "Get-WinEvent -FilterHashtable @{LogName='Application';Id=1000;StartTime=(Get-Date).AddMinutes(-30)} | Select-Object TimeCreated,Id,Message; Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Desktop Window Manager/Operational';Id=9009;StartTime=(Get-Date).AddMinutes(-30)} | Select-Object TimeCreated,Id,Message"
     ```
   - Expected result: no new Event 1000 with igdumd64.dll and no new Event 9009 after rollback/restart.

7. Return host to service.
   - Azure portal path and option: `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > SHFIN-01-A > Allow new sessions = On`
   - Fast command:
   - ```powershell
     az desktopvirtualization session-host update `
       --resource-group $ResourceGroup `
       --host-pool-name $HostPool `
       --name $SessionHostFqdn `
       --allow-new-session true
     ```
   - Expected result: SHFIN-01-A accepts new production sessions.

## Verification: how to confirm the fix worked
1. Confirm host state and session admission.
   - Azure portal path and option: `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > SHFIN-01-A > Status` and `Allow new sessions`
   - Fast command:
   - ```powershell
     az desktopvirtualization session-host show `
       --resource-group $ResourceGroup `
       --host-pool-name $HostPool `
       --name $SessionHostFqdn `
       --query "{status:status,allowNewSession:allowNewSession}" -o table
     ```
   - Pass condition: status is Available and allowNewSession is true.

2. Confirm live user stability.
   - Azure portal path and option: `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > SHFIN-01-A > Sessions > State`
   - Fast command:
   - ```powershell
     az desktopvirtualization user-session list `
       --resource-group $ResourceGroup `
       --host-pool-name $HostPool `
       --session-host-name $SessionHostFqdn `
       --query "[].{User:userPrincipalName,State:sessionState,Created:createTime}" -o table
     ```
   - Pass condition: at least two production users remain Active for 10 minutes.

3. Confirm crash signatures are absent after fix.
   - Azure portal path and option: `Azure portal > Virtual machines > SHFIN-01-A > Operations > Run command > RunPowerShellScript`
   - Fast command:
   - ```powershell
     az vm run-command invoke `
       --resource-group $ResourceGroup `
       --name $SessionHost `
       --command-id RunPowerShellScript `
       --scripts "Get-WinEvent -FilterHashtable @{LogName='Application';Id=1000;StartTime=(Get-Date).AddMinutes(-30)} | Where-Object {$_.Message -match 'igdumd64.dll'} | Select-Object TimeCreated,Id,Message; Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Desktop Window Manager/Operational';Id=9009;StartTime=(Get-Date).AddMinutes(-30)} | Select-Object TimeCreated,Id,Message; Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-TerminalServices-LocalSessionManager/Operational';Id=21,40;StartTime=(Get-Date).AddMinutes(-30)} | Select-Object TimeCreated,Id,Message"
     ```
   - Pass condition: no new 1000 events with igdumd64.dll, no 9009 spike, and no repeated immediate 21 to 40 pattern.

4. Confirm no active incident resurgence.
   - Azure portal path and option: `Azure portal > Monitor > Alerts > Fired alerts` filtered by host SHFIN-01-A and host pool POOL-FIN-01.
   - Pass condition: no new disconnect-loop alerts in the last 30 minutes.

## Rollback: what to do if the fix makes things worse
Use this if rollback driver action introduces new instability or users still disconnect.

1. Re-drain and isolate the host immediately.
   - Azure portal path and option: `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > SHFIN-01-A > Allow new sessions = Off`
   - Fast command:
   - ```powershell
     az desktopvirtualization session-host update `
       --resource-group $ResourceGroup `
       --host-pool-name $HostPool `
       --name $SessionHostFqdn `
       --allow-new-session false
     ```
   - Expected result: no new user sessions are routed to SHFIN-01-A.

2. Force logout remaining users from SHFIN-01-A.
   - Azure portal path and option: `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > SHFIN-01-A > Sessions > Sign out`
   - Fast commands:
   - ```powershell
     $sessions = az desktopvirtualization user-session list `
       --resource-group $ResourceGroup `
       --host-pool-name $HostPool `
       --session-host-name $SessionHostFqdn | ConvertFrom-Json

     foreach ($s in $sessions) {
       az desktopvirtualization user-session delete `
         --resource-group $ResourceGroup `
         --host-pool-name $HostPool `
         --session-host-name $SessionHostFqdn `
         --name $s.name
     }
     ```
   - Expected result: active session count is 0.

3. Stop (deallocate) the unstable VM.
   - Azure portal path and option: `Azure portal > Virtual machines > SHFIN-01-A > Overview > Stop` and confirm `Stop (deallocate)`
   - Fast command:
   - ```powershell
     az vm deallocate --resource-group $ResourceGroup --name $SessionHost
     ```
   - Expected result: VM power state is Stopped (deallocated).

4. Roll host back to last known-good image version.
   - Azure portal path and option:
     - `Azure portal > Azure Compute Gallery > Images > <AVD base image> > Versions > <last-known-good version>`
     - `Azure portal > Virtual machines > SHFIN-01-A > Help > Redeploy + reapply` (if image rollback is by redeploy process) or rebuild host from last-known-good image per platform standard.
   - Fast command example for image-based rebuild flow:
   - ```powershell
     az vm delete --resource-group $ResourceGroup --name $SessionHost --yes
     # Recreate SHFIN-01-A from approved last-known-good image version via your standard IaC/pipeline.
     ```
   - Expected result: host returns on approved image baseline, not the unstable build.

5. Keep service continuity on healthy hosts.
   - Azure portal path and option: `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > SHFIN-02-A > Allow new sessions = On`
   - Fast command:
   - ```powershell
     az desktopvirtualization session-host show `
       --resource-group $ResourceGroup `
       --host-pool-name $HostPool `
       --name "SHFIN-02-A.contoso.local" `
       --query "{status:status,allowNewSession:allowNewSession}" -o table
     ```
   - Expected result: users continue working on healthy hosts while SHFIN-01-A is remediated.

6. Capture rollback evidence and escalate.
   - Azure portal path and option: `Azure portal > Virtual machines > SHFIN-01-A > Operations > Run command > RunPowerShellScript`
   - Fast command:
   - ```powershell
     az vm run-command invoke `
       --resource-group $ResourceGroup `
       --name $SessionHost `
       --command-id RunPowerShellScript `
       --scripts "Get-WinEvent -FilterHashtable @{LogName='Application';Id=1000;StartTime=(Get-Date).AddHours(-2)} | Select-Object TimeCreated,Id,Message; Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Desktop Window Manager/Operational';Id=9009;StartTime=(Get-Date).AddHours(-2)} | Select-Object TimeCreated,Id,Message"
     ```
   - Expected result: evidence is attached to incident/change for image-owner escalation.

## Preventive: specific process/tooling changes to stop recurrence
1. Canary ring for display driver/image changes.
  Owner: release engineer; Timing: before deployment; Mode: automated. Run all Intel display driver/image updates in POOL-FIN-CANARY for 48 hours before production.
  Signal and pass/fail: Event 1000 (dwm.exe + igdumd64.dll) count = 0 and Event 9009 count <= 2 per host per 24h; fail if threshold exceeded.
  If fail: change manager blocks production CAB approval and image owner opens rollback task to last known-good image.

2. Event-correlation alert during rollout.
  Owner: DWP engineer; Timing: during deployment; Mode: automated. Alert when one host has Event 1000 with igdumd64.dll OR Event 21 followed by 40 within 60s, plus Event 9009, inside 10 minutes.
  Signal and pass/fail: alert volume must be 0 in rollout window; any fired alert is fail for that host.
  If fail: service desk lead triggers P1 incident and release engineer sets Allow new sessions = Off for failing host. [REQUIRES: Azure Monitor + Log Analytics rule]

3. Host admission gate after image update.
  Owner: DWP engineer; Timing: after deployment; Mode: manual with scripted checks. Keep SHFIN hosts at Allow new sessions = Off until validation is complete.
  Signal and pass/fail: 10-minute test session stable, Event 1000 (igdumd64.dll) = 0, Event 9009 = 0, and no repeated 21->40 sequence; any miss is fail.
  If fail: host stays drained and image owner reverts host to prior approved image/driver baseline.

4. Driver baseline compliance tracking.
  Owner: image owner; Timing: after deployment (daily 08:00 local); Mode: automated. Compare installed Intel display driver version/date on all POOL-FIN-01 hosts to CMDB-approved baseline.
  Signal and pass/fail: compliance = 100% required; any host drift is fail.
  If fail: auto-create platform ticket within 15 minutes and set host Allow new sessions = Off until remediated. [REQUIRES: CMDB to host-inventory integration]

5. Standardized evidence capture pack.
  Owner: DWP engineer; Timing: after deployment and during incidents; Mode: manual (automation recommended). Capture Application(1000), DWM Operational(9009), LSM Operational(21/40), and pnputil driver list.
  Signal and pass/fail: 100% of AVD disconnect incidents must include evidence bundle before closure; missing artifact is fail.
  If fail: service desk lead reopens incident and blocks closure until artifacts are attached. Automation note: schedule runbook job to auto-attach bundle. [REQUIRES: ticketing-runbook attachment API]

6. Pre-deployment smoke-test gate (added gap layer).
  Owner: release engineer; Timing: before deployment; Mode: manual. Execute scripted login test on canary host before any broad rollout.
  Signal and pass/fail: test user remains active for 10 minutes and logs show Event 1000=0 and Event 9009=0 in last 30 minutes; otherwise fail.
  If fail: do not start rollout, raise failed-change record, and return image to image owner for fix.

7. In-flight monitoring window (added gap layer).
  Owner: DWP engineer; Timing: during deployment; Mode: automated. Watch first 60 minutes after each batch enablement.
  Signal and pass/fail: disconnect-loop alert count must remain 0 and session disconnect rate on updated hosts must stay <2% per 15 minutes; otherwise fail.
  If fail: pause rollout immediately and drain only affected batch hosts. [REQUIRES: host-level session disconnect KPI dashboard]

8. Post-deployment validation before change closure (added gap layer).
  Owner: change manager; Timing: after deployment; Mode: manual checklist. Validate host state, user stability, and error logs before closing change.
  Signal and pass/fail: all updated hosts show Available + Allow new sessions = On, two production users stable 10 minutes per host, Event 1000/9009 thresholds pass.
  If fail: keep change open and assign remediation actions to DWP engineer and image owner.

9. Rollback trigger threshold (added gap layer).
  Owner: change manager; Timing: during and after deployment; Mode: automated trigger with manual approval. Trigger rollback if >=3 users disconnect within 10 minutes on one host OR any 1000(igdumd64.dll)+9009 correlation occurs twice in 15 minutes.
  Signal and pass/fail: threshold breach is automatic fail for release wave.
  If fail: auto-open rollback task, set host Allow new sessions = Off, sign out active sessions, and deallocate host. [REQUIRES: alert-to-automation workflow]

10. Knowledge update loop from incident learnings (added gap layer).
  Owner: service desk lead; Timing: after deployment (within 2 business days of incident/change); Mode: manual. Update runbook, triage checklist, and known-error article with final evidence and thresholds.
  Signal and pass/fail: document revision published with version/date and peer review sign-off; missing update by deadline is fail.
  If fail: change remains in pending-review state and next similar release is blocked until documentation is updated.

## Related: incidents and KB/runbook linkage
- Incident RCA: `../day 4/rca-avd-session-disconnect-pool-fin-01-20240315.md`
- Known error record: `../day 4/known-error-avd-session-disconnect-pool-fin-01-20240315.md`
- Operational runbook source: `./runbook-avd-session-disconnect-loop-pool-fin-01.md`
- Prior runbook variant: `./runbook-avd-session-disconnect-pool-fin-01-from-rca-20240315.md`
