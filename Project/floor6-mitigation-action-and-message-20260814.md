# Floor 6 Mitigation — Technical Action & User Message
Date: 2026-08-14

---

## Technical Action

**Assuming hypothesis confirmed: Friday document management app deployment is causing resource contention during login.**

### Mitigation — Intune (Primary)
1. Navigate to **Intune admin center** → **Apps** → **All apps** → select the deployed document management app
2. Under **Assignments**, locate the Floor 6 targeted assignment (likely scoped to a device or user group for Legal Floor 6)
3. Change the assignment intent from **"Required"** to **"Uninstall"** and click **Save** (to actively remove the app from enrolled devices)
   - *Alternatively*: Remove the Floor 6 device/user group entirely from this assignment
4. Affected devices will uninstall the app on next check-in (typically within 1 hour; can force via Company Portal or Settings > Accounts > Access work or school > Sync)

### Mitigation — SCCM (if hybrid)
1. Open **Configuration Manager Console** → **Software Library** → **Application Management** → **Applications**
2. Locate the document management app deployment targeting Floor 6
3. Modify the collection to exclude Floor 6 devices, or create a new deployment set to "Uninstall" for that collection
4. Deploy and monitor uninstall status from **Monitoring** → **Deployments**

### Permissions Required
**Yes** — Intune global admin or Application Administrator role; SCCM Full Administrator or Application Manager permissions.

### Estimated User Impact Recovery
15–45 minutes post-deployment push (app removal + next user logon).

---

## Floor 6 User Message

**Subject: Floor 6 Access Update – Logon Performance Issue**

We're aware that some of you have experienced slow or failed logins this morning. Our engineering team has identified a recent software update as the likely cause and is taking action now to resolve this.

**What we're doing:** We're removing the deployment that started Friday to restore normal login speed and reliability for everyone on Floor 6.

**What to do:**
- If you're currently logged in, you're not affected; no action needed.
- If you're having trouble logging in, try again in the next 30–45 minutes.
- If issues persist after that, contact the Service Desk with your device name and timestamp of the login attempt.

We'll send a follow-up once we've confirmed everything is back to normal. Thank you for your patience.

---

**Status:** Working hypothesis — to confirm with deployment assignment state and rollback test.
**Next step:** Compare Floor 6 affected vs. unaffected device deployment states; execute controlled rollback on pilot subset.
