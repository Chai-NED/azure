# ##############################
# Purpose: Deploy RM VM from a generalized VHD file
# Assumption: the VHD has been separately specialized. This script is NOT for building a VM from a generalized (sysprepped) image.
# 
# Author: Patrick El-Azem
#
# Reference:
# https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-create-windows-powershell-resource-manager/
# ##############################

# Arguments with defaults
param
(
    [string]$SubscriptionId = '',
    [string]$ResourceGroupName = '',
    [string]$Location = 'East US',

    [string]$StorageAccountName = '',
    [string]$StorageAccountSkuName = 'Premium_LRS',
    [string]$VHDContainerName = 'vhds',

    [string]$VMName = '',
    [string]$VMSize = 'Standard_DS3_v2',

    [string]$VHDFileName = '',

    [string]$VNetName = '',
    [string]$VNetPrefix = '',

    [string]$SubnetName = '',
    [string]$SubnetPrefix = '',

    [string]$NSGName = '',

    [string]$AvailabilitySetName = '',
    [int]$FaultDomainCount = 3,
    [int]$UpdateDomainCount = 5,
    [bool]$AvailabilitySetIsManaged = $false,

    [string]$PIPName = ($VMName + 'Pip1'),
    [string]$NICName = ($VMName + 'Nic1')
)

# Get storage account
$storageAccount = .\StorageAccount-CreateGet.ps1 -ResourceGroupName $ResourceGroupName -Location $Location -StorageAccountName $StorageAccountName -StorageAccountSkuName $StorageAccountSkuName

# Set current storage account
Set-AzureRmCurrentStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName

# Get NSG (not using rules here, see Deploy-VM-RM-Simple for example of creating and adding NSG rules)
$nsg = .\NSG-CreateGet.ps1 -ResourceGroupName $ResourceGroupName -Location $Location -NSGName $NSGName

# Get VNet and subnet
$vnet = .\VNet-CreateGet.ps1 -ResourceGroupName $ResourceGroupName -Location $Location -VNetName $VNetName -VNetPrefix $VNetPrefix

# Get subnet
$subnet = .\VNetSubnet-CreateGet.ps1 -ResourceGroupName $ResourceGroupName -Location $Location -VNetName $VNetName -VNetPrefix $VNetPrefix -SubnetName $SubnetName -SubnetPrefix $SubnetPrefix -NSGResourceId $nsg.Id

# Get public IP
$pip1 = New-AzureRmPublicIpAddress -Name $PIPName -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod Dynamic

# Get NIC
$nic1 = New-AzureRmNetworkInterface -Name $NICName -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $subnet.Id -PublicIpAddressId $pip1.Id

# If availability set specified, get it and set VM with it. Otherwise, VM without availability set.
if ($AvailabilitySetName)
{
    $avset = .\AvailabilitySet-CreateGet.ps1 -ResourceGroupName $ResourceGroupName -Location $Location -AvailabilitySetName $AvailabilitySetName -FaultDomains $FaultDomainCount -UpdateDomains $UpdateDomainCount -Managed $AvailabilitySetIsManaged

    $vm = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize -AvailabilitySetId $avset.Id
}
else
{
    $vm = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize
}

# Add NIC
$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic1.Id -Primary

# Derive URI for the OS disk VHD
$osDiskUri = $storageAccount.PrimaryEndpoints.Blob.ToString() + $VHDContainerName + '/' + $VHDFileName

# Add OS disk
$vm = Set-AzureRmVMOSDisk -VM $vm -Name ($VMName + 'OsDisk') -VhdUri $osDiskUri -CreateOption Attach -Windows

New-AzureRmVM `
    -ResourceGroupName $ResourceGroupName `
    -Location $Location `
    -VM $vm
