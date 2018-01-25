# ##############################
# Purpose: Deploy RM VM - Managed Disks
#
# Author: Patrick El-Azem
#
# Reference: https://docs.microsoft.com/en-us/azure/virtual-machines/windows/resize-vm
#
# Notes: this script assumes you have created RGs, VNets, subnets, NSGs. It does create the availability set you designate, if it doesn't exist yet.
# ##############################

# ##################################################
# Variables
$Location = ''
$ResourceGroupName = ''
$VMName = ''
$NewVMSize = 'Standard_DS3_v2'
$AvailabilitySetName = ''
# ##################################################


# ##################################################
# Useful stuff

# List all Azure regions
Get-AzureRmLocation

# List VM sizes available in region
Get-AzureRmVMSize -Location $Location

# List VM sizes available on the same hardware cluster
Get-AzureRmVMSize -ResourceGroupName $ResourceGroupName -VMName $VMName
# ##################################################


# ##################################################
# I'm deliberately doing this here so you don't just hit F5 and run everything. This script is for debugging, highlighting and running selection, etc.
Return
# ##################################################


# ##################################################
# If new size is available right on the same hardware cluster, use this code - requires VM restart but not de-allocate
$vm = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -VMName $VMName
$vm.HardwareProfile.VmSize = $NewVMSize
Update-AzureRmVM -VM $vm -ResourceGroupName $ResourceGroupName
# ##################################################


# ##################################################
# If new size is NOT available and VM is NOT in an availability set, use this code - requires de-allocate
Stop-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $VMName -Force

$vm = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $VMName
$vm.HardwareProfile.VmSize = $NewVMSize

Update-AzureRmVM -VM $vm -ResourceGroupName $ResourceGroupName

Start-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $VMName
# ##################################################


# ##################################################
# If new size is NOT available and there is an availability set, use this code to resize each VM in the availability set - requires de-allocate

# Get the availability set; stop, resize, and restart each VM in it
$as = Get-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $AvailabilitySetName
$vmIds = $as.VirtualMachinesReferences

foreach ($vmId in $vmIds)
{
    $string = $vmID.Id.Split("/")
    $vmName = $string[8]

    $vm = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $vmName

    Stop-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $vmName -Force

    $vm.HardwareProfile.VmSize = $NewVMSize

    Update-AzureRmVM -ResourceGroupName $ResourceGroupName -VM $vm

    Start-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $vmName
}
# ##################################################
