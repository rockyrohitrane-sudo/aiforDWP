# Triage Hypothesis - Login Failure (GPO Processing Failed) - Win11 Fleet

## Scope Facts Used
- Symptom: Group Policy processing failed during user login.
- Who: 3 Windows 11 machines.
- Since: Approximately 07:40 this morning.
- Change: Nil reported.

## Ranked Top 5 Most Likely Causes (Most Probable First)

### 1) Domain Controller reachability or authentication path issue at login time
Why this fits scope facts:
- Three machines failing in the same time window suggests a shared dependency issue rather than isolated endpoint corruption.
- GPO processing at logon requires reliable domain connectivity (LDAP/Kerberos/SMB/SYSVOL access).
- No declared change does not rule out transient network path failure, DC service degradation, or site routing drift.

Single fastest check to confirm or eliminate:
- From one affected endpoint, run `gpupdate /force` and immediately check for DC/SYSVOL access errors; in parallel, verify `\\<domain>\\SYSVOL` is reachable.

### 2) DNS resolution fault affecting AD service discovery (_ldap/_kerberos SRV lookups)
Why this fits scope facts:
- GPO and logon depend on accurate DNS to discover DCs and AD services.
- Multi-endpoint onset at the same time strongly matches a shared DNS issue (wrong DNS server, stale records, resolver outage).
- "No change" from users is common even when DHCP/DNS backend behavior shifts.

Single fastest check to confirm or eliminate:
- On one impacted device, run `nltest /dsgetdc:<domain>`; failure or wrong-site DC resolution quickly confirms DNS/DC discovery problems.

### 3) SYSVOL/NETLOGON replication or permissions break on one or more DCs
Why this fits scope facts:
- GPO processing failure is commonly tied to unreadable policy files in SYSVOL.
- If affected clients are hitting a specific unhealthy DC, a subset of machines can fail while others remain normal.
- Time-bounded onset can map to DFSR backlog, replication halt, or ACL drift on policy paths.

Single fastest check to confirm or eliminate:
- From an affected endpoint, open `\\<domain>\\SYSVOL\\<domain>\\Policies` and verify readable access to policy folders; access denied/path unavailable is decisive.

### 4) AD site/subnet mapping or network segment issue after morning reconnect
Why this fits scope facts:
- Exactly three Windows 11 machines can indicate they share one VLAN/subnet/site path.
- Around 07:40 aligns with startup/reconnect cycles where wrong site mapping or route/NAC behavior appears.
- This can break timely contact with an appropriate DC, causing GP processing timeouts/failures.

Single fastest check to confirm or eliminate:
- Compare `ipconfig /all` output for all three affected devices (subnet, DNS servers, gateway) and verify they match expected corporate values.

### 5) Client-side GP service timing failure on Windows 11 (slow-link/startup race/cached state)
Why this fits scope facts:
- A small set of Win11 endpoints can fail together if they share similar boot pattern, VPN timing, or identical update state.
- Login-time GP is sensitive to network readiness; race conditions can cause "processing failed" even without infrastructure change.
- Still less likely than shared AD/DNS/DC path issues because impact is on multiple machines at once.

Single fastest check to confirm or eliminate:
- Reboot one affected machine on a known-good wired network and test sign-in; if GP succeeds consistently after stable network readiness, client timing is favored.

## Constraint
This is a ranked hypothesis list derived only from scope facts. No single root cause is selected at this stage.

## Evidence Assessment Against Incident Event Logs

### Hypothesis 1) Domain Controller reachability or authentication path issue at login time
Judgement: Support.

Determining evidence:
- 07:40:08 Netlogon Event 5719: secure channel to domain could not be established, no domain controller available.
- 07:40:12 GroupPolicy Event 1129: explicit no network connectivity to a domain controller.
- 07:44:01 GroupPolicy Event 1129: repeated no domain controller connectivity during the same incident window.

### Hypothesis 2) DNS resolution fault affecting AD service discovery (_ldap/_kerberos SRV lookups)
Judgement: Support.

Determining evidence:
- 07:41:05 DNS Client Event 1014: name resolution for FINBRIDGE-DC01.finbridge.local timed out and configured DNS servers did not respond.
- 07:40:08 Netlogon Event 5719: DNS query for FINBRIDGE-DC01.finbridge.local returned no response.
- 07:42:18 DHCP Client Event 50036 on DESKTOP-FB031: DNS assigned as 10.10.3.250 (old/decommissioned), matching the failure pattern.
- 07:40:05 DHCP Client Event 50036 on DESKTOP-FB029 (unaffected): DNS assigned as 10.10.0.10 (correct), with successful GP processing shortly after.

### Hypothesis 3) SYSVOL/NETLOGON replication or permissions break on one or more DCs
Judgement: Contradicts.

Determining evidence:
- 07:40:11 GroupPolicy Event 1500 on DESKTOP-FB029: policies processed successfully in the same OU, showing SYSVOL/GP content is reachable when DNS/DC path is correct.
- 07:40:09 GroupPolicy Event 1058 on DESKTOP-FB031: cannot access gpt.ini with 0x3 path not found, which is consistent with name resolution/DC reachability failure, not a demonstrated SYSVOL ACL or replication fault.
- 07:40:12 and 07:44:01 GroupPolicy Event 1129: explicit no DC connectivity points upstream of SYSVOL content/permissions.

