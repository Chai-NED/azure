# ##############################
# Purpose: Run another PS1 script in an administrative context.
#
# Author: Patrick El-Azem
#
# Based on: https://azure.microsoft.com/blog/automating-sql-server-vm-configuration-using-custom-script-extension/
# ##############################

# Arguments with defaults
param
(
    [string]$AdminAccountName,
    [string]$AdminPassword,
    [string]$ScriptFileName
)

$password =  ConvertTo-SecureString $AdminPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential(("$env:COMPUTERNAME\" + $AdminAccountName), $password)
$command = (".\" + $ScriptFileName)

Enable-PSRemoting –Force

Invoke-Command -FilePath $command -Credential $credential -ComputerName $env:COMPUTERNAME

Disable-PSRemoting -Force