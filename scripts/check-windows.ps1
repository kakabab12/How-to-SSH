# How-to-SSH: read-only status check for a Windows machine.
# It makes NO changes and never asks for a password.
#
# Run from the repository folder:
#   powershell -ExecutionPolicy Bypass -File scripts\check-windows.ps1
#
# Output legend:  [OK] done   [--] missing / needs action   [??] cannot tell, ask the user

function Ok($m)   { Write-Output "[OK] $m" }
function Miss($m) { Write-Output "[--] $m" }
function Unk($m)  { Write-Output "[??] $m" }
function Info($m) { Write-Output "     $m" }

Write-Output "== How-to-SSH check (Windows) =="

# ---------- System ----------
$os = Get-CimInstance Win32_OperatingSystem
Info "OS: $($os.Caption) (build $($os.BuildNumber), SKU $($os.OperatingSystemSKU))"
Info "User: $(whoami)   Computer: $env:COMPUTERNAME"
# 98-101 = Home editions
if (@(98, 99, 100, 101) -contains [int]$os.OperatingSystemSKU) {
    Unk "Windows Home edition: cannot RECEIVE Windows Remote Desktop (RDP) -> use RustDesk"
} else {
    Ok "Edition can receive Windows Remote Desktop (RDP) (optional)"
}

Write-Output "-- Privileges / account"
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Ok "This shell is elevated (admin commands can run here)"
} else {
    Miss "This shell is NOT elevated -> admin commands need 'Terminal (Admin)' or a UAC prompt"
}
try {
    $lu = Get-LocalUser -Name $env:USERNAME -ErrorAction Stop
    Info "Account type: $($lu.PrincipalSource)"
    if ("$($lu.PrincipalSource)" -eq 'MicrosoftAccount') {
        Info "-> remote login password = Microsoft account password (NOT the PIN)"
    }
} catch {
    Unk "Account type: unknown"
}
try {
    $admins = @(Get-LocalGroupMember -SID 'S-1-5-32-544' -ErrorAction Stop | ForEach-Object { $_.Name })
    if ($admins -contains "$env:COMPUTERNAME\$env:USERNAME") {
        Ok "User is an administrator (SSH keys go to C:\ProgramData\ssh\administrators_authorized_keys)"
    } else {
        Info "User not found in the Administrators list (SSH keys go to ~\.ssh\authorized_keys)"
    }
} catch {
    Unk "Could not read the Administrators group"
}
$pl = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device' -Name DevicePasswordLessBuildVersion -ErrorAction SilentlyContinue
if ($pl -and $pl.DevicePasswordLessBuildVersion -eq 2) {
    Miss "'Windows Hello sign-in only' is ON -> user should turn it off (Settings > Accounts > Sign-in options)"
} elseif ($pl) {
    Ok "'Windows Hello sign-in only' is off"
} else {
    Info "'Windows Hello sign-in only' setting not present (probably off)"
}

# ---------- Tailscale ----------
Write-Output "-- Tailscale"
$tsPath = $null
$tsCmd = Get-Command tailscale -ErrorAction SilentlyContinue
if ($tsCmd) { $tsPath = $tsCmd.Source }
elseif (Test-Path "$env:ProgramFiles\Tailscale\tailscale.exe") { $tsPath = "$env:ProgramFiles\Tailscale\tailscale.exe" }
if ($tsPath) {
    Ok "Tailscale installed"
    $ip = & $tsPath ip -4 2>$null | Select-Object -First 1
    if ($ip) { Ok "Tailscale logged in, IP: $ip" } else { Miss "Tailscale not logged in" }
    $prefs = (& $tsPath debug prefs 2>$null) -join "`n"
    if ($prefs -match '"ForceDaemon":\s*true') { Ok "Tailscale 'Run unattended' is ON" }
    elseif ($prefs -match '"ForceDaemon":\s*false') { Miss "Tailscale 'Run unattended' is OFF (needed on the lab PC)" }
    else { Unk "Tailscale 'Run unattended': cannot tell -> ask the user to check the tray menu" }
} else {
    Miss "Tailscale not installed"
}
Info "Tailscale key expiry: check at https://login.tailscale.com/admin/machines (lab PC should be 'Expiry disabled')"

