# Root Cause Analysis: Document Manager v2.1 Crash Wave — Legal Floor 6

**Incident ID:** DOCMGR-2024-03-25-LEGAL  
**Incident Date:** 2024-03-25  
**Report Date:** 2024-03-25  
**Severity Level:** High  
**Status:** Active Investigation  
**Device Group:** Legal-Win11 (45 devices, 18 affected)  

---

## Executive Summary

A wave of application crashes affecting the Legal department's Document Manager deployment was identified on 2024-03-25 at 10:00. The root cause is **the auto-save indexing process in Document Manager v2.1 competing for disk I/O resources on 4GB RAM devices**. The vendor explicitly documented this as a known limitation for systems below 8GB RAM. Eighteen devices (40% of the Legal-Win11 fleet) meet this at-risk criteria.

**Impact:** 18 affected devices experiencing 6.2–6.8% application crash rate during index initialization  
**Affected Users:** All Legal staff assigned to 4GB RAM devices  
**Incident Duration:** Ongoing as of 11:00 on 2024-03-25 (expected to resolve within 2–4 hours as initial index completes)

---

## Root Cause

### Primary Cause
**Document Manager v2.1 auto-save indexing process causes resource contention on 4GB RAM systems**

The vendor release notes for Document Manager v2.1 contain this explicit warning:
> "Known limitation: on devices with under 8GB RAM, the auto-save indexing process can cause high disk I/O and intermittent crashes during the first few hours after installation while the initial index builds."

### Secondary Causes (Enabling Factors)
1. **Pre-deployment hardware inventory gap:** Legal department fleet not validated for v2.1 memory requirements before rollout
2. **Deployment sequencing:** All 45 devices received v2.1 simultaneously without staged rollout to validate against known limitation
3. **Lack of pre-deployment compatibility check:** SCCM deployment did not screen for 4GB RAM devices before initiating package transfer

---

## Incident Reconstruction

### Timeline

**09:38:20** — SCCM deployment initiated  
- Package: Document Manager v2.1  
- Target: Legal-Win11 collection (45 devices)  
- Previous version: v2.0 (stable, 6-week deployment history)  

**09:44:07** — Installation completed  
- All 45 devices: Installation success, 0 failures reported  
- Uninstall of v2.0 completed without error  
- v2.1 application files deployed  
- Auto-save feature initialized  
- **Initial index build process began on all devices simultaneously**  

**~09:45–10:00** — Silent initialization phase  
- DEX metrics remain relatively stable (still showing 90–91 range)  
- Index build consuming disk I/O on 4GB RAM devices but impact not yet visible at system level  

**10:00** — Disk I/O bottleneck reached  
- DEX Score: 91 → 58 (34-point drop, 37% degradation)  
- App crash rate: 0.1% → 6.2% (62x spike)  
- Disk I/O: Normal → High  
- **DocManager.exe identified as top crashing process (74% of all crashes)**  

**10:00–11:00** — Sustained degradation  
- DEX Score: 58–55 (continued degradation as index building continues)  
- App crash rate: 6.2–6.8% (sustained high rate)  
- Disk I/O: Sustained High  
- User complaints expected to begin appearing in service desk tickets

### Data Source Correlation

| SCCM Event | Nexthink Observation | Correlation |
|------------|---------------------|-------------|
| v2.1 installation completes at 09:44:07 | No DEX degradation at 09:00; degradation visible at 10:00 | ~16 minutes for auto-save index initialization to consume resources |
| Document Manager package deployed | DocManager.exe becomes top crashing process | Direct causation |
| Known vendor limitation: <8GB RAM affected | Legal fleet: 40% with 4GB RAM = 18 devices | Population match: 18 at-risk devices |
| Auto-save indexing causes "high disk I/O" | Nexthink DEX reports Disk I/O: High | Resource contention confirmed |

---

## Contributing Factors

