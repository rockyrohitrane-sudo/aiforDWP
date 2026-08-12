# Intune Compliance Policy – Windows 11 Security Baseline
**Author:** DWP Engineer  
**Date:** 2026-08-11  
**Scope:** Windows 11 managed devices (Intune MDM)  
**Grace Period:** 7 days applied to all settings  

---

## Purpose

This document translates the DWP Windows 11 security baseline requirements into exact Intune Compliance Policy settings. Each entry provides the setting name as it appears in the Intune portal, the required value, what it enforces, known false-positive risks, and any recommended adjustments.

---

## Policy Creation Wizard – Structure Reference

When creating the policy, the wizard presents these steps in order:

| Step | Name | Purpose |
|---|---|---|
| 1 | Basics | Set Name, Description. Select **Platform: Windows 10 and later** and **Profile type: Windows 10/11 compliance policy** |
| 2 | Compliance settings | Configure all security checks (BitLocker, Secure Boot, OS version, etc.) |
| 3 | Actions for noncompliance | Set grace period and notification actions |
| 4 | Assignments | Scope to AAD device groups |
| 5 | Review + create | Confirm and save |

### Step 2: Compliance Settings – Section Breakdown

Step 2 presents settings grouped into collapsible sections. Each section must be **expanded (click the ∨ arrow)** to see its settings. The full section list as it appears in the portal:

| Section | Relevant to This Baseline | Action |
|---|---|---|
| **Custom Compliance** | No | Leave **Not configured** — requires a custom discovery script and JSON file; not used in this standard baseline |
| **Device Health** | **Yes** | Expand — contains BitLocker, Secure Boot, and Code Integrity settings |
| **Device Properties** | **Yes** | Expand — contains Minimum OS version |
| **Configuration Manager Compliance** | No | Leave **Not configured** — only applicable to co-managed devices enrolled in SCCM/ConfigMgr; pure Intune estates should leave this off |
| **System Security** | **Yes** | Expand — contains Password, Firewall, and Defender settings |

> **Note:** Custom Compliance and Configuration Manager Compliance both default to **Not configured** (the blue "Not configured" toggle is active by default as shown in the portal). Do not change these unless your environment specifically requires them.

---

## Global Grace Period Setting

| Field | Value |
|---|---|
| **Setting** | Mark device noncompliant |
| **Value** | 7 days after noncompliance |
| **UI Path** | Intune admin center > Devices > Windows > Compliance policies > Create policy > **Step 3: Actions for noncompliance** > Add action > Mark device noncompliant > Schedule: 7 days |

Apply this to all settings below. The grace period means a device is flagged but not blocked for 7 days, allowing time for remediation before enforcement kicks in.

---

## Requirement 1 – BitLocker Must Be Enabled on the OS Drive

| Field | Detail |
|---|---|
| **Setting Name** | Require BitLocker |
| **Value** | Require |
| **UI Path** | Intune admin center > Devices > Windows > Compliance policies > Create policy > **Step 2: Compliance settings** > Device Health > Require BitLocker |

**Effect:** Intune checks that Windows reports BitLocker as enabled and protecting the OS volume (C:). A device without BitLocker active is marked non-compliant.

**False-Positive Risk:**
- BitLocker provisioning can complete but the encryption key escrow to AAD/Entra ID may not yet be confirmed — Intune may still flag briefly after enabling.
- Virtual machines (AVD session hosts, Hyper-V VMs) often report BitLocker as unsupported or inactive even when the host is encrypted.
- Devices mid-encryption (encryption in progress) may not yet pass the check.
- Some OEM factory-provisioned devices use "used space only" encryption — Intune can still detect this as compliant, but edge cases exist with older firmware.

**Recommendation:** Pair this with an Intune Device Configuration profile to silently enable BitLocker (Endpoint Security > Disk Encryption) so devices auto-remediate. For AVD shared/pooled hosts, consider excluding that device group from the BitLocker compliance check and enforce at the infrastructure layer instead.

---

## Requirement 2 – Secure Boot Must Be Enabled

| Field | Detail |
|---|---|
| **Setting Name** | Require Secure Boot to be enabled on the device |
| **Value** | Require |
| **UI Path** | Intune admin center > Devices > Windows > Compliance policies > Create policy > **Step 2: Compliance settings** > Device Health > Require Secure Boot to be enabled on the device |

