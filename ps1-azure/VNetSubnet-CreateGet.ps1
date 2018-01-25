# ##############################
# Purpose: Create VNet + Subnet
#
# Author: Patrick El-Azem
# ##############################

# Arguments with defaults
param
(
    [string]$ResourceGroupName = '',
    [string]$Location = 'East US',
    [string]$VNetName = '',
    [string]$VNetPrefix = '',
    [string]$SubnetName = '',
    [string]$SubnetPrefix = '',
    [string]$NSGResourceId = $null
)

# Get a VNet object
$vnet = .\VNet-CreateGet.ps1 -ResourceGroupName $ResourceGroupName -Location $Location -VNetName $VNetName -Prefix $VNetPrefix

# ##########
# Check if exists already and if not, create and get it
try
{
    $subnet = Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $SubnetName -ErrorAction Stop
    Write-Host('Subnet ' + $SubnetName + ': found.')
}
catch
{
    Write-Host('Subnet ' + $SubnetName + ': not found!')
    Write-Host('Subnet ' + $SubnetName + ': creating...')

    New-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetPrefix -NetworkSecurityGroupId $NSGResourceId | `
    Add-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $SubnetName -AddressPrefix $SubnetPrefix | Out-Null

    Set-AzureRmVirtualNetwork -VirtualNetwork $vnet | Out-Null

    # Refresh VNet so can return up to date subnet object
    $vnet = .\VNet-CreateGet.ps1 -ResourceGroupName $ResourceGroupName -Location $Location -VNetName $VNetName -Prefix $VNetPrefix

    $subnet = Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $SubnetName -ErrorAction Stop

    Write-Host('Subnet ' + $SubnetName + ': created.')
}
# ##########

return $subnet