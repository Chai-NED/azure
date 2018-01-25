# ##############################
# Purpose: Install Powershell, DSC, and Chocolatey bits on a Windows machine.
#
# Author: Patrick El-Azem
# ##############################

# As always, use at your own risk. Do NOT NOT NOT use this on a production system without thorough prior testing and understanding the consequences!!

Set-ExecutionPolicy Bypass -Scope Process -Force

# Need up to date Nuget provider so that following steps work
Install-PackageProvider -Name Nuget -MinimumVersion 2.8.5.201 -Force

# Set the PSGallery to trusted
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted

# Latest PowerShellGet
Install-Module -Name PowerShellGet -Force

# DSC Resources
Install-Module -Name PSDscResources -Force

# Chocolatey
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))