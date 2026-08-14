## Preventive Process Change: Floor 6 Incident

**Desktop State Validation Gate Before Production Deployment**

**The specific control:**

Before any software package is deployed to a production group, it must first be installed on an isolated test device configured with an identical baseline to the target group. Desktop state must be captured immediately before installation and immediately after installation completes. The before/after snapshots must be compared for any unintended changes—specifically missing shortcuts, deleted files, or modified system settings. If any unintended changes are detected, the deployment is automatically flagged for halt and investigation before proceeding to production.

**Why this would have caught the Floor 6 incident:**

The post-install script for the Friday document management application removed desktop shortcuts. If this same installation had been performed on a test Floor 6 device prior to production rollout, the before/after comparison would have identified the missing shortcuts immediately. The unintended change would have halted the production deployment, preventing the incident from reaching all of Floor 6.

**Implementation:**

- Assign one test device per major production group (e.g., one for Floor 6)
- Create a standardized checklist capture (screenshot, shortcut inventory, key system folders) before and after software installation
- Use this as a mandatory gate in the software release approval workflow
- Flag any discrepancies to the application owner and IT change authority before production sign-off

**Status:** Assumes the current hypothesis about post-install script behavior is confirmed (to confirm with app vendor and Intune logs).
