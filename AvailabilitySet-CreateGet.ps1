# ##############################
# Purpose: Create/get an availability set
#
# Author: Patrick El-Azem
# ##############################

# Arguments with defaults
param
(
    [string]$ResourceGroupName = '',
    [string]$Location = '',
    [string]$AvailabilitySetName = '',
    [int]$FaultDomains = 3,
    [int]$UpdateDomains = 5,
    [bool]$Managed = $false
)

$avset = Get-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $AvailabilitySetName -ErrorAction Ignore

if ($null -eq $avset)
{
    New-AzureRmAvailabilitySet -Location $Location -Name $AvailabilitySetName -ResourceGroupName $ResourceGroupName -PlatformFaultDomainCount $FaultDomains -PlatformUpdateDomainCount $UpdateDomains | Out-Null

    $avset = Get-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $AvailabilitySetName
}

if ($Managed)
{
    Update-AzureRmAvailabilitySet -AvailabilitySet $avset -Managed | Out-Null
}

return $avset