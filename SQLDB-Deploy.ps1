# ##############################
# Purpose: Create an Azure SQL Server.
#
# Author: Patrick El-Azem
# ##############################

# Arguments with defaults
param
(
    [string]$ResourceGroupName = '',
    [string]$Location = '',
    [string]$ServerName = '',
    [string]$ServerVersion = '12.0',
    [string]$UserName = '',
    [string]$ExternalIpTo1433 = '',
    [string]$StorageAcctName = '',
    [string]$StorageTableName = $ServerName + 'logs'
)

$cred = Get-Credential -UserName $UserName -Message 'Please enter password for the new credential'

$sql = New-AzureRmSqlServer -Location $Location -ResourceGroupName $ResourceGroupName -ServerName $ServerName -SqlAdministratorCredentials $cred -ServerVersion $ServerVersion

New-AzureRmSqlServerFirewallRule -ResourceGroupName $ResourceGroupName -ServerName $ServerName -AllowAllAzureIPs
New-AzureRmSqlServerFirewallRule -ResourceGroupName $ResourceGroupName -ServerName $ServerName -FirewallRuleName 'SQL Server 1433' -StartIpAddress $ExternalIpTo1433 -EndIpAddress $ExternalIpTo1433

Set-AzureRmSqlServerAuditingPolicy -ResourceGroupName $ResourceGroupName -ServerName $ServerName  -EventType All -RetentionInDays 7 -StorageAccountName $StorageAcctName -TableIdentifier $StorageTableName
