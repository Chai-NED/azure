# The following works on Windows Server 2016. It will not work on Windows 10. I haven't tested it elsewhere.

# Check installed Powershell modules
Get-Module -All

# Output all available Windows features and install status
Get-WindowsFeature