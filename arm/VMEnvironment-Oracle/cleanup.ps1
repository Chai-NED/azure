.\globals.ps1

$NamePrefixToDelete = ($ResourceGroupNameVMs + '-')

function GetResources()
{
	$resourceId = ("/subscriptions/" + $SubscriptionId + "/resourceGroups/" + $ResourceGroupNameVMs + "/resources")

	$result = Get-AzureRmResource -ResourceId $resourceId

	return $result
}

# Delete VMs first to remove any leases
Write-Host 'Removing VMs'

$vms = GetResources  | Where-Object {$_.Name -like ($NamePrefixToDelete + '*') -and $_.ResourceType -eq 'Microsoft.Compute/virtualMachines'}

$vms | ForEach-Object {Write-Host ('Removing ' + $_.Name + ' | ' + $_.ResourceId); Remove-AzureRmResource -ResourceId $_.ResourceId -Force}

# Delete other resources
Write-Host 'Removing other resources'

$resources = GetResources | Where-Object {$_.Name -like ($NamePrefixToDelete + '*')}

$resources | ForEach-Object {Write-Host ('Removing ' + $_.Name + ' | ' + $_.ResourceId); Remove-AzureRmResource -ResourceId $_.ResourceId -Force}
