# Copilot Support Ticket Cause Triage (DWP Training)

Date: 2026-08-12
Scope: Ranked likely cause, fastest first check, and Copilot bug assessment

Allowed cause list used:
- permissions/access boundary
- data indexing lag
- sensitivity label restriction
- license/client prerequisite issue
- guest/external sharing limitation
- genuine Copilot fault (kept last unless strongly evidenced)

## Ticket 1
id: 1  
Ticket: Finance lead: Copilot won’t summarise the Q3 board pack in SharePoint. “It’s right there, I can see it myself.”

Likely cause (ranked):
1. permissions/access boundary
2. data indexing lag
3. sensitivity label restriction
4. license/client prerequisite issue
5. guest/external sharing limitation
6. genuine Copilot fault

Fastest check:
- Confirm the board pack’s exact permissions path and whether the user has direct access versus inherited/view-only/share-link context that Copilot cannot ground against.

Is this actually a Copilot bug?
- Unclear. User visibility alone does not prove Copilot grounding eligibility; access boundaries and indexing are more common than product faults.

## Ticket 2
id: 2  
Ticket: New hire (started yesterday): Copilot in Outlook seems to know nothing about my recent emails.

Likely cause (ranked):
1. data indexing lag
2. license/client prerequisite issue
3. permissions/access boundary
4. sensitivity label restriction
5. guest/external sharing limitation
6. genuine Copilot fault

Fastest check:
- Verify onboarding timing/index freshness for the mailbox and that Copilot indexing has had sufficient time post-account creation.

Is this actually a Copilot bug?
- No. “Started yesterday” strongly points to freshness/indexing and readiness timing rather than a core Copilot defect.

## Ticket 3
id: 3  
Ticket: HR manager: Asked Copilot in Word to pull data from a sensitive salary review spreadsheet, got “I don’t have access to that content.”

Likely cause (ranked):
1. permissions/access boundary
2. sensitivity label restriction
3. data indexing lag
4. license/client prerequisite issue
5. guest/external sharing limitation
6. genuine Copilot fault

Fastest check:
- Check the spreadsheet’s effective permissions for the HR manager account (and if opened via delegated/shared context) first.

Is this actually a Copilot bug?
- No. The error text is a direct access denial pattern, typically caused by access scope or protection controls.

## Ticket 4
id: 4  
Ticket: Sales rep: Copilot in Teams can’t find a client contract that was shared with her via a guest link from another org.

Likely cause (ranked):
1. guest/external sharing limitation
2. permissions/access boundary
3. data indexing lag
4. sensitivity label restriction
5. license/client prerequisite issue
6. genuine Copilot fault

Fastest check:
- Confirm the file is externally shared (guest link/other tenant) and whether Copilot is expected to ground on that external source in this tenant context.

Is this actually a Copilot bug?
- No. Cross-tenant guest-link discovery limits are a common non-bug explanation.

## Ticket 5
id: 5  
Ticket: IT admin: Copilot suddenly stopped working for the whole Finance team this morning, was fine yesterday.

Likely cause (ranked):
1. license/client prerequisite issue
2. permissions/access boundary
3. data indexing lag
4. sensitivity label restriction
5. guest/external sharing limitation
6. genuine Copilot fault

Fastest check:
- Validate Finance users still have active Copilot-eligible licensing and no recent assignment/policy/client channel changes occurred overnight.

Is this actually a Copilot bug?
- Unclear. A broad same-time cohort impact usually indicates tenant config/licensing/policy drift before product fault.

## Ticket 6
id: 6  
Ticket: Manager: Copilot found and summarised a file I don’t remember ever opening, from a folder I forgot I had access to.

Likely cause (ranked):
1. permissions/access boundary
2. data indexing lag
3. sensitivity label restriction
4. license/client prerequisite issue
5. guest/external sharing limitation
6. genuine Copilot fault

Fastest check:
- Verify current effective ACL membership on that folder/file for the manager account.

Is this actually a Copilot bug?
- No. This behavior is consistent with Copilot using content the user is authorized to access, even if they do not recall opening it.

## Ticket 7
id: 7  
Ticket: Analyst: Copilot gives generic answers, doesn’t seem to use any of our internal SharePoint content at all.

Likely cause (ranked):
1. license/client prerequisite issue
2. permissions/access boundary
3. data indexing lag
4. sensitivity label restriction
5. guest/external sharing limitation
6. genuine Copilot fault

Fastest check:
- Confirm the analyst is using a Copilot-supported client/account context with active entitlement, then run a known-access internal document prompt test.

Is this actually a Copilot bug?
- Unclear. Generic responses across all internal content often indicate entitlement/client context issues, not immediate proof of a service bug.

## Ticket 8
id: 8  
Ticket: Executive assistant: Copilot in Outlook can’t see a shared mailbox’s calendar that I manage on behalf of my director.

Likely cause (ranked):
1. permissions/access boundary
2. license/client prerequisite issue
3. guest/external sharing limitation
4. data indexing lag
5. sensitivity label restriction
6. genuine Copilot fault

Fastest check:
- Check delegated/shared mailbox calendar permission model versus what Copilot can access in the assistant’s identity context.

Is this actually a Copilot bug?
- No. Shared/delegated mailbox scenarios are commonly constrained by access context rather than core Copilot failure.

## Notes for Trainees
- Favor user identity context, source location, and entitlement checks before escalating to product fault.
- Treat “genuine Copilot fault” as last resort after excluding access, indexing, labeling, licensing/client, and external-sharing boundaries.
