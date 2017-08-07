$ResourceGroupName = ''
$ServerName = ''
$DatabaseName = ''
$RestoredDatabaseName = ''

# Get list of restorable databases with delete dates
$database = Get-AzureRmSqlDeletedDatabaseBackup `
  -ResourceGroupName $ResourceGroupName `
  -ServerName $ServerName `
  -DatabaseName $DatabaseName

# Get correct database from list, use its date deleted
# Initiate restoration. Synchronous
$restoredDatabase = Restore-AzureRmSqlDatabase `
  –FromDeletedDatabaseBackup `
  -ResourceGroupName $ResourceGroupName `
  –DeletionDate $database.DeletionDate `
  -ServerName $ServerName `
  -TargetDatabaseName $RestoredDatabaseName `
  –ResourceId $database.ResourceID

# Check restored database's status
Write-Host $restoredDatabase.Status