**Effect:** Uses Windows Health Attestation Service (HAS) to verify the device's UEFI reports Secure Boot as active at boot time. Prevents unsigned or tampered bootloaders.

**False-Positive Risk:**
- Older hardware (pre-2017 devices) may have UEFI that supports Secure Boot but shipped with it off — requires a BIOS change by a local admin or SCCM/script task.
- Dual-boot configurations (Linux alongside Windows) commonly require Secure Boot to be disabled.
- Some development/test machines are intentionally configured without Secure Boot.
- The Health Attestation check requires the device to successfully contact the HAS endpoint. Network or proxy issues at the time of attestation can cause transient failures.

**Recommendation:** No value reduction recommended — Secure Boot is a hard requirement under DWP baseline. Identify and remediate the small population of legacy hardware as a one-time project. Exclude known dual-boot developer devices via a dedicated compliance policy scoped to that AAD group.

---

## Requirement 3 – Minimum OS Build (N-1 Policy)

| Field | Detail |
|---|---|
| **Setting Name** | Minimum OS version |
| **Value** | `10.0.22621.2861` |
| **UI Path** | Intune admin center > Devices > Windows > Compliance policies > Create policy > **Step 2: Compliance settings** > Device Properties > Operating System Version > Minimum OS version |

**Device Properties – Operating System Version field reference:**

The **Device Properties** section contains a sub-group labelled **"Operating System Version"** with four fields. Only set **Minimum OS version** for this baseline. Leave all others as Not configured:

| Field | Value to Set | Notes |
|---|---|---|
| **Minimum OS version** ⓘ | `10.0.22621.2861` | **Set this** — enforces N-1 patch floor for Windows 11 22H2 |
| Maximum OS version ⓘ | Not configured | Leave blank — setting this blocks devices on newer builds (23H2, 24H2) |
| Minimum OS version for mobile devices ⓘ | Not configured | Leave blank — applies to Android/iOS only; irrelevant for Windows 11 desktop |
| Maximum OS version for mobile devices ⓘ | Not configured | Leave blank — applies to Android/iOS only; irrelevant for Windows 11 desktop |

> **Format:** The Minimum OS version field is a free-text box. Enter the value exactly as shown: `10.0.22621.2861` — four dot-separated segments. Entering only the build suffix (e.g. `22621.2861`) without the `10.0.` prefix will cause the field to reject the value or evaluate incorrectly.

**Effect:** Any device running a Windows 11 22H2 build older than 22621.2861 (N-1 from the current known-good 22621.3155) will be marked non-compliant. Enforces a minimum patch currency.

**False-Positive Risk:**
- Devices pending a restart after a Windows Update download will still report the old build until reboot — they will transiently fail until rebooted.
- Devices on a Windows Update for Business deferral ring that pushes updates on a delay will systematically fail until the deferral window expires.
- Build numbers reported by Intune can have a short sync delay after patching — up to 8 hours before the portal reflects the new build.
- Devices on Windows 11 23H2 or 24H2 report higher build numbers (e.g. 22631.x, 26100.x) — these will still pass the ≥ 22621.2861 check because Intune evaluates this as a numeric minimum, not an exact match.

**Recommendation:** Align the Minimum OS version update cadence with your Windows Update for Business deferral ring. If your standard ring defers Quality Updates by 14 days, update this compliance value 14 days after Microsoft releases the target build. Review and update this value each Patch Tuesday cycle.

---

## Requirement 4 – Windows Defender Real-Time Protection Must Be On

| Field | Detail |
|---|---|
| **Setting Name** | Require real-time protection |
| **Value** | Require |
| **UI Path** | Intune admin center > Devices > Windows > Compliance policies > Create policy > **Step 2: Compliance settings** > System Security > Microsoft Defender Antimalware > Require real-time protection |

**Effect:** Checks that Microsoft Defender Antivirus real-time protection is active on the device. Devices where Defender has been disabled (manually, by policy conflict, or by a third-party AV) are marked non-compliant.

**False-Positive Risk:**
- If a third-party antivirus (e.g. CrowdStrike, Symantec) is installed and registered as the active AV in Windows Security Center, Defender real-time protection is intentionally disabled by Windows — this will trigger a false positive unless that AV registers correctly.
- Devices where a user has temporarily disabled Defender (even briefly) may not re-enable automatically before the next Intune check-in.
- Defender definition updates in progress can briefly cause a "protection off" state.
- Certain Defender exclusions applied by GPO/script can sometimes affect how the compliance report interprets RTP status.

