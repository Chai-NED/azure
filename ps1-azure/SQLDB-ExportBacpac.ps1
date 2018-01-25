# ########################################
# Purpose: Export an Azure SQL DB to bacpac in blob storage
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
    [string]$DatabaseTier = '',
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

# Get credential for SQL database/server access
$securePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
$credential = New-Object -TypeName 'System.Management.Automation.PSCredential' -ArgumentList $UserName, $securePassword

# Get SQL server context
$sqlContext = New-AzureSqlDatabaseServerContext -ServerName $SQLServerName -Credential $credential

# Get storage context
$storageContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey

#Ensure target blob does not already exist
$blob = Get-AzureStorageBlob -Context $storageContext -Container $StorageContainerName -Blob $BacpacBlobName

if ($blob -ne $null)
{
    Remove-AzureStorageBlob -Context $storageContext -Container $StorageContainerName -Blob $BacpacBlobName -Force
}

# Start export request
$exportRequest = Start-AzureSqlDatabaseExport -BlobName $BacpacBlobName -DatabaseName $DatabaseName -SqlConnectionContext $sqlContext -StorageContainerName $StorageContainerName -StorageContext $storageContext

# Wait until export request completes
do
{
    $exportRequestStatus = Get-AzureSqlDatabaseImportExportStatus -Request $exportRequest
    Write-Host $exportRequestStatus.Status
    Start-Sleep -s 5
}
until ($exportRequestStatus -ne $null -and ($exportRequestStatus.Status -eq 'Completed' -or $exportRequestStatus.Status -eq 'Failed'))
