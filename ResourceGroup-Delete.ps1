# ##############################
# Purpose: Delete a resource group.
#
# Author: Patrick El-Azem
# ##############################

# Arguments with defaults
param
(
    [string]$ResourceGroupName = ''
)

# Get RG
$rg = Get-AzureRmResourceGroup -Name $ResourceGroupName

if ($null -ne $rg)
{
   Write-Output ('Start: Delete ' + $rg.ResourceGroupName)
   Remove-AzureRmResourceGroup -Name $ResourceGroupName -Force
   Write-Output ('End: Delete ' + $rg.ResourceGroupName)
}
