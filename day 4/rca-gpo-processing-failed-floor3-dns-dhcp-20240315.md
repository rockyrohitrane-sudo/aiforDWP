# Version Header

| Field | Value |
|------|-------|
| Title | RCA - Group Policy Processing Failed - Finance Floor 3 |
| Version | 1.0 |
| Date | 07/08/2026 |
| Author | DWP Engineering |
| Reviewed | Self |
| Status | Final |
| Change | Initial RCA from verified incident evidence |

# RCA - Group Policy Processing Failed - Finance Floor 3 - 2024-03-15

## Incident Summary
- Incident: User logon failures with Group Policy processing errors.
- Symptom observed: Group Policy failed to process because domain controller and SYSVOL paths were unreachable.
- Affected scope: 3 Windows 11 machines (3 of 4 devices in OU=Finance segment for this startup window).
- Start time: Approximately 07:40.
- Recovery confirmed: 09:09.
- Final status: Resolved.

## Impact Assessment
- Impacted users/devices: Users on affected Finance Floor 3 Windows 11 endpoints.
- Functional impact: Delayed/failed logon policy application and inconsistent domain policy state during startup window.
- Business impact: Users were unable to complete normal logon policy processing and experienced login failure symptoms until remediation.
- Data loss: None indicated.

## Problem Statement
At startup, affected clients failed to contact a domain controller and failed to read SYSVOL policy files, producing Group Policy Event 1058/1030/1129 errors. The root technical driver was incorrect DNS server assignment from DHCP scope on the affected subnet. Clients received a decommissioned DNS server IP and could not resolve domain controller names. Because AD/DC discovery failed, secure channel setup and GPO retrieval also failed.

## Supporting Evidence

### Affected Host Evidence - DESKTOP-FB031 (07:40 to 07:55)
1. 07:40:08 - Netlogon Event 5719 (Error)
- Secure channel to domain FINBRIDGE could not be established.
- Explicit detail: DNS query for FINBRIDGE-DC01.finbridge.local returned no response.

2. 07:40:09 - GroupPolicy Event 1058 (Error)
- Cannot access \\FINBRIDGE-DC01\\sysvol\\finbridge.local\\Policies\\{3A1B2C4D-E5F6-7890-ABCD-EF1234567890}\\gpt.ini.
- Error code 0x3 (path not found).

3. 07:40:10 - GroupPolicy Event 1030 (Warning)
- Cannot query list of Group Policy objects.
- Error code 0x546.

4. 07:40:12 - GroupPolicy Event 1129 (Error)
- Group Policy failed because there was no network connectivity to a domain controller.

5. 07:41:05 - DNS Client Event 1014 (Warning)
- Name resolution timed out for FINBRIDGE-DC01.finbridge.local.
- None of the configured DNS servers responded.

6. 07:42:18 - DHCP Client Event 50036 (Information)
- Client lease assigned DNS server 10.10.3.250.
- Confirmed environmental fact: 10.10.3.250 was an old/decommissioned DNS server.

7. 07:44:01 - GroupPolicy Event 1129 (Error)
- Repeated GPO failure due to no DC connectivity.

### Unaffected Comparison Evidence - DESKTOP-FB029 (Same OU)
1. 07:40:05 - DHCP Client Event 50036
- DNS assigned: 10.10.0.10 (correct new DNS).

2. 07:40:11 - GroupPolicy Event 1500 (Information)
- Group Policy processed successfully.

### Cross-Host DHCP Server Evidence
- Affected set (FB055-FB057): DNS assigned 172.16.5.5 (decommissioned local DNS).
- Unaffected comparison host (FB058): DNS assigned 10.10.0.10 (correct central DNS, manually pre-configured).
- Control-plane fact: DHCP scope for the affected subnet had not been updated after DNS migration/decommission wave.

## Reconstructed Timeline

| Time | Source | Event ID | Observation |
|------|--------|----------|-------------|
| 07:40:02 | Service Control Manager (FB031) | 7036 | Network Location Awareness entered running state |
| 07:40:08 | Netlogon (FB031) | 5719 | No DC available; DNS query for DC returned no response |
| 07:40:09 | GroupPolicy (FB031) | 1058 | SYSVOL gpt.ini path inaccessible; error 0x3 |
| 07:40:10 | GroupPolicy (FB031) | 1030 | GPO list query failed; error 0x546 |
| 07:40:11 | GroupPolicy (FB031) | 1058 | Repeat GPO path access failure |
| 07:40:12 | GroupPolicy (FB031) | 1129 | No network connectivity to domain controller |
| 07:41:05 | DNS Client (FB031) | 1014 | DNS timeout; configured DNS servers did not respond |
| 07:42:18 | DHCP Client (FB031) | 50036 | DNS lease provided old/decommissioned DNS 10.10.3.250 |
| 07:44:01 | GroupPolicy (FB031) | 1129 | Repeated no-DC-connectivity GPO failure |
| 07:40:05 | DHCP Client (FB029) | 50036 | Correct DNS lease 10.10.0.10 |
| 07:40:11 | GroupPolicy (FB029) | 1500 | Successful GPO processing on comparison host |
| 09:09:00 | Operations Validation | N/A | Connectivity restored, Group Policy processing successful, no further issues reported |

