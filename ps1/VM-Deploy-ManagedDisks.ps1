# ##############################
# Purpose: Deploy RM VM with Managed Disks
#
# Author: Patrick El-Azem
#
# NOTE: at time of this writing, there is NO WAY in Powershell to specify the OS disk name for a VM created from image, nor can it be changed after deploy.
# This can be done in an ARM template, though... see /ARM/VM/
# ##############################

# Arguments with defaults
param
(
    [string]$SubscriptionId = 'e61e4c75-268b-4c94-ad48-237aa3231481',
    [string]$Location = 'East US',

    [string]$ResourceGroupNameVM = 'pz17-vm',
    [string]$StorageType = 'PremiumLRS',

    [string]$ResourceGroupNameStorageAccountDiagnostics = 'pz17-diag',
    [string]$StorageAccountDiagnosticsName = 'pzdiag',

    [string]$DataDiskFileNameTail = 'data',
    [int]$DataDiskSizeInGB = 256,
    [int]$NumberOfDataDisks = 1,

    [string]$AvailabilitySetName = 'avset_vm',
    [int]$FaultDomainCount = 3,
    [int]$UpdateDomainCount = 5,
    [bool]$AvailabilitySetIsManaged = $true,

    [string]$VMName = 'pz17vm2',
    [string]$VMSize = 'Standard_DS3_v2',

    [string]$ResourceGroupNameNetwork = 'pz17-net',
    [string]$VNetName = 'pz17-vnet',
    [string]$VNetPrefix = '10.0.0.0/8',
    [string]$SubnetName = 'subnet-vm',
    [string]$SubnetPrefix = '10.0.3.0/24',
    [string]$NSGName = 'pz17-nsg-vm',

    [string]$PIPName1 = $VMName + '_pip_1',
    [string]$NICName1 = $VMName + '_nic_1',

    [string]$VMPublisherName = 'MicrosoftWindowsServer',
    [string]$VMOffer = 'WindowsServer',
    [string]$VMSku = '2016-Datacenter',
    [string]$VMVersion = 'latest'
)

$credPromptText = 'Type the name and password of the VM local administrator account.'

# Ensure resource group exists
$rg = .\ResourceGroup-CreateGet.ps1 -ResourceGroupName $ResourceGroupNameVM -Location $Location

# Get NSG
$nsg = .\NSG-CreateGet.ps1 -ResourceGroupName $ResourceGroupNameNetwork -Location $Location -NSGName $NSGName

# Get VNet and subnet
$vnet = .\VNet-CreateGet.ps1 -ResourceGroupName $ResourceGroupNameNetwork -Location $Location -VNetName $VNetName -VNetPrefix $VNetPrefix

# Get subnet
$subnet = .\VNetSubnet-CreateGet.ps1 -ResourceGroupName $ResourceGroupNameNetwork -Location $Location -VNetName $VNetName -VNetPrefix $VNetPrefix -SubnetName $SubnetName -SubnetPrefix $SubnetPrefix -NSGResourceId $nsg.Id

# Get public IP
$pip1 = New-AzureRmPublicIpAddress -Name $PIPName1 -ResourceGroupName $ResourceGroupNameVM -Location $Location -AllocationMethod Dynamic

# Get NIC
$nic1 = New-AzureRmNetworkInterface -Name $NICName1 -ResourceGroupName $ResourceGroupNameVM -Location $Location -SubnetId $subnet.Id -PublicIpAddressId $pip1.Id

# Get credential
$cred = Get-Credential -Message $credPromptText


# Get availability set - create if not exists
if ($AvailabilitySetName)
{
    $avset = .\AvailabilitySet-CreateGet.ps1 -ResourceGroupName $ResourceGroupNameVM -Location $Location -AvailabilitySetName $AvailabilitySetName -FaultDomains $FaultDomainCount -UpdateDomains $UpdateDomainCount -Managed $AvailabilitySetIsManaged

    $vm = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize -AvailabilitySetId $avset.Id
}
else
{
    $vm = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize
}


$vm = Set-AzureRmVMOperatingSystem -VM $vm -ComputerName $VMName -Credential $cred -Windows -ProvisionVMAgent -EnableAutoUpdate

$vm = Set-AzureRmVMSourceImage -VM $vm -PublisherName $VMPublisherName -Offer $VMOffer -Skus $VMSku -Version $VMVersion

# Add NIC
$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic1.Id -Primary

# Add data disks
for ($ddi = 1; $ddi -le $NumberOfDataDisks; $ddi++)
{
    $dataDiskName = ($VMName + '_' + $DataDiskFileNameTail + '_' + $ddi)

    $dataDiskConfig = New-AzureRmDiskConfig -AccountType $StorageType -Location $Location -CreateOption Empty -DiskSizeGB $DataDiskSizeInGB

    $dataDisk = New-AzureRmDisk -ResourceGroupName $ResourceGroupNameVM -DiskName $dataDiskName -Disk $dataDiskConfig

    $vm = Add-AzureRmVMDataDisk -VM $vm -Name $dataDiskName -CreateOption Attach -ManagedDiskId $dataDisk.Id -Lun $ddi
}

New-AzureRmVM `
    -ResourceGroupName $ResourceGroupNameVM `
    -Location $Location `
    -VM $vm | Out-Null

# Add diagnostics
.\VM-AddDiagnostics.ps1 -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -Location $Location -VMName $VMName -StorageAccountNameDiagnostics $StorageAccountNameDiagnostics
