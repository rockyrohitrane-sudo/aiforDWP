# Copilot Support – End-User Communication Guide
**Date:** 2026-08-12

---

## Ticket 1: SharePoint Access Issue
**Scenario:** User sees "I don't have access to that content" when asking Copilot to summarize a SharePoint document

### Plain English Explanation
Copilot told you it can't access that file because **you don't have permission to see it yet**. Copilot can only read files that you're allowed to see—just like you wouldn't be able to open the file yourself in SharePoint if you didn't have access.

### What to Do Next
1. **Check your access:** Try opening the SharePoint folder directly in your web browser. Can you see it and open the file?
   - If **YES** → Wait 30 minutes for Copilot to catch up, then try again
   - If **NO** → Contact your IT team or folder owner and ask them to give you access to that folder
2. **Contact your IT team** if you need access to this folder for your work—they can add you in about 10 minutes

### What NOT to Do
- Don't assume Copilot is broken—this is the system working correctly
- Don't ask for special Copilot access—just get regular folder access like anyone else

---

## Ticket 2: Copilot Can't Find Emails in Outlook
**Scenario:** New employee can't find case emails when asking Copilot in Outlook

### Plain English Explanation
Your mailbox is new and **hasn't finished getting organized yet**. Think of it like moving into a new office—your files are there, but the filing system is still being set up. Outlook is building an index of all your emails so Copilot can find them quickly.

### What to Do Next
1. **Wait a few days** – New mailboxes can take 2-5 days to fully index
2. **Test native Outlook search first:**
   - Open Outlook and use the search box at the top
   - Search for a keyword from one of your case emails
   - If Outlook finds it, Copilot will too once indexing is complete
3. **Speed it up (optional):**
   - Open Outlook and click Settings > Search > Indexing to see progress
   - The search index will finish—you don't need to do anything
4. **Still missing emails after 5 days?** Contact IT support—there might be a sync issue

### What NOT to Do
- Don't move emails to different folders—this can slow indexing down
- Don't assume your emails are lost—they're there, Copilot just can't find them yet

---

## Ticket 3: You Can See Files You Shouldn't Be Able To
**Scenario:** User discovers they can access and Copilot summarized a document from a project they're not assigned to

### Plain English Explanation
This happened because of how **folder permissions are set up** in SharePoint. You've been given access to that folder (possibly through a team or department group you belong to), even though you're not directly assigned to that project. Copilot is correctly showing you what you *can* access—but this is worth reviewing.

### What to Do Next
1. **Don't panic** – You're not seeing something you shouldn't; your access is just broader than expected
2. **Report this to your manager or SharePoint admin** – Let them know what you found
   - Example: *"I discovered I have access to the Finance Project folder, but I'm not assigned to that project. Is this intentional?"*
3. **Your IT/SharePoint team will review and adjust** permissions if needed – this usually takes 1-2 days

### Why This Matters
- You might have inherited access from a team or department group
- This is a good security checkup – sharing might be too open
- No urgent action needed from you unless you're seeing something confidential you shouldn't

### What NOT to Do
- Don't delete or change any files in that folder
- Don't share this information with anyone outside your team

---

## Ticket 4: Your Entire Team Lost Copilot Access
**Scenario:** Large group (40+ people) suddenly lost access to Copilot

### Plain English Explanation
This is **almost certainly a business decision or admin action**, not a product problem. Something changed in how your company manages Copilot access—either:
- Copilot licenses were paused, changed, or expired
- Your team's access rights were updated by IT
- A security policy was applied to your team

### What to Do Next
1. **Don't try workarounds** – This is a company-level change that needs an admin to fix
2. **Alert your manager** – Let them know Copilot is down for your team
3. **Your manager or IT will contact Microsoft** – They'll restore access (usually takes a few hours to a day)
4. **In the meantime:**
   - Use Copilot outside Teams/Outlook if you have personal access
   - Use traditional search and manual research for urgent tasks

### Timeline
- **Today:** IT confirms what happened
- **Within 24 hours:** Access is restored
- **Notify everyone once restored** – Send a quick team note

### What NOT to Do
- Don't try to grant yourself access or use workarounds
- Don't contact Microsoft support directly – your IT team handles this

---

## Ticket 5: Copilot Gives Vague Answers About Contract Templates
**Scenario:** Asking Copilot about your contract template library returns generic, unhelpful answers instead of specific details

### Plain English Explanation
Copilot might not be able to **properly read your contract templates**. This could happen because:
- The templates are too specialized or structured for Copilot to easily understand
- Your documents haven't been indexed yet (so Copilot can't find them)
- Security labels on the documents are blocking Copilot from accessing details
- There's a technical issue preventing Copilot from grounding on contract files

### What to Do Next
1. **Test with a simpler document first:**
   - Ask Copilot to summarize a different document in your library (one that's not a template)
   - Does it give better answers? If yes, templates might be the issue

2. **Verify Copilot can find your templates:**
   - Open Teams or SharePoint
   - Search for a contract template using the normal search box
   - If you can find it, Copilot should be able to eventually
   - If you can't find it, your templates might not be indexed yet

3. **Check security labels:**
   - Open a contract template file
   - Look at the file details for "Sensitivity" or "Label"
   - If it has a very restrictive label, that might be limiting Copilot

4. **Contact your IT team or contract manager if:**
   - Copilot still won't access templates after 24 hours
   - You keep getting generic answers even on simple templates
   - Templates have security labels and you need Copilot to access them

### Expected Timeline
- **Today:** Test with other documents
- **24-48 hours:** Templates should be indexed and working better
- **If still broken:** IT investigates the root cause

### What NOT to Do
- Don't remove security labels yourself – contact your admin
- Don't assume Copilot is completely broken – the templates might just need indexing time

---

## Quick Reference: What to Tell Users

| Ticket | Simple Answer | First Step |
|--------|---------------|-----------|
| 1. NDA access denied | You need folder access | Try opening the folder yourself in SharePoint |
| 2. Can't find emails | Your mailbox is still being indexed | Wait a few days and test Outlook's search box |
| 3. Unexpected access | You have broader permissions than expected | Report to your manager/SharePoint admin |
| 4. Team lost Copilot | Company changed access settings | Wait for IT to restore (within 24 hours) |
| 5. Vague contract answers | Copilot can't fully read templates yet | Test with other documents; wait for indexing |

