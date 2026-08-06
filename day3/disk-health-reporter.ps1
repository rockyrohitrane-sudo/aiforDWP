<#
.SYNOPSIS
Reports disk health and optimization status on Windows endpoints without modifying disk state.

.DESCRIPTION
This PowerShell 5.1 script scans fixed disks, collects health and free-space data, and reports
an optimization status for each volume. It is read-only by default and never runs defragmentation.

Optional rollback support is limited to restoring a previously exported report from a timestamped
snapshot. The rollback mode does not change disk configuration or optimization state.
#>

[CmdletBinding(DefaultParameterSetName = 'Audit')]
param(
    # Section: Low free-space threshold used to classify a volume as warning-level.
    [Parameter(ParameterSetName = 'Audit')]
    [ValidateRange(1, 100)]
    [int]$LowFreeSpacePercent = 15,

    # Section: Optional filter for specific fixed drive letters to scan.
    [Parameter(ParameterSetName = 'Audit')]
    [string[]]$DriveLetters,

    # Section: Skips optimization analysis and reports that the check was not run.
    [Parameter(ParameterSetName = 'Audit')]
    [switch]$SkipOptimizationAnalysis,

    # Section: Dry run mode logs what would be written without creating a report file.
    [Parameter(ParameterSetName = 'Audit')]
    [switch]$DryRun,

    # Section: Optional explicit path for the generated CSV report.
    [Parameter(ParameterSetName = 'Audit')]
    [string]$ReportPath,

    # Section: Optional root folder for timestamped report output.
    [Parameter(ParameterSetName = 'Audit')]
    [string]$ReportRoot = '',

    # Section: Optional root folder for timestamped log files.
    [Parameter(ParameterSetName = 'Audit')]
    [Parameter(ParameterSetName = 'Rollback')]
    [string]$LogRoot = '',

    # Section: Enables rollback mode so a previous report snapshot can be restored.
    [Parameter(ParameterSetName = 'Rollback', Mandatory = $true)]
    [switch]$Rollback,

    # Section: Optional manifest path used for rollback; latest manifest is used when omitted.
    [Parameter(ParameterSetName = 'Rollback')]
    [string]$RollbackManifestPath,

    # Section: Optional restore path used when the rollback report is copied back.
    [Parameter(ParameterSetName = 'Rollback')]
    [string]$RollbackReportPath,

    # Section: Optional root folder that stores rollback manifests and report snapshots.
    [Parameter(ParameterSetName = 'Audit')]
    [Parameter(ParameterSetName = 'Rollback')]
    [string]$RollbackRoot = ''
)

# Section: Initializes strict runtime behavior and default file-system locations.
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$scriptRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
if ([string]::IsNullOrWhiteSpace($scriptRoot)) {
    $scriptRoot = (Get-Location).Path
}

if ([string]::IsNullOrWhiteSpace($ReportRoot)) {
    $ReportRoot = Join-Path $scriptRoot 'reports'
}

if ([string]::IsNullOrWhiteSpace($RollbackRoot)) {
    $RollbackRoot = Join-Path $scriptRoot 'rollback'
}

if ([string]::IsNullOrWhiteSpace($LogRoot)) {
    $LogRoot = Join-Path $scriptRoot 'logs'
}

$runTimestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$modeLabel = if ($Rollback) { 'rollback' } else { 'audit' }

if (-not (Test-Path -LiteralPath $ReportRoot)) {
    New-Item -Path $ReportRoot -ItemType Directory -Force | Out-Null
}

if (-not (Test-Path -LiteralPath $RollbackRoot)) {
    New-Item -Path $RollbackRoot -ItemType Directory -Force | Out-Null
}

if (-not (Test-Path -LiteralPath $LogRoot)) {
    New-Item -Path $LogRoot -ItemType Directory -Force | Out-Null
}

if ([string]::IsNullOrWhiteSpace($ReportPath) -and -not $Rollback) {
    $ReportPath = Join-Path $ReportRoot ("disk-health-reporter-{0}-{1}.csv" -f $modeLabel, $runTimestamp)
}

