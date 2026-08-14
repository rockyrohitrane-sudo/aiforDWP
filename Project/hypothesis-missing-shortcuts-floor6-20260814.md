# Hypothesis - Missing Desktop Shortcuts (Legal Floor 6)

Date: 2026-08-14
Prepared by: DWP Engineer
Purpose: Ranked likely causes using only stated scope facts (no final root cause commitment)

## Ranked top 3 likely causes (most probable first)

### 1) Deployment-side shortcut action from the Friday document management app rollout (to confirm)

Why this cause fits the scope facts:
- The strongest timing signal is a floor-targeted change on Friday followed by symptom appearance Monday morning.
- The issue appears in the same scoped cohort (Legal Floor 6, Win11, Intune).
- App deployments can include shortcut create/remove/replace logic that may misapply on some devices.

Single fastest check to confirm or eliminate:
- Compare Intune/app deployment logs and install scripts for the affected user/device versus one unaffected Floor 6 device, specifically for shortcut removal/overwrite steps and execution results.

### 2) Intune policy/configuration profile changed desktop path or icon visibility (to confirm)

Why this cause fits the scope facts:
- The cohort is explicitly Intune-enrolled and recently migrated to Win11.
- A targeted configuration assignment could alter desktop behavior without uninstalling applications.

Single fastest check to confirm or eliminate:
- Review effective Intune configuration and assignment deltas for the affected user/device since Friday, focusing on desktop/Start layout, shell restrictions, and known-folder settings.

### 3) User profile path/redirection issue (including OneDrive known-folder behavior) causing shortcuts to appear missing (to confirm)

Why this cause fits the scope facts:
- Profile or folder-redirection mismatch can make shortcuts appear missing while applications still exist.
- This can surface after migration or policy/application changes.

Single fastest check to confirm or eliminate:
- Validate the active path mapping and actual contents of user desktop and public desktop locations on the endpoint, then compare against expected profile/redirected paths.

## Relation to the separate login/performance incident

This issue could plausibly share a root cause with the same-morning login/performance incident and should be treated as potentially linked first, not assumed fully independent (to confirm).

Reasoning:
- Both incidents are on the same floor, same morning, and follow the same Friday deployment window in a recently migrated Win11 + Intune cohort.
- That pattern is consistent with a shared policy/profile/deployment failure mode.
- Full independence remains possible if shortcut behavior maps to a narrow shell/layout setting while login/performance maps to a different authentication or startup bottleneck (to confirm).
