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

   ### 4.4 Description preview (visible validation)
   - After entering **Description**, confirm the **Preview** pane renders as expected.
   - If markdown is used, verify line breaks, bullets, and headings before selecting **Next**.
   - If preview is blank or malformed, simplify formatting and re-check.

   ### 4.5 Remaining fields below Description
   Scroll down on the **App information** tab and complete these fields:

   - **Publisher** *(required)*: `FinBridge`
   - **App version**: `3.1` (or tenant standard four-part format such as `3.1.0.0`)
   - **Category**: choose a category only if your catalog taxonomy requires it; otherwise leave unselected.
   - **Show this as a featured app in Company Portal**: set to `No` by default unless service owner requests it.

   Recommended good practice:

   - Keep name and version format consistent with existing catalog standards.
   - Treat **Publisher** as mandatory quality data even when app upload technically allows draft save.
   - Add owner/support contact fields if your tenant requires them.

   Example values matching the screenshot pattern (for reference only):

   - **Name**: `7-Zip 24.08 (x64 edition)`
   - **Description**: `7-Zip 24.08 (x64 edition)`
   - **Publisher**: set vendor value (for example `Igor Pavlov` for 7-Zip)
   - **App version**: `24.08.00.0`
   - **Category**: none selected
   - **Featured app toggle**: `No`

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

   ### 6.1 Check operating system architecture *(required toggle)*
   This screen presents two radio options:

   - **Yes. Specify the systems the app can be installed on.**
   - **No. Allow this app to be installed on all systems.**

   Guidance:

   - Use **Yes** when you must restrict architecture (for example x64-only app).
   - Use **No** only when vendor supports all target architectures in your estate.
   - For most enterprise Win32 apps like FinBridge Connect, choose **Yes** and restrict to supported architecture.

   ### 6.2 Minimum operating system *(required)*
   - Select your baseline OS floor from the dropdown (for example Windows 11 22H2 or later, per DWP baseline).
   - Do not leave this unset; this field is required.

   ### 6.3 Optional hardware requirement fields (shown below Minimum OS)
   These fields are visible in the Requirements step and should be populated only when vendor guidance requires them:

   - **Disk space required (MB)**
   - **Physical memory required (MB)**
   - **Minimum number of logical processors**

   If vendor documentation does not define minimums, leave these optional fields blank to avoid unnecessary **Not applicable** outcomes.

   Guidance:

   - Keep requirement scope narrow enough to avoid unsupported installs.
   - Avoid over-constraining optional hardware values unless there is a validated business need.
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

8. **Configure Dependencies (if required).**  
   In **Dependencies** (label may vary), define apps that must be installed before this app can install.

   What this page does:

   - Lets you add one or more child dependency apps.
   - Lets you control whether each dependency should be automatically installed.
   - Shows dependency rows under columns such as **Name** and **Automatically install**.

   Guidance aligned to the screenshot behavior:

   - If no prerequisites are needed, it is valid to leave this page empty (**No results**) and continue.
   - If prerequisites are required, add each dependency and set **Automatically install** according to deployment intent.
   - Keep dependency chains minimal to reduce failure blast radius.
   - Review dependency graph size limits in tenant guidance before creating large chains.

9. **Configure Supersedence (if required).**  
   In **Supersedence** (label may vary), define whether this app version updates or replaces earlier app versions.

   What this page does:

   - Lets you select apps that this app will supersede.
   - Lets you choose update/replace behavior and whether to uninstall the previous version.
   - Shows superseded app rows with columns such as **Name**, **Publisher**, **Version**, **Type**, and **Uninstall previous version**.

   Guidance aligned to the screenshot behavior:

   - If this is the first cataloged version, it is valid to leave this page empty (**No results**) and continue.
   - Use supersedence when you are moving from an older app package to a newer package and need controlled upgrade/replace behavior.
   - Enable **Uninstall previous version** only when vendor guidance requires remove-then-install or major-version replacement.
   - Keep supersedence chains short and review graph-size limits before adding multiple relationships.