**Recommendation:** If your estate uses a third-party EDR/AV that replaces Defender, consult whether it correctly registers with Windows Security Center. If it does not, consider using the third-party AV's own compliance integration (e.g. CrowdStrike Zero Trust Assessment) instead of the Defender RTP check. For a pure-Defender estate, no adjustment needed.

---

## Requirement 5 – Firewall Must Be Enabled for All Profiles

| Field | Detail |
|---|---|
| **Setting Name** | Microsoft Defender Firewall |
| **Value** | Require |
| **UI Path** | Intune admin center > Devices > Windows > Compliance policies > Create policy > **Step 2: Compliance settings** > System Security > Microsoft Defender Firewall |

**Effect:** Verifies that Windows Firewall is enabled on all three profiles — Domain, Private, and Public. A device where any single profile has the firewall disabled will fail compliance.

**False-Positive Risk:**
- Some organisations use a third-party host-based firewall (e.g. Cisco AnyConnect includes its own firewall component). If that product disables Windows Firewall, this check will fail.
- Legacy GPO settings from an on-premises domain that explicitly disable the domain profile firewall ("Domain Networks: Windows Firewall: Do not allow exceptions") conflict with this requirement and will cause systematic failures for domain-joined devices.
- Software deployments (particularly VPN clients or security tools) occasionally temporarily disable the firewall during installation.

**Recommendation:** Audit existing GPO settings for any firewall-disabling policies before enabling this compliance check. Enable a Intune Firewall configuration profile (Endpoint Security > Firewall) to ensure Firewall is enforced via Intune rather than relying on legacy GPO.

> ⚠️ **UI Path Note:** The setting label has been seen as both **"Microsoft Defender Firewall"** and **"Windows Firewall"** in different Intune portal versions. The underlying setting is the same. Verify the label in your tenant at implementation time.

---

## Requirement 6 – A PIN or Password Must Be Configured

| Field | Detail |
|---|---|
| **Setting Name** | Require a password to unlock mobile devices |
| **Value** | Require |
| **Supporting Settings** | See below |
| **UI Path** | Intune admin center > Devices > Windows > Compliance policies > Create policy > **Step 2: Compliance settings** > System Security > Password |

**Supporting password complexity settings (configure alongside):**

| Setting | Recommended Value |
|---|---|
| Required password type | Alphanumeric |
| Minimum password length | 8 |
| Password complexity | Require digits, lowercase, uppercase (or use "Alphanumeric") |
| Maximum minutes of inactivity before password is required | 15 |
| Password expiration (days) | 365 (or per DWP policy) |
| Number of previous passwords to prevent reuse | 5 |

**Effect:** Ensures the device has a lock screen password or Windows Hello PIN configured. A device with no password/PIN is marked non-compliant.

**False-Positive Risk:**
- Shared/kiosk devices intentionally configured for auto-logon with no password will always fail this check.
- Azure AD joined devices using Windows Hello for Business (WHFB) — WHFB PINs satisfy this requirement, but there is a brief window during initial WHFB enrolment where the PIN is not yet provisioned and the device can transiently fail.
- Devices where a local admin has removed the password requirement via `net user` or Group Policy.

**Recommendation:** For kiosk/shared devices, use a separate compliance policy scoped to that device group with this check disabled or adjusted. For the general estate, the 7-day grace period covers WHFB provisioning delays.

---

## Requirement 7 – Device Must Not Be Jailbroken or Rooted

> ⚠️ **Windows-specific note:** "Block jailbroken devices" is an **iOS/Android-only** setting and does not exist in Windows compliance policies. The Windows equivalent — detecting OS tampering and unsigned boot components — is achieved through **Require code integrity**, which uses Windows Health Attestation Service (HAS).

| Field | Detail |
|---|---|
| **Setting Name** | Require code integrity |
| **Value** | Require |
| **UI Path** | Intune admin center > Devices > Windows > Compliance policies > Create policy > **Step 2: Compliance settings** > Device Health > Require code integrity |

