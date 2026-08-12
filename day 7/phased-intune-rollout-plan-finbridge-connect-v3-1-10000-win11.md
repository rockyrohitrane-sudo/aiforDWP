# FinBridge Connect v3.1 - Phased Intune Rollout Plan (10,000 Win11 Endpoints)

Date: 2026-08-12  
Deadline (3 weeks): 2026-09-02

## 1. RING STRUCTURE

### Ring 1 (Pilot)
- Size: 300 devices (3% of fleet)
- Duration: 4 calendar days (minimum 72 hours of live usage + 24 hours reporting lag)
- Include:
  - IT engineering + service desk devices
  - Cross-business champions (non-Finance)
  - 60 devices from the 4GB RAM population (intentional over-sampling of at-risk hardware)
- Purpose:
  - Validate install/uninstall, launch reliability, detection rule behavior (registry version string), and immediate stability under real usage
  - Validate performance impact on constrained hardware before larger expansion
- Intune assignment group type:
  - Microsoft Entra ID dynamic device security group (`SG-INTUNE-FINBRIDGE-R1-PILOT`)
  - App assignment intent: Required

### Ring 2 (Early)
- Size: 2,200 devices total, including Finance 500 users
- Duration: 5 calendar days
- Include:
  - Finance team (500 highest-priority users)
  - Remaining 1,700 users from medium-complexity business units and mixed hardware profile
- Purpose:
  - Confirm scale behavior beyond pilot, validate business-process usage in Finance, and confirm support load is manageable
- Intune assignment group type:
  - Microsoft Entra ID assigned security group for Finance users (`SG-INTUNE-FINBRIDGE-FINANCE-PRIORITY`)
  - Microsoft Entra ID dynamic device security group for non-Finance early adopters (`SG-INTUNE-FINBRIDGE-R2-EARLY`)
  - App assignment intent: Required

### Ring 3 (Broad)
- Size: 7,500 devices (remaining fleet)
- Duration: 9 calendar days in 3 internal waves (2,500/day wave every 3 days)
- Include:
  - All remaining production Win11 endpoints except explicitly excluded devices under investigation
- Purpose:
  - Complete enterprise rollout with controlled wave expansion and ongoing quality checks
- Intune assignment group type:
  - Microsoft Entra ID dynamic device security group (`SG-INTUNE-FINBRIDGE-R3-BROAD`)
  - App assignment intent: Required

## 2. ADVANCE CRITERIA

Use Intune app install reports (Win32 app status), Endpoint analytics (app reliability where available), and service desk ticket tagging (`App=FinBridge v3.1`) as the decision dataset.

### Ring 1 to Ring 2 Advance Gate
- Install success rate: >= 97.0% of targeted Ring 1 devices within 72 hours of assignment
- Error rate threshold: <= 2.0% failed install states (excluding "Not applicable") within the same 72-hour window
- User-reported issue rate: <= 3 tickets per 100 users during first 72 hours after install availability
- Monitoring period: Minimum 96 hours from Ring 1 assignment start before gate decision
- Time-bound decision point: Gate meeting at T+96h; if all metrics pass, Ring 2 assignment starts within next 12 hours

### Ring 2 to Ring 3 Advance Gate
- Install success rate: >= 98.0% of targeted Ring 2 devices within 96 hours of assignment
- Error rate threshold: <= 1.5% failed install states within the same 96-hour window
- User-reported issue rate: <= 2 tickets per 100 users during first 4 days after install availability
- Monitoring period: Minimum 120 hours from Ring 2 assignment start before gate decision
- Time-bound decision point: Gate meeting at T+120h; if all metrics pass, Ring 3 Wave 1 starts within next 12 hours

### Hold Condition (Pause Without Full Rollback)
- Trigger: Any single non-critical but repeating fault pattern affecting >= 1.0% of active installs in a ring over 24 hours, while app still launches and business operations continue
- Example:
  - Registry detection mismatch causes repeated reinstall attempts on 35 of 2,200 Ring 2 devices (1.59%) but users can still use the app
- Action:
  - Pause next ring/wave expansion
  - Keep current ring live
  - Fix packaging/detection logic and re-evaluate after 24 hours of patched monitoring

