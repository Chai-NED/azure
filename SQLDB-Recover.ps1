$ResourceGroupName = ''
$ServerName = ''
$DatabaseName = ''
$TargetServerName = '' # this does NOT work at this point
$TargetDatabaseName = ''

# Get list of databases
$listOfDatabases = Get-AzureRmSqlDatabase `
  -ResourceGroupName $ResourceGroupName `
  -ServerName $ServerName `
  -DatabaseName $DatabaseName

# Inspect list and get correct database
$database = $listOfDatabases[0]

# Initiate recovery. Synchronous
$recoveredDatabase = Restore-AzureRmSqlDatabase `
  –FromPointInTimeBackup `
  –PointInTime '2016-08-31T13:00:00' `
  -ResourceGroupName $ResourceGroupName `
  -ServerName $TargetServerName `
  -TargetDatabaseName $TargetDatabaseName `
  –ResourceId $database.ResourceID

# Check recovered database's status
Write-Host $recoveredDatabase.Status