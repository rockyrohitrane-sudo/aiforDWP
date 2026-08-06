# Temp File Cleanup Script (PowerShell 5.1)

This document explains how to use `temp-file-cleanup.ps1` for safe temp-file cleanup on Windows endpoints.

## Script Location

- `day3/temp-file-cleanup.ps1`

## What the Script Does

- Cleans temp files from target folders.
- Supports dry run mode to preview actions.
- Processes only files older than a configurable number of days.
- Skips locked files and logs the issue without stopping execution.
- Uses per-file `try/catch` error handling.
- Logs every action to a timestamped log file.
- Generates a summary report at the end.
- Supports rollback by restoring files from a manifest.
- Is idempotent:
  - Running cleanup repeatedly will only process files currently present.
  - Running rollback repeatedly will skip already restored or missing backup files safely.

## Parameters

- `-DryRun`
  - Cleanup mode only.
  - Shows files that would be moved to quarantine.
  - Does not move or delete files.

- `-OlderThanDays <int>`
  - Cleanup mode only.
  - Default: `0`.
  - Only files with `LastWriteTime` older than now minus this value are eligible.

- `-TargetPaths <string[]>`
  - Cleanup mode only.
  - List of folders to scan.
  - Default:
    - `$env:TEMP`
    - `$env:WINDIR\Temp`

- `-NoRecurse`
  - Cleanup mode only.
  - Limits scanning to top-level files in each target folder.

- `-Rollback`
  - Switches script to rollback mode.
  - Restores previously quarantined files.

- `-ManifestPath <string>`
  - Rollback mode only.
  - Optional explicit path to a manifest JSON file.
  - If omitted, the latest manifest under quarantine root is used.

- `-QuarantineRoot <string>`
  - Optional for both modes.
  - Default: `day3/quarantine`.
  - Stores quarantined files and manifests.

- `-LogRoot <string>`
  - Optional for both modes.
  - Default: `day3/logs`.
  - Stores timestamped log files.

## Usage Examples

### 1) Dry run with default settings

```powershell
powershell -ExecutionPolicy Bypass -File .\day3\temp-file-cleanup.ps1 -DryRun
```

### 2) Cleanup files older than 7 days

```powershell
powershell -ExecutionPolicy Bypass -File .\day3\temp-file-cleanup.ps1 -OlderThanDays 7
```

### 3) Cleanup custom locations without recursion

```powershell
powershell -ExecutionPolicy Bypass -File .\day3\temp-file-cleanup.ps1 -TargetPaths @('C:\Temp', "$env:TEMP") -OlderThanDays 3 -NoRecurse
```

### 4) Rollback using latest manifest

```powershell
powershell -ExecutionPolicy Bypass -File .\day3\temp-file-cleanup.ps1 -Rollback
```

### 5) Rollback using a specific manifest

```powershell
powershell -ExecutionPolicy Bypass -File .\day3\temp-file-cleanup.ps1 -Rollback -ManifestPath '.\day3\quarantine\cleanup-20260805-101500\manifest-20260805-101500.json'
```

## Output and Logs

- Logs are written to:
  - `day3/logs/temp-file-cleanup-cleanup-<timestamp>.log`
  - `day3/logs/temp-file-cleanup-rollback-<timestamp>.log`

- Quarantined files and manifests are written under:
  - `day3/quarantine/cleanup-<timestamp>/`

- The script exits with:
  - `0` when no errors occurred.
  - `1` when one or more errors were logged.

## Safety Notes

- The script has built-in safeguards and will skip high-risk root targets.
- Locked files are skipped and logged.
- Rollback does not overwrite existing original files; it logs and skips them.
