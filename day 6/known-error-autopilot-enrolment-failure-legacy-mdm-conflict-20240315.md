# Known-Error Record — Autopilot Enrolment Failure (Legacy MDM Conflict)
Knowledge Base Reference | Service Area: Endpoint Management (Intune / Autopilot)
Created: 2026-08-11 | Incident Reference: DESKTOP-FB099, 2024-03-15

---

**Symptom:** The device fails to complete Autopilot enrolment and does not progress through the provisioning workflow. Required security baseline and configuration profiles are not applied, and the compliance engine cannot evaluate device posture.

**Cause:** A pre-existing legacy manual MDM enrolment record remains active on the device at the time the Autopilot provisioning attempt is made. This creates a conflicting management state that blocks the new enrolment with error 0x80180014 (device already enrolled in MDM).

**Scope:** Any device targeted for Autopilot (re)provisioning where a prior manual or legacy MDM enrolment was not retired and deleted before the Autopilot attempt. Affects the individual device and its assigned user; Azure AD join state, licensing, and network connectivity are not impacted.

**Workaround:** Retire then delete the stale managed device object in the Intune admin centre, validate that a single authoritative Autopilot device record exists for the hardware identity with the correct profile assignment, and clear the device-side legacy MDM registration by disconnecting the work/school account and removing local enrolment artefacts. Reprovision from a clean OOBE state to restore service.

**Permanent Fix:** Implement a mandatory pre-enrolment clean-state gate that must pass before any Autopilot provisioning wave begins, requiring: no active legacy or manual MDM enrolment on the target device, no duplicate stale managed device objects in Intune, and a single authoritative Autopilot record per hardware identity. Enforce a lifecycle standard of Retire → Delete stale object → Validate Autopilot record before any device redeployment or reuse.

**How to Spot It:** MDM diagnostic export shows `EnrollmentState: Failed`, `ErrorCode: 0x80180014`, and `ErrorDescription: The device is already enrolled in MDM`. Cross-reference `EnrolmentSource: Legacy` and an enrolment date predating the current provisioning attempt. Downstream signals confirming this as root cause (not a separate fault) are `ProfilesApplied: 0`, `LastError: 0x80070005` (Access Denied), and `ComplianceEngine EvaluationResult: Could not evaluate` with reason `Enrolment not complete`.
