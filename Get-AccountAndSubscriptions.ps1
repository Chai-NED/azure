# ##############################
# Purpose: Get Azure RM account subscriptions, default subscription, specific subscription. Set specific subscription to context, list storage accounts.
#
# Author: Patrick El-Azem
# ##############################

# Arguments with defaults
param
(
    [string]$SubscriptionName = $null,
    [string]$SubscriptionId = $null
)

# Get all subscriptions linked to v2 account/subscription
Write-Host 'Start: Get all subscriptions for logged-in account'
Get-AzureRmSubscription
Write-Host 'End: Get all subscriptions for logged-in account'

# Get a specific subscription by Id if provided
if ($null -ne $SubscriptionId -and '' -ne $SubscriptionId)
{
    Write-Host ''
    Write-Host ('Start: Get subscription by Id: ' + $SubscriptionId)

    # Get subscription and pipe to context
    # This is ONLY for the current Powershell session - it will NOT persist for future sessions
    Get-AzureRmSubscription -SubscriptionId $SubscriptionId | Set-AzureRmContext

    # Get storage accounts
    Get-AzureRmStorageAccount

    Write-Host ('End: Get subscription by Id: ' + $SubscriptionId)
}

# Get a specific subscription by Name if provided
if ($null -ne $SubscriptionName -and '' -ne $SubscriptionName)
{
    Write-Host ''
    Write-Host ('Start: Get subscription by Name: ' + $SubscriptionName)

    # Get subscription and pipe to context
    # This is ONLY for the current Powershell session - it will NOT persist for future sessions
    Get-AzureRmSubscription -SubscriptionName $SubscriptionName | Set-AzureRmContext

    # Get storage accounts
    Get-AzureRmStorageAccount

    Write-Host ('End: Get subscription by Name: ' + $SubscriptionName)
}
