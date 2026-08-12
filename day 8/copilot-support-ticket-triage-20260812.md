# Copilot Support Ticket Triage Analysis
**Date:** 2026-08-12  
**Analyst:** DWP Engineering

---

## Ticket 1: Paralegal – SharePoint NDA Access Denied
**Issue:** Copilot returns "I don't have access to that content" for an NDA in SharePoint folder never opened before

### Likely Causes (ranked)
1. **Permissions/access boundary** – User has not been explicitly granted access to this folder
2. **Data indexing lag** – If access was just granted, indexing may not be complete

### Fastest Check
Verify that the paralegal actually has SharePoint permissions assigned to that folder in the folder's access control list (not just heard about it in conversation)

### Is This a Copilot Bug?
**No.** Copilot's error message is accurate—it's reflecting the actual permission boundary. This is correct behavior.

---

## Ticket 2: New Associate – Outlook Email Search Failing
**Issue:** New associate (started this week) cannot find case emails needed for context via Copilot in Outlook

### Likely Causes (ranked)
1. **Data indexing lag** – New mailbox has not completed initial indexing; Outlook search index may still be building
2. **Permissions/access boundary** – If emails are in shared folders or delegated mailboxes, access may not be configured
3. **License/client prerequisite issue** – New associate may not have complete client configuration or Copilot license provisioning

### Fastest Check
Confirm emails actually appear in Outlook's native search first, and check if the mailbox's Outlook search index status is complete (Settings > Search > Indexing)

### Is This a Copilot Bug?
**No.** This is almost certainly a data availability issue stemming from a new account not yet fully indexed by Outlook's search service.

---

## Ticket 3: Partner – Unauthorized Matter Access
**Issue:** Partner surfaced and summarized a draft settlement from a matter they're not assigned to; discovers they can access folder they didn't know they could see

### Likely Causes (ranked)
1. **Permissions/access boundary** – SharePoint folder permissions are overly permissive (e.g., inherited from parent folder, broad group access)
2. Data indexing is working correctly; Copilot is accurately showing content the user *does* have access to

### Fastest Check
Review the SharePoint folder's permission inheritance and explicit assignments—check if the partner is a member of a group with access or if permissions are inherited from a parent folder

### Is This a Copilot Bug?
**No.** Copilot is functioning correctly by surfacing content the user legitimately has access to. This is a SharePoint permission configuration issue, not a Copilot fault. **Escalate to SharePoint/governance team for access review.**

---

## Ticket 4: Legal Ops Manager – Team-Wide Access Loss
**Issue:** All 40 people on the Legal team suddenly lost Copilot access this morning; worked fine last week

### Likely Causes (ranked)
1. **License/client prerequisite issue** – Copilot licenses for the Legal team expired, were revoked, or provisioning was suspended
2. **Permissions/access boundary** – Tenant-wide or team-wide permission/security policy changed (e.g., group membership revoked, conditional access policy applied)
3. **Genuine Copilot fault** – Service-level outage affecting the tenant (least likely but possible)

### Fastest Check
Check Microsoft 365 admin center for license status and assign state for the Legal team; also verify Copilot service health status and any recent group membership or conditional access policy changes

### Is This a Copilot Bug?
**No.** A simultaneous loss of access across 40 users points to a systemic administrative change, not a product fault. This is almost certainly a licensing or provisioning event.

---

## Ticket 5: Contract Specialist – Generic/Vague Answers
**Issue:** Copilot gives vague, generic answers when asked about contract template clauses; "doesn't seem to actually read the documents"

### Likely Causes (ranked)
1. **Data indexing lag** – Contract templates may not be crawled or indexed properly in Copilot's search/grounding index
2. **Sensitivity label restriction** – Documents may have restrictive sensitivity labels that limit Copilot's ability to extract or summarize content
3. **Permissions/access boundary** – User may have read-only or limited access that restricts what Copilot can retrieve
4. **Genuine Copilot fault** – Possible limitation in how Copilot handles structured contract text or templates

### Fastest Check
Verify the contract templates folder is in Copilot's searchable/indexable scope (SharePoint, OneDrive, Teams) and confirm the documents are not blocked by sensitivity labels; also test with a different document to isolate whether this affects all templates or specific ones

### Is This a Copilot Bug?
**Unclear/Possible.** This could be an indexing issue, a data availability problem, or a genuine limitation in how Copilot grounds on contract templates. **Requires investigation:** 
- Test direct search in Teams/SharePoint to confirm docs are findable
- Check sensitivity labels on templates
- Test with a simpler, non-template document to determine if this is template-specific behavior

---

## Summary Triage Results

| Ticket | Root Cause Category | Copilot Bug? | Escalation Path |
|--------|-------------------|--------------|-----------------|
| 1. Paralegal NDA | Permissions/access boundary | No | IT/SharePoint – grant folder access |
| 2. New associate emails | Data indexing lag | No | Wait for mailbox indexing; verify native Outlook search |
| 3. Partner unauthorized access | Permissions/access boundary | No | SharePoint governance – audit & correct folder permissions |
| 4. Legal team bulk loss | License/provisioning | No | Microsoft 365 admin – verify licenses & provisioning |
| 5. Contract specialist vague answers | Data indexing lag / sensitivity labels (Unclear) | Unclear | Investigation required – test search indexing & labels |

