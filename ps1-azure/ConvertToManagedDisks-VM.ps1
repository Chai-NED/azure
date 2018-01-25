# ##############################
# Purpose: Update a VM using unmanaged VHD disks to managed disks.
#
# Author: Patrick El-Azem
#
# Command line:
# .\ConvertToManagedDisks-VM.ps1 -SubscriptionId 'MySubscriptionId' -ResourceGroupName 'MyResourceGroupName' -VMName 'MyVMName' -Restart $true
# 
# Dependencies: have Azure Powershell latest installed; have separate Login-RM.ps1 in same folder as this to log into Azure.
# 
# NOTE: This script converts a VM from unmanaged to managed disks. It does NOT upgrade it from Standard to Premium storage; that stays the same.
# ##############################

# Arguments with defaults
param
(
    [string]$ResourceGroupName = '',
    [string]$VMName = '',
    [bool]$Restart = $true
)

# Get the VM
$vm = Get-AzureRmVm -ResourceGroupName $ResourceGroupName -Name $VMName

# If the VM is in an availability set, we have to make sure the availability set is upgraded to "Aligned" (i.e. Managed disks)
# This can be done without/before shutting down VMs
if ($vm.AvailabilitySetReference -ne $null)
{
    $avsetname = (Get-AzureRmResource -ResourceId $vm.AvailabilitySetReference.Id).Name

    $avset = Get-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $avsetname

    if ($true -ne $avset.Managed)
    {
        # The availability set is not managed. We have to update it to be managed. Can do this without turning off other VMs.
        Update-AzureRmAvailabilitySet -AvailabilitySet $avset -Managed
    }
}

# Stop the VM
Stop-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $VMName -Force

# Convert all VM disks including OS and any data disks
ConvertTo-AzureRmVMManagedDisk -ResourceGroupName $ResourceGroupName -VMName $VMName

# Start the VM
if ($true -eq $Restart)
{
    Start-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $VMName
}