10. **Review and confirm Return Codes.**  
   In **Return codes** (label may vary), ensure success/failure logic is correct. Common Windows installer mappings:

   - `0` = Success
   - `3010` = Success (soft reboot required)
   - `1641` = Success (hard reboot initiated)
   - Any unlisted non-zero code = Failure unless explicitly mapped

   Action:

   - Keep default return codes if they match vendor behavior.
   - Add custom codes only when vendor documentation explicitly defines them.

11. **Skip assignments to full production initially; assign to pilot only.**  
   In **Assignments** (label may vary), understand assignment intent:

   ### 11.1 Read the banner warning on this page (important)
   The Assignments page displays an information banner for Win32 apps:

   - Win32 apps deployed by Intune are not automatically removed when a device is retired.
   - App binaries/data can remain on the device after retire.
   - End-user or admin action is required if app removal is needed on the endpoint.

   Operational implication:

   - Do not assume device retire equals app uninstall for Win32 workloads.
   - If your security/process policy requires removal on retire, document a separate cleanup control.

   ### 11.2 Configure **Required** assignment first
   In the **Required** section:

   - Select **Add group** and choose the pilot Azure AD group.
   - Prefer device-targeted pilot groups for machine-wide System-context installs.
   - Keep pilot size controlled (for example 10-50 endpoints) and representative.

   ### 11.3 Optional assignment intents (only if needed)
   Use additional intent sections only when there is a clear rollout reason:

   - **Required:** automatic install on targeted devices/users.
   - **Available for enrolled devices:** user can install from Company Portal (self-service).
   - **Uninstall:** removes app from targeted devices/users.

   Keep intent boundaries clean:

   - Avoid assigning the same object to conflicting intents.
   - If excludes are used, document the business reason in change notes.

   Pilot strategy requirement:

   - Assign first to a small **test/pilot AAD group** (for example 10-50 representative devices/users).
   - Do **not** assign directly to the full 10,000-device fleet. This limits blast radius from bad detection logic, uninstall defects, reboot behavior, or app conflicts.
   - Validate pilot success criteria before adding next-ring groups.

12. **Complete review and create.**  
    In the final review screen (often **Review + create**):

    - Validate app info, commands, requirements, detection rules, return codes, and assignment scope.
    - Confirm pilot group is targeted, not broad production groups.
    - Select **Create**.

13. **Verify app appears correctly in the Intune catalog.**  
    After creation, validate in:

    **Intune admin center > Apps > All apps** (or equivalent in your tenant)

    Confirm:

    - App name is listed as **FinBridge Connect**.
    - Version shows **3.1**.
    - Platform/type appears as **Windows app (Win32)**.
    - Assignment shows pilot group only.

14. **Verify install status on an assigned test device.**  
    Check deployment health in two places:

    - **App-centric view:**  
      Intune admin center > Apps > All apps > FinBridge Connect > Monitor > Device install status
    - **Device-centric view:**  
      Intune admin center > Devices > All devices > [test device] > Managed Apps

    Status meaning:

    - **Installed:** app installed and detection rule matched (`HKLM\SOFTWARE\FinBridge\Connect\Version = 3.1`).
    - **Failed:** install command returned failure or detection rule not satisfied after install attempt.
    - **Not applicable:** targeted device does not meet requirements (for example architecture/OS version mismatch) or assignment intent not relevant to that object.

15. **Troubleshoot first-wave pilot outcomes before phased rollout.**  
    Minimum checks before expanding scope:

    - Confirm at least one clean install on each representative device type (laptop, desktop, VPN-only, office LAN).
    - Confirm uninstall command works and app removal is detected correctly.
    - Confirm no systematic **Not applicable** caused by overly strict requirements.
    - Confirm no systematic **Failed** caused by bad silent switch, execution context mismatch, or detection rule path/value mismatch.

16. **Gate to phased rollout only after pilot criteria pass.**  
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
