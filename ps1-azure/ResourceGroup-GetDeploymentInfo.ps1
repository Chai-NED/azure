# Arguments with defaults
param
(
    [string]$SubscriptionId = '',
    [string]$ResourceGroupName = '',
    [string]$DeploymentName = ''
)

Get-AzureRmResourceGroupDeploymentOperation -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -DeploymentName $DeploymentName -Verbose
