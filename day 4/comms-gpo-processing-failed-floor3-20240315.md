# Communications - Group Policy Processing Failed - Finance Floor 3 (2024-03-15)

---

## Audience 1 - Non-technical Executive

Your access and data are safe, and no data was lost. Between 07:40 and 09:09, three Finance Windows 11 computers had sign-in setup fail because they were given an out-of-date network lookup setting left from an earlier migration. We corrected the central network setting, refreshed those computers, and confirmed connectivity and sign-in setup are now normal. No action is needed unless this reappears; if it does, contact the Service Desk.

---

## Audience 2 - Affected End-user Team (10 people, non-technical)

Hi team, your access and data are safe, and no data was lost. Between 07:40 and 09:09, three Finance Windows 11 computers could not complete sign-in setup because they were given an out-of-date network lookup setting left from an earlier migration. We fixed the central network setting, refreshed the affected computers, and confirmed connectivity and sign-in setup are working normally again. If you see the same issue, sign out and back in once; if it continues, contact the Service Desk.

---

## Audience 3 - Engineer-to-engineer Internal Note

Incident facts (same as user comms):
- Data/access safety: safe, no data loss.
- Incident window: 07:40 to 09:09.
- Scope: 3 Finance Win11 endpoints affected.
- Triggering technical condition: clients received stale DNS via DHCP scope (legacy/decommissioned resolver after migration), causing DC discovery failure and GP processing failure during startup/logon.

Root cause:
- DHCP scope on the affected subnet still referenced decommissioned DNS server entries after migration, so affected clients failed name resolution to DC targets.
- Downstream symptoms: Netlogon secure channel failures, DNS timeout warnings, GP 1058/1030/1129 failures.

Exact action taken:
1. Updated affected subnet DHCP scope option for DNS servers to correct resolver 10.10.0.10 and removed stale DNS entries.
2. Renewed DHCP leases on affected endpoints so corrected DNS was applied.
3. Re-ran AD/DC connectivity checks and Group Policy processing validation.

Config detail:
- Bad assigned DNS observed on affected device: 10.10.3.250 (retired).
- Correct DNS required and validated: 10.10.0.10.
- Comparison host with correct DNS processed GP successfully in same window.

Verification steps performed:
1. Confirmed corrected DNS lease present on remediated endpoints.
2. Confirmed DC name resolution and secure channel path restored.
3. Confirmed Group Policy processing succeeds with no repeat 5719/1014/1058/1030/1129 in validation window.
4. User-facing validation confirmed issue resolved at 09:09 with no further reports.

Preventive actions required:
1. Enforce migration dependency checkpoint: DHCP scope DNS must be updated before DNS decommission closure.
2. Add post-change automated audit to detect active scopes/reservations pointing to retired DNS IPs.
3. Add monitoring correlation alert for clustered 5719 + 1014 + 1058/1129 by subnet/time.
4. Standardize approved DNS templates per subnet and require change-control validation sign-off.
