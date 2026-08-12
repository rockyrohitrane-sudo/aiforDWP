# Step-by-Step Guide: Add a Windows App to the Intune App Catalog (Pre-Phased Rollout)
**Author:** DWP Engineer  
**Date:** 2026-08-11  
**Audience:** DWP engineers with no prior Intune app-deployment experience  
**Worked Example:** FinBridge Connect v3.1 (Windows LOB app packaged as `.intunewin`)

---

## Purpose

Use this guide to add an application to the Intune app catalog correctly before any phased rollout begins. It covers where to add the app, which app type to choose, required app configuration fields, assignment basics, and post-deployment verification.

> **UI Label Drift Warning (Important):** Intune portal labels and menu positions can vary by tenant version and Microsoft UI updates. Follow the navigation path below, but always verify labels live in your own tenant before clicking.

---

## Worked Example Inputs (Use Throughout)

For this procedure, use the following example values:

- **Application name:** FinBridge Connect
- **Application version:** 3.1
- **Package type:** Windows LOB app (`.intunewin`)
- **Install command:** `FinBridgeConnect_Setup.exe /silent`
- **Uninstall command:** `FinBridgeConnect_Setup.exe /uninstall /silent`
- **Detection method:** Registry key/value
- **Detection target:** `HKLM\SOFTWARE\FinBridge\Connect\Version = 3.1`

---

## Numbered Deployment Guide

1. **Open the Intune admin center and go to Apps.**  
   Navigation path (labels may vary):  
   **Intune admin center > Apps > All apps > Add**

   - If you do not see **All apps**, look for equivalent labels such as **Applications** or **App catalog**.
   - Confirm you are in the correct tenant before continuing.

2. **Choose the correct app type.**  
   In the **Select app type** step (label may vary), choose based on package source:

   - **Windows app (Win32)** for `.intunewin` packages (use this for FinBridge Connect v3.1).
   - **Microsoft Store app (new)** for apps deployed directly from Microsoft Store catalog.
   - **Web link** for URL shortcuts/web apps (opens a site, not a traditional software install).

   > For this worked example, select **Windows app (Win32)**.

3. **Upload the `.intunewin` package.**  
   In the package upload step (often called **App package file**):

   - Browse and select the FinBridge Connect package file (`.intunewin`).
   - Wait for metadata extraction to complete before selecting **Next**.
   - If the tenant shows a different button label (for example **Select file** vs **Choose app package file**), use the equivalent control.

4. **Complete App Information fields (required baseline set).**  
   The **App information** tab is the first of six tabs across the top of the Add App wizard:  
   **App information → Program → Requirements → Detection rules → Dependencies → Superseder**  
   Complete all required fields on this tab before selecting **Next**.

   ### 4.1 Select file
   - This field displays the filename of the `.intunewin` package you uploaded in step 3.
   - For this worked example it will show **FinBridgeConnect.intunewin** (or the exact filename of your package).
   - This field is read-only once the package is uploaded. If the wrong file is shown, go back and re-upload.

   ### 4.2 Name *(required)*
   - Enter the display name exactly as it should appear in the Intune app catalog and Company Portal.
   - For this worked example, enter: `FinBridge Connect`
   - Include the version in the name only if your catalog standard requires it (for example `FinBridge Connect 3.1`). Keep format consistent with existing catalog entries.

   ### 4.3 Description *(required)*
   - Enter a plain-language description of what the app does. This text appears to end users in Company Portal.
   - Markdown formatting is supported (the portal shows a live **Preview** pane below the description field — use it to verify formatting before proceeding).
   - For this worked example, enter: `FinBridge Connect v3.1 secure enterprise connectivity client.`
   - Keep descriptions factual and brief. Do not include internal ticket references or deployment notes here.

   ### 4.4 Remaining required fields (below Description)
   Scroll down on the **App information** tab to complete:

   - **Publisher:** `FinBridge`
   - **Version:** `3.1`

   Recommended good practice:

   - Keep name/version format consistent with existing catalog standards.
   - Add owner/support contact fields if your tenant requires them.

5. **Configure Program settings exactly.**  
   In **Program** (label may vary), set:

   - **Install command:** `FinBridgeConnect_Setup.exe /silent`
   - **Uninstall command:** `FinBridgeConnect_Setup.exe /uninstall /silent`
   - **Install behavior:** **System** (device context) for machine-wide deployment

   System vs User context guidance:

   - Choose **System** when app writes to `Program Files`, `HKLM`, services, or needs elevation.
   - Choose **User** only when app is profile-scoped and does not require admin/system context.

   > For FinBridge Connect with `HKLM` detection, **System** is the correct default.

6. **Set Requirements (device eligibility).**  
   In **Requirements** (label may vary), configure:

   - **Operating system architecture:** `64-bit` (or `32-bit and 64-bit` only if vendor supports both)
   - **Minimum operating system:** select your baseline floor (for example Windows 11 22H2 or later, per DWP baseline)

   Guidance:

   - Keep requirement scope narrow enough to avoid unsupported installs.
   - If labels differ (for example **Minimum OS** vs **Minimum operating system**), verify the field meaning before proceeding.

