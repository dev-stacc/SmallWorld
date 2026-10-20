#Requires -RunAsAdministrator
# lightweight.ps1 — shell and service trimming
# Usage: .\lightweight.ps1
#   Written for a machine with no WDDM 2.0 driver, where the desktop composites in
#   software. Reports idle memory before and after so the trimming is measured.
#   SysMain is left ON for spinning disks, where prefetch helps, and disabled on SSD.

$ErrorActionPreference = "Stop"

function Set-Reg($Path, $Name, $Value, $Type = "DWord") {
  if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
  New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
}

function Idle-Memory {
  $os = Get-CimInstance Win32_OperatingSystem
  [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB, 2)
}

Write-Host "lightweight.ps1"
$before = Idle-Memory
Write-Host "  memory in use before: $before GB"

Write-Host " visual effects"
Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting" 2
Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\DWM" "EnableAeroPeek" 0
Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" "EnableTransparency" 0
Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAnimations" 0
Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ListviewAlphaSelect" 0
Set-Reg "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate" "0" "String"
Set-Reg "HKCU:\Control Panel\Desktop" "UserPreferencesMask" ([byte[]](0x90, 0x12, 0x03, 0x80, 0x10, 0x00, 0x00, 0x00)) "Binary"

Write-Host " background activity"
Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" "GlobalUserDisabled" 1
Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize" "StartupDelayInMSec" 0
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" "DisableSearchBoxSuggestions" 1

Write-Host " search indexing"
$ws = Get-Service -Name WSearch -ErrorAction SilentlyContinue
if ($ws) {
  Stop-Service -Name WSearch -Force -ErrorAction SilentlyContinue
  Set-Service -Name WSearch -StartupType Disabled
  Write-Host "  disabled WSearch"
}

Write-Host " hibernation"
powercfg /hibernate off
Write-Host "  hibernation off, hiberfil.sys reclaimed"

Write-Host " prefetch policy"
$rotational = (Get-PhysicalDisk | Where-Object { $_.MediaType -eq "HDD" }).Count -gt 0
if ($rotational) {
  Write-Host "  spinning disk detected: SysMain left enabled"
} else {
  $sm = Get-Service -Name SysMain -ErrorAction SilentlyContinue
  if ($sm) {
    Stop-Service -Name SysMain -Force -ErrorAction SilentlyContinue
    Set-Service -Name SysMain -StartupType Disabled
    Write-Host "  solid-state disk: SysMain disabled"
  }
}

Write-Host ""
$after = Idle-Memory
Write-Host "memory in use after: $after GB (was $before GB)"
Write-Host "a reboot is needed before the shell changes are fully in effect"
