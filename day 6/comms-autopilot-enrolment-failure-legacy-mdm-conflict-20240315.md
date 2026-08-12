# End-User Communications — Autopilot Enrolment Failure (Legacy MDM Conflict)
Incident Date: 2024-03-15 | Device: DESKTOP-FB099 | User: FINBRIDGE\rthomas  
Author: DWP Analyst | Date: 2026-08-11

---

## Audience 1 — Non-Technical Executive

Subject: Device Setup Delay — No Impact to Your Data or Access

Your data and account access are safe and unaffected.

A device assigned to your team could not complete its automated setup on 15 March 2024 because an outdated configuration record was still active from a previous setup. Our team has identified the cause, cleared the conflict, and restarted the setup process. No action is required from you.

---

## Audience 2 — Affected End-User Team

Subject: Device Setup Issue — What Happened and What to Do

Hi team,

On 15 March, one of our devices could not finish setting itself up because an old registration from a previous setup was still attached to it and got in the way. Our team has already sorted this out and the device is being reconfigured.

If your own device ever shows an error during setup or asks you to re-enrol, please do not attempt to fix it yourself — just raise a ticket with the helpdesk straight away.

Contact: IT Helpdesk | [helpdesk@finbridge.internal](mailto:helpdesk@finbridge.internal)

---

## Audience 3 — Engineer-to-Engineer Internal Note

Subject: P1 Post-Incident Note — Autopilot Failure 0x80180014 | DESKTOP-FB099 | 2024-03-15

**Root Cause**

Pre-existing legacy manual MDM enrolment (EnrolmentSource: Legacy, dated 2023-11-04) remained active on DESKTOP-FB099 at the time of the Autopilot reprovisioning attempt on 2024-03-15. This produced error `0x80180014` ("device already enrolled in MDM") at 09:18:44, blocking the enrolment workflow entirely.

Downstream effects (not causal):
- `0x80070005` (Access Denied) — policy phase attempted post-failure, 0/4 profiles applied.
- Compliance engine returned `Could not evaluate` — blocked by incomplete enrolment state.

Confirmed healthy at time of failure: AzureADJoin (Yes), IntuneP1License (Yes), AutopilotLicense (Yes), network endpoints (OK), ProxyDetected (No). These are ruled out as contributing factors.

**Exact Actions Taken (Remediation Sequence)**

1. Retired then deleted the stale Intune managed device object for DESKTOP-FB099 via Intune admin center.
2. Validated the Autopilot device record — confirmed single authoritative record for the hardware hash, correct profile assignment.
3. Cleared device-side legacy MDM registration — disconnected work/school account and removed local enrolment artifacts.
4. Reprovisioned from clean OOBE, triggered Autopilot workflow.

**Verification Steps**

- Confirmed no repeat of `0x80180014` on re-enrolment.
- Confirmed EnrollmentState: Enrolled, EnrolmentSource: Autopilot.
- Confirmed ProfilesAttempted: 4, ProfilesApplied: 4.
- Confirmed ComplianceEngine EvaluationResult: Compliant.

**Preventive Action Required**

The process gap is a missing mandatory pre-enrolment clean-state gate. Before any Autopilot (re)provision wave:

1. **Pre-flight check (must pass before OOBE start):**
   - No active legacy/manual MDM enrolment on target device.
   - No duplicate stale managed device objects in Intune.
   - Single authoritative Autopilot record per hardware identity (hardware hash match).

2. **Hard deployment gate:** Do not initiate Autopilot if pre-flight fails — route to L2 pre-staging queue for cleanup first.

3. **Lifecycle standard:** On any redeployment or device reuse, Retire → Delete stale object → Validate Autopilot record → then assign to user wave.

4. **Operational monitoring:**
   - Weekly hygiene report flagging devices with legacy/manual enrolment source or duplicate identity records.
   - KPI: % of Autopilot-targeted devices passing clean-state gate before wave start.

5. **Runbook update:** Add explicit stale-enrolment cleanup sequence with verification checkpoints. Brief L1/L2 on the `0x80180014` triage path and the required cleanup order (retire → delete → clear device-side → OOBE).

**If This Recurs**

Check MDM diagnostic export for `ErrorCode: 0x80180014` and `EnrolmentSource: Legacy`. The cleanup sequence above is the confirmed resolution path. Do not attempt re-enrolment without completing all pre-flight steps — a partial cleanup will reproduce the same failure.
