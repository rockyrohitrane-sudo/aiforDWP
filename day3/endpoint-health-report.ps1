<#
Endpoint Health Report (Read-Only)
PowerShell Version: 5.1

VERIFY BEFORE RUNNING:
1) Internet speed estimate requires internet access and outbound HTTPS to at least one test endpoint:
    - https://speed.cloudflare.com/
    - https://proof.ovh.net/
    - https://speed.hetzner.de/
2) Internet speed value is an approximate download test (not a full ISP-grade benchmark) (to confirm).
3) Running as standard user may limit access to some event logs/registry paths; run in elevated session if needed.
4) "How many users logged in" is reported as interactive sessions discovered via quser output.

Safety:
- This script is strictly read-only. It only reads WMI/CIM, registry, services, event logs, and process/session data.
- It does not modify system configuration, files, services, registry, or network settings.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host '=== Endpoint Health Report (Read-Only) ===' -ForegroundColor Cyan
Write-Host ("Generated: {0}" -f (Get-Date))
Write-Host ''

# Section: System uptime
# Reads OS last boot time and computes uptime duration without changing any state.
try {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $lastBoot = $os.LastBootUpTime
    $uptime = (Get-Date) - $lastBoot
    Write-Host '--- System Uptime ---' -ForegroundColor Yellow
    Write-Host ("Last Boot Time : {0}" -f $lastBoot)
    Write-Host ("Uptime         : {0} days {1} hours {2} minutes" -f $uptime.Days, $uptime.Hours, $uptime.Minutes)
    Write-Host ''
}
catch {
    Write-Warning "System uptime: unable to retrieve data. $_"
}

# Section: Free disk space
# Reads logical disk information (fixed disks only) and displays total/free space.
try {
    Write-Host '--- Free Disk Space (Fixed Drives) ---' -ForegroundColor Yellow
    $disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType = 3" |
        Select-Object DeviceID,
            @{Name='SizeGB';Expression={[math]::Round($_.Size / 1GB, 2)}},
            @{Name='FreeGB';Expression={[math]::Round($_.FreeSpace / 1GB, 2)}},
            @{Name='FreePercent';Expression={ if ($_.Size -gt 0) { [math]::Round(($_.FreeSpace / $_.Size) * 100, 2) } else { 0 } }}
    $disks | Format-Table -AutoSize
    Write-Host ''
}
catch {
    Write-Warning "Free disk space: unable to retrieve data. $_"
}

# Section: Pending reboot check (registry)
# Reads known reboot-indicator registry keys to determine whether a reboot is pending.
try {
    Write-Host '--- Pending Reboot (Registry Indicators) ---' -ForegroundColor Yellow
    $rebootIndicators = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending',
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
    )

    $pendingRename = $false
    $pendingRenamePath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'
    $pendingRenameValue = 'PendingFileRenameOperations'
    try {
        $pendingRenameData = Get-ItemProperty -Path $pendingRenamePath -Name $pendingRenameValue -ErrorAction Stop
        if ($null -ne $pendingRenameData.$pendingRenameValue) {
            $pendingRename = $true
        }
    }
    catch {
        $pendingRename = $false
    }

    $foundKeys = @()
    foreach ($key in $rebootIndicators) {
        if (Test-Path -Path $key) {
            $foundKeys += $key
        }
    }

    $isPendingReboot = ($foundKeys.Count -gt 0) -or $pendingRename
    Write-Host ("Pending Reboot : {0}" -f $(if ($isPendingReboot) { 'Yes' } else { 'No' }))
    if ($foundKeys.Count -gt 0) {
        Write-Host 'Matched Keys   :'
        $foundKeys | ForEach-Object { Write-Host (" - {0}" -f $_) }
    }
    if ($pendingRename) {
        Write-Host ("Matched Value  : {0}\{1}" -f $pendingRenamePath, $pendingRenameValue)
    }
    Write-Host ''
}
catch {
    Write-Warning "Pending reboot check: unable to retrieve data. $_"
}

# Section: Top 5 processes by memory (Working Set)
# Reads process working set memory and shows the top consumers.
try {
    Write-Host '--- Top 5 Processes by Memory (Working Set) ---' -ForegroundColor Yellow
    Get-Process |
        Sort-Object -Property WorkingSet64 -Descending |
        Select-Object -First 5 Name, Id,
            @{Name='WorkingSetMB';Expression={[math]::Round($_.WorkingSet64 / 1MB, 2)}} |
        Format-Table -AutoSize
    Write-Host ''
}
catch {
    Write-Warning "Top memory processes: unable to retrieve data. $_"
}

# Section: Top 5 processes by CPU
# Reads cumulative CPU time used by processes and shows top consumers.
try {
    Write-Host '--- Top 5 Processes by CPU (Total Processor Time) ---' -ForegroundColor Yellow
    $cpuRows = foreach ($proc in Get-Process) {
        try {
            # Some protected/system processes may throw when CPU is accessed; skip only those entries.
            $cpuSeconds = if ($null -ne $proc.TotalProcessorTime) {
                [math]::Round($proc.TotalProcessorTime.TotalSeconds, 2)
            }
            else {
                0
            }

            [pscustomobject]@{
                Name       = $proc.Name
                Id         = $proc.Id
                CPUSeconds = $cpuSeconds
            }
        }
        catch {
            continue
        }
    }

    if ($cpuRows) {
        $cpuRows |
            Sort-Object -Property CPUSeconds -Descending |
            Select-Object -First 5 Name, Id, CPUSeconds |
            Format-Table -AutoSize
    }
    else {
        Write-Warning 'Top CPU processes: no readable process CPU data returned. (to verify)'
    }
    Write-Host ''
}
catch {
    Write-Warning "Top CPU processes: unable to retrieve data. $_"
}

