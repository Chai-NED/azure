# ##############################
# Purpose: Create or get an NSG
#
# Author: Patrick El-Azem
# ##############################

# Arguments with defaults
param
(
    [string]$ResourceGroupName = '',
    [string]$Location = '',
    [string]$NSGName = '',
    [Microsoft.Azure.Commands.Network.Models.PSSecurityRule[]]$Rules = $null
)


# ##########
# Check if exists already and if not, create and get it
try
{
    $nsg = Get-AzureRmNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Name $NSGName -ErrorAction Stop
    Write-Host('Found existing NSG ' + $NSGName)
}
catch
{
    Write-Host('NSG ' + $NSGName + ': not found!')
    Write-Host('NSG ' + $NSGName + ': creating...')

    $nsg = New-AzureRmNetworkSecurityGroup `
        -ResourceGroupName $ResourceGroupName `
        -Location $Location `
        -Name $NSGName `
        -SecurityRules $Rules

    Write-Host('NSG ' + $NSGName + ': created.')
}
# ##########

return $nsg