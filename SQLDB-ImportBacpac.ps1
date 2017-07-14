# ########################################
# Purpose: Restore an Azure SQL DB from bacpac in blob storage
#
# Author: Patrick El-Azem
# ########################################


# ########################################
# ASSUMPTIONS
# The subscription, resource group, storage account, container, and blob specified in defaults or passed as arguments ALREADY EXIST. These will not be JIT-created in this script.
# ########################################


# ########################################
# Arguments with defaults
param
(
    [string]$SubscriptionId = '',
    [string]$ResourceGroupName = '',
    [string]$StorageAccountName = '',
    [string]$StorageAccountKey = '',
    [string]$StorageContainerName = '',
    [string]$BacpacBlobName = '',
    [string]$SQLServerName = '',
    [string]$DatabaseName = '',
    [string]$DatabaseTier = 'S1',
    [string]$UserName = '',
    [string]$Password = ''
)
# ########################################


# ########################################
# Login
Try
{
    $loginContext = Get-AzureRmContext
}
Catch
{
    $loginContext = $null
}
Finally
{
    if ($null -eq $loginContext)
    {
        Login-AzureRmAccount

        $loginContext = Get-AzureRmContext
    }
}
# ########################################


# Set default subscription
Select-AzureSubscription -SubscriptionId $SubscriptionId


# ########################################
# Delete database if it exists
Try
{
    $database = Get-AzureRmSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -DatabaseName $DatabaseName -ErrorAction Stop

    if ($database -ne $null)
    {
        Remove-AzureRmSqlDatabase -DatabaseName $DatabaseName -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -Force
    }
}
Catch
{
}
# ########################################


# Get credential for SQL database/server access
$securePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
$credential = New-Object -TypeName 'System.Management.Automation.PSCredential' -ArgumentList $UserName, $securePassword

# Get SQL server context
$sqlContext = New-AzureSqlDatabaseServerContext -ServerName $SQLServerName -Credential $credential

# Get storage context
$storageContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey

# Start import request
$importRequest = Start-AzureSqlDatabaseImport -BlobName $BacpacBlobName -DatabaseName $DatabaseName -SqlConnectionContext $sqlContext -StorageContainerName $StorageContainerName -StorageContext $storageContext

# Wait until import request completes
do
{
    $importRequestStatus = Get-AzureSqlDatabaseImportExportStatus -Request $importRequest
    Write-Host $importRequestStatus.Status
    Start-Sleep -s 5
}
until ($importRequestStatus -ne $null -and ($importRequestStatus.Status -eq 'Completed' -or $importRequestStatus.Status -eq 'Failed'))

# Set database to requested tier
if ($importRequestStatus.Status -eq 'Completed')
{
    Set-AzureRmSqlDatabase -DatabaseName $DatabaseName -ResourceGroupName $ResourceGroupName -ServerName $SQLServerName -RequestedServiceObjectiveName $DatabaseTier
}