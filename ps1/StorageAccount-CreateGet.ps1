# ##############################
# Purpose: Create a storage account
#
# Author: Patrick El-Azem
# ##############################

# Arguments with defaults
param
(
    [string]$ResourceGroupName = '',
    [string]$Location = '',
    [string]$StorageAccountName = '',
    [string]$StorageAccountSkuName = 'Standard_LRS'
)

# ##########
# Check if SA exists already and if not, create and get it
try
{
    $sa = Get-AzureRmStorageAccount -Name $StorageAccountName -ResourceGroupName $ResourceGroupName -ErrorAction Stop
    Write-Host('Found existing storage account ' + $StorageAccountName)
}
catch
{
    Write-Host('Storage account ' + $StorageAccountName + ': not found!')
    Write-Host('Storage account ' + $StorageAccountName + ': creating...')
    $sa = New-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Location $Location -Name $StorageAccountName -SkuName $StorageAccountSkuName -Kind Storage
    Write-Host('Storage account ' + $StorageAccountName + ': created.')
}
# ##########

return $sa