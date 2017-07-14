# ##############################
# Purpose: Create an unmanaged availability set and two VMs for testing purposes (see other scripts that convert to managed storage etc.)
# 
# Author: Patrick El-Azem
# ##############################

# Arguments with defaults
param
(
    [string]$SubscriptionId = '',
    [string]$ResourceGroupName = '',
    [string]$Location = 'East US',
    [string]$VNetName = '',
    [string]$SubnetName = '',
    [string]$StorageAccountName = '',
    [string]$VMSizeForNewVMs = 'Standard_DS2_v2',
    [int]$FaultDomainCount = 3,
    [int]$UpdateDomainCount = 5,
    [string]$AvailabilitySetName = '',
    [string]$VM1Name = 'vmtest1',
    [string]$VM1PIPName = ($VM1Name + 'pip'),
    [string]$VM1NICName = ($VM1Name + 'nic'),
    [string]$VM1DataDiskName = ($VM1Name + 'DataDisk1'),
    [string]$VM2Name = 'vmtest2',
    [string]$VM2PIPName = ($VM2Name + 'pip'),
    [string]$VM2NICName = ($VM2Name + 'nic'),
    [string]$VM2DataDiskName = ($VM2Name + 'DataDisk1')
)


# Create availability set - unmanaged
$avset = .\AvailabilitySet-CreateGet.ps1 -ResourceGroupName $ResourceGroupName -Location $Location -AvailabilitySetName $AvailabilitySetName -FaultDomains $FaultDomainCount -UpdateDomains $UpdateDomainCount -Managed $false


# VM1
$vm1 = .\VM-Deploy.ps1 -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -Location $Location -StorageAccountName $StorageAccountName -AvailabilitySetName $AvailabilitySetName -VMName $VM1Name -VNetName $VNetName -SubnetName $SubnetName -PIPName $VM1PIPName -NICName $VM1NICName

Stop-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $vm1.Name -Force

$VM1DataDiskUri = ('https://' + $StorageAccountName + '.blob.core.windows.net/vhds/' + $VM1DataDiskName + '.vhd')

$vm1 = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $vm1.Name

Add-AzureRmVMDataDisk -VM $vm1 -Name $VM1DataDiskName -VhdUri $VM1DataDiskUri -CreateOption Empty -DiskSizeInGB 127 -Lun 0

Update-AzureRmVm -ResourceGroupName $ResourceGroupName -VM $vm1


# VM2
$vm2 = .\VM-Deploy.ps1 -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -Location $Location -StorageAccountName $StorageAccountName -AvailabilitySetName $AvailabilitySetName -VMName $VM2Name -VNetName $VNetName -SubnetName $SubnetName -PIPName $VM2PIPName -NICName $VM2NICName

Stop-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $vm2.Name -Force

$VM2DataDiskUri = ('https://' + $StorageAccountName + '.blob.core.windows.net/vhds/' + $VM2DataDiskName + '.vhd')

$vm2 = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $vm2.Name

Add-AzureRmVMDataDisk -VM $vm2 -Name $VM2DataDiskName -VhdUri $VM2DataDiskUri -CreateOption Empty -DiskSizeInGB 127 -Lun 0

Update-AzureRmVm -ResourceGroupName $ResourceGroupName -VM $vm2