### Factor 1: Hardware Composition Not Validated Pre-Deployment
- Legal-Win11 collection contains mixed hardware: 60% (27 devices) at 8GB, 40% (18 devices) at 4GB
- Deployment went forward without pre-flight compatibility check against v2.1 requirements
- SCCM collections could have been split to stage deployment by hardware tier

### Factor 2: No Staged Rollout Strategy
- All 45 devices received the update simultaneously
- If deployed in waves (e.g., 8GB devices first, then 4GB devices with delay), the known limitation would have been visible in first wave and prevented full-fleet impact
- Staged approach would have allowed vendor workaround or fallback to v2.0 before Legal staff impacted

### Factor 3: Deployment Process Missed Vendor Release Notes
- SCCM deployment approved without cross-reference to vendor release notes
- Known limitation was not surfaced to decision-making process
- No pre-deployment risk assessment documented

---

## Impact Assessment

### Affected Users
- All Legal staff assigned to the 18 devices with 4GB RAM
- Expected user experience: intermittent Document Manager crashes during first 2–4 hours of device usage after deployment

### Business Impact
- Document management workflows blocked intermittently
- Legal department productivity degraded during peak work hours (morning)
- Escalation risk: increased service desk ticket volume
- Reputational impact: unplanned outage without advance notice or mitigation

### System Impact
- 18 devices in High disk I/O state (potential I/O wait times affecting other applications)
- DocManager.exe process repeatedly crashing and restarting, consuming additional resources
- Potential user frustration leading to forced shutdowns or power cycles

---

## Remediation Actions

### Immediate (In Progress)

**Action 1: Accept Expected Resolution Window**
- **Description:** Index build process will complete within 2–4 hours of initial installation
- **Expected outcome:** DocManager.exe crashes will naturally cease as initial index completes and disk I/O returns to normal
- **Timeline:** Automatic, no IT action required
- **Stakeholder communication:** Inform Legal management that the issue is temporary and resolve within stated window

**Action 2: Monitor DEX Metrics**
- **Description:** Track DEX scores and app crash rate on Legal-Win11 devices at 10:30, 11:00, 12:00, and 14:00
- **Success criteria:** DEX Score returns to >85, App crash rate returns to <0.5%
- **Owner:** NOC/Nexthink monitoring

**Action 3: Notify Legal Department**
- **Description:** Send communication to Legal Floor 6 staff explaining:
  - What happened: v2.1 deployment triggered expected initialization process
  - Why it's happening: Vendor known limitation on 4GB RAM systems
  - How long: 2–4 hours
  - What to do: Save work frequently; if crashes prevent work, contact Service Desk for alternative device
- **Template:** See Stakeholder Communication section below

### Short-Term (Next 24–48 Hours)

**Action 4: Hardware Refresh Planning**
- **Description:** Identify the 18 devices with 4GB RAM and plan RAM upgrade or device refresh
- **Business case:** v2.1 is the forward platform; 4GB devices will continue to struggle with future updates
- **Timeline:** Escalate to procurement; schedule upgrades for next maintenance window
- **Owner:** IT Asset Management + Procurement

**Action 5: Deployment Process Improvement**
- **Description:** Add the following steps to standard software deployment checklist:
  1. Query CMDB for device hardware profiles in target collection
  2. Cross-reference target hardware against vendor system requirements and release notes
  3. Identify at-risk devices; split deployment by hardware tier if mixed environment
  4. Document approval of known risks or implement staged rollout
- **Owner:** Change Management / SCCM Administration
- **Audit:** Implement checklists in SCCM approval workflow

**Action 6: SCCM Collection Restructuring (Optional)**
- **Description:** Consider splitting Legal-Win11 collection into:
  - Legal-Win11-8GB (27 devices)
  - Legal-Win11-4GB (18 devices)
- **Benefit:** Enables future deployments to target hardware-appropriate versions or rollout strategies
- **Owner:** SCCM Administration

---

## Preventive Measures

