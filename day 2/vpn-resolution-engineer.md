Root cause: Win11 upgrade removed legacy VPN client; Intune did not re-deploy new client due to detection-rule gap.
Exact action taken: Manually removed stale VPN registry entries under HKLM\SOFTWARE\<vendor>, force-triggered Intune sync, new client deployed, split-tunnel config applied.
Config detail: split-tunnel enabled; stale entries removed specifically under HKLM\SOFTWARE\<vendor>.
Verification: connectivity confirmed to all internal subnets.
Data impact: no data loss.
Preventive action needed: close the Intune detection-rule gap so post-upgrade missing-client states reliably trigger re-deployment.
