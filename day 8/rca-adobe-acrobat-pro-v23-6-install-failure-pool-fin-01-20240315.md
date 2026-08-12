# Version Header

| Field | Value |
|------|-------|
| Title | RCA - Adobe Acrobat Pro v23.6 Install Failure (Pool FIN-01) |
| Version | 1.0 |
| Date | 12/08/2026 |
| Author | DWP Engineer |
| Reviewed | Self |
| Status | Draft |
| Change | Initial RCA from Intune/installer event log evidence |

# RCA - Adobe Acrobat Pro v23.6 Install Failure (Pool FIN-01) - 2024-03-15

## Incident Summary
- Incident: Adobe Acrobat Pro v23.6 failed to install via Intune Win32 deployment.
- Affected scope: Reported in one AVD pool after overnight image update (Pool FIN-01).
- First observed failure: 2024-03-15 10:01:44.
- Retry outcome: Retry attempt at 11:01 also failed with same return code 1603.
- Current state: Not installed, detection state = Not detected.

---

## Most Likely Cause (Current Best-Fit Hypothesis)
The overnight image update in Pool FIN-01 introduced an image-level installer prerequisite/conflict condition that causes `msiexec /i AcrobatPro.msi /quiet` to fail under SYSTEM context with fatal MSI code 1603.

This is the most likely cause, not a final absolute proof, because the provided log has no verbose MSI internals. However, it is the strongest fit to the observed pattern and timing/scope clue.

---

## Evidence From Events

1. `10:01:00` Agent starts install for Adobe Acrobat Pro v23.6.
2. `10:01:01` Install context is SYSTEM.
3. `10:01:03` Command executed: `msiexec /i AcrobatPro.msi /quiet`.
4. `10:01:44` Return code `1603` (fatal MSI failure).
5. `10:01:44` Install marked failed immediately.
6. `10:01:45` Detection rule runs only after failure and checks registry key `HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0`.
7. `10:01:45` Detection value is not found.
8. `10:01:46` Detection result = Not detected.
9. `10:01:47` App install result = Failed; retry scheduled.
10. `11:01:48` Retry uses same command.
11. `11:02:31` Retry fails again with return code `1603`.

### Why these events support the selected cause
- Deterministic repeat of the same fatal return code (`1603`) across initial run and retry indicates a stable environmental/config issue, not a transient outage.
- Failure happens before any successful detection, so detection result is a consequence of failed install, not the initial trigger.
- SYSTEM context plus silent MSI execution is sensitive to missing prerequisites, product conflicts, locked resources, or image-borne configuration blockers.
- The timing clue (issue started after overnight image update and is limited to one pool) strongly raises probability of pool-specific image drift over tenant-wide packaging/service failures.

---

## Alternative Hypotheses Considered (and why lower confidence)

1. Wrong detection rule for Pro vs Reader path:
- Possible gap (Pro app validated using Reader key), but install itself already failed with 1603 before detection outcome mattered.

2. Bad installer command line syntax:
- Command is syntactically valid MSI install invocation; no obvious malformed switch pattern in log.

3. Intune service-side transient:
- Repeated same-code failure after 60-minute retry lowers likelihood of temporary service issue.

4. Content download/corruption:
- Could still produce 1603, but log does not show content acquisition errors; image timing clue makes pool baseline conflict/prereq drift more likely.

---

## 5 Whys Analysis

1. Why did Adobe Acrobat Pro v23.6 not get installed?
Because the installer process returned MSI code 1603 and the deployment was marked failed.

2. Why did MSI return 1603?
Because `AcrobatPro.msi` encountered a fatal condition during silent execution under SYSTEM context.

3. Why would a fatal condition occur in this deployment path?
Because the runtime environment in the affected pool likely had a prerequisite missing or a conflicting state (for example prior Adobe component state, dependency mismatch, or policy/resource condition) after the overnight image change.

4. Why was that conflicting/missing condition present only for the affected population?
Because only one pool received the specific overnight image update, creating a pool-specific baseline difference.

5. Why did the release process allow this to impact users?
Because the image/app validation gate did not include a post-image, in-pool, SYSTEM-context silent install verification for Acrobat Pro before broad availability.

Root cause statement from 5 Whys:
- A pool-specific image baseline change introduced an unvalidated installer dependency/conflict path, causing deterministic MSI 1603 failure for Acrobat Pro installs under SYSTEM context.

---

## Immediate Confirm/Eliminate Check (Fastest Single Check)
Run one manual SYSTEM-context verbose MSI install on a failed FIN-01 host and inspect first failing action in log.

Command pattern:
- `msiexec /i AcrobatPro.msi /qn /L*v C:\Windows\Temp\AcrobatPro_Install.log`

Expected outcome:
- If the same failure reproduces and MSI log points to prerequisite/conflict/custom-action failure, this confirms the selected most-likely cause.
- If MSI log points instead to content/package or permissions path, re-rank hypotheses accordingly.

---

## Corrective Actions

1. Add deployment logging:
- Update install command to always emit verbose MSI log for Acrobat deployments in pilot pools.

2. Harden image release validation:
- Add mandatory smoke test: Intune Win32 install under SYSTEM context on at least one host per updated pool.

3. Add prerequisite gate:
- Validate Adobe prerequisites and conflicting legacy Adobe product states in image bake checklist.

4. Refine detection logic:
- Ensure detection key/path matches Acrobat Pro target (not Reader-only marker unless intentionally designed).

5. Pilot-ring control:
- Roll image updates to pilot subset first; block full pool rollout until app install health passes.

---

## Prevention and Monitoring

- Create alert for repeated Win32 app return code `1603` spikes by pool.
- Track install success rate by image version and pool ID.
- Maintain known-error entry linking MSI 1603 + pool image version signature.

---

## Confidence and Decision Note
- Confidence in current most-likely cause: Medium-High.
- Reason: event pattern + scope timing strongly support image/pool-specific environment conflict.
- Limitation: no verbose MSI action-level failure details were provided in source log.
- Decision posture: treat as primary working root cause pending one confirmatory SYSTEM-context verbose MSI check.