# ---------- SSH ----------
Write-Output "-- SSH"
if (Get-Command ssh -ErrorAction SilentlyContinue) { Ok "OpenSSH client (ssh) available" } else { Miss "OpenSSH client (ssh) not found" }
$sshd = Get-Service sshd -ErrorAction SilentlyContinue
if ($sshd) {
    if ($sshd.Status -eq 'Running') { Ok "SSH server (sshd) running" } else { Miss "SSH server (sshd) status: $($sshd.Status)" }
    if ("$($sshd.StartType)" -eq 'Automatic') { Ok "SSH server starts automatically" } else { Miss "SSH server start type: $($sshd.StartType)" }
    $fw = Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -ErrorAction SilentlyContinue
    if ($fw) {
        if ("$($fw.Enabled)" -eq 'True') { Ok "Firewall rule for SSH enabled (profile: $($fw.Profile))" } else { Miss "Firewall rule for SSH exists but is disabled" }
    } else {
        Miss "Firewall rule 'OpenSSH-Server-In-TCP' not found"
    }
    $shell = (Get-ItemProperty 'HKLM:\SOFTWARE\OpenSSH' -Name DefaultShell -ErrorAction SilentlyContinue).DefaultShell
    if ($shell) { Info "SSH default shell: $shell" } else { Info "SSH default shell: cmd (Windows default)" }
} else {
    Miss "SSH server (OpenSSH Server) not installed (only needed on the lab PC)"
}

# ---------- Power ----------
Write-Output "-- Sleep"
function Get-AcIndex($alias) {
    $out = powercfg /query SCHEME_CURRENT SUB_SLEEP $alias 2>$null
    $vals = @($out | Select-String -Pattern ':\s*(0x[0-9a-fA-F]+)\s*$' | ForEach-Object { $_.Matches[0].Groups[1].Value })
    if ($vals.Count -ge 2) { return [Convert]::ToInt64($vals[$vals.Count - 2], 16) }
    return $null
}
$standby = Get-AcIndex 'STANDBYIDLE'
if ($standby -eq 0) { Ok "Sleep on AC power: never" }
elseif ($null -eq $standby) { Unk "Sleep on AC power: unknown" }
else { Miss "Sleep on AC power after $standby seconds (lab PC should be 'never')" }
$hib = Get-AcIndex 'HIBERNATEIDLE'
if ($hib -eq 0) { Ok "Hibernate on AC power: never" }
elseif ($null -eq $hib) { Unk "Hibernate on AC power: unknown" }
else { Miss "Hibernate on AC power after $hib seconds (lab PC should be 'never')" }

# ---------- Remote desktop ----------
Write-Output "-- Remote desktop"
$rdp = Get-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -ErrorAction SilentlyContinue
if ($rdp -and $rdp.fDenyTSConnections -eq 0) { Ok "Windows Remote Desktop (RDP) is ON" } else { Info "Windows Remote Desktop (RDP) is off (optional)" }
$rd = Get-Service RustDesk -ErrorAction SilentlyContinue
if ($rd) {
    if ($rd.Status -eq 'Running') { Ok "RustDesk installed as a service and running" } else { Miss "RustDesk service status: $($rd.Status)" }
} elseif (Test-Path "$env:ProgramFiles\RustDesk\rustdesk.exe") {
    Miss "RustDesk files found but no service -> press 'Install' in RustDesk"
} else {
    Miss "RustDesk not installed as a service (lab PC needs the installed version)"
}
$cfgs = @("$env:APPDATA\RustDesk\config\RustDesk2.toml", "$env:WINDIR\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk2.toml")
$direct = $false
foreach ($c in $cfgs) {
    if ((Test-Path $c) -and (Select-String -Path $c -Pattern "direct-server\s*=\s*'Y'" -Quiet -ErrorAction SilentlyContinue)) { $direct = $true }
}
if ($direct) { Ok "RustDesk direct IP access enabled" } else { Unk "RustDesk direct IP access: cannot confirm -> ask the user to check Settings > Security" }
Info "RustDesk permanent password: cannot be checked by a script -> ask the user"

Write-Output "== done =="
