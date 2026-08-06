# Disk Health Reporter (PowerShell 5.1)

This document explains how to use `disk-health-reporter.ps1` for read-only disk health checks on Windows endpoints.

## Script Location

- `day3/disk-health-reporter.ps1`

## What the Script Does

- Reports health information for fixed disks.
- Calculates free space and flags low-space volumes.
- Optionally runs read-only optimization analysis.
- Does not run defragmentation.
- Logs every action to a timestamped log file.
- Writes a CSV report by default.
- Prints a summary at the end of the run.
- Supports rollback by restoring a previously exported report from a manifest snapshot.
- Is idempotent:
  - Audit mode only reads disk state and writes a timestamped report.
  - Rollback mode skips restoring the report if the destination already exists.

## Parameters

- `-LowFreeSpacePercent <int>`
  - Audit mode only.
  - Default: `15`.
  - Volumes below this free-space percentage are reported as warning-level.

- `-DriveLetters <string[]>`
  - Audit mode only.
  - Optional list of fixed drive letters to scan.
  - Example: `-DriveLetters C, D`

- `-SkipOptimizationAnalysis`
  - Audit mode only.
  - Skips the read-only optimization analysis step.
  - Use this if you want the report to only collect health and space data.

- `-DryRun`
  - Audit mode only.
  - Logs what would be reported.
  - Does not write the CSV report or snapshot manifest.

- `-ReportPath <string>`
  - Audit mode only.
  - Optional explicit path for the CSV report.
  - If omitted, a timestamped report is written under `day3/reports`.

- `-ReportRoot <string>`
  - Audit mode only.
  - Optional root folder for report output.
  - Default: `day3/reports`.

- `-Rollback`
  - Switches the script to rollback mode.
  - Restores a previously exported report from a manifest snapshot.

- `-RollbackManifestPath <string>`
  - Rollback mode only.
  - Optional explicit path to a manifest JSON file.
  - If omitted, the latest manifest under the rollback root is used.

- `-RollbackReportPath <string>`
  - Rollback mode only.
  - Optional restore location for the copied report.
  - Default: `day3/reports/restored/disk-health-reporter-restored.csv`.

- `-RollbackRoot <string>`
  - Audit and rollback modes.
  - Default: `day3/rollback`.
  - Stores rollback manifests and report snapshots.

- `-LogRoot <string>`
  - Audit and rollback modes.
  - Default: `day3/logs`.
  - Stores timestamped log files.

## Usage Examples

### 1) Read-only audit with defaults

```powershell
powershell -ExecutionPolicy Bypass -File .\day3\disk-health-reporter.ps1
```

### 2) Audit with a custom low-free-space threshold

```powershell
powershell -ExecutionPolicy Bypass -File .\day3\disk-health-reporter.ps1 -LowFreeSpacePercent 20
```

### 3) Audit only selected drives

```powershell
powershell -ExecutionPolicy Bypass -File .\day3\disk-health-reporter.ps1 -DriveLetters C, D
```

### 4) Skip optimization analysis

```powershell
powershell -ExecutionPolicy Bypass -File .\day3\disk-health-reporter.ps1 -SkipOptimizationAnalysis
```

### 5) Dry run audit

```powershell
powershell -ExecutionPolicy Bypass -File .\day3\disk-health-reporter.ps1 -DryRun
```

### 6) Roll back the last saved report

```powershell
powershell -ExecutionPolicy Bypass -File .\day3\disk-health-reporter.ps1 -Rollback
```

### 7) Roll back from a specific manifest

```powershell
powershell -ExecutionPolicy Bypass -File .\day3\disk-health-reporter.ps1 -Rollback -RollbackManifestPath '.\day3\rollback\disk-health-reporter-20260805-175213\manifest-20260805-175213.json' -RollbackReportPath '.\day3\reports\restored\disk-health-reporter-restored.csv'
```

## Output and Logs

- Logs are written to:
  - `day3/logs/disk-health-reporter-audit-<timestamp>.log`
  - `day3/logs/disk-health-reporter-rollback-<timestamp>.log`

- Reports are written to:
  - `day3/reports/disk-health-reporter-audit-<timestamp>.csv`
  - Or the path you pass with `-ReportPath`

- Rollback snapshots and manifests are written to:
  - `day3/rollback/disk-health-reporter-<timestamp>/`

- The script exits with:
  - `0` when no errors were logged.
  - `1` when one or more errors were logged.

## Notes

- The script is strictly read-only with respect to disk state.
- It reports optimization status, but it does not run defragmentation.
- Rollback only restores the exported report file, not any disk configuration.
- Some volume metadata or optimization analysis may require elevated permissions.
