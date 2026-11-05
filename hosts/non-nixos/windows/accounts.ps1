#Requires -RunAsAdministrator
# accounts.ps1 — passwords and privilege check
# Usage: .\accounts.ps1 -User <his-account-name>
#   Run once as "settings" on first boot, BEFORE connecting to any network.
#   autounattend.xml creates both accounts with no password; this sets them and
#   asserts that only "settings" holds administrator rights.

param(
  [Parameter(Mandatory = $true)][string]$User
)

$ErrorActionPreference = "Stop"

function Set-Reg($Path, $Name, $Value, $Type = "DWord") {
  if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
  New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
}

Write-Host "accounts.ps1"

foreach ($account in @("settings", $User)) {
  if (-not (Get-LocalUser -Name $account -ErrorAction SilentlyContinue)) {
    throw "account '$account' does not exist; was autounattend.xml applied?"
  }
  $secret = Read-Host -AsSecureString "  password for $account"
  Set-LocalUser -Name $account -Password $secret -PasswordNeverExpires $true
  Write-Host "  password set: $account"
}

$builtin = Get-LocalUser -Name "Administrator" -ErrorAction SilentlyContinue
if ($builtin -and $builtin.Enabled) {
  Disable-LocalUser -Name "Administrator"
  Write-Host "  disabled built-in Administrator"
}

$uac = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
Set-Reg $uac "EnableLUA" 1
Set-Reg $uac "ConsentPromptBehaviorAdmin" 2
Set-Reg $uac "ConsentPromptBehaviorUser" 3
Set-Reg $uac "PromptOnSecureDesktop" 1
Write-Host "  UAC set to maximum"

Write-Host ""
Write-Host "verification"
$admins = (Get-LocalGroupMember -Group "Administrators").Name
foreach ($a in $admins) { Write-Host "  administrator: $a" }

if ($admins -match "\\$User$") {
  Write-Warning "  FAIL: $User is an administrator; it should be a standard user"
} else {
  Write-Host "  ok: $User is not an administrator"
}
if (-not ($admins -match "\\settings$")) {
  Write-Warning "  FAIL: settings is not an administrator"
} else {
  Write-Host "  ok: settings is an administrator"
}
