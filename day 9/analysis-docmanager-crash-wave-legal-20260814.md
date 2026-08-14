# Analysis: Document Manager Crash Wave — Legal-Win11 (45 Devices)

**Date of Incident:** 2026-08-14  
**Report Date:** 2026-08-14  
**Device Group:** Legal-Win11 (45 devices)  
**Method:** Timing-weighted hypothesis ranking (no single-cause commitment)

---

## Scope Facts Used (Only)

- Symptom: wave of app crashes (primarily DocManager.exe), DEX score drop, disk I/O rise
- Who: Legal-Win11 device group (45 devices)
- Since: degradation began mid-morning today; normal earlier in the day
- Change: Document Manager v2.1 deployed this morning to all 45 devices; 0 install failures
- Baseline: v2.0 stable for 6 weeks
- Device mix: some 8GB RAM devices, some 4GB RAM devices
- Vendor note: v2.1 has known limitation of high disk I/O + intermittent crashes on lower-RAM devices during first hours after install while indexing completes

---

## Ranked Most Likely Causes (Most Probable First)

## 1) v2.1 first-run indexing limitation on lower-RAM devices (vendor-documented)
**Likelihood:** Very High  
**Status:** to confirm

**Why this fits scope facts**
- Timing alignment is strong: crashes and DEX degradation began shortly after morning deployment.
- Symptom alignment is direct: vendor note explicitly calls out high disk I/O and intermittent crashes during initial indexing.
- Process alignment: dominant crashing process is DocManager.exe, the updated app itself.
- Population alignment is plausible: mixed RAM fleet includes lower-RAM (4GB) devices that match vendor risk profile.

**Fastest single check**
- Segment crash and DEX impact by RAM tier (4GB vs 8GB) for the first 2-4 hours post-install; if 4GB devices show a disproportionate crash spike, this cause is strongly confirmed.

---

## 2) v2.1 regression independent of RAM (new defect introduced in this build)
**Likelihood:** High  
**Status:** to confirm

**Why this fits scope facts**
- The strongest timing clue still supports version-induced fault: stable on v2.0 for 6 weeks, then immediate degradation after v2.1.
- 0 install failures does not rule out runtime defects; successful deployment can still deliver buggy code.
- If crashes are occurring beyond lower-RAM subset, a broader regression is plausible.

**Fastest single check**
- Compare crash incidence on 8GB devices during the same post-deploy window; significant 8GB impact would point to a general v2.1 defect, not only low-RAM pressure.

---

## 3) Post-install indexer saturation causing transient local resource contention (I/O queue pressure) beyond expected vendor envelope
**Likelihood:** Medium-High  
**Status:** to confirm

**Why this fits scope facts**
- Disk I/O rise is a primary observed signal and coincides with DEX decline/crash wave.
- Even when "known," indexer behavior can exceed expected load in real fleet conditions and produce crash cascades.
- Mid-morning onset after successful install is consistent with first-run background processing side effects.

**Fastest single check**
- On an affected device, sample per-process disk usage and queue length during crash window; confirmation is rapid if DocManager/indexing threads dominate I/O at crash time.

---

## 4) Memory pressure/commit exhaustion on 4GB devices triggered by v2.1 startup workload
**Likelihood:** Medium  
**Status:** to confirm

**Why this fits scope facts**
- Fleet heterogeneity (4GB + 8GB) creates a clear risk boundary for memory-sensitive startup operations.
- Vendor note references lower-RAM instability during first hours after install.
- DEX degradation plus crashes commonly co-occur with resource pressure states.

**Fastest single check**
- Check commit charge and hard-fault activity on a crashing 4GB endpoint during launch/index period; sustained pressure near limits supports this cause.

---

## 5) Non-version environmental trigger that coincided with deployment timing (less likely but not excluded)
**Likelihood:** Low-Medium  
**Status:** to confirm

**Why this fits scope facts**
- The temporal link to v2.1 is strong, so unrelated causes are lower probability.
- Still possible: another same-window environmental factor could amplify crashes and DEX decline.
- Must remain in consideration until excluded by cohort and timeline validation.

**Fastest single check**
- Build a same-day change timeline (security, policy, platform, storage agents) against incident onset; absence of parallel changes and strong v2.1 cohort correlation quickly deprioritizes this path.

---

## Timing-Weighted Interpretation

Given normal behavior earlier today, immediate post-deploy onset, and a vendor note that mirrors observed symptoms, the probability mass is concentrated in **v2.1-induced mechanisms** (especially low-RAM first-run indexing effects).  
At this stage, ranking remains hypothesis-based and **to confirm** through rapid cohort checks (RAM split + post-install timing + process-level resource telemetry).
