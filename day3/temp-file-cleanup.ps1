<#
.SYNOPSIS
Safely cleans temporary files on Windows endpoints with dry-run, logging, and rollback support.

.DESCRIPTION
This script targets files in configurable temporary folders, optionally previews what would be moved,
and moves eligible files to a quarantine location so they can be restored later.

Designed for PowerShell 5.1.
#>

[CmdletBinding()]
param(
    # When set, the script only reports what it would process and does not move files.
    [Parameter(ParameterSetName = 'Cleanup')]
    [switch]$DryRun,

    # Processes only files older than this number of days.
    [Parameter(ParameterSetName = 'Cleanup')]
    [ValidateRange(0, 36500)]
    [int]$OlderThanDays = 0,

    # List of folders to scan for temp files.
    [Parameter(ParameterSetName = 'Cleanup')]
    [string[]]$TargetPaths = @(
        $env:TEMP,
        (Join-Path $env:WINDIR 'Temp')
    ),

    # Set this switch to disable recursive scanning of subfolders.
    [Parameter(ParameterSetName = 'Cleanup')]
    [switch]$NoRecurse,

    # Runs rollback mode and restores files from a manifest.
    [Parameter(ParameterSetName = 'Rollback', Mandatory = $true)]
    [switch]$Rollback,

    # Optional manifest path used for rollback; latest manifest is used when omitted.
    [Parameter(ParameterSetName = 'Rollback')]
    [string]$ManifestPath,

    # Root folder where quarantined files and manifests are stored.
    [Parameter()]
    [string]$QuarantineRoot = '',

    # Folder where timestamped log files are written.
    [Parameter()]
    [string]$LogRoot = ''
)

# Section: Initialize runtime settings and summary counters.
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$scriptRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
if ([string]::IsNullOrWhiteSpace($scriptRoot)) {
    $scriptRoot = (Get-Location).Path
}

if ([string]::IsNullOrWhiteSpace($QuarantineRoot)) {
    $QuarantineRoot = Join-Path $scriptRoot 'quarantine'
}

if ([string]::IsNullOrWhiteSpace($LogRoot)) {
    $LogRoot = Join-Path $scriptRoot 'logs'
}

$runTimestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$modeLabel = if ($Rollback) { 'rollback' } else { 'cleanup' }

if (-not (Test-Path -LiteralPath $LogRoot)) {
    New-Item -Path $LogRoot -ItemType Directory -Force | Out-Null
}

$logFile = Join-Path $LogRoot ("temp-file-cleanup-{0}-{1}.log" -f $modeLabel, $runTimestamp)

$summary = [ordered]@{
    Mode                  = $modeLabel
    TargetFoldersScanned  = 0
    FilesEnumerated       = 0
    FilesEligible         = 0
    FilesMoved            = 0
    FilesRestored         = 0
    DryRunWouldMove       = 0
    SkippedTooNew         = 0
    SkippedLocked         = 0
    SkippedSafety         = 0
    SkippedMissingBackup  = 0
    SkippedAlreadyPresent = 0
    Errors                = 0
    ManifestPath          = ''
    LogFile               = $logFile
}

# Section: Writes a timestamped message to both console and log file.
function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO'
    )

    $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "[{0}] [{1}] {2}" -f $stamp, $Level, $Message
    Write-Output $line
    Add-Content -LiteralPath $logFile -Value $line
}

# Section: Basic safety guard to prevent scanning high-risk root paths.
function Test-IsSafeTargetPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PathToValidate
    )

    try {
        $fullPath = [System.IO.Path]::GetFullPath($PathToValidate)
    }
    catch {
        return $false
    }

    $trimmed = $fullPath.TrimEnd('\\')
    $windowsRoot = [System.IO.Path]::GetFullPath($env:WINDIR).TrimEnd('\\')
    $driveRoot = [System.IO.Path]::GetPathRoot($fullPath).TrimEnd('\\')

    if ($trimmed -ieq $driveRoot) {
        return $false
    }

    if ($trimmed -ieq $windowsRoot) {
        return $false
    }

    return $true
}

