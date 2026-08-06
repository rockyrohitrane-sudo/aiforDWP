# Startup Program Auditor (PowerShell 5.1)

This document explains how to use the DWP startup program auditor script.

## Script Location

- day3/startup-program-auditor.ps1

## What the Script Does

- Audits startup programs from:
  - Registry Run and RunOnce keys (HKCU and HKLM)
  - Startup folders (current user and all users)
- Supports dry run mode for safe preview.
- Supports disable mode by program name filter.
- Uses per-entry try/catch error handling so one failure does not stop the run.
- Logs every action to a timestamped log file.
- Generates a rollback manifest after disable operations.
- Supports rollback from the latest or a specific manifest.
- Is idempotent:
  - Re-running disable skips entries already disabled.
  - Re-running rollback skips entries already restored.

## Parameters

- -DryRun
  - Audit mode: lists startup programs without making changes.
  - Disable mode: shows entries that would be disabled.

- -Disable
  - Enables disable mode.
  - Must be used with -ProgramName.

- -ProgramName <string>
  - Name filter used in disable mode.
  - Partial match is supported (case-insensitive).

- -Rollback
  - Enables rollback mode.
  - Restores entries using a manifest.

- -RollbackManifestPath <string>
  - Optional in rollback mode.
  - When omitted, the script uses the latest manifest under rollback root.

- -LogRoot <string>
  - Optional path for log files.
  - Default: day3/logs

- -BackupRoot <string>
  - Optional path for rollback manifests.
  - Default: day3/rollback

## Usage Examples

### 1) Audit startup programs

```powershell
powershell -ExecutionPolicy Bypass -File .\day3\startup-program-auditor.ps1
```

### 2) Dry run audit (explicit)

```powershell
powershell -ExecutionPolicy Bypass -File .\day3\startup-program-auditor.ps1 -DryRun
```

### 3) Dry run disable preview

```powershell
powershell -ExecutionPolicy Bypass -File .\day3\startup-program-auditor.ps1 -Disable -ProgramName 'Teams' -DryRun
```

### 4) Disable matched startup entries

```powershell
powershell -ExecutionPolicy Bypass -File .\day3\startup-program-auditor.ps1 -Disable -ProgramName 'Teams'
```

### 5) Rollback latest disable run

```powershell
powershell -ExecutionPolicy Bypass -File .\day3\startup-program-auditor.ps1 -Rollback
```

### 6) Rollback from a specific manifest

```powershell
powershell -ExecutionPolicy Bypass -File .\day3\startup-program-auditor.ps1 -Rollback -RollbackManifestPath '.\day3\rollback\disable-20260805-120000\manifest-20260805-120000.json'
```

## Logs, Manifests, and Exit Code

- Log files are written to:
  - day3/logs/startup-program-auditor-<mode>-<timestamp>.log

- Rollback manifests are written to:
  - day3/rollback/disable-<timestamp>/manifest-<timestamp>.json

- Exit code:
  - 0 when no errors were logged.
  - 1 when one or more errors were logged.

## Notes

- Disable mode does not delete startup entries; it moves them to script-managed disabled locations so rollback can restore them.
- Some HKLM changes may require running PowerShell as Administrator.
