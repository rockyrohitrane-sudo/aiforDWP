<#
.SYNOPSIS
Audits Windows startup programs and can disable matched entries with rollback support.

.DESCRIPTION
This PowerShell 5.1 script provides:
- Startup program auditing (registry + startup folders)
- Dry run preview
- Disable by program name
- Rollback from manifest
- Per-entry error handling with resilient execution
- Timestamped logging and end-of-run summary
#>

[CmdletBinding(DefaultParameterSetName = 'Audit')]
param(
    # Section: Audit/disable behavior flags.
    [Parameter(ParameterSetName = 'Audit')]
    [Parameter(ParameterSetName = 'Disable')]
    [switch]$DryRun,

    # Section: Enables disable mode and requires a name filter.
    [Parameter(ParameterSetName = 'Disable', Mandatory = $true)]
    [switch]$Disable,

    # Section: Startup program name filter used in disable mode.
    [Parameter(ParameterSetName = 'Disable', Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ProgramName,

    # Section: Enables rollback mode and restores from a manifest.
    [Parameter(ParameterSetName = 'Rollback', Mandatory = $true)]
    [switch]$Rollback,

    # Section: Optional rollback manifest path; latest is used when omitted.
    [Parameter(ParameterSetName = 'Rollback')]
    [string]$RollbackManifestPath,

    # Section: Folder for timestamped log files.
    [Parameter()]
    [string]$LogRoot = '',

    # Section: Folder for disable manifests used by rollback.
    [Parameter()]
    [string]$BackupRoot = ''
)

# Section: Initialize strict runtime behavior and mode metadata.
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$scriptRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
if ([string]::IsNullOrWhiteSpace($scriptRoot)) {
    $scriptRoot = (Get-Location).Path
}

if ([string]::IsNullOrWhiteSpace($LogRoot)) {
    $LogRoot = Join-Path $scriptRoot 'logs'
}

if ([string]::IsNullOrWhiteSpace($BackupRoot)) {
    $BackupRoot = Join-Path $scriptRoot 'rollback'
}

if (-not (Test-Path -LiteralPath $LogRoot)) {
    New-Item -Path $LogRoot -ItemType Directory -Force | Out-Null
}

if (-not (Test-Path -LiteralPath $BackupRoot)) {
    New-Item -Path $BackupRoot -ItemType Directory -Force | Out-Null
}

$runTimestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$modeLabel = if ($Rollback) { 'rollback' } elseif ($Disable) { 'disable' } else { 'audit' }
$logFile = Join-Path $LogRoot ("startup-program-auditor-{0}-{1}.log" -f $modeLabel, $runTimestamp)

# Section: Collects operation counters for end-of-run summary.
$summary = [ordered]@{
    Mode                    = $modeLabel
    EntriesEnumerated       = 0
    EntriesMatched          = 0
    EntriesDisabled         = 0
    EntriesRestored         = 0
    DryRunWouldDisable      = 0
    SkippedAlreadyDisabled  = 0
    SkippedAlreadyRestored  = 0
    SkippedMissingSource    = 0
    Errors                  = 0
    ManifestPath            = ''
    LogFile                 = $logFile
}

# Section: Writes timestamped messages to console and log file.
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

# Section: Maps registry value kind to New-ItemProperty type names.
function Convert-RegistryKindToPropertyType {
    param(
        [Parameter(Mandatory = $true)]
        [Microsoft.Win32.RegistryValueKind]$Kind
    )

    switch ($Kind) {
        'String' { return 'String' }
        'ExpandString' { return 'ExpandString' }
        'Binary' { return 'Binary' }
        'DWord' { return 'DWord' }
        'MultiString' { return 'MultiString' }
        'QWord' { return 'QWord' }
        default { return 'String' }
    }
}

# Section: Checks if a named registry value exists on a key path.
function Test-RegistryValueExists {
    param(
        [Parameter(Mandatory = $true)]
        [string]$KeyPath,

        [Parameter(Mandatory = $true)]
        [string]$ValueName
    )

    if (-not (Test-Path -LiteralPath $KeyPath)) {
        return $false
    }

    try {
        $null = Get-ItemPropertyValue -LiteralPath $KeyPath -Name $ValueName -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

# Section: Returns active startup registry entries for current and local machine scopes.
function Get-RegistryStartupEntries {
    $registryTargets = @(
        [PSCustomObject]@{ Scope = 'CurrentUser'; Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' },
        [PSCustomObject]@{ Scope = 'CurrentUser'; Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce' },
        [PSCustomObject]@{ Scope = 'LocalMachine'; Path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run' },
        [PSCustomObject]@{ Scope = 'LocalMachine'; Path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce' }
    )

    $entries = New-Object System.Collections.Generic.List[object]

    foreach ($target in $registryTargets) {
        try {
            if (-not (Test-Path -LiteralPath $target.Path)) {
                continue
            }

            $regItem = Get-Item -LiteralPath $target.Path -ErrorAction Stop
            foreach ($valueName in $regItem.GetValueNames()) {
                $valueData = $regItem.GetValue($valueName, $null, 'DoNotExpandEnvironmentNames')
                $kind = $regItem.GetValueKind($valueName)

                $entries.Add([PSCustomObject]@{
                    EntryType        = 'Registry'
                    Scope            = $target.Scope
                    ProgramName      = $valueName
                    Command          = [string]$valueData
                    Location         = $target.Path
                    RegistryValueName= $valueName
                    RegistryValueKind= $kind
                    DisabledLocation = (Join-Path $target.Path 'DWPStartupAuditorDisabled')
                    SourcePath       = $target.Path
                })
            }
        }
        catch {
            $summary.Errors++
            Write-Log -Level 'ERROR' -Message ("Failed to enumerate registry startup entries at '{0}': {1}" -f $target.Path, $_.Exception.Message)
            continue
        }
    }

    return $entries
}

# Section: Returns startup folder entries for current and all users.
function Get-StartupFolderEntries {
    $folderTargets = @(
        [PSCustomObject]@{ Scope = 'CurrentUser'; Path = [Environment]::GetFolderPath('Startup') },
        [PSCustomObject]@{ Scope = 'AllUsers'; Path = [Environment]::GetFolderPath('CommonStartup') }
    )

    $entries = New-Object System.Collections.Generic.List[object]

    foreach ($target in $folderTargets) {
        try {
            if ([string]::IsNullOrWhiteSpace($target.Path) -or -not (Test-Path -LiteralPath $target.Path)) {
                continue
            }

            $files = Get-ChildItem -LiteralPath $target.Path -File -Force -ErrorAction Stop
            foreach ($file in $files) {
                $entries.Add([PSCustomObject]@{
                    EntryType        = 'StartupFolder'
                    Scope            = $target.Scope
                    ProgramName      = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
                    Command          = $file.FullName
                    Location         = $target.Path
                    FilePath         = $file.FullName
                    DisabledLocation = (Join-Path $target.Path 'DWPStartupAuditorDisabled')
                    SourcePath       = $file.FullName
                })
            }
        }
        catch {
            $summary.Errors++
            Write-Log -Level 'ERROR' -Message ("Failed to enumerate startup folder entries at '{0}': {1}" -f $target.Path, $_.Exception.Message)
            continue
        }
    }

    return $entries
}

# Section: Aggregates all startup entries used by audit and disable operations.
function Get-StartupEntries {
    $registryEntries = Get-RegistryStartupEntries
    $folderEntries = Get-StartupFolderEntries
    return @($registryEntries + $folderEntries)
}

# Section: Finds the latest manifest in backup root for rollback convenience.
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

# Section: Persists disable actions to a manifest file for rollback operations.
function Save-DisableManifest {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Actions
    )

    if ($Actions.Count -eq 0) {
        return $null
    }

    $runFolder = Join-Path $BackupRoot ("disable-{0}" -f $runTimestamp)
    if (-not (Test-Path -LiteralPath $runFolder)) {
        New-Item -Path $runFolder -ItemType Directory -Force | Out-Null
    }

    $manifestPath = Join-Path $runFolder ("manifest-{0}.json" -f $runTimestamp)
    $manifest = [PSCustomObject]@{
        CreatedAtUtc       = (Get-Date).ToUniversalTime().ToString('o')
        ComputerName       = $env:COMPUTERNAME
        UserName           = $env:USERNAME
        DisableNameFilter  = $ProgramName
        Actions            = $Actions
    }

    $manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
    return $manifestPath
}

# Section: Runs audit mode and prints startup entries.
function Invoke-Audit {
    Write-Log -Message 'Starting audit mode.'

    $entries = Get-StartupEntries
    $summary.EntriesEnumerated = $entries.Count

    if ($entries.Count -eq 0) {
        Write-Log -Level 'WARN' -Message 'No startup entries were found.'
        return
    }

    if ($DryRun) {
        Write-Log -Message 'DRY RUN: Listing startup entries (no changes will be made).'
    }

    foreach ($entry in $entries | Sort-Object Scope, EntryType, ProgramName) {
        Write-Output ("{0} | {1} | {2} | {3}" -f $entry.Scope, $entry.EntryType, $entry.ProgramName, $entry.Command)
    }
}

# Section: Runs disable mode by moving entries to disabled locations.
function Invoke-Disable {
    Write-Log -Message ("Starting disable mode. ProgramName filter='{0}', DryRun={1}" -f $ProgramName, [bool]$DryRun)

    $entries = Get-StartupEntries
    $summary.EntriesEnumerated = $entries.Count

    $matchedEntries = @($entries | Where-Object { $_.ProgramName -like ("*{0}*" -f $ProgramName) })
    $summary.EntriesMatched = $matchedEntries.Count

    if ($matchedEntries.Count -eq 0) {
        Write-Log -Level 'WARN' -Message ("No startup entries matched '{0}'." -f $ProgramName)
        return
    }

    $actions = New-Object System.Collections.Generic.List[object]

    foreach ($entry in $matchedEntries) {
        # Section: Per-entry try/catch ensures one failure does not stop the run.
        try {
            if ($entry.EntryType -eq 'Registry') {
                $sourceKey = $entry.SourcePath
                $destKey = $entry.DisabledLocation
                $valueName = $entry.RegistryValueName

                $sourceExists = Test-RegistryValueExists -KeyPath $sourceKey -ValueName $valueName
                $destExists = Test-RegistryValueExists -KeyPath $destKey -ValueName $valueName

                if (-not $sourceExists -and $destExists) {
                    $summary.SkippedAlreadyDisabled++
                    Write-Log -Message ("Already disabled (registry): {0}" -f $valueName)
                    continue
                }

                if (-not $sourceExists -and -not $destExists) {
                    $summary.SkippedMissingSource++
                    Write-Log -Level 'WARN' -Message ("Source startup value missing (registry): {0} at {1}" -f $valueName, $sourceKey)
                    continue
                }

                if ($DryRun) {
                    $summary.DryRunWouldDisable++
                    Write-Log -Message ("DRY RUN: Would disable registry startup entry '{0}' from '{1}'" -f $valueName, $sourceKey)
                    continue
                }

                if (-not (Test-Path -LiteralPath $destKey)) {
                    New-Item -Path $destKey -Force | Out-Null
                }

                $valueData = Get-ItemPropertyValue -LiteralPath $sourceKey -Name $valueName -ErrorAction Stop
                $propertyType = Convert-RegistryKindToPropertyType -Kind $entry.RegistryValueKind

                New-ItemProperty -LiteralPath $destKey -Name $valueName -Value $valueData -PropertyType $propertyType -Force | Out-Null
                Remove-ItemProperty -LiteralPath $sourceKey -Name $valueName -ErrorAction Stop

                $summary.EntriesDisabled++
                Write-Log -Message ("Disabled registry startup entry '{0}' by moving it to '{1}'" -f $valueName, $destKey)

                $actions.Add([PSCustomObject]@{
                    ActionType          = 'RegistryMove'
                    ProgramName         = $entry.ProgramName
                    SourceKey           = $sourceKey
                    SourceValueName     = $valueName
                    DestinationKey      = $destKey
                    RegistryValueKind   = [string]$entry.RegistryValueKind
                })
            }
            elseif ($entry.EntryType -eq 'StartupFolder') {
                $sourceFile = $entry.FilePath
                $destFolder = $entry.DisabledLocation
                $destFile = Join-Path $destFolder ([System.IO.Path]::GetFileName($sourceFile))

                if ((-not (Test-Path -LiteralPath $sourceFile)) -and (Test-Path -LiteralPath $destFile)) {
                    $summary.SkippedAlreadyDisabled++
                    Write-Log -Message ("Already disabled (startup folder): {0}" -f $entry.ProgramName)
                    continue
                }

                if (-not (Test-Path -LiteralPath $sourceFile) -and -not (Test-Path -LiteralPath $destFile)) {
                    $summary.SkippedMissingSource++
                    Write-Log -Level 'WARN' -Message ("Source startup file missing: {0}" -f $sourceFile)
                    continue
                }

                if ($DryRun) {
                    $summary.DryRunWouldDisable++
                    Write-Log -Message ("DRY RUN: Would move startup file '{0}' to '{1}'" -f $sourceFile, $destFile)
                    continue
                }

                if (-not (Test-Path -LiteralPath $destFolder)) {
                    New-Item -Path $destFolder -ItemType Directory -Force | Out-Null
                }

                if (Test-Path -LiteralPath $destFile) {
                    $base = [System.IO.Path]::GetFileNameWithoutExtension($destFile)
                    $ext = [System.IO.Path]::GetExtension($destFile)
                    $destFile = Join-Path $destFolder ("{0}-{1}{2}" -f $base, $runTimestamp, $ext)
                }

                Move-Item -LiteralPath $sourceFile -Destination $destFile -Force -ErrorAction Stop
                $summary.EntriesDisabled++
                Write-Log -Message ("Disabled startup file '{0}' by moving it to '{1}'" -f $sourceFile, $destFile)

                $actions.Add([PSCustomObject]@{
                    ActionType      = 'StartupFolderMove'
                    ProgramName     = $entry.ProgramName
                    SourcePath      = $sourceFile
                    DestinationPath = $destFile
                })
            }
        }
        catch {
            $summary.Errors++
            Write-Log -Level 'ERROR' -Message ("Failed to disable entry '{0}': {1}" -f $entry.ProgramName, $_.Exception.Message)
            continue
        }
    }

    if (-not $DryRun) {
        $manifestPath = Save-DisableManifest -Actions $actions.ToArray()
        if (-not [string]::IsNullOrWhiteSpace($manifestPath)) {
            $summary.ManifestPath = $manifestPath
            Write-Log -Message ("Rollback manifest created: {0}" -f $manifestPath)
        }
        else {
            Write-Log -Message 'No manifest written because no entries were disabled.'
        }
    }
}

# Section: Restores disabled entries from a rollback manifest.
function Invoke-Rollback {
    if ([string]::IsNullOrWhiteSpace($RollbackManifestPath)) {
        $RollbackManifestPath = Get-LatestManifestPath -RootPath $BackupRoot
    }

    if ([string]::IsNullOrWhiteSpace($RollbackManifestPath) -or -not (Test-Path -LiteralPath $RollbackManifestPath)) {
        throw "Rollback manifest not found. Provide -RollbackManifestPath or run a disable action first."
    }

    $summary.ManifestPath = $RollbackManifestPath
    Write-Log -Message ("Starting rollback mode using manifest: {0}" -f $RollbackManifestPath)

    $manifest = Get-Content -LiteralPath $RollbackManifestPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    $actions = @($manifest.Actions)

    if ($actions.Count -eq 0) {
        Write-Log -Level 'WARN' -Message 'Manifest has no actions to rollback.'
        return
    }

    $summary.EntriesEnumerated = $actions.Count

    foreach ($action in $actions) {
        # Section: Per-action try/catch keeps rollback resilient per item.
        try {
            if ($action.ActionType -eq 'RegistryMove') {
                $sourceKey = [string]$action.SourceKey
                $sourceValueName = [string]$action.SourceValueName
                $destKey = [string]$action.DestinationKey
                $propertyType = [string]$action.RegistryValueKind

                $sourceExists = Test-RegistryValueExists -KeyPath $sourceKey -ValueName $sourceValueName
                $destExists = Test-RegistryValueExists -KeyPath $destKey -ValueName $sourceValueName

                if ($sourceExists) {
                    $summary.SkippedAlreadyRestored++
                    Write-Log -Message ("Already restored (registry): {0}" -f $sourceValueName)
                    continue
                }

                if (-not $destExists) {
                    $summary.SkippedMissingSource++
                    Write-Log -Level 'WARN' -Message ("Disabled registry copy not found for rollback: {0}" -f $sourceValueName)
                    continue
                }

                if (-not (Test-Path -LiteralPath $sourceKey)) {
                    New-Item -Path $sourceKey -Force | Out-Null
                }

                $valueData = Get-ItemPropertyValue -LiteralPath $destKey -Name $sourceValueName -ErrorAction Stop
                $propertyName = Convert-RegistryKindToPropertyType -Kind ([Microsoft.Win32.RegistryValueKind]::$propertyType)

                New-ItemProperty -LiteralPath $sourceKey -Name $sourceValueName -Value $valueData -PropertyType $propertyName -Force | Out-Null
                Remove-ItemProperty -LiteralPath $destKey -Name $sourceValueName -ErrorAction Stop

                $summary.EntriesRestored++
                Write-Log -Message ("Restored registry startup entry '{0}' to '{1}'" -f $sourceValueName, $sourceKey)
            }
            elseif ($action.ActionType -eq 'StartupFolderMove') {
                $sourcePath = [string]$action.SourcePath
                $destPath = [string]$action.DestinationPath

                if (Test-Path -LiteralPath $sourcePath) {
                    $summary.SkippedAlreadyRestored++
                    Write-Log -Message ("Already restored (startup folder): {0}" -f $sourcePath)
                    continue
                }

                if (-not (Test-Path -LiteralPath $destPath)) {
                    $summary.SkippedMissingSource++
                    Write-Log -Level 'WARN' -Message ("Disabled startup file not found for rollback: {0}" -f $destPath)
                    continue
                }

                $parent = Split-Path -Path $sourcePath -Parent
                if (-not (Test-Path -LiteralPath $parent)) {
                    New-Item -Path $parent -ItemType Directory -Force | Out-Null
                }

                Move-Item -LiteralPath $destPath -Destination $sourcePath -Force -ErrorAction Stop
                $summary.EntriesRestored++
                Write-Log -Message ("Restored startup file '{0}'" -f $sourcePath)
            }
        }
        catch {
            $summary.Errors++
            Write-Log -Level 'ERROR' -Message ("Failed to rollback action for '{0}': {1}" -f $action.ProgramName, $_.Exception.Message)
            continue
        }
    }
}

# Section: Main execution flow dispatches the selected mode.
try {
    if ($Rollback) {
        Invoke-Rollback
    }
    elseif ($Disable) {
        Invoke-Disable
    }
    else {
        Invoke-Audit
    }
}
catch {
    $summary.Errors++
    Write-Log -Level 'ERROR' -Message ("Fatal script error: {0}" -f $_.Exception.Message)
}

# Section: Print structured summary and set process exit code.
Write-Output ''
Write-Output '========== Summary =========='
$summary.GetEnumerator() | ForEach-Object {
    Write-Output ("{0}: {1}" -f $_.Key, $_.Value)
}
Write-Output '============================='

if ($summary.Errors -gt 0) {
    exit 1
}

exit 0
