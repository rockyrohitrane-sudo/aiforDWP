<#
.SYNOPSIS
Finds large files on Windows endpoints and reports them without changing source files.

.DESCRIPTION
This PowerShell 5.1 script scans one or more target paths, finds files at or above a
configurable size threshold, logs every action to a timestamped log file, and prints a
summary at the end.

The script is read-only by default. An optional quarantine mode is available for cases
where an engineer wants to move matched files into a managed backup location, and a
rollback mode can restore those files later.
#>

[CmdletBinding(DefaultParameterSetName = 'Audit')]
param(
    # Section: Size threshold used to determine whether a file is considered large.
    [Parameter(ParameterSetName = 'Audit')]
    [Parameter(ParameterSetName = 'Quarantine')]
    [ValidateRange(1, 1048576)]
    [int]$ThresholdMB = 100,

    # Section: Target paths that will be scanned for large files.
    [Parameter(ParameterSetName = 'Audit')]
    [Parameter(ParameterSetName = 'Quarantine')]
    [string[]]$TargetPaths = @(
        $env:USERPROFILE,
        (Join-Path $env:WINDIR 'Temp')
    ),

    # Section: When set, the script only reports matches and does not write a CSV export.
    [Parameter(ParameterSetName = 'Audit')]
    [switch]$DryRun,

    # Section: Optional CSV export path for the audit or quarantine report.
    [Parameter(ParameterSetName = 'Audit')]
    [Parameter(ParameterSetName = 'Quarantine')]
    [string]$ReportPath,

    # Section: Optional root folder for logs.
    [Parameter(ParameterSetName = 'Audit')]
    [Parameter(ParameterSetName = 'Quarantine')]
    [Parameter(ParameterSetName = 'Rollback')]
    [string]$LogRoot = '',

    # Section: Enables quarantine mode so matched files are moved into a managed backup location.
    [Parameter(ParameterSetName = 'Quarantine', Mandatory = $true)]
    [switch]$Quarantine,

    # Section: Root folder used to store quarantined files and rollback manifests.
    [Parameter(ParameterSetName = 'Quarantine')]
    [Parameter(ParameterSetName = 'Rollback')]
    [string]$QuarantineRoot = '',

    # Section: Enables rollback mode so files can be restored from a manifest.
    [Parameter(ParameterSetName = 'Rollback', Mandatory = $true)]
    [switch]$Rollback,

    # Section: Optional manifest path used for rollback; latest manifest is used when omitted.
    [Parameter(ParameterSetName = 'Rollback')]
    [string]$RollbackManifestPath
)

# Section: Initializes runtime settings, default paths, and summary counters.
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$scriptRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
if ([string]::IsNullOrWhiteSpace($scriptRoot)) {
    $scriptRoot = (Get-Location).Path
}

if ([string]::IsNullOrWhiteSpace($LogRoot)) {
    $LogRoot = Join-Path $scriptRoot 'logs'
}

if ([string]::IsNullOrWhiteSpace($QuarantineRoot)) {
    $QuarantineRoot = Join-Path $scriptRoot 'quarantine'
}

if ([string]::IsNullOrWhiteSpace($ReportPath) -and -not $Rollback) {
    $reportsRoot = Join-Path $scriptRoot 'reports'
}
else {
    $reportsRoot = $null
}

$runTimestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$modeLabel = if ($Rollback) { 'rollback' } elseif ($Quarantine) { 'quarantine' } else { 'audit' }
$thresholdBytes = [int64]$ThresholdMB * 1MB

if (-not (Test-Path -LiteralPath $LogRoot)) {
    New-Item -Path $LogRoot -ItemType Directory -Force | Out-Null
}

if (-not [string]::IsNullOrWhiteSpace($reportsRoot) -and -not (Test-Path -LiteralPath $reportsRoot)) {
    New-Item -Path $reportsRoot -ItemType Directory -Force | Out-Null
}

