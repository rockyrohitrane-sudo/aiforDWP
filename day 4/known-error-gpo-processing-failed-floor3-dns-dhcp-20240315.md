Symptom : Users on affected Finance Windows 11 endpoints experienced login failure symptoms where Group Policy processing failed at startup/logon. Systems reported inability to access domain controller and SYSVOL policy paths.

Cause : The verified root cause was stale DHCP DNS scope configuration on the affected Floor 3 subnet after DNS decommission. Clients received decommissioned DNS server addresses, which caused AD/DC name resolution failure and broke secure channel setup and Group Policy retrieval.

Scope : 3 Windows 11 machines were affected (3 of 4 devices in the OU=Finance segment during the startup window). The incident window began around 07:40 and was resolved at 09:09.

Workaround : Immediately restore service by assigning the correct DNS server (10.10.0.10) on affected endpoints and renewing client leases. Then re-run Group Policy processing and validate domain connectivity.

Permanent fix: Update DHCP scope options for the affected subnet to distribute the correct DNS server (10.10.0.10) and remove retired DNS entries. Keep DHCP scope updates synchronized with DNS decommission changes and validate post-change leases.

How to spot it: Look for Netlogon Event 5719, GroupPolicy Events 1058/1030/1129, DNS Client Event 1014, and DHCP Client Event 50036 in the same incident window. Typical messages include "DNS query for FINBRIDGE-DC01.finbridge.local returned no response," "Cannot access ...\\gpt.ini" with error 0x3, and "None of the configured DNS servers responded." Relevant event sources/modules in this pattern are Netlogon, GroupPolicy, DNS Client, and DHCP Client.
