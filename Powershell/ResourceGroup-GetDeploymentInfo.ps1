# Arguments with defaults
param
(
    [string]$SubscriptionId = '',
    [string]$ResourceGroupName = '',
    [string]$DeploymentName = ''
)

# Consider running a RG deploy with -DeploymentDebugLogLevel All so this gets more info

Get-AzureRmResourceGroupDeploymentOperation -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -DeploymentName $DeploymentName