if (-not [string]::IsNullOrWhiteSpace($QuarantineRoot) -and -not (Test-Path -LiteralPath $QuarantineRoot)) {
    New-Item -Path $QuarantineRoot -ItemType Directory -Force | Out-Null
}

$logFile = Join-Path $LogRoot ("large-file-finder-{0}-{1}.log" -f $modeLabel, $runTimestamp)

if ([string]::IsNullOrWhiteSpace($ReportPath) -and -not $Rollback) {
    $ReportPath = Join-Path $reportsRoot ("large-file-finder-{0}-{1}.csv" -f $modeLabel, $runTimestamp)
}

# Section: Collects summary counters for the final report.
$summary = [ordered]@{
    Mode                    = $modeLabel
    ThresholdMB             = $ThresholdMB
    TargetFoldersScanned     = 0
    FilesEnumerated          = 0
    FilesMatched             = 0
    FilesQuarantined         = 0
    FilesRestored            = 0
    DryRunWouldQuarantine    = 0
    SkippedAlreadyQuarantined = 0
    SkippedAlreadyRestored   = 0
    SkippedMissingSource     = 0
    SkippedUnreachablePath   = 0
    Errors                   = 0
    ReportPath               = ''
    ManifestPath             = ''
    LogFile                  = $logFile
}

# Section: Writes timestamped messages to both the console and the log file.
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

# Section: Converts a byte count into a rounded megabyte display string.
function Convert-BytesToDisplaySize {
    param(
        [Parameter(Mandatory = $true)]
        [Int64]$Bytes
    )

    return ('{0:N2} MB' -f ($Bytes / 1MB))
}

# Section: Safely resolves a path to an absolute file-system location.
function Resolve-SafePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    try {
        return (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
    }
    catch {
        return $null
    }
}

# Section: Retrieves the latest rollback manifest from the quarantine root.
function Get-LatestManifestPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RootPath
    )

    if (-not (Test-Path -LiteralPath $RootPath)) {
        return $null
    }

    $manifest = Get-ChildItem -LiteralPath $RootPath -File -Recurse -Filter 'manifest-*.json' -ErrorAction SilentlyContinue |
        Sort-Object -Property LastWriteTime -Descending |
        Select-Object -First 1

    if ($null -eq $manifest) {
        return $null
    }

    return $manifest.FullName
}

# Section: Builds a quarantine run folder path for the current execution.
function Get-QuarantineRunPath {
    return (Join-Path $QuarantineRoot ("large-file-finder-{0}" -f $runTimestamp))
}

# Section: Ensures that a folder exists before writing files into it.
function Ensure-FolderExists {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FolderPath
    )

    if (-not (Test-Path -LiteralPath $FolderPath)) {
        New-Item -Path $FolderPath -ItemType Directory -Force | Out-Null
    }
}

# Section: Writes the report file and returns the output path.
function Save-Report {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Items
    )

    if ([string]::IsNullOrWhiteSpace($ReportPath)) {
        return $null
    }

    $reportFolder = Split-Path -Path $ReportPath -Parent
    if (-not [string]::IsNullOrWhiteSpace($reportFolder)) {
        Ensure-FolderExists -FolderPath $reportFolder
    }

    $Items |
        Select-Object FileName, FullName, DirectoryName, SizeBytes, SizeMB, LastWriteTimeUtc, MachineName, ScannedAtUtc |
        Export-Csv -LiteralPath $ReportPath -NoTypeInformation -Encoding UTF8

    return $ReportPath
}

# Section: Saves quarantine actions to a manifest so rollback can restore them later.
function Save-QuarantineManifest {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Actions
    )

            if (-not $Actions) {
        return $null
    }

    $runFolder = Get-QuarantineRunPath
    Ensure-FolderExists -FolderPath $runFolder

    $manifestPath = Join-Path $runFolder ("manifest-{0}.json" -f $runTimestamp)
    $manifest = [PSCustomObject]@{
        CreatedAtUtc = (Get-Date).ToUniversalTime().ToString('o')
        ComputerName = $env:COMPUTERNAME
        UserName     = $env:USERNAME
        ThresholdMB  = $ThresholdMB
        Actions      = $Actions
    }

    $manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
    return $manifestPath
}

