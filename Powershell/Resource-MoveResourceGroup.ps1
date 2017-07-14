# ##############################
# Purpose: Move a resource from a source to a target resource group
#
# Author: Patrick El-Azem
# ##############################

# Arguments with defaults
param
(
    [string]$ResourceGroupNameSource = '',
    [string]$ResourceGroupNameTarget = '',
    [string]$ResourceName = ''
)

$resource = Get-AzureRmResource -ResourceName $ResourceName -ResourceGroupName $ResourceGroupNameSource

Move-AzureRmResource -DestinationResourceGroupName $ResourceGroupNameTarget -ResourceId $resource.ResourceId -Force