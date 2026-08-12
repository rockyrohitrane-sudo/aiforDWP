# Microsoft 365 Copilot Readiness Checklist — Finance Department
**Organisation:** FinBridge (Financial Services)
**Department:** Finance (~200 users)
**Licensing baseline:** Microsoft 365 E5
**Prepared by:** DWP Engineer
**Date:** 2026-08-12

---

> **Risk note before you begin:**
> SharePoint permissions in this department were inherited from a 2019 migration and have never been audited. The data in scope includes payroll records, board packs, M&A documents, and client financial data. Copilot reasons over everything the user can access — if permissions are too broad, Copilot will surface content the user should not see, and will do so silently and at scale. **Complete Section 3 (Permissions and Oversharing) before assigning any Copilot licences.** Do not treat it as a parallel workstream.

---

## Section 1 — Licensing Prerequisites

- [ ] Confirm all ~200 Finance users hold a Microsoft 365 E5 licence (or E3 + M365 Copilot add-on eligibility confirmed with Microsoft)
- [ ] Confirm Microsoft 365 Copilot add-on licences have been procured for the Finance rollout cohort
- [ ] Assign Copilot licences in the Microsoft 365 admin centre — do not assign until Sections 2, 3, and 4 are complete
- [ ] Confirm no users are on legacy Office 365 E1/E3 plans that exclude Copilot eligibility
- [ ] Verify licence assignment is scoped to Finance only — not applied tenant-wide by accident

---

## Section 2 — Microsoft 365 Apps Client Version

- [ ] Confirm all Finance devices are running Microsoft 365 Apps for Enterprise (not Office 2019/2021 perpetual)
- [ ] Confirm build is on **Current Channel** or **Monthly Enterprise Channel** — Semi-Annual Channel is not supported for Copilot
- [ ] Verify minimum build version: **Version 2302 (Build 16130.20306)** or later on all devices
- [ ] Check for any devices still on Office 2019 perpetual — these must be migrated before Copilot is assigned
- [ ] Confirm automatic update policy is active for Finance devices in Intune or SCCM
- [ ] Run a quick inventory: pull the Office build version report from Intune — flag any device below the minimum build

---

## Section 3 — SharePoint and OneDrive Permissions and Oversharing ⚠️ HIGHEST PRIORITY

> This section must be completed and signed off before licences are assigned. The 2019 migration left permissions in an unknown state. Copilot will use whatever access the user has — broad permissions mean broad Copilot responses, including surfacing payroll data, M&A documents, and board packs to users who should not see them.

### 3a — Audit inherited permissions from 2019 migration

- [ ] Run the **SharePoint Permission Report** (via SharePoint Admin Centre → Reports, or via Microsoft 365 Assessment Tool) across all Finance-owned SharePoint sites
- [ ] Identify all sites, libraries, and folders where **"Everyone"**, **"Everyone except external users"**, or **"All Company"** has been granted access — these are oversharing red flags
- [ ] Identify all broken permission inheritance (unique permissions set at item or folder level) — document and rationalise
- [ ] List all SharePoint groups and confirm membership is current — remove leavers, contractors, and anyone whose role has changed since 2019
- [ ] Confirm no Finance sites have **anonymous sharing links** active
- [ ] Flag all sites containing payroll, board packs, M&A documents, or client financial data — these require explicit access control review before proceeding

### 3b — Oversharing checks on high-risk libraries

- [ ] For each high-risk library identified above: confirm access is restricted to named individuals or a defined security group — not a broad department or everyone group
- [ ] Check for **sharing links** (organisation-wide or anyone links) on files within high-risk libraries — revoke all that are not actively required
- [ ] Confirm payroll-related content is held in a dedicated site/library with access limited to Payroll team members and approved Finance leads only
- [ ] Confirm M&A and board pack content is in a dedicated site with access restricted to named individuals under a non-disclosure requirement
- [ ] Confirm client financial data is scoped per client or per engagement — not open to all Finance users
- [ ] Run **Microsoft Purview Content Explorer** to identify where sensitive information types (e.g., UK bank account numbers, National Insurance numbers, financial data) are stored and whether access aligns with expectations

### 3c — OneDrive

