param
(
    [string]$SubscriptionId = '',
    [string]$ResourceGroupName = '',
    [string]$Location = 'East US',

    [string]$VMName = '',

    [string]$StorageAccountName = '',
    [string]$StorageAccountSkuName = 'Premium_LRS',
    [string]$VHDContainerName = 'vhds',
    [string]$DiskFileNameExtension = '.vhd',

    [string]$DataDiskFileNameTail = 'DataDisk',
    [int]$DataDiskSizeInGB = 256
)

$ddi = 3

# Get storage account
$storageAccount = .\StorageAccount-CreateGet.ps1 -ResourceGroupName $ResourceGroupName -Location $Location -StorageAccountName $StorageAccountName -StorageAccountSkuName $StorageAccountSkuName

$vm = Get-AzureRmVM -Name $VMName -ResourceGroupName $ResourceGroupName

$dataDiskName = ($VMName + $DataDiskFileNameTail + $ddi)

Remove-AzureRmVMDataDisk -VM $vm -DataDiskNames $dataDiskName

Update-AzureRmVM -ResourceGroupName $ResourceGroupName -VM $vm

# Delete the VHD file from blob storage

$vm = Get-AzureRmVM -Name $VMName -ResourceGroupName $ResourceGroupName

$dataDiskUri = $storageAccount.PrimaryEndpoints.Blob.ToString() + $VHDContainerName + '/' + $dataDiskName + $DiskFileNameExtension

$vm = Add-AzureRmVMDataDisk -VM $vm -Lun $ddi -Name $dataDiskName -VhdUri $dataDiskUri -CreateOption Empty -DiskSizeInGB $DataDiskSizeInGB

Update-AzureRmVM -ResourceGroupName $ResourceGroupName -VM $vm