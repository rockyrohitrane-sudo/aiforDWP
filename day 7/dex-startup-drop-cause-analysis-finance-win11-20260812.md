# DEX Startup Performance Drop — Cause Analysis
**Device group:** Finance-Win11 (215 devices)
**Date:** 2026-08-12
**Analyst:** DWP Analyst

---

## Context

Median startup time on Finance-Win11 jumped from 17.5 seconds (score 84) to 41.3 seconds (score 61) on 2026-08-04 — the morning after a security baseline configuration profile was deployed at 02:00. The comparison group IT-Win11 (40 devices, no config change) held steady at score 84–85 across the same window. The timing and clean comparison group make the config change the primary anchor for all three hypotheses below.

---

## Ranked Causes

---

### Cause 1 — Startup Script for Compliance Logging Is Blocking Desktop Readiness

**Probability: Most likely**

**Why it fits the evidence:**
The config change explicitly added a startup script for compliance logging. Startup scripts run synchronously during login processing — the desktop does not become usable until the script completes or times out. A ~24-second increase maps directly to a script that either waits on a network resource (such as a compliance logging endpoint), retries on failure, or runs a slow operation before releasing control. The timing is exact: deployed 02:00 on 2026-08-04, degradation first appears on 2026-08-04. IT-Win11 received no script and shows no change.

**Fastest check to confirm or eliminate:**
On one affected Finance-Win11 device, open Event Viewer → Applications and Services Logs → Microsoft → Windows → GroupPolicy → Operational. Look for script execution events at login and note the start and end timestamps. If the script duration accounts for ~24 seconds, this is the cause. Alternatively, temporarily move one test device out of the Finance-Win11 group, remove the startup script policy, reboot, and measure startup time.

---

### Cause 2 — Additional Defender Scan Policy Triggering a Full Scan at Login

**Probability: Second most likely**

**Why it fits the evidence:**
The config change also applied an additional Defender scan policy. If that policy triggers a scan at startup or login, it will compete heavily for disk and CPU at exactly the point when the OS is loading user profile, mapped drives, and startup applications — directly extending the time to a usable desktop. The 3-day persistence (scores 61 → 59 → 60) is consistent with a scan that runs every login rather than a one-off event. Again, IT-Win11 received no Defender policy change and remained unaffected.

**Fastest check to confirm or eliminate:**
On an affected device, open Windows Security → Virus & threat protection → Protection history and check whether a scan is running or completing at login time. Cross-reference with Task Manager or Resource Monitor during login to see whether MsMpEng.exe (Defender) is consuming high disk or CPU in the first 40–60 seconds after login. If confirmed, check the deployed policy in Intune for the scan schedule trigger setting.

---

### Cause 3 — Startup Script and Defender Scan Running Simultaneously, Causing Resource Contention

**Probability: Third most likely**

**Why it fits the evidence:**
Both components of the config change execute at login. If the compliance logging script and the Defender scan are both running at the same time, they will compete for disk I/O and CPU, compounding the delay beyond what either would cause alone. This would explain why the drop is as large as 136% rather than a smaller incremental increase. The fact that the degradation is consistent across three days (not recovering) supports two persistent co-running processes rather than a one-off conflict. IT-Win11 has neither component and is unaffected.

**Fastest check to confirm or eliminate:**
During a login on an affected device, open Task Manager immediately and watch for simultaneous high activity from both the compliance script process and MsMpEng.exe. If both are peaking at the same time within the first 60 seconds, contention is the amplifying factor. Staggering the scan schedule (e.g., delaying it 5 minutes post-login) via the Intune policy would test whether separating them reduces startup time without removing either component.

---

## Summary Table

| Rank | Cause | Key evidence fit | Fastest check |
|---|---|---|---|
| 1 | Startup script blocking desktop readiness | Direct timing match; scripts hold login process | Event Viewer GroupPolicy log on one device |
| 2 | Defender scan triggering at login | Policy applied at same time; persistent 3-day degradation | Task Manager / Protection history during login |
| 3 | Script + Defender scan resource contention | 136% degradation suggests compounding, not single cause | Watch Task Manager for simultaneous spikes at login |

---

*All three hypotheses derive solely from the config change applied at 02:00 on 2026-08-04. The clean IT-Win11 comparison group eliminates hardware, OS update, and network infrastructure as independent causes.*

---

*Analysis by DWP Analyst | 2026-08-12*
