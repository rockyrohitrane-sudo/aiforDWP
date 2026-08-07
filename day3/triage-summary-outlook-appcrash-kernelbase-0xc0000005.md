# Triage Summary - Outlook APPCRASH on Windows 11 (Recurring)

- Incident date in logs: 2024-03-15
- Affected app: OUTLOOK.EXE (version 16.0.17126.20132)
- Host OS component in crash: KERNELBASE.dll (10.0.22621.3155)
- Log sources: Application Error (1000), Windows Error Reporting (1001), .NET Runtime (1026)

## 1) Distinct Error Code(s) Present

Primary distinct error code identified from provided lines:
- `0xc0000005` (Exception code)

Related exception notation present:
- `System.AccessViolationException` (.NET Runtime Event 1026)
  - Interpretation: This is an exception type, not a hex NTSTATUS code.
  - Correlation note: It is consistent with access violation behavior and likely aligns with `0xc0000005`, but exact mapping in this case should be validated in Microsoft docs. **[VERIFY WITH MICROSOFT DOCS]**

Not treated as error codes (but relevant telemetry):
- Event IDs `1000`, `1001`, `1026`
- WER metadata: `Fault bucket 1847362910`, `type 4`, `Event Name: APPCRASH`
- Fault offset `0x000000000003a4b2` (debug context, not a standalone error code)

## 2) What the Pattern Suggests

Observed pattern:
- Repeated `OUTLOOK.EXE` crashes in `KERNELBASE.dll` with exception `0xc0000005`.
- WER classifies it as `APPCRASH`.
- .NET Runtime logs unhandled `System.AccessViolationException`.

Interpretation:
- Most likely a recurring memory access violation triggered by Outlook code path, add-in interaction, profile/store corruption, or damaged Office binaries.
- `KERNELBASE.dll` as faulting module is common in user-mode app crashes and does not by itself prove OS corruption.

## 3) Ranked Remediation Plan (Most Likely Fix First)

### 1. Start Outlook in Safe Mode and isolate COM add-ins
Why ranked first:
- Add-ins are a frequent cause of recurring Outlook access-violation style crashes.

Specific checks:
- Launch `outlook.exe /safe`.
- If stable in Safe Mode, disable all COM add-ins, then re-enable one-by-one.
- After each enablement, perform a repeatable action (open mailbox, new mail, search, calendar switch).
- Verify result in Event Viewer:
  - No new Application Error 1000 for `OUTLOOK.EXE` during test window.
  - No new .NET Runtime 1026 for Outlook.

Evidence confirming fix:
- Crash stops after a specific add-in is disabled.

Microsoft doc verification:
- Safe mode and add-in troubleshooting sequence for modern Outlook versions. **[VERIFY WITH MICROSOFT DOCS]**

### 2. Repair Office installation (Quick Repair, then Online Repair if needed)
Why ranked second:
- Repeated same-version crash and stable offset can indicate damaged/unstable Office binaries.

Specific checks:
- Run Office `Quick Repair` first.
- If crash persists, run `Online Repair`.
- Confirm Outlook executable version after repair/update remains consistent with expected channel build.
- Re-test normal Outlook startup and core workflows.
- Re-check Event Viewer for absence of fresh Event 1000/1026 entries.

Evidence confirming fix:
- Outlook runs normally after repair and no recurrence of `0xc0000005` in new events.

Microsoft doc verification:
- Supported Office repair flow and expected impact of Online Repair on local settings. **[VERIFY WITH MICROSOFT DOCS]**

### 3. Create a new Outlook profile and test with clean profile state
Why ranked third:
- Corrupt profile/navigation state can trigger repeat startup and runtime crashes.

Specific checks:
- Create a new profile via Mail control panel.
- Set new profile as default for testing.
- Add mailbox and test send/receive, search, and folder navigation.
- Compare behavior old profile vs new profile.
- Validate no new crash events under new profile.

Evidence confirming fix:
- New profile stable while old profile reproduces crash.

Microsoft doc verification:
- Official profile recreation guidance and retention caveats for local profile data. **[VERIFY WITH MICROSOFT DOCS]**

### 4. Run inbox and store integrity checks (OST/PST and mailbox mode checks)
Why ranked fourth:
- Corrupt local data files can cause Outlook instability under specific operations.

Specific checks:
- Identify whether cached mode and OST are in use.
- For PST-based workflows, run `SCANPST.EXE` on relevant PSTs.
- For OST issues, test with OST rebuild (after confirming sync readiness/policy).
- Re-run previously failing actions and monitor Event Viewer.

Evidence confirming fix:
- Crash no longer occurs after store repair/rebuild.

Microsoft doc verification:
- Current support stance on SCANPST usage and OST rebuild procedures in Microsoft 365 Apps. **[VERIFY WITH MICROSOFT DOCS]**

### 5. Update or roll back Office build within supported channel policy
Why ranked fifth:
- If issue is build-specific regression, channel update/rollback can be decisive.

Specific checks:
- Confirm current Office channel and build (`16.0.17126.20132`).
- Check whether crashes correlate with recent Office update timing.
- Apply approved update or rollback path per enterprise policy.
- Validate with post-change crash monitoring (Event 1000/1026) over at least one business cycle.

Evidence confirming fix:
- Crash pattern stops after controlled version change.

Microsoft doc verification:
- Office update channel management and supported rollback procedures for Microsoft 365 Apps. **[VERIFY WITH MICROSOFT DOCS]**

### 6. Validate OS and runtime health (SFC/DISM, Windows updates, .NET state)
Why ranked sixth:
- Lower probability than add-in/profile/Office causes, but appropriate if app-focused fixes fail.

Specific checks:
- Run `sfc /scannow`.
- Run `DISM /Online /Cleanup-Image /RestoreHealth`.
- Check pending Windows cumulative updates for build `22621` family.
- Re-test Outlook after maintenance reboot.

Evidence confirming fix:
- Corruption repaired and Outlook no longer emits `0xc0000005` crashes.

Microsoft doc verification:
- Exact command sequencing and interpretation of SFC/DISM outcomes. **[VERIFY WITH MICROSOFT DOCS]**

## 4) Additional Analyst Notes

- `KERNELBASE.dll` faulting module alone should not be over-interpreted as root cause; it often surfaces where the exception is raised.
- Repeated same fault offset (`0x000000000003a4b2`) supports a reproducible crash path; capturing a dump for symbolized analysis is warranted if steps 1-3 fail.
- Fault bucket `1847362910` can help correlation with known crash signatures internally, but mapping of bucket to public known issue is not guaranteed. **[VERIFY WITH MICROSOFT DOCS]**

## 5) Confidence and Uncertainty

High confidence:
- Distinct hex error code present is `0xc0000005`.
- Crash is recurring and application-scoped to Outlook.

Uncertain (explicit):
- Whether this exact bucket/build combination maps to a known Microsoft-published Outlook defect without checking current Microsoft references. **[VERIFY WITH MICROSOFT DOCS]**
