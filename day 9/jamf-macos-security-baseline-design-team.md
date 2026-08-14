# JAMF Configuration Profile Baseline - macOS Security (Design Team)
Author: DWP Engineer  
Date: 2026-08-14  
Scope: 25 managed macOS devices (Design team fleet)

---

## Purpose

This document translates the DWP macOS security baseline into JAMF Pro configuration profile settings and related compliance logic.  
Each requirement includes:

- Payload type: where the control is set in JAMF
- Value: what to configure
- Effect: what it enforces in plain English
- False-positive risk: common reasons healthy devices are flagged

---

## Critical verification note (same discipline as Day 6 Intune labs)

JAMF Pro labels, payload locations, and workflow pages can differ by:

- JAMF Pro version
- Classic vs newer UI paths
- macOS channel differences (traditional MDM vs DDM-based update controls)

Any row explicitly marked with a naming drift warning must be verified in your own JAMF tenant before production rollout. Do not trust the exact label text from this document without confirming in your environment.

---

## Implementation model for this baseline

Unlike Intune Compliance Policy objects, JAMF usually enforces these controls through a mix of:

1. Configuration Profiles
2. Software Update enforcement policies/plans
3. Smart Group logic for compliance visibility and remediation targeting

For this reason, Requirement 3 and Requirement 6 include both profile settings and operational compliance logic.

---

## Recommended build sequence in JAMF

| Step | Area | Purpose |
|---|---|---|
| 1 | Computers > Configuration Profiles | Create baseline profile shell and payloads (FileVault, Security and Privacy controls) |
| 2 | Computers > Smart Computer Groups | Build dynamic groups for compliant, at-risk, and non-compliant states |
| 3 | Computers > Policies / Software Updates | Enforce update behavior and remediation actions |
| 4 | Computers > Configuration Profiles > Scope | Assign to Design team device group |
| 5 | Reports / Dashboards / Smart Groups | Validate compliance signal and triage drift |

Note: exact navigation text may vary by JAMF version; verify against your tenant navigation.

---

## Baseline translation table

| # | Baseline requirement | Payload type | Value | Effect | False-positive risk |
|---|---|---|---|---|---|
| 1 | FileVault disk encryption must be enabled | Disk Encryption payload in a macOS configuration profile. Naming may appear as Disk Encryption or FileVault in different JAMF versions; verify label in your tenant. | Enable FileVault. Escrow personal recovery key to JAMF. Require institutional key if your standard requires it. Enforce at logout/restart if deferred enablement is used. | Encrypts local data at rest so lost/stolen devices do not expose readable disk contents. | Device is encrypted but key escrow has not synced yet. User has not completed required logout/restart. Inventory lag after enablement shows temporary non-compliance. |
| 2 | Gatekeeper must be enabled (identified developers only) | Security and Privacy payload. Control may be shown under Gatekeeper/app execution restrictions; verify exact section name in your tenant. | Set Gatekeeper to App Store and identified developers. Do not allow Anywhere. | Blocks unsigned/untrusted applications while allowing notarized and identified developer software. | Temporary local admin overrides for troubleshooting. Developer testing workflows using unsigned binaries. Delay between local setting change and JAMF inventory update. |
| 3 | Minimum macOS version: current stable minus one point release | Not a single profile toggle in many JAMF setups. Implement with Managed Software Updates plus Smart Group criteria. High UI variance; verify your workflow labels. | Define compliance floor as current stable minus one point release. Example method: if stable is macOS 15.6, minimum allowed is 15.5. Enforce deadlines and scope remediation policy to devices below floor. | Keeps devices on near-current supported builds to reduce known vulnerability exposure. | Device downloaded update but has not rebooted. Inventory still reports old version. Apple staged rollout delays availability for some models. Build vs marketing version comparison errors in Smart Group criteria. |
| 4 | Firewall must be enabled | Security and Privacy payload (Firewall section). Label path can vary by JAMF version; verify in your tenant. | Enable macOS firewall. Optional: enable stealth mode and firewall logging if required by policy. | Reduces inbound attack surface by blocking unsolicited inbound network traffic. | Third-party network security products may interfere with reported firewall state. Temporary drift during profile re-application or after OS upgrade before next check-in. |
| 5 | Login password required after sleep/screen saver | Security and Privacy payload, authentication lock settings. Exact option names can drift; verify in your tenant. | Require password immediately after sleep or screen saver begins. | Prevents walk-up access to an unlocked user session after idle/sleep transitions. | Compliance checks run before profile refresh. Local user preference temporarily differs before MDM re-assertion. Active session state may delay inventory reflection. |
| 6 | Automatic security updates enabled | Software Update payload/settings, or Managed Updates controls depending on JAMF version and Apple management channel. High UI variance; verify exact labels. | Enable automatic check, download, and install for security updates and system data files. Define install deadline and reboot expectations per maintenance window. | Reduces patching delay by automating security update adoption without relying on manual user action. | Device offline during maintenance window. Update installed but reboot pending. CDN deferrals or staged Apple release timing can delay observed compliance. |