# Section: Last 5 System log errors
# Reads the System event log and returns the 5 most recent Error entries.
try {
    Write-Host '--- Last 5 System Log Errors ---' -ForegroundColor Yellow
    Get-WinEvent -FilterHashtable @{ LogName = 'System'; Level = 2 } -MaxEvents 5 |
        Select-Object TimeCreated, Id, ProviderName, Message |
        Format-List
    Write-Host ''
}
catch {
    Write-Warning "System log errors: unable to retrieve data. $_"
}

# Section: Internet speed
# Performs an in-memory download throughput estimate to approximate internet speed.
# This is strictly read-only: it does not write files or change configuration/state.
try {
    Write-Host '--- Internet Speed ---' -ForegroundColor Yellow
    # Try multiple endpoints to avoid single-host DNS/CDN issues.
    $speedTestEndpoints = @(
        'https://speed.cloudflare.com/__down?bytes=10000000',
        'https://proof.ovh.net/files/10Mb.dat',
        'https://speed.hetzner.de/10MB.bin'
    )

    $success = $false
    $errors = New-Object System.Collections.Generic.List[string]

    foreach ($testUrl in $speedTestEndpoints) {
        try {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $response = Invoke-WebRequest -Uri $testUrl -UseBasicParsing -ErrorAction Stop
            $stopwatch.Stop()

            $bytes = $response.RawContentLength
            if ($bytes -le 0 -and $response.Content) {
                $bytes = [Text.Encoding]::UTF8.GetByteCount($response.Content)
            }

            if ($bytes -gt 0 -and $stopwatch.Elapsed.TotalSeconds -gt 0) {
                $mbps = [math]::Round((($bytes * 8) / 1MB) / $stopwatch.Elapsed.TotalSeconds, 2)
                Write-Host ("Approx Download Speed : {0} Mbps (to confirm)" -f $mbps)
                Write-Host ("Sample Size            : {0} MB" -f [math]::Round($bytes / 1MB, 2))
                Write-Host ("Elapsed Time           : {0} sec" -f [math]::Round($stopwatch.Elapsed.TotalSeconds, 2))
                Write-Host ("Endpoint Used          : {0}" -f $testUrl)
                $success = $true
                break
            }
            else {
                $errors.Add("{0} -> response size/time invalid" -f $testUrl)
            }
        }
        catch {
            $errors.Add("{0} -> {1}" -f $testUrl, $_.Exception.Message)
        }
    }

    if (-not $success) {
        Write-Warning 'Internet speed estimate failed for all test endpoints. (to confirm)'
        Write-Host 'Endpoint Errors :'
        foreach ($err in $errors) {
            Write-Host (" - {0}" -f $err)
        }
        Write-Host 'Verification    : confirm DNS resolution, proxy settings, and outbound HTTPS policy for the listed endpoints. (to confirm)'
    }
    Write-Host ''
}
catch {
    Write-Warning "Internet speed: unable to complete test. $_"
}

# Section: Microsoft Defender service status
# Reads service state for WinDefend to report whether Defender service is running.
try {
    Write-Host '--- Microsoft Defender Service ---' -ForegroundColor Yellow
    $defender = Get-Service -Name WinDefend -ErrorAction Stop
    Write-Host ("Service Name   : {0}" -f $defender.Name)
    Write-Host ("Display Name   : {0}" -f $defender.DisplayName)
    Write-Host ("Status         : {0}" -f $defender.Status)
    Write-Host ''
}
catch {
    Write-Warning "Defender service: unable to retrieve status. $_"
}

# Section: Number of users logged in
# Reads interactive user sessions via quser and counts active/disconnected sessions.
try {
    Write-Host '--- Logged-In Users (Interactive Sessions) ---' -ForegroundColor Yellow
    $quserOutput = & quser 2>$null
    if (-not $quserOutput) {
        Write-Warning 'Unable to read session list via quser. (to verify)'
    }
    else {
        $sessionLines = $quserOutput | Select-Object -Skip 1 | Where-Object { $_.Trim() -ne '' }
        $sessionCount = ($sessionLines | Measure-Object).Count
        Write-Host ("Session Count  : {0}" -f $sessionCount)
        Write-Host 'Raw Sessions   :'
        $sessionLines | ForEach-Object { Write-Host (" - {0}" -f $_.Trim()) }
    }
    Write-Host ''
}
catch {
    Write-Warning "Logged-in users: unable to retrieve data. $_"
}

# Section: Last Windows Update install time
# Reads hotfix/install history and reports the most recent installed update date.
try {
    Write-Host '--- Last Windows Update ---' -ForegroundColor Yellow
    $hotfix = Get-HotFix -ErrorAction Stop |
        Sort-Object -Property InstalledOn -Descending |
        Select-Object -First 1

    if ($null -ne $hotfix) {
        Write-Host ("Last Update KB : {0}" -f $hotfix.HotFixID)
        Write-Host ("Installed On   : {0}" -f $hotfix.InstalledOn)
        Write-Host ("Description    : {0}" -f $hotfix.Description)
    }
    else {
        Write-Warning 'No hotfix records returned. (to verify)'
    }
    Write-Host ''
}
catch {
    Write-Warning "Last Windows update: unable to retrieve data. $_"
}

Write-Host '=== End of Report ===' -ForegroundColor Cyan