## Hypothesis Elimination Summary
- H1 DC reachability issue: Supported by 5719 and 1129.
- H2 DNS discovery fault: Supported by 1014, 5719, and DHCP 50036 wrong DNS assignment.
- H3 SYSVOL ACL/replication fault: Contradicted by healthy comparison host success (1500) when DNS is correct.
- H4 Site/subnet segment config issue: Supported by subnet-specific DHCP DNS misassignment pattern.
- H5 Win11 startup timing defect: Contradicted by hard DNS misconfiguration evidence and healthy peer with correct DNS.

## Root Cause Determination

### Primary Root Cause
DHCP scope for the affected Floor 3 subnet still distributed decommissioned DNS server addresses after the DNS migration wave, causing AD/DC name resolution failure during startup. This broke secure channel establishment and Group Policy retrieval.

### Contributing Causes
- DNS decommission and DHCP scope updates were not synchronized.
- No post-change validation detected active leases still pointing to retired DNS servers.
- Partial/manual pre-configuration on one host masked full-scope impact until production startup.

### Why Alternative Causes Were Excluded
- A general AD/SYSVOL outage is unlikely because comparison host FB029 with correct DNS processed GPO successfully (Event 1500 at 07:40:11).
- A Win11-only client race condition does not explain deterministic DNS timeout and wrong DHCP DNS lease values.

## Resolution Actions Applied
1. Updated DHCP scope options for the affected subnet to distribute the correct DNS server (10.10.0.10) and removed retired DNS entries.
2. Forced DHCP renewal on affected clients to obtain corrected DNS settings.
3. Validated DNS resolution and DC discovery from affected endpoints.
4. Re-ran Group Policy processing and verified successful policy application.
5. Monitored event logs to confirm no recurring 5719/1058/1030/1129/1014 errors.

### Resolution Verification
- Resolution completion time: 09:09.
- Verified outcome: connectivity restored, Group Policy processing successful, no further issues reported by affected users.

## 5 Whys Analysis

1. Why did users experience login failure symptoms?
- Because Group Policy processing failed during startup/logon.

2. Why did Group Policy processing fail?
- Because affected clients could not reach/discover a domain controller and could not access SYSVOL policy files.

3. Why could clients not discover/reach a domain controller?
- Because DNS queries for domain controller records/hostnames timed out or returned no response.

4. Why were DNS queries failing on affected clients?
- Because DHCP assigned decommissioned DNS server IPs to the affected subnet clients.

5. Why did DHCP assign decommissioned DNS servers?
- Because the DHCP scope was not updated as part of the DNS migration/decommission change, and dependency validation controls were insufficient.

## Corrective and Preventive Actions

### Corrective Actions Completed
- DHCP scope corrected for affected subnet DNS options.
- Client leases renewed and endpoint validation completed.
- Incident confirmed resolved at 09:09 with stable GPO processing.

### Preventive Actions
1. Enforce migration dependency checklist
- Require explicit completion check that DHCP scopes are updated before DNS decommission tasks are closed.
- Owner: Network Services.
- Target: Immediate adoption in next change cycle.

2. Add automated post-change validation
- Run scripted checks after DNS changes to detect any active DHCP scope or reservation referencing retired DNS IPs.
- Owner: Infrastructure Automation.
- Target: Within 10 business days.

3. Add startup health monitor for AD/DNS/GPO signals
- Alert on threshold breaches for Netlogon 5719, DNS 1014, and GroupPolicy 1058/1129 in the same subnet/time window.
- Owner: EUC Monitoring.
- Target: Within 15 business days.

4. Standardize fallback DNS policy
- Define and enforce approved primary/secondary DNS server pairs for each subnet with change-controlled templates.
- Owner: Network Architecture.
- Target: Within 20 business days.

5. Strengthen rollout and rollback governance
- For migration waves, require pilot subnet verification and signed checkpoint before broad rollout/decommission.
- Owner: Change Management.
- Target: Next migration release.

## Final Determination
The incident was caused by stale DHCP DNS scope configuration on the affected Floor 3 subnet after DNS decommission. This produced domain controller resolution failures and repeated Group Policy processing errors during logon. After DHCP scope correction and client lease refresh, connectivity and policy processing were restored, and the service remained stable through validation at 09:09.
