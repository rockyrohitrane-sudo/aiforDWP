<#
.SYNOPSIS
Collects read-only incident evidence from a Windows 10 or Windows 11 workstation.

.DESCRIPTION
Collects local endpoint evidence for or against the hypothesis that a Friday document
management system deployment caused slow logons, logon failures, poor performance,
missing desktop shortcuts, or related endpoint-side access anomalies on Floor 6.

This script is designed for first-response triage by Service Desk or engineering staff.
It is read-only and does not modify system configuration, registry values, services,
processes, or deployed software.

.PARAMETER OutputRoot
Root folder where the timestamped evidence folder will be created.
Defaults to an Evidence output folder beneath the script directory.

.PARAMETER AppNamePatterns
One or more application name fragments used to match deployment-related software,
services, processes, scheduled tasks, and event log messages.

.PARAMETER DeploymentStart
Timestamp used to identify artifacts plausibly linked to the Friday deployment window.
Defaults to the previous Friday at 12:00 local time.

.PARAMETER EventLogDays
How many days of recent event logs to inspect when an explicit deployment window filter
does not fully populate the requested evidence.

.PARAMETER DryRun
Shows what the script would collect and where it would write output, without creating
folders or files.

.EXAMPLE
.\collect-floor6-deployment-evidence.ps1 -DryRun

.EXAMPLE
.\collect-floor6-deployment-evidence.ps1 -AppNamePatterns 'iManage','NetDocuments' -OutputRoot 'C:\IR'

.NOTES
PowerShell 5.1 compatible.
Recommended: run from an elevated PowerShell session for broader event log access.
#>

