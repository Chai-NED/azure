# The following works on Windows Server 2016. It will not work on Windows 10. I haven't tested it elsewhere.
# As always, use at your own risk. Do NOT NOT NOT use this on a production system without thorough prior testing and understanding the consequences!!

# Set the PSGallery to trusted
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted

# Check what's installed
Get-Module -All

# Latest PowerShellGet
Install-Module -Name PowerShellGet -Force

# DSC Resources
Install-Module -Name PSDscResources

# Output all available Windows features and install status
Get-WindowsFeature