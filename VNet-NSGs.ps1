# ##############################
# Purpose: Create NSG and rules
#
# Author: Patrick El-Azem
# ##############################

# Arguments with defaults
param
(
    [string]$ResourceGroupName = '',
    [string]$Location = 'East US',
    [string]$VNetName = '',
    [string]$FrontEndSubnetName = '',
    [string]$FrontEndSubnetPrefix = '',
    [string]$FrontEndNSGName = ''
)

$frontEndRule1 = New-AzureRmNetworkSecurityRuleConfig -Name rdp-rule -Description "Allow RDP" `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 `
    -SourceAddressPrefix Internet -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange 3389

$frontEndNsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Location $Location -Name $FrontEndNSGName `
    -SecurityRules $frontEndRule1

$frontEndNsg

$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VNetName

Set-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $FrontEndSubnetName `
    -AddressPrefix $FrontEndSubnetPrefix -NetworkSecurityGroup $frontEndNsg

Set-AzureRmVirtualNetwork -VirtualNetwork $vnet