7. **Create Detection Rules so Intune can confirm install success.**  
   In **Detection rules** (label may vary), choose **Manually configure detection rules** and add a registry-based rule:

   - **Rule type:** Registry
   - **Key path:** `HKEY_LOCAL_MACHINE\SOFTWARE\FinBridge\Connect`
   - **Value name:** `Version`
   - **Detection method/operator:** `String comparison` / `Equals`
   - **Expected value:** `3.1`
   - **Associated with 32-bit app on 64-bit clients:** `No` (unless vendor confirms x86 redirection path)

   Other valid detection types in Intune (for reference):

   - **MSI product code** (best when installer is MSI-based and stable)
   - **File or folder path** (use when registry/product code is unavailable)

   > For this worked example, keep registry detection as specified.

8. **Review and confirm Return Codes.**  
   In **Return codes** (label may vary), ensure success/failure logic is correct. Common Windows installer mappings:

   - `0` = Success
   - `3010` = Success (soft reboot required)
   - `1641` = Success (hard reboot initiated)
   - Any unlisted non-zero code = Failure unless explicitly mapped

   Action:

   - Keep default return codes if they match vendor behavior.
   - Add custom codes only when vendor documentation explicitly defines them.

9. **Skip assignments to full production initially; assign to pilot only.**  
   In **Assignments** (label may vary), understand assignment intent:

   - **Required:** automatic install on targeted devices/users.
   - **Available for enrolled devices:** user can install from Company Portal (self-service).
   - **Uninstall:** removes app from targeted devices/users.

   Pilot strategy requirement:

   - Assign first to a small **test/pilot AAD group** (for example 10-50 representative devices/users).
   - Do **not** assign directly to the full 10,000-device fleet. This limits blast radius from bad detection logic, uninstall defects, reboot behavior, or app conflicts.

10. **Complete review and create.**  
    In the final review screen (often **Review + create**):

    - Validate app info, commands, requirements, detection rules, return codes, and assignment scope.
    - Confirm pilot group is targeted, not broad production groups.
    - Select **Create**.

11. **Verify app appears correctly in the Intune catalog.**  
    After creation, validate in:

    **Intune admin center > Apps > All apps** (or equivalent in your tenant)

    Confirm:

    - App name is listed as **FinBridge Connect**.
    - Version shows **3.1**.
    - Platform/type appears as **Windows app (Win32)**.
    - Assignment shows pilot group only.

12. **Verify install status on an assigned test device.**  
    Check deployment health in two places:

    - **App-centric view:**  
      Intune admin center > Apps > All apps > FinBridge Connect > Monitor > Device install status
    - **Device-centric view:**  
      Intune admin center > Devices > All devices > [test device] > Managed Apps

    Status meaning:

    - **Installed:** app installed and detection rule matched (`HKLM\SOFTWARE\FinBridge\Connect\Version = 3.1`).
    - **Failed:** install command returned failure or detection rule not satisfied after install attempt.
    - **Not applicable:** targeted device does not meet requirements (for example architecture/OS version mismatch) or assignment intent not relevant to that object.

13. **Troubleshoot first-wave pilot outcomes before phased rollout.**  
    Minimum checks before expanding scope:

    - Confirm at least one clean install on each representative device type (laptop, desktop, VPN-only, office LAN).
    - Confirm uninstall command works and app removal is detected correctly.
    - Confirm no systematic **Not applicable** caused by overly strict requirements.
    - Confirm no systematic **Failed** caused by bad silent switch, execution context mismatch, or detection rule path/value mismatch.

14. **Gate to phased rollout only after pilot criteria pass.**  
    Proceed to phased deployment rings only when:

    - Detection is stable.
    - Return code handling is understood.
    - Failure rate is within DWP tolerance.
    - Support desk has rollback and known-issues notes.

---

## Quick Reference: Common UI Labels That Vary by Tenant Version

Always verify these labels in your tenant:

- **All apps** may appear as **Applications** or under a different Apps sub-menu.
- **Windows app (Win32)** may be grouped differently in the app type picker.
- **Requirements**, **Detection rules**, and **Return codes** may appear as separate tabs, sections, or wizard steps.
- **Available for enrolled devices** may appear shortened as **Available** in some views.
- **Monitor > Device install status** may be surfaced under a similarly named monitoring blade.

If labels do not match exactly, follow the functional intent of each step rather than the literal label text.

---

## Completion Outcome

At the end of this guide, FinBridge Connect v3.1 is:

- Added to the Intune app catalog as a Win32 (`.intunewin`) app
- Configured with correct install/uninstall commands
- Detected by registry value `HKLM\SOFTWARE\FinBridge\Connect\Version = 3.1`
- Assigned safely to a pilot group for validation before any full-fleet rollout