---

## Detailed requirement implementation guidance

## Requirement 1 - FileVault must be enabled

| Field | Detail |
|---|---|
| Payload type | Disk Encryption |
| Value | FileVault enabled, recovery key escrow required |
| Scope guidance | Apply to all Design team Macs, excluding temporary lab devices only if documented |

Effect in practice:

- Device storage is encrypted at rest
- Recovery workflow is available through escrowed keys

Common false-positive causes:

- Encryption in progress but not complete
- User postponed enablement prompt
- Recovery key escrow delay

Operational recommendation:

- Build Smart Groups: FileVault Enabled, FileVault Pending User Action, FileVault Non-Compliant
- Send user-facing prompt communication before enforcement

## Requirement 2 - Gatekeeper enabled for identified developers

| Field | Detail |
|---|---|
| Payload type | Security and Privacy |
| Value | App Store and identified developers |
| Scope guidance | Standard for all Design team endpoints |

Effect in practice:

- Prevents untrusted binary execution by default
- Maintains compatibility with signed creative tooling

Common false-positive causes:

- Temporary local override during troubleshooting
- Packaging/signing anomalies in in-house tools

Operational recommendation:

- Maintain an exception process with expiration date for any temporary developer bypass

## Requirement 3 - Minimum macOS version at stable minus one

| Field | Detail |
|---|---|
| Payload type | Managed Updates plus Smart Group compliance logic |
| Value | Minimum allowed version = current stable - one point release |
| Scope guidance | Full Design team fleet; test pilot first across Apple Silicon and Intel if mixed |

Effect in practice:

- Forces baseline patch currency
- Lowers exposure window to recently remediated CVEs

Common false-positive causes:

- Reboot pending after update installation
- Inventory delay after successful upgrade
- Device model receives staged update later

Operational recommendation:

- Use three Smart Groups: Meets Version Floor, Below Floor In Grace, Below Floor Enforce
- Recalculate version floor monthly after patch stabilization

## Requirement 4 - Firewall enabled

| Field | Detail |
|---|---|
| Payload type | Security and Privacy |
| Value | Firewall On |
| Scope guidance | All managed Design team Macs |

Effect in practice:

- Blocks unsolicited inbound connections not explicitly allowed

Common false-positive causes:

- Third-party security agent status conflicts
- Short telemetry lag after profile deployment

Operational recommendation:

- Validate with both JAMF inventory and local endpoint check during pilot

## Requirement 5 - Password required after sleep/screensaver

| Field | Detail |
|---|---|
| Payload type | Security and Privacy |
| Value | Password required immediately |
| Scope guidance | All user-assigned Design team devices |

Effect in practice:

- Enforces immediate re-authentication when waking device

Common false-positive causes:

- Local settings not yet re-asserted by profile
- Inventory snapshot taken before policy refresh

Operational recommendation:

- Include this control in a dedicated workstation hardening profile to reduce policy fragmentation

## Requirement 6 - Automatic security updates enabled

| Field | Detail |
|---|---|
| Payload type | Software Update controls (profile and/or managed update workflow) |
| Value | Automatic security updates on; enforced install deadlines |
| Scope guidance | All Design team Macs, with maintenance window-aware reboot coordination |

Effect in practice:

- Improves patch consistency and reduces manual remediation workload

Common false-positive causes:

- Download complete but install pending restart
- User deferrals inside allowed deferral window
- Device off-network during enforcement window

