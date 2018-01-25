# ##############################
# Purpose: Create VNet
#
# Author: Patrick El-Azem
# ##############################

# Arguments with defaults
param
(
    [string]$ResourceGroupName = '',
    [string]$Location = '',
    [string]$VNetName = '',
    [string]$VNetPrefix = ''
)

# ##########
# Check if exists already and if not, create and get it
try
{
    $vnet = Get-AzureRmVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroupName -ErrorAction Stop
    Write-Host('Found existing VNet ' + $VNetName)
}
catch
{
    Write-Host('VNet ' + $VNetName + ': not found!')
    Write-Host('VNet ' + $VNetName + ': creating...')
    $vnet = New-AzureRmVirtualNetwork -ResourceGroupName $ResourceGroupName -Location $Location -Name $VNetName -AddressPrefix $VNetPrefix
    Write-Host('VNet ' + $VNetName + ': created.')
}
# ##########

return $vnet