# Section: Scans the target locations and returns files at or above the threshold.
function Get-LargeFiles {
    $results = New-Object System.Collections.Generic.List[object]
    $seenPaths = New-Object 'System.Collections.Generic.HashSet[string]'

    foreach ($target in ($TargetPaths | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)) {
        try {
            if (-not (Test-Path -LiteralPath $target)) {
                $summary.SkippedUnreachablePath++
                Write-Log -Level 'WARN' -Message ("Target path not found. Skipping: {0}" -f $target)
                continue
            }

            $resolvedTarget = Resolve-SafePath -Path $target
            if ([string]::IsNullOrWhiteSpace($resolvedTarget)) {
                $summary.SkippedUnreachablePath++
                Write-Log -Level 'WARN' -Message ("Target path could not be resolved. Skipping: {0}" -f $target)
                continue
            }

            $summary.TargetFoldersScanned++
            Write-Log -Message ("Scanning target: {0}" -f $resolvedTarget)

            $items = Get-ChildItem -LiteralPath $resolvedTarget -File -Force -Recurse -ErrorAction Stop

            foreach ($item in $items) {
                $summary.FilesEnumerated++

                # Section: Per-file try/catch keeps one unreadable file from stopping the scan.
                try {
                    if ($item.Length -lt $thresholdBytes) {
                        continue
                    }

                    if (-not $seenPaths.Add($item.FullName)) {
                        continue
                    }

                    $summary.FilesMatched++
                    $results.Add([PSCustomObject]@{
                        FileName        = $item.Name
                        FullName        = $item.FullName
                        DirectoryName   = $item.DirectoryName
                        SizeBytes       = [Int64]$item.Length
                        SizeMB          = [math]::Round(($item.Length / 1MB), 2)
                        LastWriteTimeUtc = $item.LastWriteTimeUtc
                        MachineName     = $env:COMPUTERNAME
                        ScannedAtUtc    = (Get-Date).ToUniversalTime()
                    })

                    Write-Log -Message ("Matched large file: {0} ({1})" -f $item.FullName, (Convert-BytesToDisplaySize -Bytes $item.Length))
                }
                catch {
                    $summary.Errors++
                    Write-Log -Level 'ERROR' -Message ("Failed to process file '{0}': {1}" -f $item.FullName, $_.Exception.Message)
                    continue
                }
            }
        }
        catch {
            $summary.Errors++
            $errorDetails = @(
                ("Type: {0}" -f $_.Exception.GetType().FullName)
                ("Message: {0}" -f $_.Exception.Message)
                ("Position: {0}" -f $_.InvocationInfo.PositionMessage)
            ) -join ' | '
            Write-Log -Level 'ERROR' -Message ("Failed to scan target '{0}': {1}" -f $target, $errorDetails)
            continue
        }
    }

        return $results.ToArray()
}