**Effect:** Uses Windows Health Attestation to verify that code integrity is enforced at boot — meaning only signed, trusted drivers and system files were loaded. A device where unsigned or tampered code was loaded fails this check and is marked non-compliant.

**False-Positive Risk:**
- This check on Windows relies on the Health Attestation Service (HAS). Any device unable to reach the HAS endpoint (`has.spserv.microsoft.com`) due to network/proxy restrictions will fail attestation and be flagged.
- Devices with custom Secure Boot keys (e.g. enterprise-signed bootloaders for specialised hardware) may fail standard attestation.
- Test/dev machines with debug-mode Windows builds will fail this check.
- Hyper-V VMs without virtualisation-based security (VBS) enabled may not pass all attestation checks.

**Recommendation:** Ensure the HAS endpoint is reachable from all device network segments, including when connected via VPN only. Add `has.spserv.microsoft.com` to the VPN split-tunnel allowlist if applicable. For dev/test VMs, scope to a separate compliance policy.

---

## Summary Table

| # | Requirement | Setting Name | Value | Grace Period |
|---|---|---|---|---|
| 1 | BitLocker on OS drive | Require BitLocker | Require | 7 days |
| 2 | Secure Boot enabled | Require Secure Boot to be enabled on the device | Require | 7 days |
| 3 | Minimum OS build (N-1) | Minimum OS version | 10.0.22621.2861 | 7 days |
| 4 | Defender real-time protection | Require real-time protection | Require | 7 days |
| 5 | Firewall all profiles | Microsoft Defender Firewall | Require | 7 days |
| 6 | PIN or password configured | Require a password to unlock mobile devices | Require | 7 days |
| 7 | Not jailbroken/rooted | Require code integrity | Require | 7 days |

---

## UI Path Change Flags

The following settings carry a risk of UI path drift since training data cutoff. Verify each before implementation:

| Setting | Risk | Action |
|---|---|---|
| Minimum OS version | "Operating System Version" sub-header removed; setting now sits directly under Device Properties | Path corrected — confirm label matches in your tenant |
| Microsoft Defender Firewall | Intermediate "Windows Firewall" sub-section removed in current portal; setting is now a direct child of System Security | Path corrected — search for "firewall" if not immediately visible |
| Require BitLocker | Moved from System Security > Device Security to Device Health in current portal layout | Path corrected — confirm under Device Health tab |
| Require code integrity | Replaces the non-applicable "Block jailbroken devices" (iOS/Android only); always under Device Health for Windows | Verify this setting is present in your tenant's Windows compliance wizard |
| Require real-time protection | Sometimes listed under "Microsoft Defender Antimalware" and sometimes under a collapsed "Defender" group | Search for "real-time" if not immediately visible |

**Reference:** Always validate against the current Microsoft Learn documentation at implementation time:  
https://learn.microsoft.com/en-us/mem/intune/protect/compliance-policy-create-windows

---

## Implementation Notes

1. **Create a dedicated compliance policy** — do not add these settings to an existing broad policy. A dedicated "Win11-Security-Baseline-Compliance" policy makes auditing and exception management cleaner.
2. **Scope with AAD groups** — assign to a device group representing the target estate. Create separate policies for excluded populations (kiosk, AVD, dev/test).
3. **Conditional Access dependency** — compliance status only enforces access controls if a Conditional Access policy is linked. Confirm CA policies reference this compliance policy.
4. **Monitor before enforce** — set the grace period to 7 days and monitor the non-compliance report for the first two weeks before any CA block takes effect. Investigate systematic failures before assuming device compromise.
5. **Review cadence** — review Requirement 3 (OS build) monthly and update after each Patch Tuesday stabilisation period.

---

## Post-Assignment Validation

### Where to Check a Device's Compliance Status for This Policy

After the device syncs, follow this exact path to see per-policy, per-setting compliance status:

**Intune admin center > Devices > Windows > [select the device] > Monitor > Device compliance**

This view shows:
- Every compliance policy assigned to the device listed by name
- The overall result for each policy (Compliant / Not compliant / In grace period)
- A **"Per-setting status"** drill-down — click the policy name to expand it and see which individual settings passed or failed

**Alternative path to find the same device faster:**  
Intune admin center > Devices > All devices > search device name > select device > Monitor > Device compliance

---

### Compliance Status Definitions and Conditional Access Impact

