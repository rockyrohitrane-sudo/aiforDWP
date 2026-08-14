# RCA - Citrix Session Launch Failure - FinBridge Pool-02

Date: 2026-08-14
Author: DWP Analyst
Incident type: VDI session launch failure (pool-specific)

## 1) Executive summary

FinBridge-VDI-Pool-02 experienced significant launch failures affecting 22 of 30 users. Evidence shows that most Pool-02 VDAs were unregistered and could not reach a healthy broker path via dc-vdi-02. The Citrix Broker Service on dc-vdi-02 was stopped, while dc-vdi-01 (serving Pool-01) remained healthy. This aligns with the pool-specific impact pattern and broker timeout behavior.

Note on error code interpretation:
- No external interpretation is introduced for code 1030.
- RCA uses the exact log-provided message: 'No machines available in the desktop group'.

## 2) Scope and impact

- Affected pool: FinBridge-VDI-Pool-02
- User impact: 22/30 users unable to launch sessions
- Unaffected pool: FinBridge-VDI-Pool-01
- Business effect: substantial partial outage for users mapped to Pool-02 desktops

## 3) Supporting evidence

### Broker events
- [08:58:04] Broker queried available machines in Pool-02.
- [08:58:34] Timeout waiting for machine registration response (30000ms exceeded).
- [08:58:34] Launch failed with error 1030 and message 'No machines available in the desktop group'.

### Catalog registration state
- Pool-02:
  - 25 provisioned
  - 3 registered
  - 22 unregistered
  - maintenance mode 0
- Pool-01:
  - 20 provisioned
  - 19 registered
  - 1 unregistered

### VDA unregistered sample (Pool-02)
- VDI-P02-014 and VDI-P02-017 both show:
  - Unable to contact Delivery Controller
  - dc-vdi-02.finbridge.local:80 - connection refused

### Controller health
- dc-vdi-02:
  - Citrix Broker Service STOPPED
  - last known running yesterday 23:40
  - Windows update installed at 00:15
  - reboot required flag set; reboot not completed
- dc-vdi-01:
  - Citrix Broker Service RUNNING
  - uptime 14 days

## 4) Timeline (evidence-based)

- Yesterday 23:40
  - dc-vdi-02 Broker Service last known running.

- Today 00:15
  - Windows Update installed on dc-vdi-02.
  - Reboot required flag set.

- 06:15:22
  - VDI-P02-014 registration attempt failed.
  - Error references inability to contact dc-vdi-02:80 (connection refused).

- 06:16:01
  - VDI-P02-017 registration attempt failed with same pattern.

- 08:58:03 to 08:58:34
  - User launch request for Pool-02 processed by broker.
  - Broker waited 30 seconds for registration response.
  - Launch failed with 1030 and no-machines-available message.

## 5) 5 Whys analysis

1. Why did users fail to launch sessions in Pool-02?
- Broker reported no machines available in desktop group during launch.

2. Why were no machines available in Pool-02?
- Only 3 of 25 machines were registered; 22 were unregistered.

3. Why were many Pool-02 machines unregistered?
- VDA samples show failed registration attempts to dc-vdi-02:80 with connection refused.

4. Why did registration to dc-vdi-02 fail?
- Citrix Broker Service on dc-vdi-02 was stopped.

5. Why was broker service stopped at incident time?
- Evidence shows update activity and pending reboot around the service stop window; final triggering mechanism is not proven from current data alone.

RCA statement:
- Proven direct service failure condition: Broker Service stopped on dc-vdi-02, causing widespread Pool-02 unregistration and launch failure.
- Probable contributing condition: update/reboot handling on dc-vdi-02.

## 6) Ranked cause candidates considered

1. Broker Service stopped on dc-vdi-02 causing registration collapse in Pool-02. (Most likely)
2. Controller-path connectivity controls issue to dc-vdi-02:80. (Possible but less likely given stopped service)
3. Post-update pending reboot state causing service non-restoration. (Likely contributor/trigger)

## 7) Final hypothesis selected

Selected hypothesis:
- dc-vdi-02 Citrix Broker Service outage is the immediate operational cause of Pool-02 session launch failures.

Confidence:
- High for immediate cause.
- Medium for upstream trigger linkage to update/reboot state.

## 8) Remediation plan (exact, ordered)

1. Announce maintenance and isolate change window for dc-vdi-02.
2. On dc-vdi-02, validate dependencies and set Broker Service startup to Automatic.
3. Start Citrix Broker Service.
4. If unstable or non-starting, reboot dc-vdi-02 (pending reboot already exists).
5. After controller health restored, recover VDA registration in Pool-02:
  - Restart VDA registration service (Citrix Desktop Service) in batches.
  - Reboot only non-registering hosts as needed.
6. Monitor registration counts until normal operating range.
7. Execute user launch tests against Pool-02.
8. Close incident after sustained stability window.

## 9) Verification of successful resolution

Success criteria:
- dc-vdi-02 Broker Service remains RUNNING after recovery.
- Pool-02 registered machines increase from 3 toward expected baseline; unregistered decreases from 22.
- New Pool-02 launches succeed without 30000ms registration timeout.
- No repeated 1030/no-machines-available failures during validation window.
- Pool-01 remains stable throughout remediation.

## 10) Preventive actions

1. Enforce post-patch reboot completion for Delivery Controllers before maintenance close.
2. Add active monitoring/alerting for:
  - Citrix Broker Service down state
  - registration ratio degradation per pool
  - launch failure spikes by desktop group
3. Schedule synthetic launch probes per pool every few minutes.
4. Add operational runbook step: controller service validation immediately after patching/reboot.
5. Perform periodic resilience drill for single-controller degradation scenarios.

## 11) Residual risk and follow-up

Residual risk:
- If service stop trigger was due to deeper OS/service dependency issue, recurrence is possible without deeper post-incident engineering review.

Follow-up actions:
- Capture detailed Windows Service Control Manager and Citrix event logs across 23:30-01:00 window.
- Confirm startup sequence dependencies and delayed start policy on dc-vdi-02.
- Review patch orchestration standards for controller tier.
