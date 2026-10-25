# Copyright (c) 2026 Celestial
# Licensed under the PolyForm Noncommercial License 1.0.0. See LICENSE.md.
# Rewrites RedirectHost in Module.cpp. Usage: SetRedirectHost.ps1 <Module.cpp> <ip>
param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Ip
)

if ($Ip -notmatch '^\d{1,3}(\.\d{1,3}){3}$') { Write-Error "Not an IPv4 address: $Ip"; exit 3 }

$Text = [IO.File]::ReadAllText($Path)
$Pattern = '(constexpr wchar_t RedirectHost\[\] = L")[^"]*(";)'
if ($Text -notmatch $Pattern) { exit 2 }

$Updated = [regex]::Replace($Text, $Pattern, { param($m) $m.Groups[1].Value + $Ip + $m.Groups[2].Value })
if ($Updated -ne $Text) {
    # No BOM: the original has none and a BOM would change the file's bytes.
    [IO.File]::WriteAllText($Path, $Updated, (New-Object Text.UTF8Encoding($false)))
}
