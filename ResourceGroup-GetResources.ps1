# ##############################
# Purpose: Get all resources in a resource group
#
# Author: Patrick El-Azem
# ##############################

# Arguments with defaults
param
(
    [string]$SubscriptionId = '',
    [string]$ResourceGroupName = ''
)

$resourceId = ("/subscriptions/" + $SubscriptionId + "/resourceGroups/" + $ResourceGroupName + "/resources")

$result = Get-AzureRmResource -ResourceId $resourceId

return $result