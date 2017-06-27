# ##############################
# Purpose: Update a VM using unmanaged VHD disks to managed disks.
#
# Author: Patrick El-Azem
#
# Command line:
# .\ConvertToManagedDisksAndPremium-VM.ps1 -SubscriptionId 'MySubscriptionId' -ResourceGroupName 'MyResourceGroupName' -VMName 'MyVMName' -Restart $true
# 
# Dependencies: have Azure Powershell latest installed; have separate Login-RM.ps1 in same folder as this to log into Azure.
# 
# NOTE: This script is for converting a VM that is on Standard unmanaged disks, to Premium managed disks.
# This script WILL NOT WORK for a VM that is in an availability set. In that case, the VM will need to be deleted and re-created in the new availability set - see separate script.
# ##############################

# Arguments with defaults
param
(
    [string]$ResourceGroupName = '',
    [string]$VMName = '',
    [string]$VMSizeNew = 'Standard_DS2_v2',
    [bool]$Restart = $false
)

# Get the VM
$vm = Get-AzureRmVm -ResourceGroupName $ResourceGroupName -Name $VMName

# If the VM is in an availability set, cannot use this script.
if ($vm.AvailabilitySetReference -ne $null)
{
    Write-Output 'This script cannot be used with this VM. The VM is in an availability set, and to upgrade its storage, must be deleted and re-created in a new availability set.'
    exit
}

# Stop the VM
Stop-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $VMName -Force

# Convert the VM to the new size, if one was specified (e.g. if the current VM size does not support Premium storage)
if ($null -ne $VMSizeNew -and $VMSizeNew -ne $vm.HardwareProfile.VmSize)
{
    Write-Host 'Starting VM size update'
    $vm.HardwareProfile.VmSize = $VMSizeNew
    Update-AzureRmVM -VM $vm -ResourceGroupName $ResourceGroupName
    $vm = Get-AzureRmVm -ResourceGroupName $ResourceGroupName -Name $VMName
    Write-Host 'Completed VM size update'
}

# Convert all VM disks including OS and any data disks
try
{
    ConvertTo-AzureRmVMManagedDisk -ResourceGroupName $ResourceGroupName -VMName $VMName -ErrorAction Continue
}
catch
{
    Write-Host 'Convert to managed disks: error. This VM may already have been converted to managed disks.'
}

# Stop the VM in case it was started by managed disk conversion
Stop-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $VMName -Force

$vm = Get-AzureRmVm -ResourceGroupName $ResourceGroupName -Name $VMName

Write-Host ''

# Upgrade existing Standard disks to Premium storage
$diskUpdateConfig = New-AzureRmDiskUpdateConfig –AccountType PremiumLRS

$doItAgain = $true

while ($true -eq $doItAgain)
{
    Write-Host 'Starting storage upgrade loop'
    Write-Host ''

    $doItAgain = $false

    $vmDisks = Get-AzureRmDisk -ResourceGroupName $ResourceGroupName | Where-Object {$_.OwnerId -eq $vm.Id}

    foreach ($disk in $vmDisks) 
    {
        Write-Host ('Starting loop for disk: ' + $disk.Name)

        if ($disk.AccountType -ne 'PremiumLRS')
        {
            Write-Host ('Disk account type is ' + $disk.AccountType + '. Initiating upgrade to premium.')

            $doItAgain = $true

            Update-AzureRmDisk -DiskUpdate $diskUpdateConfig -ResourceGroupName $ResourceGroupName -DiskName $disk.Name
        }
        else
        {
            Write-Host ('Disk is already premium storage. No upgrade action will be taken.')
        }
    }

    Write-Host ''

    if ($true -eq $doItAgain)
    {
        Write-Host ('Found standard disks. Upgrade loop will be re-run.')

        Start-Sleep -s 5
    }
    else 
    {
        Write-Host ('Storage upgrade complete')
    }

    Write-Host ''
}


# Start the VM
if ($true -eq $Restart)
{
    Write-Host ('Starting VM')

    Start-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $VMName
}
