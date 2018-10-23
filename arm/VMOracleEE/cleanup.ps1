param
(
    [string]$SubscriptionId = '',
    [string]$ResourceGroupName = '',
    [string]$NamePrefixToDelete = ''
)

function GetResources()
{
	$resourceId = ("/subscriptions/" + $SubscriptionId + "/resourceGroups/" + $ResourceGroupName + "/resources")

	$result = Get-AzureRmResource -ResourceId $resourceId

	return $result
}

# Delete VMs first to remove any leases
Write-Host 'Removing VMs'

$vms = GetResources  | where {$_.Name -like ($NamePrefixToDelete + '*') -and $_.ResourceType -eq 'Microsoft.Compute/virtualMachines'}

$vms | foreach {Write-Host ('Removing ' + $_.Name + ' | ' + $_.ResourceId); Remove-AzureRmResource -ResourceId $_.ResourceId -Force}

# Delete other resources
Write-Host 'Removing other resources'

$resources = GetResources | where {$_.Name -like ($NamePrefixToDelete + '*')}

$resources | foreach {Write-Host ('Removing ' + $_.Name + ' | ' + $_.ResourceId); Remove-AzureRmResource -ResourceId $_.ResourceId -Force}