[CmdletBinding()]
param(
    [string]$OutputRoot,
    [string[]]$AppNamePatterns = @('Document Management', 'DMS', 'iManage', 'NetDocuments', 'Worldox'),
    [datetime]$DeploymentStart,
    [ValidateRange(1, 30)]
    [int]$EventLogDays = 7,
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:InvokedScriptPath = $PSCommandPath
$script:EvidenceRoot = $null
$script:Warnings = @()
$script:TranscriptStarted = $false

function Write-Status {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Write-Host ('[{0}] [{1}] {2}' -f $timestamp, $Level, $Message)
}

function Add-CollectionWarning {
    param(
        [string]$Section,
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )

    $warningRecord = [pscustomobject]@{
        Timestamp             = Get-Date
        Section               = $Section
        Message               = $ErrorRecord.Exception.Message
        FullyQualifiedErrorId = $ErrorRecord.FullyQualifiedErrorId
    }

    $script:Warnings += $warningRecord
    Write-Status -Level 'WARN' -Message ('{0}: {1}' -f $Section, $ErrorRecord.Exception.Message)
}

function Invoke-CollectionStep {
    param(
        [string]$Section,
        [scriptblock]$ScriptBlock
    )

    try {
        & $ScriptBlock
    }
    catch {
        Add-CollectionWarning -Section $Section -ErrorRecord $_
        $null
    }
}

function Get-ScriptDirectory {
    $scriptPath = $script:InvokedScriptPath
    if ([string]::IsNullOrWhiteSpace($scriptPath)) {
        return (Get-Location).Path
    }

    return (Split-Path -Path $scriptPath -Parent)
}

function Get-DefaultDeploymentStart {
    param(
        [datetime]$ReferenceDate = (Get-Date)
    )

    $daysBack = (([int]$ReferenceDate.DayOfWeek - [int][System.DayOfWeek]::Friday) + 7) % 7
    if ($daysBack -eq 0 -and $ReferenceDate.TimeOfDay -lt [TimeSpan]::FromHours(12)) {
        $daysBack = 7
    }

    return $ReferenceDate.Date.AddDays(-1 * $daysBack).AddHours(12)
}

function Ensure-Directory {
    param(
        [string]$Path
    )

    if ($DryRun) {
        Write-Status -Message ('DryRun: would create directory {0}' -f $Path)
        return
    }

    if (-not (Test-Path -Path $Path)) {
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
    }
}

function Initialize-EvidenceFolder {
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $folderName = 'Evidence-Floor6-{0}-{1}' -f $env:COMPUTERNAME, $timestamp

    Ensure-Directory -Path $OutputRoot
    $script:EvidenceRoot = Join-Path -Path $OutputRoot -ChildPath $folderName
    Ensure-Directory -Path $script:EvidenceRoot
}

function Save-Json {
    param(
        [string]$FileName,
        $Data,
        [int]$Depth = 6
    )

    $path = Join-Path -Path $script:EvidenceRoot -ChildPath $FileName
    if ($DryRun) {
        Write-Status -Message ('DryRun: would write JSON {0}' -f $path)
        return
    }

    $Data |
        ConvertTo-Json -Depth $Depth |
        Out-File -FilePath $path -Encoding utf8
}

function Save-Csv {
    param(
        [string]$FileName,
        [object[]]$Data
    )

    $path = Join-Path -Path $script:EvidenceRoot -ChildPath $FileName
    if ($DryRun) {
        Write-Status -Message ('DryRun: would write CSV {0}' -f $path)
        return
    }

    @($Data) | Export-Csv -Path $path -NoTypeInformation -Encoding UTF8
}

function Save-Text {
    param(
        [string]$FileName,
        [string[]]$Lines
    )

    $path = Join-Path -Path $script:EvidenceRoot -ChildPath $FileName
    if ($DryRun) {
        Write-Status -Message ('DryRun: would write text {0}' -f $path)
        return
    }

    $Lines | Out-File -FilePath $path -Encoding utf8
}

function Convert-BytesToGB {
    param(
        [Nullable[double]]$Bytes
    )

    if (-not $Bytes) {
        return $null
    }

    return [math]::Round(($Bytes / 1GB), 2)
}

function Convert-InstallDate {
    param(
        [string]$InstallDate
    )

    if ([string]::IsNullOrWhiteSpace($InstallDate)) {
        return $null
    }

    if ($InstallDate -match '^\d{8}$') {
        try {
            return [datetime]::ParseExact($InstallDate, 'yyyyMMdd', $null)
        }
        catch {
            return $null
        }
    }

    return $null
}

function Get-ObjectPropertyValue {
    param(
        [object]$InputObject,
        [string]$PropertyName
    )

    if ($null -eq $InputObject -or [string]::IsNullOrWhiteSpace($PropertyName)) {
        return $null
    }

    $property = $InputObject.PSObject.Properties[$PropertyName]
    if ($null -eq $property) {
        return $null
    }

    return $property.Value
}

function Test-PatternMatch {
    param(
        [string]$Value,
        [string[]]$Patterns
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $false
    }

    foreach ($pattern in $Patterns) {
        if (-not [string]::IsNullOrWhiteSpace($pattern) -and $Value -like ('*{0}*' -f $pattern)) {
            return $true
        }
    }

    return $false
}

function Get-ComputerIdentityArtifact {
    $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
    $operatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem
    $bios = Get-CimInstance -ClassName Win32_BIOS
    $currentIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()

    [pscustomobject]@{
        CollectedAtUtc        = (Get-Date).ToUniversalTime().ToString('o')
        ComputerName          = $env:COMPUTERNAME
        Domain                = $computerSystem.Domain
        PartOfDomain          = $computerSystem.PartOfDomain
        Manufacturer          = $computerSystem.Manufacturer
        Model                 = $computerSystem.Model
        LoggedOnConsoleUser   = $computerSystem.UserName
        CurrentSecurityUser   = $currentIdentity.Name
        CurrentUserSid        = $currentIdentity.User.Value
        OSName                = $operatingSystem.Caption
        OSVersion             = $operatingSystem.Version
        OSBuildNumber         = $operatingSystem.BuildNumber
        InstallDate           = $operatingSystem.InstallDate
        LastBootUpTime        = $operatingSystem.LastBootUpTime
        SerialNumber          = $bios.SerialNumber
        BIOSVersion           = ($bios.SMBIOSBIOSVersion -join '; ')
        PowerShellVersion     = $PSVersionTable.PSVersion.ToString()
        IsElevated            = ([bool](([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)))
    }
}

function Get-InstalledProgramsArtifact {
    $registryPaths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )

    $results = @()
    foreach ($path in $registryPaths) {
        try {
            $items = Get-ItemProperty -Path $path -ErrorAction Stop | Where-Object {
                -not [string]::IsNullOrWhiteSpace((Get-ObjectPropertyValue -InputObject $_ -PropertyName 'DisplayName'))
            }
            foreach ($item in $items) {
                $displayName = Get-ObjectPropertyValue -InputObject $item -PropertyName 'DisplayName'
                $displayVersion = Get-ObjectPropertyValue -InputObject $item -PropertyName 'DisplayVersion'
                $publisher = Get-ObjectPropertyValue -InputObject $item -PropertyName 'Publisher'
                $installDateRaw = Get-ObjectPropertyValue -InputObject $item -PropertyName 'InstallDate'
                $installLocation = Get-ObjectPropertyValue -InputObject $item -PropertyName 'InstallLocation'
                $uninstallString = Get-ObjectPropertyValue -InputObject $item -PropertyName 'UninstallString'
                $quietUninstallString = Get-ObjectPropertyValue -InputObject $item -PropertyName 'QuietUninstallString'
                $parsedInstallDate = Convert-InstallDate -InstallDate $installDateRaw

                $results += [pscustomobject]@{
                    DisplayName      = $displayName
                    DisplayVersion   = $displayVersion
                    Publisher        = $publisher
                    InstallDateRaw   = $installDateRaw
                    InstallDate      = $parsedInstallDate
                    InstallLocation  = $installLocation
                    UninstallString  = $uninstallString
                    QuietUninstall   = $quietUninstallString
                    RegistrySource   = $path
                }
            }
        }
        catch {
            Add-CollectionWarning -Section ('InstalledPrograms:{0}' -f $path) -ErrorRecord $_
        }
    }

    $results |
        Sort-Object -Property DisplayName, DisplayVersion, Publisher -Unique
}

function Get-RecentlyInstalledProgramsArtifact {
    param(
        [object[]]$InstalledPrograms
    )

    @($InstalledPrograms | Where-Object { $_.InstallDate -and $_.InstallDate -ge $DeploymentStart } | Sort-Object -Property InstallDate -Descending)
}

function Get-MatchedProgramsArtifact {
    param(
        [object[]]$InstalledPrograms
    )

    @($InstalledPrograms | Where-Object {
            (Test-PatternMatch -Value $_.DisplayName -Patterns $AppNamePatterns) -or
            (Test-PatternMatch -Value $_.Publisher -Patterns $AppNamePatterns) -or
            (Test-PatternMatch -Value $_.InstallLocation -Patterns $AppNamePatterns)
        } | Sort-Object -Property DisplayName, DisplayVersion -Unique)
}

function Get-StartupApplicationsArtifact {
    $startupItems = Get-CimInstance -ClassName Win32_StartupCommand | ForEach-Object {
        [pscustomobject]@{
            Name         = $_.Name
            Command      = $_.Command
            Location     = $_.Location
            User         = $_.User
            UserSID      = $_.UserSID
            MatchedApp   = (Test-PatternMatch -Value ($_.Name + ' ' + $_.Command) -Patterns $AppNamePatterns)
        }
    }

    @($startupItems | Sort-Object -Property Name, Location -Unique)
}

function Get-ScheduledTasksArtifact {
    $tasks = Get-ScheduledTask | ForEach-Object {
        $taskActions = @($_.Actions)
        $taskTriggers = @($_.Triggers)

        $actions = @($taskActions | Where-Object { $null -ne $_ } | ForEach-Object {
                $execute = Get-ObjectPropertyValue -InputObject $_ -PropertyName 'Execute'
                $arguments = Get-ObjectPropertyValue -InputObject $_ -PropertyName 'Arguments'
                if ([string]::IsNullOrWhiteSpace($arguments)) {
                    $execute
                }
                else {
                    '{0} {1}' -f $execute, $arguments
                }
            }) -join '; '

        $triggers = @($taskTriggers | Where-Object { $null -ne $_ } | ForEach-Object { $_.ToString() }) -join '; '

        [pscustomobject]@{
            TaskName     = $_.TaskName
            TaskPath     = $_.TaskPath
            State        = $_.State
            Author       = $_.Author
            Description  = $_.Description
            Actions      = $actions
            Triggers     = $triggers
            MatchedApp   = (Test-PatternMatch -Value ($_.TaskName + ' ' + $actions + ' ' + $_.TaskPath) -Patterns $AppNamePatterns)
        }
    }

    @($tasks | Sort-Object -Property TaskPath, TaskName)
}

function Get-RunningProcessesArtifact {
    $processes = @()
    foreach ($process in Get-Process) {
        try {
            $path = $null
            try {
                $path = $process.Path
            }
            catch {
                $path = $null
            }

            $processes += [pscustomobject]@{
                Name           = $process.ProcessName
                Id             = $process.Id
                CPUSeconds     = if ($null -ne $process.CPU) { [math]::Round($process.CPU, 2) } else { $null }
                WorkingSetMB   = [math]::Round(($process.WorkingSet64 / 1MB), 2)
                VirtualMemoryMB = [math]::Round(($process.VirtualMemorySize64 / 1MB), 2)
                StartTime      = $(try { $process.StartTime } catch { $null })
                Path           = $path
                Company        = $(try { $process.Company } catch { $null })
                MatchedApp     = (Test-PatternMatch -Value ($process.ProcessName + ' ' + $path + ' ' + $(try { $process.Company } catch { '' })) -Patterns $AppNamePatterns)
            }
        }
        catch {
            continue
        }
    }

    @($processes | Sort-Object -Property Name, Id)
}

function Get-PerformanceSnapshotArtifact {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $processors = Get-CimInstance -ClassName Win32_Processor
    $disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DriveType = 3' | ForEach-Object {
        [pscustomobject]@{
            Drive         = $_.DeviceID
            SizeGB        = Convert-BytesToGB -Bytes $_.Size
            FreeGB        = Convert-BytesToGB -Bytes $_.FreeSpace
            FreePercent   = if ($_.Size -gt 0) { [math]::Round((($_.FreeSpace / $_.Size) * 100), 2) } else { $null }
        }
    }

    [pscustomobject]@{
        SnapshotTimeUtc     = (Get-Date).ToUniversalTime().ToString('o')
        CPUAverageLoad      = [math]::Round((($processors | Measure-Object -Property LoadPercentage -Average).Average), 2)
        MemoryTotalGB       = [math]::Round(($os.TotalVisibleMemorySize / 1MB), 2)
        MemoryFreeGB        = [math]::Round(($os.FreePhysicalMemory / 1MB), 2)
        MemoryUsedPercent   = if ($os.TotalVisibleMemorySize -gt 0) {
            [math]::Round(((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100), 2)
        }
        else {
            $null
        }
        Disks               = @($disks)
    }
}

function Get-DeploymentServicesArtifact {
    $services = Get-CimInstance -ClassName Win32_Service | Where-Object {
        (Test-PatternMatch -Value $_.Name -Patterns $AppNamePatterns) -or
        (Test-PatternMatch -Value $_.DisplayName -Patterns $AppNamePatterns) -or
        (Test-PatternMatch -Value $_.PathName -Patterns $AppNamePatterns)
    } | ForEach-Object {
        [pscustomobject]@{
            Name           = $_.Name
            DisplayName    = $_.DisplayName
            State          = $_.State
            StartMode      = $_.StartMode
            StartName      = $_.StartName
            PathName       = $_.PathName
            ProcessId      = $_.ProcessId
        }
    }

    @($services | Sort-Object -Property DisplayName, Name)
}

function Convert-WinEventRecord {
    param(
        [System.Diagnostics.Eventing.Reader.EventRecord]$EventRecord
    )

    [pscustomobject]@{
        TimeCreated      = $EventRecord.TimeCreated
        LogName          = $EventRecord.LogName
        Id               = $EventRecord.Id
        LevelDisplayName = $EventRecord.LevelDisplayName
        ProviderName     = $EventRecord.ProviderName
        UserId           = if ($EventRecord.UserId) { $EventRecord.UserId.Value } else { $null }
        MachineName      = $EventRecord.MachineName
        Message          = $EventRecord.FormatDescription()
    }
}

function Get-EventsByFilter {
    param(
        [hashtable]$FilterHashtable,
        [int]$MaxEvents = 200
    )

    try {
        $events = Get-WinEvent -FilterHashtable $FilterHashtable -MaxEvents $MaxEvents | ForEach-Object {
            Convert-WinEventRecord -EventRecord $_
        }

        return @($events)
    }
    catch {
        $message = $_.Exception.Message
        if ($message -like 'No events were found*' -or $message -like 'There is not an event log*') {
            return @()
        }

        throw
    }
}

function Get-CombinedEventArtifact {
    param(
        [object[]]$EventSets
    )

    @($EventSets | Where-Object { $null -ne $_ } | Sort-Object -Property TimeCreated -Descending)
}

function Get-EventArtifacts {
    $recentStart = (Get-Date).AddDays(-1 * $EventLogDays)
    if ($DeploymentStart -gt $recentStart) {
        $recentStart = $DeploymentStart
    }

    $systemErrors = Invoke-CollectionStep -Section 'EventLogs:SystemErrors' -ScriptBlock {
        Get-EventsByFilter -FilterHashtable @{ LogName = 'System'; StartTime = $recentStart; Level = 2 } -MaxEvents 200
    }

    $applicationErrors = Invoke-CollectionStep -Section 'EventLogs:ApplicationErrors' -ScriptBlock {
        Get-EventsByFilter -FilterHashtable @{ LogName = 'Application'; StartTime = $recentStart; Level = 2 } -MaxEvents 200
    }

    $securityLogonEvents = Invoke-CollectionStep -Section 'EventLogs:SecurityLogons' -ScriptBlock {
        Get-EventsByFilter -FilterHashtable @{ LogName = 'Security'; StartTime = $recentStart; Id = @(4624, 4625, 4634, 4647, 4771, 4776) } -MaxEvents 200
    }

    $systemAuthEvents = Invoke-CollectionStep -Section 'EventLogs:SystemAuth' -ScriptBlock {
        Get-EventsByFilter -FilterHashtable @{ LogName = 'System'; StartTime = $recentStart; Id = @(5719, 1058, 1030, 1129) } -MaxEvents 200
    }

    $groupPolicyEvents = Invoke-CollectionStep -Section 'EventLogs:GroupPolicy' -ScriptBlock {
        Get-EventsByFilter -FilterHashtable @{ LogName = 'Microsoft-Windows-GroupPolicy/Operational'; StartTime = $recentStart } -MaxEvents 200
    }

    $userProfileEvents = Invoke-CollectionStep -Section 'EventLogs:UserProfileOperational' -ScriptBlock {
        Get-EventsByFilter -FilterHashtable @{ LogName = 'Microsoft-Windows-User Profiles Service/Operational'; StartTime = $recentStart } -MaxEvents 200
    }

    $applicationMatches = @(@($applicationErrors) | Where-Object {
            (Test-PatternMatch -Value $_.ProviderName -Patterns $AppNamePatterns) -or
            (Test-PatternMatch -Value $_.Message -Patterns $AppNamePatterns)
        })

    [pscustomobject]@{
        SystemErrors          = @($systemErrors)
        ApplicationErrors     = @($applicationErrors)
        LoginRelatedEvents    = Get-CombinedEventArtifact -EventSets @($securityLogonEvents + $systemAuthEvents)
        GroupPolicyEvents     = @($groupPolicyEvents)
        UserProfileEvents     = @($userProfileEvents)
        ApplicationMatchEvents = @($applicationMatches)
    }
}

function Get-GpResultArtifact {
    $computerOutput = @()
    $userOutput = @()

    try {
        $computerOutput = @(& gpresult /R /Scope Computer 2>&1)
    }
    catch {
        $computerOutput = @('gpresult computer scope failed: {0}' -f $_.Exception.Message)
    }

    try {
        $userOutput = @(& gpresult /R /Scope User 2>&1)
    }
    catch {
        $userOutput = @('gpresult user scope failed: {0}' -f $_.Exception.Message)
    }

    [pscustomobject]@{
        Computer = $computerOutput
        User     = $userOutput
    }
}

function Get-UserProfileArtifact {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $sid = $identity.User.Value
    $userProfile = Get-CimInstance -ClassName Win32_UserProfile | Where-Object { $_.SID -eq $sid }
    $profileListPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\{0}' -f $sid
    $profileList = $null

    if (Test-Path -Path $profileListPath) {
        $profileList = Get-ItemProperty -Path $profileListPath
    }

    $shellFolders = Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders'
    $registryDesktopPath = Get-ObjectPropertyValue -InputObject $shellFolders -PropertyName 'Desktop'
    $desktopPath = [Environment]::GetFolderPath('Desktop')
    $publicDesktop = [Environment]::GetFolderPath('CommonDesktopDirectory')
    $profileDirectory = [Environment]::GetFolderPath('UserProfile')

    $isTemporarySignal = $false
    $profileState = Get-ObjectPropertyValue -InputObject $profileList -PropertyName 'State'
    $profileRefCount = Get-ObjectPropertyValue -InputObject $profileList -PropertyName 'RefCount'
    $profileImagePath = Get-ObjectPropertyValue -InputObject $profileList -PropertyName 'ProfileImagePath'

    if ($profileList -and $null -ne $profileState -and [int]$profileState -ne 0) {
        $isTemporarySignal = $true
    }
    if ($desktopPath -like 'C:\Users\TEMP*') {
        $isTemporarySignal = $true
    }

    [pscustomobject]@{
        UserName                    = $identity.Name
        UserSid                     = $sid
        LocalProfilePath            = $profileDirectory
        Win32ProfileLocalPath       = if ($userProfile) { $userProfile.LocalPath } else { $null }
        Win32ProfileLoaded          = if ($userProfile) { $userProfile.Loaded } else { $null }
        Win32ProfileLastUseTime     = if ($userProfile) { $userProfile.LastUseTime } else { $null }
        Win32ProfileSpecial         = if ($userProfile) { $userProfile.Special } else { $null }
        ProfileImagePath            = $profileImagePath
        ProfileState                = $profileState
        ProfileRefCount             = $profileRefCount
        DesktopPath                 = $desktopPath
        RegistryDesktopPath         = $registryDesktopPath
        PublicDesktopPath           = $publicDesktop
        DesktopExists               = (Test-Path -Path $desktopPath)
        PublicDesktopExists         = (Test-Path -Path $publicDesktop)
        FolderRedirectionLikely     = ($registryDesktopPath -and ($registryDesktopPath -notlike ('{0}*' -f $profileDirectory)))
        OneDriveRedirectionLikely   = ($registryDesktopPath -like '*OneDrive*')
        TemporaryProfileSignal      = $isTemporarySignal
    }
}

function Get-ShortcutInventoryArtifact {
    param(
        [string]$DesktopPath,
        [string]$PublicDesktopPath
    )

    $targets = @(
        [pscustomobject]@{ Scope = 'CurrentUser'; Path = $DesktopPath },
        [pscustomobject]@{ Scope = 'Public'; Path = $PublicDesktopPath }
    )

    $shortcutReader = $null
    try {
        $shortcutReader = New-Object -ComObject WScript.Shell
    }
    catch {
        Add-CollectionWarning -Section 'ShortcutInventory:ComObject' -ErrorRecord $_
    }

    $results = @()
    foreach ($target in $targets) {
        if ([string]::IsNullOrWhiteSpace($target.Path) -or -not (Test-Path -Path $target.Path)) {
            continue
        }

        $files = Get-ChildItem -Path $target.Path -Recurse -Force -File -ErrorAction Stop |
            Where-Object { $_.Extension -in '.lnk', '.url' }

        foreach ($file in $files) {
            $resolvedTarget = $null
            if ($file.Extension -eq '.lnk' -and $shortcutReader) {
                try {
                    $resolvedTarget = $shortcutReader.CreateShortcut($file.FullName).TargetPath
                }
                catch {
                    $resolvedTarget = $null
                }
            }
            elseif ($file.Extension -eq '.url') {
                try {
                    $urlLine = Get-Content -Path $file.FullName -ErrorAction Stop | Where-Object { $_ -like 'URL=*' } | Select-Object -First 1
                    if ($urlLine) {
                        $resolvedTarget = $urlLine.Substring(4)
                    }
                }
                catch {
                    $resolvedTarget = $null
                }
            }

            $results += [pscustomobject]@{
                Scope            = $target.Scope
                Name             = $file.Name
                Extension        = $file.Extension
                FullName         = $file.FullName
                Directory        = $file.DirectoryName
                CreationTime     = $file.CreationTime
                LastWriteTime    = $file.LastWriteTime
                Length           = $file.Length
                ResolvedTarget   = $resolvedTarget
                ChangedSinceDeployment = ($file.LastWriteTime -ge $DeploymentStart)
                MatchedApp       = (Test-PatternMatch -Value ($file.Name + ' ' + $resolvedTarget) -Patterns $AppNamePatterns)
            }
        }
    }

    @($results | Sort-Object -Property Scope, FullName)
}

function Get-NetworkArtifact {
    $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
    $dnsServers = @()
    try {
        $dnsServers = Get-DnsClientServerAddress -AddressFamily IPv4 | ForEach-Object {
            [pscustomobject]@{
                InterfaceAlias = $_.InterfaceAlias
                InterfaceIndex = $_.InterfaceIndex
                ServerAddresses = ($_.ServerAddresses -join '; ')
            }
        }
    }
    catch {
        Add-CollectionWarning -Section 'NetworkInfo:DnsServers' -ErrorRecord $_
    }

    $ipConfigs = @()
    try {
        $ipConfigs = Get-NetIPConfiguration | ForEach-Object {
            [pscustomobject]@{
                InterfaceAlias = $_.InterfaceAlias
                InterfaceDescription = $_.InterfaceDescription
                IPv4Address    = if ($_.IPv4Address) { ($_.IPv4Address | ForEach-Object { $_.IPAddress }) -join '; ' } else { $null }
                IPv4Gateway    = if ($_.IPv4DefaultGateway) { ($_.IPv4DefaultGateway | ForEach-Object { $_.NextHop }) -join '; ' } else { $null }
                DNSServer      = if ($_.DNSServer) { ($_.DNSServer.ServerAddresses -join '; ') } else { $null }
                NetProfile     = if ($_.NetAdapter.Status) { $_.NetAdapter.Status } else { $null }
            }
        }
    }
    catch {
        Add-CollectionWarning -Section 'NetworkInfo:IPConfiguration' -ErrorRecord $_
    }

    $secureChannel = $null
    try {
        $secureChannel = Test-ComputerSecureChannel -Verbose:$false
    }
    catch {
        Add-CollectionWarning -Section 'NetworkInfo:SecureChannel' -ErrorRecord $_
    }

    $nltestOutput = @()
    if ($computerSystem.PartOfDomain -and -not [string]::IsNullOrWhiteSpace($computerSystem.Domain)) {
        try {
            $nltestOutput = @(& nltest /dsgetdc:$($computerSystem.Domain) 2>&1)
        }
        catch {
            Add-CollectionWarning -Section 'NetworkInfo:Nltest' -ErrorRecord $_
        }
    }

    [pscustomobject]@{
        DomainJoined      = $computerSystem.PartOfDomain
        Domain            = $computerSystem.Domain
        SecureChannelOk   = $secureChannel
        IpConfigurations  = @($ipConfigs)
        DnsServers        = @($dnsServers)
        DomainControllerQuery = @($nltestOutput)
    }
}

function Get-DeploymentLinkedArtifact {
    param(
        [object[]]$RecentPrograms,
        [object[]]$Shortcuts,
        [object[]]$MatchedEvents
    )

    $artifactRows = @()

    foreach ($program in @($RecentPrograms)) {
        $artifactRows += [pscustomobject]@{
            ArtifactType = 'RecentlyInstalledProgram'
            Name         = $program.DisplayName
            Path         = $program.InstallLocation
            EventTime    = $program.InstallDate
            Detail       = $program.DisplayVersion
        }
    }

    foreach ($shortcut in @(@($Shortcuts) | Where-Object { (Get-ObjectPropertyValue -InputObject $_ -PropertyName 'ChangedSinceDeployment') })) {
        $artifactRows += [pscustomobject]@{
            ArtifactType = 'ShortcutChangedSinceDeployment'
            Name         = $shortcut.Name
            Path         = $shortcut.FullName
            EventTime    = $shortcut.LastWriteTime
            Detail       = $shortcut.ResolvedTarget
        }
    }

    foreach ($eventItem in @($MatchedEvents)) {
        $artifactRows += [pscustomobject]@{
            ArtifactType = 'ApplicationEvent'
            Name         = $eventItem.ProviderName
            Path         = $eventItem.LogName
            EventTime    = $eventItem.TimeCreated
            Detail       = $eventItem.Id
        }
    }

    @($artifactRows | Sort-Object -Property EventTime -Descending)
}

if (-not $PSBoundParameters.ContainsKey('OutputRoot')) {
    $OutputRoot = Join-Path -Path (Get-ScriptDirectory) -ChildPath 'Evidence'
}

if (-not $PSBoundParameters.ContainsKey('DeploymentStart')) {
    $DeploymentStart = Get-DefaultDeploymentStart
}

Initialize-EvidenceFolder

Write-Status -Message ('Collection starting. DryRun={0}. OutputRoot={1}. DeploymentStart={2}' -f [bool]$DryRun, $script:EvidenceRoot, $DeploymentStart)

try {
    if (-not $DryRun) {
        $transcriptPath = Join-Path -Path $script:EvidenceRoot -ChildPath 'Transcript.log'
        Start-Transcript -Path $transcriptPath -Force | Out-Null
        $script:TranscriptStarted = $true
    }
    else {
        Write-Status -Message 'DryRun: transcript would be started in the evidence folder.'
    }

    $systemInfo = Invoke-CollectionStep -Section 'SystemInfo' -ScriptBlock { Get-ComputerIdentityArtifact }
    Save-Json -FileName 'SystemInfo.json' -Data $systemInfo -Depth 5

    $installedPrograms = Invoke-CollectionStep -Section 'InstalledPrograms' -ScriptBlock { Get-InstalledProgramsArtifact }
    Save-Csv -FileName 'InstalledSoftware.csv' -Data $installedPrograms
    Save-Json -FileName 'InstalledSoftware.json' -Data $installedPrograms -Depth 5

    $recentPrograms = Invoke-CollectionStep -Section 'RecentlyInstalledPrograms' -ScriptBlock { Get-RecentlyInstalledProgramsArtifact -InstalledPrograms $installedPrograms }
    Save-Csv -FileName 'RecentlyInstalledSoftware.csv' -Data $recentPrograms

    $matchedPrograms = Invoke-CollectionStep -Section 'MatchedPrograms' -ScriptBlock { Get-MatchedProgramsArtifact -InstalledPrograms $installedPrograms }
    Save-Csv -FileName 'DmsMatchedSoftware.csv' -Data $matchedPrograms

    $startupApplications = Invoke-CollectionStep -Section 'StartupApplications' -ScriptBlock { Get-StartupApplicationsArtifact }
    Save-Csv -FileName 'StartupApplications.csv' -Data $startupApplications

    $scheduledTasks = Invoke-CollectionStep -Section 'ScheduledTasks' -ScriptBlock { Get-ScheduledTasksArtifact }
    Save-Csv -FileName 'ScheduledTasks.csv' -Data $scheduledTasks

    $runningProcesses = Invoke-CollectionStep -Section 'RunningProcesses' -ScriptBlock { Get-RunningProcessesArtifact }
    Save-Csv -FileName 'RunningProcesses.csv' -Data $runningProcesses

    $performanceSnapshot = Invoke-CollectionStep -Section 'PerformanceSnapshot' -ScriptBlock { Get-PerformanceSnapshotArtifact }
    Save-Json -FileName 'PerformanceSnapshot.json' -Data $performanceSnapshot -Depth 6
    Save-Csv -FileName 'DiskUtilization.csv' -Data $performanceSnapshot.Disks

    $deploymentServices = Invoke-CollectionStep -Section 'DeploymentServices' -ScriptBlock { Get-DeploymentServicesArtifact }
    Save-Csv -FileName 'Services.csv' -Data $deploymentServices

    $eventArtifacts = Invoke-CollectionStep -Section 'EventArtifacts' -ScriptBlock { Get-EventArtifacts }
    Save-Csv -FileName 'EventLogs-System.csv' -Data $eventArtifacts.SystemErrors
    Save-Csv -FileName 'EventLogs-Application.csv' -Data $eventArtifacts.ApplicationErrors
    Save-Csv -FileName 'EventLogs-Logon.csv' -Data $eventArtifacts.LoginRelatedEvents
    Save-Csv -FileName 'EventLogs-GroupPolicy.csv' -Data $eventArtifacts.GroupPolicyEvents
    Save-Csv -FileName 'EventLogs-UserProfile.csv' -Data $eventArtifacts.UserProfileEvents
    Save-Csv -FileName 'EventLogs-AppMatches.csv' -Data $eventArtifacts.ApplicationMatchEvents

    $gpResult = Invoke-CollectionStep -Section 'GpResult' -ScriptBlock { Get-GpResultArtifact }
    Save-Text -FileName 'GpResult-Computer.txt' -Lines $gpResult.Computer
    Save-Text -FileName 'GpResult-User.txt' -Lines $gpResult.User

    $userProfile = Invoke-CollectionStep -Section 'UserProfile' -ScriptBlock { Get-UserProfileArtifact }
    Save-Json -FileName 'UserProfile.json' -Data $userProfile -Depth 5

    $shortcutInventory = Invoke-CollectionStep -Section 'ShortcutInventory' -ScriptBlock {
        Get-ShortcutInventoryArtifact -DesktopPath $userProfile.DesktopPath -PublicDesktopPath $userProfile.PublicDesktopPath
    }
    Save-Csv -FileName 'DesktopShortcuts.csv' -Data $shortcutInventory

    $networkInfo = Invoke-CollectionStep -Section 'NetworkInfo' -ScriptBlock { Get-NetworkArtifact }
    Save-Json -FileName 'NetworkInfo.json' -Data $networkInfo -Depth 6
    Save-Csv -FileName 'DnsConfig.csv' -Data $networkInfo.DnsServers
    Save-Csv -FileName 'NetworkAdapters.csv' -Data $networkInfo.IpConfigurations
    Save-Text -FileName 'DomainControllerQuery.txt' -Lines $networkInfo.DomainControllerQuery

    $deploymentLinkedArtifacts = Invoke-CollectionStep -Section 'DeploymentLinkedArtifacts' -ScriptBlock {
        Get-DeploymentLinkedArtifact -RecentPrograms $recentPrograms -Shortcuts $shortcutInventory -MatchedEvents $eventArtifacts.ApplicationMatchEvents
    }
    Save-Csv -FileName 'DeploymentLinkedArtifacts.csv' -Data $deploymentLinkedArtifacts

    $summary = [pscustomobject]@{
        CollectedAtUtc                  = (Get-Date).ToUniversalTime().ToString('o')
        ComputerName                    = $env:COMPUTERNAME
        DryRun                          = [bool]$DryRun
        OutputFolder                    = $script:EvidenceRoot
        DeploymentStart                 = $DeploymentStart
        AppNamePatterns                 = @($AppNamePatterns)
        InstalledSoftwareCount          = @($installedPrograms).Count
        RecentlyInstalledCount          = @($recentPrograms).Count
        MatchedApplicationCount         = @($matchedPrograms).Count
        StartupApplicationCount         = @($startupApplications).Count
        ScheduledTaskCount              = @($scheduledTasks).Count
        RunningProcessCount             = @($runningProcesses).Count
        DeploymentServiceCount          = @($deploymentServices).Count
        SystemErrorEventCount           = @($eventArtifacts.SystemErrors).Count
        ApplicationErrorEventCount      = @($eventArtifacts.ApplicationErrors).Count
        LogonEventCount                 = @($eventArtifacts.LoginRelatedEvents).Count
        GroupPolicyEventCount           = @($eventArtifacts.GroupPolicyEvents).Count
        UserProfileEventCount           = @($eventArtifacts.UserProfileEvents).Count
        AppSpecificEventCount           = @($eventArtifacts.ApplicationMatchEvents).Count
        ShortcutCount                   = @($shortcutInventory).Count
        ShortcutsChangedSinceDeployment = @($shortcutInventory | Where-Object { $_.ChangedSinceDeployment }).Count
        FolderRedirectionLikely         = $userProfile.FolderRedirectionLikely
        OneDriveRedirectionLikely       = $userProfile.OneDriveRedirectionLikely
        TemporaryProfileSignal          = $userProfile.TemporaryProfileSignal
        DomainJoined                    = $networkInfo.DomainJoined
        SecureChannelOk                 = $networkInfo.SecureChannelOk
        WarningCount                    = @($script:Warnings).Count
    }

    Save-Json -FileName 'SummaryReport.json' -Data $summary -Depth 5
    Save-Json -FileName 'CollectionWarnings.json' -Data $script:Warnings -Depth 5

    Write-Status -Message ('Collection complete. Warnings={0}. EvidenceFolder={1}' -f @($script:Warnings).Count, $script:EvidenceRoot)
}
finally {
    if ($script:TranscriptStarted) {
        Stop-Transcript | Out-Null
    }
}