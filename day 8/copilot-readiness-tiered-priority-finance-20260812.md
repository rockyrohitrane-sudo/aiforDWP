# M365 Copilot Readiness — Tiered Priority Guide
**Department:** Finance (~200 users)
**Date:** 2026-08-12
**Companion to:** copilot-readiness-checklist-finance-m365-20260812.md

---

## Tier 1 — MUST Complete Before Rollout (Blocking)

These items must be fully complete and signed off before a single Copilot licence is assigned. Proceeding without them creates either a hard technical failure or an irreversible data exposure risk.

| Item | Why it is blocking |
|---|---|
| **S3a — Permissions audit on inherited SharePoint sites** | Copilot queries everything the user can access. Unaudited 2019 permissions mean unknown access scope — licences assigned before this is done expose payroll, M&A, and board data to the wrong people immediately. |
| **S3b — Oversharing remediation on high-risk libraries** | Must precede licence assignment — there is no safe way to roll back a Copilot response that has already surfaced a board pack to the wrong user. |
| **S3c — OneDrive external sharing and anyone-link revocation** | Any active "anyone" links become Copilot-accessible content pathways. Must be closed before go-live. |
| **S3d — Permissions sign-off gate (InfoSec + Data Governance)** | Dual sign-off confirms the audit was completed to the required standard, not just started. |
| **S4 — MFA enforced for all Finance users** | Copilot access without MFA creates an authentication risk at the front door. A compromised account with Copilot access has significantly broader reach than without it. |
| **S4 — No Finance users excluded from Conditional Access MFA policies** | Exclusions are frequently forgotten and represent the highest-risk accounts. Must be verified explicitly. |
| **S1 — Copilot licences procured and staged (not yet assigned)** | Licences must be ready to assign but held back until all MUST items are complete. |
| **S2 — All Finance devices on a supported Microsoft 365 Apps build** | Copilot will not function on unsupported builds. Devices below minimum version must be updated first or excluded from the rollout cohort. |

---

## Tier 2 — SHOULD Complete Before Rollout (High Risk if Skipped)

These items do not cause an immediate hard failure, but skipping them creates meaningful risk that is difficult to manage retrospectively once Copilot is live and in use.

| Item | Why skipping is high risk |
|---|---|
| **S5 — Sensitivity labels published and actively used** | Without labels, Copilot has no classification context. It cannot warn users when it surfaces or repurposes sensitive content. Auto-labelling for known sensitive data types (payroll, NI numbers) should be active before go-live. |
| **S5 — Highly Confidential label applies encryption, not just visual markings** | A label that only adds a header provides no access control. Encryption must be enforced at this tier before Copilot can be trusted to handle it appropriately. |
| **S4 — PIM active for Finance users with elevated admin roles** | Copilot inherits the permissions of the signed-in user. An admin-level user with Copilot access has a very large effective access surface. |
| **S6 — Pre-launch communication sent to Finance staff** | Users who do not understand what Copilot can access will use it inappropriately. The first week of usage sets behaviour patterns that are hard to change later. |
| **S6 — Mandatory awareness session completed before go-live** | M&A and board communications drafted via Copilot without guidance is a plausible first-week risk in a Finance department. |
| **S1 — Confirm no service accounts or shared mailboxes are in licence scope** | Shared mailboxes with Copilot enabled create ungoverned access that no individual is accountable for. |

---

## Tier 3 — CAN Complete During or After Rollout (Lower Risk)

These items improve the experience and governance posture but do not create an immediate or irreversible risk if they lag slightly behind go-live.

| Item | Notes |
|---|---|
| **S6 — Finance Copilot champions identified and briefed** | Useful for adoption but not a safety gate. Can be in place by end of week 1. |
| **S6 — Feedback channel set up** | Should be ready at go-live but absence does not block it. Can be created the same day. |
| **S6 — 2-week post-go-live review scheduled** | Forward planning. Schedule before go-live, conduct after. |
| **S5 — Spot-check: 10 random documents for labelling compliance** | A useful quality check but does not need to block go-live if auto-labelling policies are already active. |
| **S2 — Automatic update policy confirmed active in Intune** | Devices are already on a supported build (Tier 1). The ongoing update policy is hygiene, not a day-one blocker. |

---

## Why Permissions and Oversharing is MUST Tier — Not Just Another Checklist Item

Licensing and client version checks are also in the MUST tier, but they are **technical prerequisites** — if they are missing, Copilot simply will not work. They are easy to verify, straightforward to fix, and the consequence of getting them wrong is that the feature does not launch. That is a nuisance, not a risk.

Permissions and oversharing is different in three ways:

**1. The harm is silent and immediate.**
Copilot does not warn a user when it draws on content they technically have access to but should not. On the day licences are assigned, Finance users will begin asking Copilot questions — summarise this, find me the latest figures, what did we agree in that meeting. If a payroll analyst has inherited access to the CEO's board pack from a 2019 migration, Copilot will include board pack content in its answer. The user may not even realise where the information came from.

**2. There is no rollback.**
A file that was not accessed can be audited and protected. Information that has already been surfaced in a Copilot response and read by the wrong person cannot be un-read. Data governance and regulatory obligations (GDPR, FCA conduct rules) do not stop applying because the exposure was caused by an AI tool rather than a deliberate sharing action.

**3. The 2019 inheritance is a known, unquantified risk specific to this department.**
In a clean environment, a permissions check would still be MUST tier but would take an hour. In this environment, SharePoint permissions have been accumulating for seven years without audit, across sites holding payroll records, M&A documents, and client financial data. The scope of potential oversharing is unknown — which means it must be treated as significant until proven otherwise. Assigning Copilot licences before this audit completes is equivalent to opening a door before checking what is behind it.

Licensing and version checks confirm Copilot *can* work. The permissions audit confirms it is *safe* to work. Both are MUST tier, but for entirely different reasons.

---

*Prepared by DWP Engineer | 2026-08-12*
*Companion document to: copilot-readiness-checklist-finance-m365-20260812.md*
