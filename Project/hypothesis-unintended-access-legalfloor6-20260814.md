# Hypothesis - Unintended Matter Access (Legal Floor 6)

Date: 2026-08-14
Prepared by: DWP Service Desk Analyst
Purpose: Security/Data-Governance escalation hypothesis list (not final root cause)

## Ranked top 3 likely reasons for unintended access (most probable first)

### 1) Inherited permission through one or more security groups (to confirm)

Why likely:
- Unexpected matter visibility most commonly comes from group-based inheritance.
- Current facts do not yet include the user's effective group-path mapping.

Single fastest check:
- Run an effective-access report for the user on the exact matter and identify the specific granting group path.

### 2) Recent ACL or inheritance change on the matter (or parent scope) added the user/account group (to confirm)

Why likely:
- A permission change at matter or parent level can create unintended access without direct user awareness.
- Current facts do not include matter permission change history.

Single fastest check:
- Review recent permission audit logs for the matter and parent container to identify newly added users/groups and inheritance changes.

### 3) Role-based or dynamic entitlement rule granted access based on identity attributes (to confirm)

Why likely:
- Legal environments frequently use role/profile or attribute-based access assignment.
- Current facts do not include policy evaluation output or entitlement rules.

Single fastest check:
- Trace effective entitlements from role and dynamic policy evaluation for this user and confirm whether any rule includes the matter.

## Escalation note
- This should be handled strictly as a permissions/access-scope investigation.
- Do not close as AI behavior, UI issue, or product malfunction without access-path verification.
