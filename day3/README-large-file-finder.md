# Large File Finder (PowerShell 5.1)

This document explains how to use `large-file-finder.ps1` for a read-only large file audit on Windows endpoints.

## Script Location

- `day3/large-file-finder.ps1`

## What the Script Does

- Scans one or more target folders for files at or above a size threshold.
- Uses a default threshold of `100 MB`.
- Works in read-only audit mode by default.
- Logs every action to a timestamped log file.
- Uses per-file try/catch error handling so one file failure does not stop the scan.
- Prints a summary at the end of the run.
- Supports optional quarantine mode for managed movement of files.
- Supports rollback from the latest or a specific quarantine manifest.
- Is idempotent:
  - Audit mode only reads files and produces a repeatable report from the current filesystem state.
  - Quarantine mode skips files that are already quarantined.
  - Rollback mode skips files that are already restored.

## Parameters

- `-ThresholdMB <int>`
  - Sets the minimum file size to report.
  - Default: `100`.
  - Example: `-ThresholdMB 250` finds files at or above 250 MB.

- `-TargetPaths <string[]>`
  - Audit and quarantine modes only.
  - List of folders to scan.
  - Default:
    - `$env:USERPROFILE`
    - `$env:WINDIR\Temp`

- `-DryRun`
  - Audit and quarantine modes only.
  - In audit mode, it suppresses CSV report creation.
  - In quarantine mode, it shows what would be moved without moving anything.

- `-ReportPath <string>`
  - Audit and quarantine modes only.
  - Optional CSV export path for the report.
  - If omitted, the script writes a timestamped CSV file under `day3/reports`.

- `-Quarantine`
  - Enables quarantine mode.
  - Moves matched files into a managed backup folder so they can be restored later.
  - This is optional and off by default.

- `-QuarantineRoot <string>`
  - Quarantine and rollback modes only.
  - Default: `day3/quarantine`.
  - Stores quarantined files and rollback manifests.

- `-Rollback`
  - Enables rollback mode.
  - Restores files from a quarantine manifest.

- `-RollbackManifestPath <string>`
  - Rollback mode only.
  - Optional explicit path to a manifest JSON file.
  - If omitted, the script uses the latest manifest under the quarantine root.

- `-LogRoot <string>`
  - Optional for all modes.
  - Default: `day3/logs`.
  - Stores timestamped log files.

## Usage Examples

### 1) Read-only audit with defaults

```powershell
powershell -ExecutionPolicy Bypass -File .\day3\large-file-finder.ps1
```

### 2) Read-only audit with a custom threshold

```powershell
powershell -ExecutionPolicy Bypass -File .\day3\large-file-finder.ps1 -ThresholdMB 250
```

### 3) Read-only audit of custom paths

```powershell
powershell -ExecutionPolicy Bypass -File .\day3\large-file-finder.ps1 -TargetPaths @('C:\Users', 'D:\Data') -ThresholdMB 150
```

### 4) Dry run audit with no CSV export

```powershell
powershell -ExecutionPolicy Bypass -File .\day3\large-file-finder.ps1 -DryRun
```

### 5) Quarantine matched files

```powershell
powershell -ExecutionPolicy Bypass -File .\day3\large-file-finder.ps1 -Quarantine -TargetPaths @('D:\Data') -ThresholdMB 500
```

### 6) Roll back from the latest quarantine manifest

```powershell
powershell -ExecutionPolicy Bypass -File .\day3\large-file-finder.ps1 -Rollback
```

### 7) Roll back from a specific manifest

```powershell
powershell -ExecutionPolicy Bypass -File .\day3\large-file-finder.ps1 -Rollback -RollbackManifestPath '.\day3\quarantine\large-file-finder-20260805-120000\manifest-20260805-120000.json'
```

## Output and Logs

- Logs are written to:
  - `day3/logs/large-file-finder-audit-<timestamp>.log`
  - `day3/logs/large-file-finder-quarantine-<timestamp>.log`
  - `day3/logs/large-file-finder-rollback-<timestamp>.log`

- CSV reports are written to:
  - `day3/reports/large-file-finder-<mode>-<timestamp>.csv`
  - Or to the path you pass with `-ReportPath`

- Quarantine files and rollback manifests are written under:
  - `day3/quarantine/large-file-finder-<timestamp>/`

- The script exits with:
  - `0` when no errors were logged.
  - `1` when one or more errors were logged.

## Notes

- The default behavior is read-only and does not change source files.
- Quarantine mode is optional and should only be used when file movement is acceptable.
- Rollback works only for files that were previously quarantined by this script.
- Some target paths may require elevated permissions to read.
