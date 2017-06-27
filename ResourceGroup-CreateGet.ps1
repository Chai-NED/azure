# ##############################
# Purpose: Get a resource group. Create if it doesn't exist.
#
# Author: Patrick El-Azem
# ##############################

# Arguments with defaults
param
(
    [string]$ResourceGroupName = '',
    [string]$Location = ''
)

# Variables
# $tags = @{Name='Period';Value='FY16'}, @{Name='Department';Value='Training'} | Out-Null

# ##########
# Check if RG exists already and if not, create and get it
try
{
    $rg = Get-AzureRmResourceGroup -Name $ResourceGroupName -ErrorAction Stop
    Write-Host('Resource group ' + $ResourceGroupName + ': found.')
}
catch
{
    Write-Host('Resource group ' + $ResourceGroupName + ': not found!')
    Write-Host('Resource group ' + $ResourceGroupName + ': creating...')
    $rg = New-AzureRmResourceGroup -Location $Location -Name $ResourceGroupName
    Write-Host('Resource group ' + $ResourceGroupName + ': created.')
}
# ##########

return $rg