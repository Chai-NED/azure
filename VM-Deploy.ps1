# ##############################
# Purpose: Deploy RM VM
#
# Author: Patrick El-Azem
#
# Reference:
# https://docs.microsoft.com/azure/virtual-machines/windows/quick-create-powershell
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
    [string]$DiskFileNameExtension = '.vhd',

    [string]$StorageAccountNameDiagnostics = '',

    [string]$OsDiskFileNameTail = 'OsDisk',
    [int]$OSDiskSizeInGB = 128,

    [string]$DataDiskFileNameTail = 'DataDisk',
    [int]$DataDiskSizeInGB = 256,
    [int]$NumberOfDataDisks = 0,

    [string]$AvailabilitySetName = '',
    [int]$FaultDomainCount = 3,
    [int]$UpdateDomainCount = 5,
    [bool]$AvailabilitySetIsManaged = $false,

    [string]$VMName = '',
    [string]$VMSize = 'Standard_DS2_v2',

    [string]$VNetName = '',
    [string]$VNetPrefix = '172.16.0.0/16',

    [string]$SubnetName = '',
    [string]$SubnetPrefix = '172.16.1.0/24',

    [string]$NSGName = '',

    [string]$PIPName1 = $VMName + 'pip1',
    [string]$NICName1 = $VMName + 'nic1',

    [string]$VMPublisherName = 'MicrosoftWindowsServer',
    [string]$VMOffer = 'WindowsServer',
    [string]$VMSku = '2016-Datacenter',
    [string]$VMVersion = 'latest'
)

$credPromptText = 'Type the name and password of the VM local administrator account.'

# Ensure resource group exists
$rg = .\ResourceGroup-CreateGet.ps1 -ResourceGroupName $ResourceGroupName -Location $Location

# Get storage account
$storageAccount = .\StorageAccount-CreateGet.ps1 -ResourceGroupName $ResourceGroupName -Location $Location -StorageAccountName $StorageAccountName -StorageAccountSkuName $StorageAccountSkuName

# Set current storage account
Set-AzureRmCurrentStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName

# Ensure diagnostics storage account exists
$diagsa = .\StorageAccount-CreateGet.ps1 -ResourceGroupName $ResourceGroupName -Location $Location -StorageAccountName $StorageAccountNameDiagnostics -StorageAccountSkuName 'Standard_LRS'


# Get NSG - rules in case NSG does not exist yet (will not be applied to already-existing NSG)
$nsgRule1 = New-AzureRmNetworkSecurityRuleConfig `
    -Name 'Allow-RDP' `
    -Description 'Allow RDP' `
    -Access Allow `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 100 `
    -SourceAddressPrefix Internet `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange 3389

$nsgRule2 = New-AzureRmNetworkSecurityRuleConfig `
    -Name 'Allow-SQL' `
    -Description 'Allow SQL' `
    -Access Allow `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 101 `
    -SourceAddressPrefix Internet `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange 1433

$nsg = .\NSG-CreateGet.ps1 -ResourceGroupName $ResourceGroupName -Location $Location -NSGName $NSGName -Rules $nsgRule1, $nsgRule2



# Get VNet and subnet
$vnet = .\VNet-CreateGet.ps1 -ResourceGroupName $ResourceGroupName -Location $Location -VNetName $VNetName -VNetPrefix $VNetPrefix

# Get subnet
$subnet = .\VNetSubnet-CreateGet.ps1 -ResourceGroupName $ResourceGroupName -Location $Location -VNetName $VNetName -VNetPrefix $VNetPrefix -SubnetName $SubnetName -SubnetPrefix $SubnetPrefix -NSGResourceId $nsg.Id


# Get public IP
$pip1 = New-AzureRmPublicIpAddress -Name $PIPName1 -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod Dynamic

# Get NIC
$nic1 = New-AzureRmNetworkInterface -Name $NICName1 -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $subnet.Id -PublicIpAddressId $pip1.Id

# Get credential
$cred = Get-Credential -Message $credPromptText


# Get availability set - create if not exists
$avset = .\AvailabilitySet-CreateGet.ps1 -ResourceGroupName $ResourceGroupName -Location $Location -AvailabilitySetName $AvailabilitySetName -FaultDomains $FaultDomainCount -UpdateDomains $UpdateDomainCount -Managed $AvailabilitySetIsManaged

$vm = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize -AvailabilitySetId $avset.Id

$vm = Set-AzureRmVMOperatingSystem -VM $vm -ComputerName $VMName -Credential $cred -Windows -ProvisionVMAgent -EnableAutoUpdate

$vm = Set-AzureRmVMSourceImage -VM $vm -PublisherName $VMPublisherName -Offer $VMOffer -Skus $VMSku -Version $VMVersion

# Add NIC
$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic1.Id -Primary

# Add OS disk
$osDiskUri = $storageAccount.PrimaryEndpoints.Blob.ToString() + $VHDContainerName + '/' + $VMName + $OsDiskFileNameTail + $DiskFileNameExtension
$vm = Set-AzureRmVMOSDisk -VM $vm -Name ($VMName + $OsDiskFileNameTail) -VhdUri $osDiskUri -CreateOption FromImage -DiskSizeInGB $OSDiskSizeInGB -Windows

# Add data disks
for ($ddi = 1; $ddi -le $NumberOfDataDisks; $ddi++)
{
    $dataDiskName = ($VMName + $DataDiskFileNameTail + $ddi)
    $dataDiskUri = $storageAccount.PrimaryEndpoints.Blob.ToString() + $VHDContainerName + '/' + $dataDiskName + $DiskFileNameExtension
    $vm = Add-AzureRmVMDataDisk -VM $vm -Lun $ddi -Name $dataDiskName -VhdUri $dataDiskUri -CreateOption Empty -DiskSizeInGB $DataDiskSizeInGB
}

New-AzureRmVM `
    -ResourceGroupName $ResourceGroupName `
    -Location $Location `
    -VM $vm | Out-Null

# Add diagnostics
.\VM-AddDiagnostics.ps1 -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -Location $Location -VMName $VMName -StorageAccountNameDiagnostics $StorageAccountNameDiagnostics

return $vm