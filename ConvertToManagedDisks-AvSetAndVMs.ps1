# ##############################
# Purpose: Update an availability set and all VMs in it to managed disks.
#
# Author: Patrick El-Azem
#
# Command line:
# .\ConvertToManagedDisks-AvSetAndVMs.ps1 -SubscriptionId 'MySubscriptionId' -ResourceGroupName 'MyResourceGroupName' -AvailabilitySetName 'MyAvsetName'
# 
# NOTE: This script does not convert from Standard to Premium storage. It stays at the same level and converts from unmanaged to managed disks.
# ##############################

# Arguments with defaults
param
(
    [string]$ResourceGroupName = '',
    [string]$AvailabilitySetName = ''
)

# Get the availability set
$avset = Get-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $AvailabilitySetName

# The availability set is not managed. We have to update it to be managed.
Update-AzureRmAvailabilitySet -AvailabilitySet $avset -Managed

foreach($vmInfo in $avset.VirtualMachinesReferences)
{
    $vm = Get-AzureRmVM -ResourceGroupName $ResourceGroupName | Where-Object {$_.Id -eq $vmInfo.id}

    Stop-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $vm.Name -Force

    ConvertTo-AzureRmVMManagedDisk -ResourceGroupName $ResourceGroupName -VMName $vm.Name

    Start-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $vm.Name
}