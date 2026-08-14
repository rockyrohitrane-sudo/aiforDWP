# Floor 6 Missing Shortcuts — Technical Action & User Message
Date: 2026-08-14

---

## Technical Action

**Assuming hypothesis confirmed: Friday document management app deployment's post-install script removed or altered desktop shortcuts across user profiles on affected devices.**

### Step 1: Identify and Disable the Offending Post-Install Script (Intune)
1. Navigate to **Intune admin center** → **Apps** → **All apps** → select the document management app
2. Under **Properties**, review the deployment package source and post-install script behavior
3. If the script is embedded in the app package:
   - Contact the app vendor for a corrected package that does not remove shortcuts, OR
   - Stage a corrected deployment version if available internally
4. If the script is deployed via a separate configuration or startup task assignment:
   - Go to **Devices** → **Configuration profiles** → locate the Floor 6 post-deployment script/task profile
   - Edit the profile to remove or disable the shortcut-removal step
   - Reassign to Floor 6 and confirm deployment

### Step 2: Restore Shortcuts via Remediation Script (Intune Remediation)
**Deploy a corrective PowerShell remediation script to affected Floor 6 devices:**

1. In **Intune admin center**, go to **Devices** → **Remediation scripts** → **Create script**
2. Create a detection script (detects missing shortcuts):
   ```powershell
   $deskPath = [System.Environment]::GetFolderPath('Desktop')
   $shortcuts = Get-ChildItem -Path $deskPath -Filter "*.lnk" -ErrorAction SilentlyContinue
   if ($shortcuts.Count -lt 3) { exit 1 } else { exit 0 }
   ```
   *(Adjust threshold based on expected baseline count)*

3. Create a remediation script (restores known shortcuts):
   ```powershell
   $deskPath = [System.Environment]::GetFolderPath('Desktop')
   $appPath = "C:\Program Files\<DocumentManagementApp>"
   if (Test-Path $appPath) {
       $shortcutPath = "$deskPath\<AppName>.lnk"
       if (-not (Test-Path $shortcutPath)) {
           $shell = New-Object -ComObject WScript.Shell
           $link = $shell.CreateShortcut($shortcutPath)
           $link.TargetPath = "$appPath\<executable.exe>"
           $link.WorkingDirectory = $appPath
           $link.Save()
       }
   }
   ```

4. Assign to the Floor 6 device group and deploy
5. Monitor execution from **Devices** → **Remediation scripts** → **Status** (to confirm success or failures)

### Step 3: Alternative — Rollback and Revert to Pre-Deployment Shortcuts
If the corrected script will take time to build, consider temporary rollback:
1. Remove or suspend the document management app assignment for Floor 6 (as outlined in the login/performance mitigation)
2. Deploy a system restore or group policy shortcut-restoration profile to Floor 6 that restores baseline desktop shortcuts while the app team corrects the post-install script

### Permissions Required
**Yes** — Intune global admin, Application Administrator, or Device Administrator role to modify app properties, create remediation scripts, and manage device assignments.

### Estimated User Impact Recovery
- 30–90 minutes post-remediation deployment (script execution + device check-in + user logon to see restored shortcuts)
- To confirm: users can manually trigger sync via **Settings** > **Accounts** > **Access work or school** > **Sync**

---

## Floor 6 User Message

**Subject: Floor 6 Desktop Shortcuts — Restoration in Progress**

We noticed that some of you are missing desktop shortcuts this morning. This happened because of how Friday's new software was installed, and we're fixing it right now.

**What we're doing:** We're deploying an automatic fix to restore your shortcuts. You don't need to do anything—it will happen on its own.

**What to do:**
- If you see shortcuts reappear, you're all set.
- If they're still missing in 1 hour, restart your device or contact the Service Desk.
- Your applications still work fine; only the shortcuts are affected.

We'll confirm when everyone is restored. Thank you for your patience.

---

**Status:** Working hypothesis — to confirm with post-install script review and device-side shortcut detection.
**Next step:** Compare Intune deployment logs for affected vs. unaffected devices; review app package post-install script content.