# Section: Detects whether a file is currently locked by another process.
function Test-FileLocked {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    try {
        $stream = [System.IO.File]::Open($FilePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
        $stream.Close()
        return $false
    }
    catch [System.IO.IOException] {
        return $true
    }
    catch {
        return $false
    }
}

# Section: Finds the most recent rollback manifest when one is not supplied.
function Get-LatestManifest {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RootPath
    )

    if (-not (Test-Path -LiteralPath $RootPath)) {
        return $null
    }

    $latest = Get-ChildItem -LiteralPath $RootPath -File -Recurse -Filter 'manifest-*.json' -ErrorAction SilentlyContinue |
        Sort-Object -Property LastWriteTime -Descending |
        Select-Object -First 1

    if ($null -eq $latest) {
        return $null
    }

    return $latest.FullName
}

# Section: Executes cleanup mode by moving eligible files into a timestamped quarantine folder.
function Invoke-Cleanup {
    $cutoffDate = (Get-Date).AddDays(-1 * $OlderThanDays)
    $quarantineRunPath = Join-Path $QuarantineRoot ("cleanup-{0}" -f $runTimestamp)
    $manifestEntries = New-Object System.Collections.Generic.List[object]

    if (-not $DryRun) {
        if (-not (Test-Path -LiteralPath $quarantineRunPath)) {
            New-Item -Path $quarantineRunPath -ItemType Directory -Force | Out-Null
        }
    }

    Write-Log -Message ("Starting cleanup mode. OlderThanDays={0}, DryRun={1}" -f $OlderThanDays, [bool]$DryRun)

    foreach ($target in ($TargetPaths | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)) {
        try {
            if (-not (Test-Path -LiteralPath $target)) {
                Write-Log -Level 'WARN' -Message ("Target path not found. Skipping: {0}" -f $target)
                continue
            }

            $resolvedTarget = (Resolve-Path -LiteralPath $target).Path

            if (-not (Test-IsSafeTargetPath -PathToValidate $resolvedTarget)) {
                $summary.SkippedSafety++
                Write-Log -Level 'WARN' -Message ("Target path failed safety check. Skipping: {0}" -f $resolvedTarget)
                continue
            }

            $summary.TargetFoldersScanned++
            Write-Log -Message ("Scanning target: {0}" -f $resolvedTarget)

            $items = Get-ChildItem -LiteralPath $resolvedTarget -File -Force -Recurse:(!$NoRecurse) -ErrorAction Stop

            foreach ($item in $items) {
                $summary.FilesEnumerated++

                try {
                    if ($item.LastWriteTime -gt $cutoffDate) {
                        $summary.SkippedTooNew++
                        continue
                    }

                    $summary.FilesEligible++

                    if (Test-FileLocked -FilePath $item.FullName) {
                        $summary.SkippedLocked++
                        Write-Log -Level 'WARN' -Message ("Locked file skipped: {0}" -f $item.FullName)
                        continue
                    }

                    $quarantineFileName = "{0}_{1}" -f ([Guid]::NewGuid().ToString('N')), $item.Name
                    $destinationPath = Join-Path $quarantineRunPath $quarantineFileName

                    if ($DryRun) {
                        $summary.DryRunWouldMove++
                        Write-Log -Message ("DRY RUN: Would move '{0}' to '{1}'" -f $item.FullName, $destinationPath)
                        continue
                    }

                    Move-Item -LiteralPath $item.FullName -Destination $destinationPath -Force -ErrorAction Stop
                    $summary.FilesMoved++
                    Write-Log -Message ("Moved file: '{0}' -> '{1}'" -f $item.FullName, $destinationPath)

                    $manifestEntries.Add([PSCustomObject]@{
                        OriginalPath   = $item.FullName
                        QuarantinePath = $destinationPath
                        FileName       = $item.Name
                        SizeBytes      = $item.Length
                        LastWriteTime  = $item.LastWriteTime
                        MovedAt        = (Get-Date)
                    })
                }
                catch {
                    $summary.Errors++
                    Write-Log -Level 'ERROR' -Message ("Error processing file '{0}': {1}" -f $item.FullName, $_.Exception.Message)
                    continue
                }
            }
        }
        catch {
            $summary.Errors++
            Write-Log -Level 'ERROR' -Message ("Error scanning target '{0}': {1}" -f $target, $_.Exception.Message)
            continue
        }
    }

    if (-not $DryRun) {
        if ($manifestEntries.Count -gt 0) {
            $manifestPath = Join-Path $quarantineRunPath ("manifest-{0}.json" -f $runTimestamp)
            $manifestEntries | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
            $summary.ManifestPath = $manifestPath
            Write-Log -Message ("Manifest created: {0}" -f $manifestPath)
        }
        else {
            Write-Log -Message 'No files moved. Manifest not created.'
        }
    }
}