## 3. ROLLBACK TRIGGERS

### Trigger 1: Install Failure Rate (Automatic Halt)
- Condition: Failed install rate >= 5.0% in any active ring for a continuous 6-hour reporting window
- Decision owner: DWP Incident Commander (with Endpoint Engineering lead)
- Decision window: 30 minutes from threshold breach alert
- Exact Intune action:
  - Remove FinBridge v3.1 Required assignment from active ring group(s)
  - Add FinBridge v3.0 Required assignment to same ring group(s)
  - Keep unaffected prior rings unchanged unless they also breach thresholds

### Trigger 2: Application Crash Rate (Rollback Consideration)
- Condition: Crash/fault rate >= 2.0 crashes per device per day on assigned devices for 24 hours, or >= 10% of active devices showing repeat crash telemetry in 24 hours
- Decision owner: Endpoint Engineering Manager + App Owner + Service Operations Manager
- Decision window: 2 hours from validated telemetry confirmation
- Exact Intune action:
  - Halt all new v3.1 wave assignments immediately
  - If approved, switch active impacted groups from v3.1 Required to v3.0 Required
  - Maintain v3.1 only on unaffected groups pending targeted investigation

### Trigger 3: Business-Critical Failure (Immediate Rollback Regardless of %)
- Condition: Finance users cannot complete end-of-day transaction posting/export workflow in production due to v3.1 behavior
- Decision owner: Major Incident Manager in consultation with Finance IT Product Owner
- Decision window: Immediate (<= 15 minutes from incident validation)
- Exact Intune action:
  - Immediate removal of v3.1 Required assignment for Finance group (`SG-INTUNE-FINBRIDGE-FINANCE-PRIORITY`)
  - Immediate assignment of v3.0 Required to Finance group
  - Freeze all non-Finance ring progression until post-incident review

### Trigger 4: 4GB RAM Device Failures (Ring Isolation)
- Condition: 4GB RAM subgroup failure rate >= 8.0% failed installs or >= 15% severe performance complaints within 48 hours
- Decision owner: Endpoint Engineering lead + EUC Performance SME
- Decision window: 1 hour from threshold confirmation
- Exact Intune action:
  - Create/maintain exclusion group `SG-INTUNE-FINBRIDGE-4GB-EXCLUDE`
  - Exclude this group from all v3.1 assignments (R2/R3)
  - Assign v3.0 Required to excluded 4GB devices until remediation package is validated

## 4. FINANCE DEADLINE RESOLUTION

### Option A - Compress Pilot to place Finance in Ring 2 by end of week 1
- Minimum safe pilot duration: 72 hours of production usage + same-day checkpoint at hour 72
- Risk introduced:
  - Less soak time may miss lower-frequency defects (for example, defects appearing only after multiple reboots or day-2 usage patterns)
- Compensating control:
  - Increase Ring 1 hardware-risk sampling (already 60 x 4GB devices), enforce 24x7 telemetry review during pilot, and pre-stage immediate rollback assignments for Finance group before Ring 2 starts
- Outcome:
  - Finance can begin Ring 2 no later than day 4 and complete by end of week 1

### Option B - Separate Priority Ring 0 for Finance before main pilot
- Ring 0 structure:
  - 500 Finance users in two waves (150 then 350) over 3 days
- Ring 0 advance conditions:
  - >= 97% success in wave 1 in 24 hours, <= 2% error, <= 3 tickets per 100 users before wave 2
- Ring 0 rollback plan:
  - If >= 5% failure in 6 hours or any end-of-day posting failure occurs, revert Finance immediately to v3.0 and stop Ring 0
- Tradeoff:
  - Meets urgency but inverts normal risk sequence by exposing a business-critical function before cross-functional pilot proof

### Recommendation (Single Clear Decision)
Recommend Option A.

Justification:
- It satisfies the Finance end-of-week-1 commitment while preserving the standard risk-reduction sequence (Pilot -> Early -> Broad).
- It uses prior confidence from v3.0 rollout stability and keeps operational control simpler than parallel Ring 0 governance.
- It limits blast radius versus a Finance-first ring by requiring pilot gate pass before Finance exposure, while still fitting the 3-week enterprise deadline.
