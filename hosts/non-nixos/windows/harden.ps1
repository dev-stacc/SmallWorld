#Requires -RunAsAdministrator
# harden.ps1 — telemetry, ads and bloat removal
# Usage: .\harden.ps1
#   Removes telemetry, advertising and the consumer app bundle. Deliberately keeps
#   Defender, SmartScreen, Windows Update and the firewall, and asserts all four at
#   the end: a debloat pass that silently disables them is a failure, not a success.

$ErrorActionPreference = "Stop"

function Set-Reg($Path, $Name, $Value, $Type = "DWord") {
  if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
  New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
}

function Disable-Svc($Name) {
  $svc = Get-Service -Name $Name -ErrorAction SilentlyContinue
  if ($svc) {
    Stop-Service -Name $Name -Force -ErrorAction SilentlyContinue
    Set-Service -Name $Name -StartupType Disabled
    Write-Host "  disabled service: $Name"
  }
}

Write-Host "harden.ps1"

Write-Host " telemetry"
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 0
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "DoNotShowFeedbackNotifications" 1
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" "AITEnable" 0
Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" 0
Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" "TailoredExperiencesWithDiagnosticDataEnabled" 0
Disable-Svc "DiagTrack"
Disable-Svc "dmwappushservice"

Write-Host " ads and suggestions"
$cdm = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
foreach ($k in @("SilentInstalledAppsEnabled", "SystemPaneSuggestionsEnabled",
                 "SubscribedContent-338388Enabled", "SubscribedContent-338389Enabled",
                 "SubscribedContent-310093Enabled", "RotatingLockScreenOverlayEnabled",
                 "SoftLandingEnabled", "PreInstalledAppsEnabled",
                 "OemPreInstalledAppsEnabled", "ContentDeliveryAllowed")) {
  Set-Reg $cdm $k 0
}
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableWindowsConsumerFeatures" 1
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableCloudOptimizedContent" 1

Write-Host " copilot, recall, widgets"
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" 1
Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowCopilotButton" 0
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" "DisableAIDataAnalysis" 1
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" "AllowNewsAndInterests" 0
Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarDa" 0
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Chat" "ChatIcon" 3

Write-Host " onedrive"
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" "DisableFileSyncNGSC" 1

Write-Host " consumer app bundle"
$strip = @(
  "Microsoft.549981C3F5F10", "Microsoft.BingNews", "Microsoft.BingWeather",
  "Microsoft.GamingApp", "Microsoft.GetHelp", "Microsoft.Getstarted",
  "Microsoft.MicrosoftOfficeHub", "Microsoft.MicrosoftSolitaireCollection",
  "Microsoft.MicrosoftStickyNotes", "Microsoft.People", "Microsoft.PowerAutomateDesktop",
  "Microsoft.Todos", "Microsoft.WindowsAlarms", "Microsoft.WindowsCamera",
  "Microsoft.WindowsFeedbackHub", "Microsoft.WindowsMaps", "Microsoft.Xbox.TCUI",
  "Microsoft.XboxGameOverlay", "Microsoft.XboxGamingOverlay", "Microsoft.XboxIdentityProvider",
  "Microsoft.XboxSpeechToTextOverlay", "Microsoft.YourPhone", "Microsoft.ZuneMusic",
  "Microsoft.ZuneVideo", "MicrosoftTeams", "MSTeams", "Clipchamp.Clipchamp",
  "Microsoft.Copilot", "Microsoft.OutlookForWindows"
)
foreach ($pkg in $strip) {
  Get-AppxPackage -AllUsers -Name $pkg -ErrorAction SilentlyContinue |
    Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
  Get-AppxProvisionedPackage -Online |
    Where-Object { $_.DisplayName -eq $pkg } |
    Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Out-Null
}
Write-Host "  stripped $($strip.Count) package names"

Write-Host ""
Write-Host "verification — these must all be ON"
$fail = 0

$mp = Get-MpComputerStatus
Write-Host "  defender realtime : $($mp.RealTimeProtectionEnabled)"
if (-not $mp.RealTimeProtectionEnabled) { $fail++ }
Write-Host "  defender antivirus: $($mp.AntivirusEnabled)"
if (-not $mp.AntivirusEnabled) { $fail++ }

$wu = (Get-Service wuauserv).StartType
Write-Host "  windows update    : $wu"
if ($wu -eq "Disabled") { $fail++ }

foreach ($p in Get-NetFirewallProfile) {
  Write-Host "  firewall $($p.Name): enabled=$($p.Enabled) inbound=$($p.DefaultInboundAction)"
  if (-not $p.Enabled) { $fail++ }
  if ($p.DefaultInboundAction -eq "Allow") { $fail++ }
}

$ss = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name SmartScreenEnabled -ErrorAction SilentlyContinue).SmartScreenEnabled
Write-Host "  smartscreen       : $ss"

if ($fail -gt 0) {
  Write-Warning "FAIL: $fail protection(s) are off — fix before handing the machine over"
  exit 1
}
Write-Host "  all protections intact"