| Status | What it means | Conditional Access impact |
|---|---|---|
| **Compliant** | All settings in the policy are met as of the last check-in | Device is granted access to resources protected by CA policies that require compliance. No block applied. |
| **Not compliant** | One or more settings are failing AND the grace period has expired | Device is **blocked** from CA-protected resources (M365, SharePoint, etc.) at the next token refresh. Existing sessions may persist briefly until token expiry (typically 1 hour). |
| **In grace period** | One or more settings are failing BUT the 7-day grace period is still running | Device is **not yet blocked** — CA treats it as compliant during the grace window. The non-compliant state is recorded and visible in reports. Block begins automatically when the grace period expires. |

> **Key operational point:** "In grace period" does not mean the device is healthy — it means enforcement is deferred. Use the grace period window to remediate, not to ignore. If a device reaches day 7 still non-compliant, the CA block is automatic and users will contact the helpdesk.

---

### BitLocker Shows Non-Compliant Despite BitLocker Being Enabled — Three Most Common Causes

#### Cause 1: Recovery Key Not Escrowed to Entra ID

**What happens:** BitLocker is fully encrypting the drive, but the recovery key has not been backed up to Entra ID. Intune's BitLocker compliance check verifies both encryption state *and* key escrow. If the key is not in Entra ID, the device is marked non-compliant even though the disk is encrypted.

**Fastest check:**  
On the device, run in an elevated PowerShell prompt:
```powershell
manage-bde -protectors -get C:
```
Confirm a recovery password protector exists. Then in Intune admin center go to:  
**Devices > [device] > Recovery keys**  
If no key appears there, escrow has not completed. Force it with:
```powershell
BackupToAAD-BitLockerKeyProtector -MountPoint "C:" -KeyProtectorId ((Get-BitLockerVolume -MountPoint "C:").KeyProtector | Where-Object {$_.KeyProtectorType -eq "RecoveryPassword"}).KeyProtectorId
```

---

#### Cause 2: Encryption in Progress (Not Yet Fully Encrypted)

**What happens:** BitLocker has been enabled and is actively encrypting, but the percentage is not yet 100%. Intune reports the device as non-compliant because it checks for `FullyEncrypted` status, not `EncryptionInProgress`.

**Fastest check:**  
On the device, run:
```powershell
Get-BitLockerVolume -MountPoint "C:" | Select-Object EncryptionPercentage, VolumeStatus
```
If `VolumeStatus` shows `EncryptionInProgress`, this is the cause. No action needed — wait for encryption to complete, then trigger an Intune sync:  
**Settings > Accounts > Access work or school > [account] > Info > Sync**

---

#### Cause 3: Stale Intune Compliance Evaluation (Report Not Refreshed After BitLocker Enabled)

**What happens:** BitLocker was enabled after the last Intune compliance evaluation. The portal still shows the pre-encryption state. The device is actually compliant but Intune does not know yet.

**Fastest check:**  
Check the **Last check-in** timestamp on the device:  
**Intune admin center > Devices > [device] > Overview** — look at "Last check-in".  
If the last check-in predates when BitLocker was enabled, the portal result is stale. Force a sync from the device or from the portal:  
**Intune admin center > Devices > [device] > Sync** (the Sync button in the device toolbar)  
Allow up to 15 minutes after sync for the compliance status to update.

---

### First 24-Hour Monitoring Checklist After Policy Assignment

| Hour | Check | Location | What you are looking for |
|---|---|---|---|
| 0–1 | Policy assignment confirmed | Intune > Devices > Windows > Compliance policies > [policy] > Device status | Policy shows as assigned; device count increasing as devices check in |
| 1–4 | First wave of check-ins | Intune > Reports > Device compliance > Policy compliance | Non-compliant count — identify which settings are failing and whether failures are expected or unexpected |
| 4–8 | BitLocker escrow status | Intune > Devices > [any non-compliant device] > Recovery keys | Confirm recovery keys are present; absence = escrow issue (Cause 1 above) |
| 8–16 | Conditional Access sign-in failures | Entra ID > Monitoring > Sign-in logs > Filter: Status = Failure, Failure reason = Device compliance | Any CA blocks firing — should be zero during grace period |
| 16–24 | Helpdesk ticket volume | ITSM platform | Spike in "can't access email/Teams/SharePoint" = CA block firing earlier than expected; investigate immediately |