Operational recommendation:

- Combine update policy with user notifications and a deadline escalation policy

---

## Suggested compliance state model (JAMF)

JAMF does not always present a single native compliance status identical to Intune per-setting compliance pages. For operational clarity, implement a Smart Group state model:

| State | Meaning | Action |
|---|---|---|
| Compliant | All six baseline controls present and healthy | No action |
| At Risk | One or more controls are pending (reboot required, escrow pending, inventory stale) | Notify user and re-check |
| Non-Compliant | One or more controls failed beyond grace threshold | Remediation policy and escalation |

Recommended grace threshold for this fleet: 7 days for version/update and FileVault pending states, aligned with your existing Windows baseline governance pattern.

---

## UI label drift flags (must verify in your own JAMF instance)

| Setting | Drift risk | What to verify |
|---|---|---|
| Disk Encryption/FileVault payload naming | Medium | Whether payload appears as Disk Encryption, FileVault, or equivalent security payload label |
| Gatekeeper control label | High | Whether option is shown as App Store and identified developers or under a reworded Gatekeeper control |
| Software update controls | High | Whether update enforcement lives under Software Update payload, managed updates workflow, or DDM-specific controls |
| Firewall controls | Medium | Firewall toggle location and optional stealth mode/logging labels |
| Password-after-sleep control text | Medium | Exact wording for immediate password requirement after sleep/screensaver |

Do not proceed to production solely on label text from this document. Validate control identity and behavior in your own tenant.

---

## Assignment and pilot strategy for a 25-device Design fleet

1. Build a pilot group of 5 devices representing real usage patterns.
2. Assign profile and update controls to pilot only for 3 business days.
3. Validate Smart Group population and false-positive rate.
4. Expand to remaining 20 devices in one wave if pilot false positives remain low.
5. Keep an exceptions group with explicit owner and expiry for temporary deviations.

---

## Post-assignment validation checklist

Use both JAMF console data and local endpoint validation:

1. Confirm profile installed status for all scoped devices.
2. Confirm FileVault enabled and recovery key escrowed.
3. Confirm Gatekeeper effective setting is not Anywhere.
4. Confirm firewall state is enabled.
5. Confirm lock-after-sleep behavior triggers immediate password prompt.
6. Confirm automatic security update settings are active and update deadlines enforce correctly.
7. Confirm Smart Group states align with observed endpoint reality.

---

## First 24-hour monitoring checklist

| Hour | Check | What to look for |
|---|---|---|
| 0-2 | Profile deployment status | All pilot devices receive profile without payload errors |
| 2-6 | FileVault and escrow | Encryption starts and escrow records appear |
| 6-12 | Gatekeeper/firewall state | No unexpected drift from enforced values |
| 12-18 | Update posture | Devices at or moving to minimum accepted macOS version |
| 18-24 | User impact/helpdesk | Unexpected lockouts, creative app launch issues, or repeated prompts |

---

## Troubleshooting: FileVault appears non-compliant while encryption is expected to be healthy

Most common causes:

1. User has not completed logout/restart required to finalize enablement.
2. Recovery key escrow has not posted to JAMF yet.
3. Inventory snapshot is stale and predates encryption completion.

Triage sequence:

1. Confirm local FileVault status on endpoint.
2. Confirm escrow record presence in JAMF.
3. Trigger inventory update and re-evaluate Smart Group membership.

---

## Operational review cadence

1. Weekly: review non-compliant and at-risk Smart Groups.
2. Monthly: update minimum macOS version floor (stable minus one point release).
3. Quarterly: re-validate payload labels and workflow paths after JAMF upgrades.

---

## Summary table

| # | Requirement | Payload type | Value |
|---|---|---|---|
| 1 | FileVault enabled | Disk Encryption | Enable and escrow recovery key |
| 2 | Gatekeeper enabled | Security and Privacy | App Store and identified developers |
| 3 | Minimum macOS version | Managed Updates plus Smart Groups | Current stable minus one point release |
| 4 | Firewall enabled | Security and Privacy | On |
| 5 | Password required after sleep/screensaver | Security and Privacy | Immediately require password |
| 6 | Automatic security updates | Software Update controls | Automatic security updates on with enforcement deadline |
