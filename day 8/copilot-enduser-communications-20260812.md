# Copilot End-User Communications

Date: 2026-08-12
Audience: End users raising Copilot support tickets
Purpose: Plain-English explanation and next steps for each case

## Ticket 1
Subject: Copilot cannot summarize Q3 board pack in SharePoint

Message to user:
Thanks for reporting this. Even when you can open a file yourself, Copilot can fail to use it if access is being provided in a way Copilot cannot use yet, or if the file has not fully indexed for Copilot retrieval.

Next steps for you:
1. Open the board pack directly from the main SharePoint library (not only from a shared link) and confirm it opens normally.
2. Copy the exact file location and send it to IT support.
3. Try again after a short wait in case indexing is still catching up.

What IT will check:
- Whether your account has direct effective access in the file path Copilot uses.
- Whether the document is still processing for search/indexing.

## Ticket 2
Subject: New starter cannot get useful Copilot responses in Outlook

Message to user:
This is usually expected in the first day or two after account setup. Copilot may not yet have enough indexed mailbox content to provide specific answers.

Next steps for you:
1. Confirm you are signed into your work account in Outlook and Copilot.
2. Wait for indexing to complete and try again later today or next business day.
3. If still the same after that, raise a follow-up with screenshots of the prompt and response.

What IT will check:
- Mailbox onboarding and indexing status.
- Copilot license and client readiness for your account.

## Ticket 3
Subject: Copilot says it cannot access sensitive salary spreadsheet

Message to user:
The message indicates Copilot is respecting access controls. If the spreadsheet is protected or permissioned in a restricted way, Copilot will not use it unless your account has the required access in that exact context.

Next steps for you:
1. Confirm with the file owner that your account has the correct permission level on the salary review file.
2. Check whether the file has a sensitivity label that blocks wider use.
3. Retry the request once access is confirmed.

What IT will check:
- Effective permissions and any sensitivity restrictions on the file.

## Ticket 4
Subject: Copilot cannot find externally shared client contract

Message to user:
This is usually due to cross-organization sharing limits. A guest link from another company may open for viewing, but Copilot in your tenant may not be able to retrieve and ground on that external content.

Next steps for you:
1. Confirm the contract owner can share a copy into your internal SharePoint or Teams location.
2. Use that internal copy for Copilot prompts.
3. If external access is mandatory, ask IT to validate supported sharing patterns.

What IT will check:
- Whether the current external link type is compatible with Copilot grounding.

## Ticket 5
Subject: Copilot stopped working for whole Finance team

Message to user:
When an entire team is affected at once, this is usually a configuration or licensing change rather than a problem with your individual usage.

Next steps for you:
1. Confirm whether all Finance users are seeing the same behavior.
2. Share one or two examples (app used, prompt, exact error text) with IT.
3. Avoid repeated retries while IT validates tenant settings.

What IT will check:
- Copilot license assignment and policy/client changes made since yesterday.

## Ticket 6
Subject: Copilot summarized a file you do not remember opening

Message to user:
Copilot can use files you are currently allowed to access, even if you have not opened them recently or forgot that permission exists. This is expected behavior and not usually a fault.

Next steps for you:
1. Review the folder permissions for your account.
2. If access is no longer appropriate, ask the folder owner to remove or adjust your permission.
3. Re-test Copilot after permission updates are applied.

What IT will check:
- Current access group membership and effective file permissions.

## Ticket 7
Subject: Copilot gives generic answers instead of using internal SharePoint

Message to user:
Generic responses often happen when Copilot cannot use your internal content context, commonly due to account entitlement, app context, or access scope.

Next steps for you:
1. Test with a known internal document you can open directly.
2. In your prompt, include the document name or location explicitly.
3. If still generic, send IT the prompt and the document path you tested.

What IT will check:
- Copilot entitlement and supported client context.
- Your effective access to the tested SharePoint content.

## Ticket 8
Subject: Copilot cannot see delegated shared mailbox calendar in Outlook

Message to user:
Managing a mailbox on behalf of someone does not always mean Copilot can use that shared mailbox calendar in the same way as your own mailbox data.

Next steps for you:
1. Confirm your delegated calendar permissions with the mailbox owner or admin.
2. Test Copilot against your primary mailbox calendar to compare behavior.
3. Send IT the mailbox name and exact action Copilot could not complete.

What IT will check:
- Delegated/shared mailbox access model and Copilot support boundaries for that scenario.

## Standard closing line for all users
If the issue continues after these checks, reply with:
- App name (Outlook, Word, Teams, etc.)
- Exact prompt used
- Full error text or screenshot
- File or mailbox path involved

This helps support confirm root cause faster and avoid unnecessary escalation.