if ([string]::IsNullOrWhiteSpace($RollbackReportPath) -and $Rollback) {
    $restoredRoot = Join-Path $ReportRoot 'restored'
    if (-not (Test-Path -LiteralPath $restoredRoot)) {
        New-Item -Path $restoredRoot -ItemType Directory -Force | Out-Null
    }

    $RollbackReportPath = Join-Path $restoredRoot 'disk-health-reporter-restored.csv'
}

$logFile = Join-Path $LogRoot ("disk-health-reporter-{0}-{1}.log" -f $modeLabel, $runTimestamp)

# Section: Collects summary counters for the final report.
$summary = [ordered]@{
    Mode                    = $modeLabel
    LowFreeSpacePercent     = $LowFreeSpacePercent
    DrivesScanned           = 0
    VolumesReported         = 0
    HealthyVolumes          = 0
    WarningVolumes          = 0
    CriticalVolumes         = 0
    LowFreeSpaceVolumes     = 0
    OptimizationAnalysed    = 0
    OptimizationSkipped     = 0
    OptimizationUnavailable = 0
    DryRunWouldWriteReport  = 0
    RollbackRestored        = 0
    RollbackSkipped         = 0
    Errors                  = 0
    ReportPath              = ''
    SnapshotPath            = ''
    ManifestPath            = ''
    LogFile                 = $logFile
}

# Section: Writes a timestamped message to the console and log file.
function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO'
    )

    $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "[{0}] [{1}] {2}" -f $stamp, $Level, $Message
    Write-Host $line
    Add-Content -LiteralPath $logFile -Value $line
}

# Section: Ensures the parent folder for a file path exists before writing to it.
function Ensure-FolderExists {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FolderPath
    )

    if (-not (Test-Path -LiteralPath $FolderPath)) {
        New-Item -Path $FolderPath -ItemType Directory -Force | Out-Null
    }
}

# Section: Normalizes a numeric byte value into a rounded gigabyte display string.
function Convert-BytesToGB {
    param(
        [Parameter(Mandatory = $true)]
        [Int64]$Bytes
    )

    return [math]::Round(($Bytes / 1GB), 2)
}

# Section: Finds the latest manifest file when rollback is requested without an explicit path.
function Get-LatestManifestPath {
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

# Section: Builds a read-only optimization analysis result for one drive letter.
function Get-OptimizationAnalysis {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DriveLetter
    )

    if ($SkipOptimizationAnalysis) {
        $summary.OptimizationSkipped++
        Write-Log -Message ("Optimization analysis skipped for {0}: requested by parameter." -f $DriveLetter)
        return [PSCustomObject]@{
            OptimizationStatus  = 'Skipped'
            OptimizationDetails = 'Skipped by request'
        }
    }

    $optimizeCommand = Get-Command -Name Optimize-Volume -ErrorAction SilentlyContinue
    if ($null -eq $optimizeCommand) {
        $summary.OptimizationUnavailable++
        Write-Log -Level 'WARN' -Message ("Optimization analysis unavailable for {0}: Optimize-Volume not found." -f $DriveLetter)
        return [PSCustomObject]@{
            OptimizationStatus  = 'Unavailable'
            OptimizationDetails = 'Optimize-Volume not available on this system'
        }
    }

    try {
        $analysis = Optimize-Volume -DriveLetter $DriveLetter -Analyze -ErrorAction Stop
        $summary.OptimizationAnalysed++

        $detailText = ($analysis | Select-Object * | Out-String).Trim()
        if ([string]::IsNullOrWhiteSpace($detailText)) {
            $detailText = 'Analysis completed'
        }

        Write-Log -Message ("Optimization analysis completed for {0}" -f $DriveLetter)
        return [PSCustomObject]@{
            OptimizationStatus  = 'Analyzed'
            OptimizationDetails = $detailText
        }
    }
    catch {
        $summary.OptimizationUnavailable++
        Write-Log -Level 'WARN' -Message ("Optimization analysis unavailable for {0}: {1}" -f $DriveLetter, $_.Exception.Message)
        return [PSCustomObject]@{
            OptimizationStatus  = 'Unavailable'
            OptimizationDetails = $_.Exception.Message
        }
    }
}

