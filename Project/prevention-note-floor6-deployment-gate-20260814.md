# Prevention Note: Floor 6 Multi-Incident
**Date:** 2026-08-14  
**Incident:** Legal Floor 6 login failures, slow logon, missing desktop shortcuts following Friday document management app deployment  

---

## Preventive Process Changes

All three Floor 6 deployment-impact issues (login failures, slow logon, missing shortcuts) are prevented by a single unified control: **mandatory pre-flight deployment validation gate for applications targeting recently-migrated platform cohorts.**

---

### Issue 1: Login Failures

**Preventive Control: Test Authentication and Sign-In Availability Before Production Rollout**

Before authorizing production deployment of any new application to a device cohort that completed platform/policy migration within the prior 90 days, the deployment change control must require:

1. **Test Device Deployment:** Deploy the application to at least one representative test device matching the target cohort's exact platform state (Windows 11, Intune-enrolled, same policy profile set as Floor 6).

2. **Sign-In Success Validation:** Perform three consecutive user authentication cycles (credential entry to desktop ready state) on the test device. Document that all three sign-in attempts succeed without error. Record any failed logon attempts, error codes, or authentication timeouts; if any occur, the deployment does not proceed to production.

3. **Comparison Against Baseline:** Document sign-in success rate before and after test app deployment. Production rollout is authorized only if success rate remains at or above baseline (to confirm: baseline threshold for Floor 6 cohort).

4. **Change Authorization Hold:** Do not proceed to production rollout until sign-in validation results are documented in the change ticket and approved by platform owner (to confirm: role/title).

**Why This Prevents Floor 6 Login Failures:**  
The Friday deployment to Floor 6 resulted in hard authentication failures for at least 12 users. A pre-deployment test on a representative Floor 6 device would have detected this failure mode before the production rollout, allowing the change to be held for remediation or reversal.

---

### Issue 2: Slow Logon Performance Degradation

**Preventive Control: Measure and Validate Sign-In Performance Before Production Rollout**

Using the same pre-flight deployment validation gate as Issue 1, add a performance measurement step:

1. **Test Device Deployment:** (Same as Issue 1, step 1)

2. **Sign-In Latency Baseline Measurement:** Using the test device before app deployment, measure sign-in latency (credential submission to desktop ready state) across 3 consecutive logon cycles. Record and document this baseline.

3. **Post-Deployment Latency Measurement:** After deploying the application to the test device, repeat the 3-cycle sign-in measurement. Compare post-deployment latency to baseline.

4. **Performance Threshold Validation:** Authorize production rollout only if post-deployment latency increase is ≤ [to confirm: acceptable threshold in seconds] above baseline. If latency degradation exceeds threshold, hold the deployment for vendor remediation of startup performance behavior.

5. **Change Authorization Hold:** Document baseline and post-deployment latency measurements in the change ticket. Proceed to production only upon platform owner approval (to confirm: role/title).

**Why This Prevents Floor 6 Slow Logon:**  
The Friday deployment introduced severe logon latency for multiple Floor 6 users. A pre-deployment performance measurement on a representative test device would have detected this degradation before the production rollout, allowing the change to be held or modified before user impact.

---

### Issue 3: Missing Desktop Shortcuts

**Preventive Control: Verify System Artifacts Are Preserved After Application Installation**

Using the same pre-flight deployment validation gate, add an artifact verification step:

1. **Test Device Deployment:** (Same as Issue 1, step 1)

2. **Pre-Deployment Artifact Inventory:** Document the presence and functionality of standard desktop shortcuts before app deployment (e.g., [to confirm: expected list for Floor 6]: system shortcuts, user-installed app shortcuts, count, state).

3. **Post-Deployment Artifact Verification:** After deploying the application, re-verify that all baseline shortcuts remain present, accessible, and functional. Confirm count matches or exceeds pre-deployment inventory.

4. **Artifact Preservation Threshold:** Authorize production rollout only if all baseline system artifacts (shortcuts) are present post-deployment. If the app install removes, hides, or relocates standard shortcuts, hold the deployment for vendor remediation of post-install script behavior.

5. **Change Authorization Hold:** Document pre- and post-deployment artifact state in the change ticket. Proceed to production only upon platform owner approval (to confirm: role/title).

**Why This Prevents Floor 6 Missing Shortcuts:**  
The Friday deployment's post-install script removed desktop shortcuts from Floor 6 devices. A pre-deployment artifact inventory and post-deployment verification on the test device would have detected this behavior before the production rollout, preventing user-facing shortcut loss.

---

## Unified Implementation: Single Pre-Flight Gate

**Core Preventive Process:** Establish a single mandatory change-control gate that requires all three validations (sign-in success, sign-in latency, artifact preservation) as a bundle before any new application is deployed to a device cohort within 90 days of platform/policy migration.

**Trigger:** Automatically activated whenever a new application deployment targets a device cohort that completed Windows 11, Intune migration, or major platform/policy change within the prior 90 days.

**Enforcement:** Embed this gate in the change-management system or Intune governance policy to ensure consistent application.

**Why This Catches All Three Floor 6 Issues:**  
- Floor 6 completed Win11 + Intune migration recently; the Friday deployment triggered this gate.
- A single test device deployment would have exposed all three failure modes (login failure, latency, missing shortcuts) before rolling out to 45 users.
- The change would have been held at the authorization step, preventing all three incidents from reaching production.

---

## Confidence and Dependencies

- **Confidence:** High, provided test device accurately reflects production Floor 6 configuration and all three validation steps are executed.
- **To Confirm:**  
  - Exact sign-in latency baseline and acceptable performance threshold for Floor 6 cohort
  - Expected system shortcut inventory for Floor 6 baseline (count, standard shortcuts, state)
  - Specific platform owner role/title for change authorization
  - Whether this gate applies retroactively to the document management app, or prospectively to future deployments

---

**Implementation Note:** This control is best embedded as a change-board rule or Intune governance policy rather than a manual checklist, to ensure consistent enforcement across all future recently-migrated cohorts.
