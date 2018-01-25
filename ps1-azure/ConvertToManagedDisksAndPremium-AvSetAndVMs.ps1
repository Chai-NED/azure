# ##############################
# Purpose: Update an availability set and all VMs in it to managed disks and upgrade from Standard to Premium storage.
# 
# Author: Patrick El-Azem
#
# Command line:
# .\ConvertToManagedDisksAndPremium-AvSetAndVMs.ps1 -ResourceGroupName 'MyResourceGroupName' 'MyCurrentAvsetName' -AvailabilitySetNameNew 'MyNewAvailabilitySetName' -VMName 'MyVMName'
# 
# Dependencies: have Azure Powershell latest installed; have separate Login-RM.ps1 in same folder as this to log into Azure.
#
# This file starts with a non-managed availability set containing VMs with unmanaged standard disks. The end goal is a managed availability set containing VMs with managed premium disks.
# Availability sets cannot be changed to managed while unmanaged VMs are associated with the availability set. So we create a new availability set that is managed, and VMs will move to that.
# Azure VMs cannot update their availability set; the availability set for a VM can only be set at VM create. Therefore, we will need to remove the existing VMs (preserving disks and NICs/PIPs) and re-create them in the new availability set.
# Here, we are upgrading each VM to managed disks, then to premium storage. The managed disk conversion has to be done before adding to the managed availability set (creating a non-managed disk VM and associating it to a managed availability set will fail).
# To do this, we will create an interim VM that is not associated with an availability set, and do the managed disk conversion and standard->premium storage upgrade at this point, for both OS and any data disks.
# Then, we remove the interim VM again and create the final VM associated with the new, managed availability set.
# ##############################

# Arguments with defaults
param
(
    [string]$ResourceGroupName = '',
    [string]$AvailabilitySetNameCurrent = '',
    [string]$AvailabilitySetNameNew = '',
    [string]$VMSizeForNewVMs = '',
    [int]$FaultDomainCount = 3,
    [int]$UpdateDomainCount = 5
)


# Get the current availability set 
$avsetCurrent = Get-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $AvailabilitySetNameCurrent

if (-not $avsetCurrent)
{
    Write-Host ('Current availability set not found! Exiting.')
    exit
}


# Sanity checks for fault and update domain counts for new availability set
if (-not $FaultDomainCount -or $FaultDomainCount -le 1)
{
    $FaultDomainCount = $avsetCurrent.PlatformFaultDomainCount
    Write-Host ('Fault domain count: ' + $FaultDomainCount)
}

if (-not $UpdateDomainCount -or $UpdateDomainCount -le 1)
{
    $UpdateDomainCount = $avsetCurrent.PlatformUpdateDomainCount
    Write-Host ('Update domain count: ' + $UpdateDomainCount)
}



# Get the new availability set
$avsetNew = Get-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $AvailabilitySetNameNew -ErrorAction Ignore

# Create new managed availability set if it doesn't exist yet
if (-not $avsetNew)
{
    New-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Location $avsetCurrent.Location -Name $AvailabilitySetNameNew -PlatformUpdateDomainCount $UpdateDomainCount -PlatformFaultDomainCount $FaultDomainCount

    $avsetNew = Get-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $AvailabilitySetNameNew
}

# Whether it existed or not, make sure the availability set is managed
Update-AzureRmAvailabilitySet -AvailabilitySet $avsetNew -Managed


# Upgrade existing Standard disks to Premium storage
$diskUpdateConfig = New-AzureRmDiskUpdateConfig –AccountType PremiumLRS


# Iterate through each VM
foreach($vmInfo in $avsetCurrent.VirtualMachinesReferences)
{
    $vm = Get-AzureRmVM -ResourceGroupName $ResourceGroupName | Where-Object {$_.Id -eq $vmInfo.id}

    # Determine size for new VM. If a size was passed in, use that. Otherwise use old VM size.
    # One problem with this: if no size was passed, AND old VM used a size for which Premium storage is not available, new VM creation will fail below.
    # For this script, could be safest to pass a good VM size default, and then after this script resize individual VMs in availability set as needed.
    $vmNewSize = $null

    if (-not $VMSizeForNewVMs)
    {
        $vmNewSize = $vm.HardwareProfile.VmSize
    }
    else
    {
        $vmNewSize = $VMSizeForNewVMs
    }

    Write-Host ('New VM size: ' + $vmNewSize)


    # Stop and deallocate the VM
    Stop-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $vm.Name -Force

    # Remove the original VM
    Remove-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $vm.Name -Force


    # ##################################################
    # Create interim VM not in availability set
    $vmInterim = New-AzureRmVMConfig -VMName $vm.Name -VMSize $vmNewSize
    Set-AzureRmVMOSDisk -VM $vmInterim -VhdUri $vm.StorageProfile.OsDisk.Vhd.Uri -Name $vm.Name -CreateOption Attach -Windows

    #Add Data Disks
    foreach ($disk in $vm.StorageProfile.DataDisks)
    {
        Add-AzureRmVMDataDisk -VM $vmInterim -Name $disk.Name -VhdUri $disk.Vhd.Uri -Caching $disk.Caching -Lun $disk.Lun -CreateOption Attach -DiskSizeInGB $disk.DiskSizeGB
    }

    #Add NIC(s)
    foreach ($nic in $vm.NetworkInterfaceIDs)
    {
        Add-AzureRmVMNetworkInterface -VM $vmInterim -Id $nic
    }

    #Create the VM
    New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $vm.Location -VM $vmInterim -DisableBginfoExtension

    # Stop and deallocate the VM
    Stop-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $vmInterim.Name -Force

    # Convert VM to managed disks
    ConvertTo-AzureRmVMManagedDisk -ResourceGroupName $ResourceGroupName -VMName $vmInterim.Name

    # Stop and deallocate the VM
    Stop-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $vmInterim.Name -Force

    # Get an updated instance of the interim VM so we have up-to-date storage profile
    $vmInterim = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $vmInterim.Name


    # Loop here because occasionally I have observed the standard->premium upgrade not work, so keep at it until it does!
    $doItAgain = $true

    while ($true -eq $doItAgain)
    {
        Write-Host 'Starting storage upgrade loop'
        Write-Host ''

        $doItAgain = $false

        $vmDisks = Get-AzureRmDisk -ResourceGroupName $ResourceGroupName | Where-Object {$_.OwnerId -eq $vmInterim.Id}

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


    # Get an updated instance of the interim VM so we have up-to-date storage profile
    $vmInterim = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $vmInterim.Name


    # Remove the interim VM
    Remove-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $vmInterim.Name -Force
    # ##################################################



    # Create replacement VM
    $vmNew = New-AzureRmVMConfig -VMName $vm.Name -VMSize $vmNewSize -AvailabilitySetId $avsetNew.Id
    Set-AzureRmVMOSDisk -VM $vmNew -ManagedDiskId $vmInterim.StorageProfile.OsDisk.ManagedDisk.Id -CreateOption Attach -Windows

    #Add Data Disks
    foreach ($disk in $vmInterim.StorageProfile.DataDisks)
    {
        Add-AzureRmVMDataDisk -VM $vmNew -Name $disk.Name -ManagedDiskId $disk.ManagedDisk.Id  -Caching $disk.Caching -Lun $disk.Lun -CreateOption Attach # -DiskSizeInGB $disk.DiskSizeGB
    }

    #Add NIC(s)
    foreach ($nic in $vm.NetworkInterfaceIDs)
    {
        Add-AzureRmVMNetworkInterface -VM $vmNew -Id $nic
    }

    #Create the VM
    New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $vm.Location -VM $vmNew -DisableBginfoExtension
}