### Hypothesis 4) AD site/subnet mapping or network segment issue after morning reconnect
Judgement: Support.

Determining evidence:
- 07:42:18 DHCP Client Event 50036 on DESKTOP-FB031: subnet lease assigns decommissioned DNS server 10.10.3.250.
- DHCP comparison note: affected Floor 3 hosts received decommissioned DNS while unaffected host received correct central DNS, indicating a segment/scope-level network configuration problem.
- 07:40:12 GroupPolicy Event 1129: no DC connectivity is a direct downstream effect of that segment-level DNS misassignment.

### Hypothesis 5) Client-side GP service timing failure on Windows 11 (slow-link/startup race/cached state)
Judgement: Contradicts.

Determining evidence:
- 07:41:05 DNS Client Event 1014 and 07:40:08 Netlogon Event 5719 show hard DNS/DC discovery failure, not only startup timing race.
- 07:42:18 DHCP Client Event 50036 shows objectively wrong DNS configuration delivered to the affected client.
- 07:40:11 GroupPolicy Event 1500 on DESKTOP-FB029 shows successful processing on comparable Windows 11 endpoint when DNS is correct, arguing against a generic Win11 GP timing defect.

## Assessment Constraint
All five hypotheses were assessed against the supplied logs. No final winning cause is selected in this step.

## Addendum - Updated Event Details, Surviving Hypothesis, and Resolution

### Updated Event Details (Chronological)
- 07:40:02 - Service Control Manager Event 7036: Network Location Awareness entered running state.
- 07:40:08 - Netlogon Event 5719 (Error): secure channel to domain FINBRIDGE could not be established; DNS query for FINBRIDGE-DC01.finbridge.local returned no response.
- 07:40:09 - GroupPolicy Event 1058 (Error): cannot access \\FINBRIDGE-DC01\\sysvol\\finbridge.local\\Policies\\{3A1B2C4D-E5F6-7890-ABCD-EF1234567890}\\gpt.ini, error 0x3.
- 07:40:10 - GroupPolicy Event 1030 (Warning): cannot query list of Group Policy objects, error 0x546.
- 07:40:11 - GroupPolicy Event 1058 (Error): repeated SYSVOL path access failure.
- 07:40:12 - GroupPolicy Event 1129 (Error): Group Policy failed due to no network connectivity to a domain controller.
- 07:41:05 - DNS Client Events Event 1014 (Warning): name resolution for FINBRIDGE-DC01.finbridge.local timed out; configured DNS servers did not respond.
- 07:42:18 - DHCP Client Event 50036 (Information): DESKTOP-FB031 received IP 10.10.3.144 and DNS server 10.10.3.250 (old/decommissioned).
- 07:44:01 - GroupPolicy Event 1129 (Error): repeated no-DC-connectivity Group Policy failure.
- 07:40:05 - DHCP Client Event 50036 on DESKTOP-FB029 (comparison host): DNS server 10.10.0.10 (correct new DNS).
- 07:40:11 - GroupPolicy Event 1500 on DESKTOP-FB029: Group Policy processed successfully.

### Surviving Hypothesis
DNS resolution fault affecting AD/DC discovery, caused by incorrect DHCP scope DNS assignment (decommissioned DNS server distributed to affected subnet clients).

Why this survived elimination:
- Event 5719 at 07:40:08 directly reports DC secure-channel setup failure with DNS query no response.
- Event 1014 at 07:41:05 confirms DNS timeout and non-responsive configured DNS servers.
- Event 50036 at 07:42:18 confirms affected host received old DNS server 10.10.3.250 from DHCP.
- Comparison host FB029 received correct DNS 10.10.0.10 at 07:40:05 and processed GP successfully at 07:40:11 (Event 1500).

### Detailed Resolution Steps
1. Contain impact immediately.
- Set affected endpoints to temporary correct DNS (10.10.0.10) to restore sign-in and policy path.

2. Correct DHCP scope configuration for the affected subnet.
- Replace decommissioned DNS entries with the approved DNS server list.
- Remove old DNS server 10.10.3.250 from active scope options.

3. Validate DNS service functionality.
- From an affected subnet client, verify DC hostname resolution and domain SRV discovery succeed using the corrected DNS server.

4. Force clients to obtain corrected settings.
- Renew DHCP leases on affected clients and confirm DNS server list reflects the updated scope.

5. Verify AD connectivity and Group Policy recovery.
- Re-test domain secure channel and run Group Policy refresh.
- Confirm no new Event 5719, 1058, 1030, 1129, or 1014 entries during validation window.

6. Baseline-check against known-good host.
- Compare one remediated endpoint with FB029 network/DNS/GPO outcomes to confirm parity.

7. Implement prevention controls.
- Update migration runbook: DHCP scope DNS updates must complete before DNS decommission.
- Add post-change monitoring for clients still leased with retired DNS IPs.
- Record this incident pattern in known-error documentation for faster future triage.
