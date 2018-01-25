# ##############################
# Purpose: Disables UAC on a Windows machine by writing to the appropriate registry key.
# Checks if the key exists already and writes to it, or creates it if needed.
# Note: requires admin priv, and requires a reboot.
#
# Author: Patrick El-Azem
# ##############################

$prop = Get-ItemProperty -Path registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\policies\system -Name EnableLUA

# Write-Host ($null -eq $prop)

if ($null -eq $prop)
{
    New-ItemProperty -Path registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\policies\system -Name EnableLUA -PropertyType DWord -Value 0 -Force
}
else
{
    Set-ItemProperty -Path registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\policies\system -Name EnableLUA -Value 0 -Force
}

Restart-Computer -Force