# Section: Executes rollback mode and restores files listed in a manifest.
function Invoke-Rollback {
    $manifestToUse = $ManifestPath

    if ([string]::IsNullOrWhiteSpace($manifestToUse)) {
        $manifestToUse = Get-LatestManifest -RootPath $QuarantineRoot
    }

    if ([string]::IsNullOrWhiteSpace($manifestToUse) -or -not (Test-Path -LiteralPath $manifestToUse)) {
        $summary.Errors++
        Write-Log -Level 'ERROR' -Message 'Rollback manifest not found. Provide -ManifestPath or run cleanup first.'
        return
    }

    Write-Log -Message ("Starting rollback mode using manifest: {0}" -f $manifestToUse)
    $summary.ManifestPath = $manifestToUse

    try {
        $entries = Get-Content -LiteralPath $manifestToUse -Raw | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        $summary.Errors++
        Write-Log -Level 'ERROR' -Message ("Failed to read manifest '{0}': {1}" -f $manifestToUse, $_.Exception.Message)
        return
    }

    foreach ($entry in $entries) {
        try {
            if (-not (Test-Path -LiteralPath $entry.QuarantinePath)) {
                $summary.SkippedMissingBackup++
                Write-Log -Level 'WARN' -Message ("Backup file missing. Skipping: {0}" -f $entry.QuarantinePath)
                continue
            }

            if (Test-Path -LiteralPath $entry.OriginalPath) {
                $summary.SkippedAlreadyPresent++
                Write-Log -Level 'WARN' -Message ("Original file already exists. Skipping restore: {0}" -f $entry.OriginalPath)
                continue
            }

            $parent = Split-Path -Path $entry.OriginalPath -Parent
            if (-not (Test-Path -LiteralPath $parent)) {
                New-Item -Path $parent -ItemType Directory -Force | Out-Null
            }

            Move-Item -LiteralPath $entry.QuarantinePath -Destination $entry.OriginalPath -Force -ErrorAction Stop
            $summary.FilesRestored++
            Write-Log -Message ("Restored file: '{0}' -> '{1}'" -f $entry.QuarantinePath, $entry.OriginalPath)
        }
        catch {
            $summary.Errors++
            Write-Log -Level 'ERROR' -Message ("Error restoring '{0}': {1}" -f $entry.OriginalPath, $_.Exception.Message)
            continue
        }
    }
}

# Section: Main execution block selects cleanup or rollback mode.
try {
    if ($Rollback) {
        Invoke-Rollback
    }
    else {
        Invoke-Cleanup
    }
}
catch {
    $summary.Errors++
    Write-Log -Level 'ERROR' -Message ("Unhandled error: {0}" -f $_.Exception.Message)
}

# Section: Prints a run summary and keeps log details for auditability.
Write-Log -Message 'Run summary:'
foreach ($key in $summary.Keys) {
    Write-Log -Message ("  {0}: {1}" -f $key, $summary[$key])
}

# Section: Returns non-zero exit code only when errors occurred.
if ($summary.Errors -gt 0) {
    exit 1
}

exit 0