- [ ] Confirm Finance users are not storing shared/team content in personal OneDrive folders that others have been granted broad access to
- [ ] Check for OneDrive folders shared with "Anyone with the link" — revoke all instances in the Finance cohort
- [ ] Confirm OneDrive external sharing is disabled or restricted to approved domains only for this cohort

### 3d — Sign-off gate

- [ ] A named owner (Information Security or Data Governance lead) has reviewed and signed off the permissions audit findings
- [ ] All critical oversharing findings are remediated or have an accepted risk with a documented owner before Copilot licences are assigned

---

## Section 4 — Identity and MFA Readiness

- [ ] Confirm all 200 Finance users are **Azure AD (Entra ID) accounts** — no on-premises-only accounts in scope
- [ ] Confirm **Multi-Factor Authentication (MFA)** is enforced for all Finance users — check via Entra ID → Users → Per-user MFA or Conditional Access policies
- [ ] Confirm no Finance users are excluded from MFA Conditional Access policies (check exclusion groups)
- [ ] Confirm **passwordless or phishing-resistant MFA** (Authenticator app, FIDO2) is in place — SMS-based MFA is not sufficient for a high-sensitivity Finance cohort
- [ ] Verify no Finance service accounts or shared mailboxes are in the Copilot licence assignment scope
- [ ] Confirm **Privileged Identity Management (PIM)** is active for any Finance users with elevated SharePoint or Exchange admin roles — Copilot inheriting admin-level access is a significant risk

---

## Section 5 — Sensitivity Labelling

- [ ] Confirm Microsoft Purview sensitivity labels are deployed and published to the Finance users group
- [ ] Confirm at minimum the following labels exist and are in active use: **Confidential**, **Highly Confidential**, **Internal Only**
- [ ] Confirm labels apply **encryption and access control** at Highly Confidential level — not just visual markings
- [ ] Run a sample check: open 10 Finance SharePoint documents at random — are they labelled? If fewer than 7 of 10 are labelled, mandatory labelling policy must be applied before Copilot goes live
- [ ] Confirm **auto-labelling policies** are configured for known sensitive information types (payroll data, financial figures, NI numbers) in SharePoint and OneDrive
- [ ] Confirm Copilot responses will **inherit sensitivity context** — test by asking Copilot to summarise a Highly Confidential document and confirm the output carries the correct label warning
- [ ] Confirm users cannot use Copilot to copy content from a Highly Confidential document into an unlabelled or lower-classification destination without a policy warning

---

## Section 6 — End-User Communications and Enablement

- [ ] Draft and send a **pre-launch communication** to Finance staff explaining what Copilot is, what it can access, and — critically — that it can see everything they have permission to see (set expectations clearly)
- [ ] Run a **mandatory 30-minute awareness session** for Finance users before go-live: cover what Copilot does well, what it does not do, and how to handle AI-generated output involving sensitive data
- [ ] Publish a **Finance-specific acceptable use guidance note** covering: do not share Copilot outputs externally without review, do not use Copilot to draft M&A or board communications without senior sign-off
- [ ] Identify and brief **2–3 Finance Copilot champions** who can support colleagues and escalate concerns in the first weeks
- [ ] Set up a **feedback channel** (Teams channel or shared mailbox) for Finance staff to report unexpected Copilot behaviour — particularly any instance where Copilot surfaces content the user believes they should not have access to
- [ ] Schedule a **2-week post-go-live review** to assess usage, gather feedback, and check for any oversharing issues surfaced through Copilot activity

---

## Go-Live Gate Summary

| Section | Status | Sign-off required |
|---|---|---|
| 1 — Licensing | ☐ Complete | IT Lead |
| 2 — Client version | ☐ Complete | IT Lead |
| 3 — Permissions and oversharing ⚠️ | ☐ Complete | Information Security + Data Governance |
| 4 — Identity and MFA | ☐ Complete | IT Security Lead |
| 5 — Sensitivity labelling | ☐ Complete | Information Security |
| 6 — Comms and enablement | ☐ Complete | Finance Business Lead |

> **Do not assign Copilot licences until all six sections show Complete and Section 3 has dual sign-off from Information Security and Data Governance.**

---

*Checklist prepared by DWP Engineer | 2026-08-12*
*Review and update before each Copilot rollout phase*