# Section: Quarantines matched files by moving them into a timestamped backup folder.
function Invoke-Quarantine {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Items
    )

    $runPath = Get-QuarantineRunPath
    Ensure-FolderExists -FolderPath $runPath

    $actions = New-Object System.Collections.Generic.List[object]

    foreach ($item in $Items) {
        # Section: Per-file try/catch keeps quarantine work resilient.
        try {
            $sourcePath = [string]$item.FullName
            $destinationPath = Join-Path $runPath ([System.IO.Path]::GetFileName($sourcePath))

            if ((-not (Test-Path -LiteralPath $sourcePath)) -and (Test-Path -LiteralPath $destinationPath)) {
                $summary.SkippedAlreadyQuarantined++
                Write-Log -Message ("Already quarantined: {0}" -f $sourcePath)
                continue
            }

            if (-not (Test-Path -LiteralPath $sourcePath)) {
                $summary.SkippedMissingSource++
                Write-Log -Level 'WARN' -Message ("Source file missing. Skipping quarantine: {0}" -f $sourcePath)
                continue
            }

            if ($DryRun) {
                $summary.DryRunWouldQuarantine++
                Write-Log -Message ("DRY RUN: Would quarantine '{0}' to '{1}'" -f $sourcePath, $destinationPath)
                continue
            }

            if (Test-Path -LiteralPath $destinationPath) {
                $baseName = [System.IO.Path]::GetFileNameWithoutExtension($destinationPath)
                $extension = [System.IO.Path]::GetExtension($destinationPath)
                $destinationPath = Join-Path $runPath ("{0}-{1}{2}" -f $baseName, $runTimestamp, $extension)
            }

            Move-Item -LiteralPath $sourcePath -Destination $destinationPath -Force -ErrorAction Stop
            $summary.FilesQuarantined++
            Write-Log -Message ("Quarantined file: '{0}' -> '{1}'" -f $sourcePath, $destinationPath)

            $actions.Add([PSCustomObject]@{
                ActionType    = 'MoveToQuarantine'
                SourcePath    = $sourcePath
                DestinationPath = $destinationPath
                FileName      = $item.FileName
                SizeBytes     = [Int64]$item.SizeBytes
                LastWriteTimeUtc = $item.LastWriteTimeUtc
            })
        }
        catch {
            $summary.Errors++
            Write-Log -Level 'ERROR' -Message ("Failed to quarantine file '{0}': {1}" -f $item.FullName, $_.Exception.Message)
            continue
        }
    }

    $manifestPath = Save-QuarantineManifest -Actions $actions.ToArray()
    if (-not [string]::IsNullOrWhiteSpace($manifestPath)) {
        $summary.ManifestPath = $manifestPath
        Write-Log -Message ("Rollback manifest created: {0}" -f $manifestPath)
    }
    else {
        Write-Log -Message 'No manifest was written because no files were quarantined.'
    }
}

# Section: Restores quarantined files from a rollback manifest.
function Invoke-Rollback {
    if ([string]::IsNullOrWhiteSpace($RollbackManifestPath)) {
        $RollbackManifestPath = Get-LatestManifestPath -RootPath $QuarantineRoot
    }

    if ([string]::IsNullOrWhiteSpace($RollbackManifestPath) -or -not (Test-Path -LiteralPath $RollbackManifestPath)) {
        throw 'Rollback manifest not found. Provide -RollbackManifestPath or run quarantine mode first.'
    }

    $summary.ManifestPath = $RollbackManifestPath
    Write-Log -Message ("Starting rollback mode using manifest: {0}" -f $RollbackManifestPath)

    $manifest = Get-Content -LiteralPath $RollbackManifestPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    $actions = @($manifest.Actions)

            if (-not $actions) {
        Write-Log -Level 'WARN' -Message 'Manifest has no actions to rollback.'
        return
    }

    foreach ($action in $actions) {
        # Section: Per-action try/catch keeps rollback resilient for each file.
        try {
            $sourcePath = [string]$action.SourcePath
            $destinationPath = [string]$action.DestinationPath

            if (Test-Path -LiteralPath $sourcePath) {
                $summary.SkippedAlreadyRestored++
                Write-Log -Message ("Already restored: {0}" -f $sourcePath)
                continue
            }

            if (-not (Test-Path -LiteralPath $destinationPath)) {
                $summary.SkippedMissingSource++
                Write-Log -Level 'WARN' -Message ("Quarantined file not found for rollback: {0}" -f $destinationPath)
                continue
            }

            $destinationFolder = Split-Path -Path $sourcePath -Parent
            if (-not [string]::IsNullOrWhiteSpace($destinationFolder)) {
                Ensure-FolderExists -FolderPath $destinationFolder
            }

            Move-Item -LiteralPath $destinationPath -Destination $sourcePath -Force -ErrorAction Stop
            $summary.FilesRestored++
            Write-Log -Message ("Restored file: '{0}' -> '{1}'" -f $destinationPath, $sourcePath)
        }
        catch {
            $summary.Errors++
            Write-Log -Level 'ERROR' -Message ("Failed to rollback file '{0}': {1}" -f $action.SourcePath, $_.Exception.Message)
            continue
        }
    }
}

