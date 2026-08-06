# ==============================================
# Script Name : inherit.ps1
# Purpose     : Collect and display a quick local system health snapshot.
#               Outputs computer identity and memory, free C: space,
#               top memory-consuming processes, recent System log errors,
#               and a count of stale user profiles.
# Author      : Unknown (refactored for readability)
# How to Run  : Open PowerShell and run:
#               .\inherit.ps1
# Notes       : Read-only reporting script; does not change system state.
# ==============================================

# Get core computer system details (name and total physical memory).
$computerSystem = Get-CimInstance Win32_ComputerSystem

# Get free space on the C: drive (in bytes).
$cDriveFreeBytes = Get-PSDrive C | Select-Object -ExpandProperty Free

# Get the top 5 running processes by working set memory usage.
$topMemoryProcesses = Get-Process | Sort-Object WS -Descending | Select-Object -First 5

# Get the latest 10 System events, then keep only error-level events (Level 2).
$recentSystemErrors = Get-WinEvent -LogName System -MaxEvents 10 | Where-Object {$_.Level -eq 2}

# Get user profiles and start filtering for stale, non-special profiles.
$staleUserProfiles = Get-CimInstance Win32_UserProfile | Where-Object {
     # Keep only non-special profiles not used in the last 90 days.
     -not $_.Special -and $_.LastUseTime -lt (Get-Date).AddDays(-90)}

# Print computer name and total physical memory.
Write-Host $computerSystem.Name $computerSystem.TotalPhysicalMemory

# Convert free bytes to GB (2 decimals) and print the free C: space.
Write-Host ([math]::Round($cDriveFreeBytes/1GB,2)) 'GB free'

# Print each of the top memory-consuming process names and memory values.
$topMemoryProcesses | ForEach-Object { Write-Host $_.Name $_.WS }

# Print timestamp and message for each recent System error event.
$recentSystemErrors | ForEach-Object { Write-Host $_.TimeCreated $_.Message }

# If stale profiles exist, print how many were found.
if ($staleUserProfiles.Count -gt 0) { Write-Host 'Stale profiles:' $staleUserProfiles.Count }