### Process Level
1. **Vendor Release Notes Review Checklist:** Require cross-reference of vendor ReleaseNotes.txt for all major version deployments (v2.x, v3.x, etc.)
2. **Hardware Compatibility Matrix:** Maintain pre-deployment compatibility database linking applications to minimum RAM, disk space, and CPU requirements
3. **Staged Rollout Policy:** For collections with mixed hardware, implement 50% / 50% staged deployment with 24-hour validation between waves
4. **Pre-Flight Testing:** Route major application updates through pilot group (typically 5–10% of devices) before full rollout

### Technical Level
1. **SCCM Automated Validation:** Add custom SCCM task sequence step that queries device RAM and halts deployment if below threshold (optional action based on risk tolerance)
2. **Nexthink Baseline Thresholds:** Set alerting on DEX Score drops >20 points within 1-hour window; correlate with deployment timestamps
3. **Incident Response Runbook:** Create template document linking high app crash rate → check SCCM deployment log for recent updates → check vendor release notes for known limitations

---

## Stakeholder Communication

### To: Legal Department Management
**Subject: Document Manager Update — Expected Brief Service Degradation This Morning**

The Legal department received an update to Document Manager this morning (v2.0 → v2.1) as part of a planned software refresh. A temporary issue has been identified:

**What:** Some devices are experiencing intermittent crashes of the Document Manager application this morning.

**Why:** The new version includes an improved auto-save feature that requires an initialization process on first installation. Due to the memory configuration of some devices (4GB RAM), this initialization is consuming more disk resources than anticipated, causing temporary application instability.

**How long:** This is a temporary condition that will resolve automatically within 2–4 hours as the initialization completes. No further action is required.

**What you can do now:**
- Save work frequently if you're actively using Document Manager
- If crashes prevent you from working, please contact the Service Desk for access to an alternative device
- The update is beneficial and will not be rolled back; this is only a one-time initialization effect

**What's next:**
- We will monitor the devices throughout the morning and validate full recovery by noon
- We are reviewing our deployment process to prevent similar issues in future updates
- We are planning hardware upgrades for affected devices to ensure stable performance with future updates

We apologize for this disruption and appreciate your patience. Questions? Contact the Service Desk.

---

### To: SCCM/Deployment Team
**Subject: Post-Incident Review Required: Document Manager v2.1 Deployment**

A known vendor limitation for Document Manager v2.1 (crashes on <8GB RAM systems during initial index build) was not identified during the pre-deployment review, resulting in unplanned impact to 18 Legal department devices.

**Required Actions:**
1. Document what went wrong in pre-flight review
2. Propose updated pre-deployment validation checklist
3. Plan remediation for the 18 affected 4GB RAM devices
4. Schedule process improvement review with Change Management within 5 business days

---

## Closure Criteria

This incident will be considered **resolved** when:
1. ✓ DEX Score on Legal-Win11 collection returns to >85 (completed at [timestamp to be filled])
2. ✓ App crash rate on Legal-Win11 collection returns to <0.5% (expected by [14:00 on 2024-03-25])
3. ✓ Service Desk confirms zero new tickets from Legal regarding DocManager crashes for 2 consecutive hours
4. ✓ Formal communication sent to Legal management confirming resolution
5. ✓ Process improvement action items assigned to Change Management for implementation

---

## Attachments / References

- Nexthink DEX Export: Legal-Win11, 2024-03-25, 08:00–11:00 window
- SCCM Deployment Log: Document Manager v2.1, Legal-Win11 collection, timestamp 09:38:20–09:44:07
- Document Manager v2.1 Vendor Release Notes (containing known limitation for <8GB RAM)
- Legal-Win11 collection hardware inventory (60% 8GB / 40% 4GB)

---

**RCA Prepared By:** [IT Support Engineering]  
**Date:** 2024-03-25  
**Next Review:** 2024-03-25 14:00 (Validation that resolution is sustained)
