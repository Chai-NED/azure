## Written by Bret Swedeen

$subs = Get-AzureRmSubscription
$i = 0
while ($subs.SubscriptionId[$i] -ne $null)
{
    Write-Host $i $subs.SubscriptionName[$i]
    $i++
}
[int]$j = Read-Host -Prompt 'Enter the number to select the subscription'
if (($j -ge 0) -and ($j -lt $i)) {
    Write-Host "Switching to subscription:" $subs.SubscriptionName[$j]
    Set-AzureRmContext -SubscriptionId $subs.SubscriptionId[$j]    
} else {
    Write-Host "Invalid selection. Subscription not changed."
}