# Section: Runs the read-only audit and report workflow.
function Invoke-Audit {
    Write-Log -Message ("Starting audit mode. ThresholdMB={0}, DryRun={1}" -f $ThresholdMB, [bool]$DryRun)

    $matches = Get-LargeFiles

        if (-not $matches) {
        Write-Log -Level 'WARN' -Message ('No files were found at or above the threshold of {0} bytes.' -f $thresholdBytes)
        return $matches
    }

    $sortedMatches = @($matches) |
        Where-Object { $null -ne $_ -and $_.PSObject.Properties['FullName'] } |
        Sort-Object -Property @{ Expression = 'SizeBytes'; Descending = $true }, @{ Expression = 'FullName'; Descending = $false }

    foreach ($match in $sortedMatches) {
        # Section: Per-item try/catch keeps a single malformed result from stopping the report.
        try {
            Write-Output ("{0} | {1} | {2} bytes | {3}" -f $match.FullName, $match.SizeMB, $match.SizeBytes, $match.LastWriteTimeUtc)
        }
        catch {
            $summary.Errors++
            Write-Log -Level 'ERROR' -Message ("Failed to write audit result for '{0}': {1}" -f $match.PSObject.TypeNames[0], $_.Exception.Message)
            continue
        }
    }

    if (-not $DryRun) {
        $reportFile = Save-Report -Items $matches
        if (-not [string]::IsNullOrWhiteSpace($reportFile)) {
            $summary.ReportPath = $reportFile
            Write-Log -Message ("Report written to: {0}" -f $reportFile)
        }
    }

    return $matches
}

# Section: Writes the final summary and exit status for the run.
function Write-Summary {
    Write-Log -Message 'Run summary:'
    foreach ($key in $summary.Keys) {
        if ($key -in @('LogFile', 'ReportPath', 'ManifestPath')) {
            continue
        }

        Write-Log -Message ("{0}: {1}" -f $key, $summary[$key])
    }

    if (-not [string]::IsNullOrWhiteSpace($summary.ReportPath)) {
        Write-Log -Message ("ReportPath: {0}" -f $summary.ReportPath)
    }

    if (-not [string]::IsNullOrWhiteSpace($summary.ManifestPath)) {
        Write-Log -Message ("ManifestPath: {0}" -f $summary.ManifestPath)
    }

    Write-Log -Message ("LogFile: {0}" -f $summary.LogFile)
}

# Section: Executes the requested mode based on the parameter set.
try {
    if ($Rollback) {
        Invoke-Rollback
    }
    elseif ($Quarantine) {
        $auditMatches = Invoke-Audit
        Invoke-Quarantine -Items $auditMatches
    }
    else {
        Invoke-Audit | Out-Null
    }
}
catch {
    $summary.Errors++
    $fatalDetails = @(
        ("Type: {0}" -f $_.Exception.GetType().FullName)
        ("Message: {0}" -f $_.Exception.Message)
        ("Position: {0}" -f $_.InvocationInfo.PositionMessage)
        ("Stack: {0}" -f $_.ScriptStackTrace)
    ) -join ' | '
    Write-Log -Level 'ERROR' -Message ("Fatal error: {0}" -f $fatalDetails)
}
finally {
    Write-Summary
    if ($summary.Errors -gt 0) {
        exit 1
    }

    exit 0
}
