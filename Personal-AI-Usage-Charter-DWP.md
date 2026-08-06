# Personal AI Usage Charter

## DWP Engineer (Public AI Assistants)

**Purpose**  
Use public AI assistants to improve speed and quality for desktop and endpoint engineering, without exposing sensitive data or bypassing engineering accountability.

**Scope**  
This charter applies to day-to-day endpoint work, including Windows desktop support, packaging, scripting, configuration, troubleshooting, and documentation.

## 1) Appropriate DWP Tasks for Public LLM Help
Use public AI for low-risk, non-sensitive support activities:

- Drafting PowerShell or batch script skeletons using placeholder values only.
- Explaining Windows endpoint concepts, command behavior, logs, and error messages that contain no sensitive data.
- Proposing troubleshooting flows for issues such as policy application, software deployment failures, printer faults, profile issues, and patching errors.
- Creating documentation drafts, runbooks, checklists, and user communication templates with no case-specific personal data.
- Refactoring generic code for readability, error handling, and logging where content is sanitized.
- Producing test ideas for scripts and deployment logic in a lab context.

## 2) Tasks That Are Not Appropriate
Do not use public AI for:

- Any task requiring production data, end-user identifiers, credentials, tokens, or internal security details.
- Decisions that change security posture, privileged access, or baseline configuration without formal review.
- Incident-handling content that includes sensitive operational details, live threat indicators, or unredacted forensic data.
- Final authority on compliance, policy interpretation, or architectural approval.
- Autonomous execution of system changes on managed endpoints.

## 3) Data-Handling Rule for PII and Credentials
**Single rule:** If data identifies a person, device owner, account, or access path, it must not be entered into a public AI prompt.

Apply this rule by default:

- Never paste names, National Insurance numbers, emails, phone numbers, usernames, hostnames tied to users, ticket transcripts, screenshots with user data, passwords, API keys, tokens, certificates, or connection strings.
- Sanitize before prompting by replacing sensitive values with neutral placeholders such as `USER_A`, `DEVICE_01`, and `APP_X`.
- Share only the minimum technical context needed.
- Stop immediately if meaningful sanitization is not possible.

## 4) Personal Generate-Then-Verify Rule (Scripts and System Changes)
Treat AI output as a draft, never as authority.

Before any script or endpoint change:

1. **Generate**: Ask AI for an initial draft including assumptions and rollback notes.
2. **Review**: Read every line; remove unsafe commands; validate paths, scopes, and permissions.
3. **Verify in lab**: Test in non-production with success, failure, and rollback scenarios.
4. **Validate controls**: Check against DWP policy, security baseline, change process, and least privilege.
5. **Peer check**: Obtain second-engineer review for changes affecting multiple users or critical services.
6. **Deploy safely**: Use staged rollout and monitor logs/telemetry for expected outcomes.
7. **Record evidence**: Document generated content, edits made, tests run, and approval references.

## Accountability Statement
I remain responsible for every command run, every change deployed, and every data item shared. AI supports engineering judgment; it does not replace it.