# Section: Collects health data for each fixed drive and converts it into report rows.
function Get-DiskHealthEntries {
    $entries = @()

    $logicalDisks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType = 3" -ErrorAction Stop
    if (-not $DriveLetters) {
        $targetLetters = @($logicalDisks | ForEach-Object { $_.DeviceID.TrimEnd(':') })
    }
    else {
        $targetLetters = @($DriveLetters | ForEach-Object { $_.TrimEnd(':').Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
    }

    foreach ($disk in $logicalDisks) {
        # Section: Per-drive try/catch keeps one unreadable volume from stopping the report.
        try {
            $driveLetter = $disk.DeviceID.TrimEnd(':')
            if ($targetLetters -and ($targetLetters -notcontains $driveLetter)) {
                continue
            }

            $summary.DrivesScanned++
            Write-Log -Message ("Scanning drive: {0}:" -f $driveLetter)

            $sizeBytes = [Int64]$disk.Size
            $freeBytes = [Int64]$disk.FreeSpace
            $sizeGB = if ($sizeBytes -gt 0) { Convert-BytesToGB -Bytes $sizeBytes } else { 0 }
            $freeGB = if ($freeBytes -gt 0) { Convert-BytesToGB -Bytes $freeBytes } else { 0 }
            $freePercent = if ($sizeBytes -gt 0) { [math]::Round(($freeBytes / $sizeBytes) * 100, 2) } else { 0 }

            $volume = $null
            try {
                $volume = Get-Volume -DriveLetter $driveLetter -ErrorAction Stop
            }
            catch {
                Write-Log -Level 'WARN' -Message ("Volume metadata unavailable for {0}: {1}" -f $driveLetter, $_.Exception.Message)
            }

            $healthStatus = 'Unknown'
            $operationalStatus = 'Unknown'
            $label = $disk.VolumeName
            $fileSystem = $disk.FileSystem

            if ($null -ne $volume) {
                if ($null -ne $volume.HealthStatus) {
                    $healthStatus = [string]$volume.HealthStatus
                }

                if ($null -ne $volume.OperationalStatus) {
                    $operationalStatus = ($volume.OperationalStatus | ForEach-Object { [string]$_ }) -join ', '
                }

                if (-not [string]::IsNullOrWhiteSpace($volume.FileSystemLabel)) {
                    $label = $volume.FileSystemLabel
                }

                if (-not [string]::IsNullOrWhiteSpace($volume.FileSystem)) {
                    $fileSystem = $volume.FileSystem
                }
            }

            $optimization = Get-OptimizationAnalysis -DriveLetter $driveLetter

            $overallStatus = 'Healthy'
            if (($healthStatus -eq 'Unhealthy') -or ($freePercent -lt 5)) {
                $overallStatus = 'Critical'
            }
            elseif (($healthStatus -eq 'Warning') -or ($freePercent -lt $LowFreeSpacePercent)) {
                $overallStatus = 'Warning'
            }

            if ($overallStatus -eq 'Healthy') {
                $summary.HealthyVolumes++
            }
            elseif ($overallStatus -eq 'Warning') {
                $summary.WarningVolumes++
                if ($freePercent -lt $LowFreeSpacePercent) {
                    $summary.LowFreeSpaceVolumes++
                }
            }
            else {
                $summary.CriticalVolumes++
                if ($freePercent -lt $LowFreeSpacePercent) {
                    $summary.LowFreeSpaceVolumes++
                }
            }

            $summary.VolumesReported++
            Write-Log -Message ("Reported drive {0}: with status {1}" -f $driveLetter, $overallStatus)

            $entries += [PSCustomObject]@{
                DriveLetter         = ('{0}:' -f $driveLetter)
                Label               = $label
                FileSystem          = $fileSystem
                HealthStatus        = $healthStatus
                OperationalStatus   = $operationalStatus
                OverallStatus       = $overallStatus
                SizeGB              = $sizeGB
                FreeGB              = $freeGB
                FreePercent         = $freePercent
                LowFreeSpacePercent = $LowFreeSpacePercent
                OptimizationStatus  = $optimization.OptimizationStatus
                OptimizationDetails = $optimization.OptimizationDetails
                ReportedAtUtc       = (Get-Date).ToUniversalTime().ToString('o')
            }
        }
        catch {
            $summary.Errors++
            Write-Log -Level 'ERROR' -Message ("Failed to process drive '{0}': {1}" -f $disk.DeviceID, $_.Exception.Message)
            continue
        }
    }

    return $entries
}

# Section: Writes the CSV report and returns the saved file path.
function Save-Report {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Entries
    )

    if ([string]::IsNullOrWhiteSpace($ReportPath)) {
        return $null
    }

    $reportFolder = Split-Path -Path $ReportPath -Parent
    if (-not [string]::IsNullOrWhiteSpace($reportFolder)) {
        Ensure-FolderExists -FolderPath $reportFolder
    }

    $Entries |
        Select-Object DriveLetter, Label, FileSystem, HealthStatus, OperationalStatus, OverallStatus, SizeGB, FreeGB, FreePercent, LowFreeSpacePercent, OptimizationStatus, OptimizationDetails, ReportedAtUtc |
        Export-Csv -LiteralPath $ReportPath -NoTypeInformation -Encoding UTF8

    return $ReportPath
}

# Section: Saves a report snapshot and manifest so rollback can restore the exported CSV later.
function Save-SnapshotManifest {
    param(
        [Parameter(Mandatory = $true)]
        [string]$WrittenReportPath
    )

    $runFolder = Join-Path $RollbackRoot ("disk-health-reporter-{0}" -f $runTimestamp)
    Ensure-FolderExists -FolderPath $runFolder

    $snapshotPath = Join-Path $runFolder ([System.IO.Path]::GetFileName($WrittenReportPath))
    Copy-Item -LiteralPath $WrittenReportPath -Destination $snapshotPath -Force -ErrorAction Stop

    $manifestPath = Join-Path $runFolder ("manifest-{0}.json" -f $runTimestamp)
    $manifest = [PSCustomObject]@{
        CreatedAtUtc       = (Get-Date).ToUniversalTime().ToString('o')
        ComputerName       = $env:COMPUTERNAME
        UserName           = $env:USERNAME
        LowFreeSpacePercent = $LowFreeSpacePercent
        ReportPath         = $WrittenReportPath
        SnapshotReportPath  = $snapshotPath
        Mode               = 'Audit'
    }

    $manifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
    $summary.SnapshotPath = $snapshotPath
    $summary.ManifestPath = $manifestPath
    Write-Log -Message ("Snapshot manifest created: {0}" -f $manifestPath)
    return $manifestPath
}

# Section: Runs the audit workflow and generates the disk health report.
function Invoke-Audit {
    Write-Log -Message ("Starting audit mode. LowFreeSpacePercent={0}, SkipOptimizationAnalysis={1}" -f $LowFreeSpacePercent, [bool]$SkipOptimizationAnalysis)

    $entries = Get-DiskHealthEntries

    if (-not $entries) {
        Write-Log -Level 'WARN' -Message 'No fixed drives were found to report.'
        return $entries
    }

    $reportRows = @($entries | Where-Object { $null -ne $_ -and $_.PSObject.Properties['DriveLetter'] } | Sort-Object DriveLetter)

    foreach ($entry in $reportRows) {
        # Section: Per-row try/catch keeps a malformed report row from stopping the audit.
        try {
            Write-Output ("{0} | {1} | {2} | {3} | {4} | {5}% free | Optimization: {6}" -f $entry.DriveLetter, $entry.OverallStatus, $entry.HealthStatus, $entry.FileSystem, $entry.Label, $entry.FreePercent, $entry.OptimizationStatus)
        }
        catch {
            $summary.Errors++
            Write-Log -Level 'ERROR' -Message ("Failed to write audit row for '{0}': {1}" -f $entry.PSObject.TypeNames[0], $_.Exception.Message)
            continue
        }
    }

    if ($DryRun) {
        $summary.DryRunWouldWriteReport++
        Write-Log -Message ("DRY RUN: Would write report to {0}" -f $ReportPath)
        return $entries
    }

    $writtenReportPath = Save-Report -Entries $entries
    if (-not [string]::IsNullOrWhiteSpace($writtenReportPath)) {
        $summary.ReportPath = $writtenReportPath
        Write-Log -Message ("Report written to: {0}" -f $writtenReportPath)
        Save-SnapshotManifest -WrittenReportPath $writtenReportPath | Out-Null
    }

    return $entries
}

# Section: Restores the last exported report snapshot from a rollback manifest.
function Invoke-Rollback {
    if ([string]::IsNullOrWhiteSpace($RollbackManifestPath)) {
        $RollbackManifestPath = Get-LatestManifestPath -RootPath $RollbackRoot
    }

    if ([string]::IsNullOrWhiteSpace($RollbackManifestPath) -or -not (Test-Path -LiteralPath $RollbackManifestPath)) {
        throw 'Rollback manifest not found. Provide -RollbackManifestPath or run audit mode first.'
    }

    $summary.ManifestPath = $RollbackManifestPath
    Write-Log -Message ("Starting rollback mode using manifest: {0}" -f $RollbackManifestPath)

    $manifest = Get-Content -LiteralPath $RollbackManifestPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    $snapshotPath = [string]$manifest.SnapshotReportPath

    if ([string]::IsNullOrWhiteSpace($snapshotPath) -or -not (Test-Path -LiteralPath $snapshotPath)) {
        $summary.Errors++
        Write-Log -Level 'ERROR' -Message 'Rollback snapshot not found in the manifest.'
        return
    }

    if (Test-Path -LiteralPath $RollbackReportPath) {
        $summary.RollbackSkipped++
        Write-Log -Message ("Rollback destination already exists. Skipping restore: {0}" -f $RollbackReportPath)
        return
    }

    $restoreFolder = Split-Path -Path $RollbackReportPath -Parent
    if (-not [string]::IsNullOrWhiteSpace($restoreFolder)) {
        Ensure-FolderExists -FolderPath $restoreFolder
    }

    Copy-Item -LiteralPath $snapshotPath -Destination $RollbackReportPath -Force -ErrorAction Stop
    $summary.RollbackRestored++
    $summary.ReportPath = $RollbackReportPath
    Write-Log -Message ("Rollback restored report to: {0}" -f $RollbackReportPath)
}

# Section: Writes the final summary so the operator can see the run outcome at a glance.
function Write-Summary {
    Write-Log -Message 'Run summary:'
    foreach ($key in $summary.Keys) {
        if ($key -in @('ReportPath', 'SnapshotPath', 'ManifestPath', 'LogFile')) {
            continue
        }

        Write-Log -Message ("{0}: {1}" -f $key, $summary[$key])
    }

    if (-not [string]::IsNullOrWhiteSpace($summary.ReportPath)) {
        Write-Log -Message ("ReportPath: {0}" -f $summary.ReportPath)
    }

    if (-not [string]::IsNullOrWhiteSpace($summary.SnapshotPath)) {
        Write-Log -Message ("SnapshotPath: {0}" -f $summary.SnapshotPath)
    }

    if (-not [string]::IsNullOrWhiteSpace($summary.ManifestPath)) {
        Write-Log -Message ("ManifestPath: {0}" -f $summary.ManifestPath)
    }

    Write-Log -Message ("LogFile: {0}" -f $summary.LogFile)
}

# Section: Executes the selected mode and ensures the final summary is always written.
try {
    if ($Rollback) {
        Invoke-Rollback
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
