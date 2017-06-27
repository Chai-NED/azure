# ##############################
# Purpose: Check whether an Azure login context already exists. If not, invoke the login UI/process.
#
# Author: Patrick El-Azem
# ##############################

param
(
    [string]$SubscriptionId = ''
)


$loginContext = Get-AzureRmContext

if ($null -eq $loginContext -or $null -eq $loginContext.Subscription)
{
    Login-AzureRmAccount | Out-Null
}

Set-AzureRmContext -SubscriptionId $SubscriptionId | Out-Null

Get-AzureRmContext