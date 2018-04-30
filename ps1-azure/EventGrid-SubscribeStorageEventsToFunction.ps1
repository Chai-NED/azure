param(
    [string]
    $eventSubscriptionName = $null,

    [string]
    $storageAccountResourceGroup = $null,

    [string]
    $storageAccountName = $null,

    [string]
    $storageAccountFilterPrefix = $null,

    [string]
    $storageAccountFilterSuffix = $null,

    [string]
    $functionEndpoint = $null
)

$storageAcct = Get-AzureRmStorageAccount -ResourceGroupName $storageAccountResourceGroup -Name $storageAccountName

if (!$storageAcct)
{
    Write-Host "Error! Could not get storage account."
    Return
}

if ($storageAccountFilterPrefix)
{
    $subject = "/blobServices/default/containers/"

    # Prepend standard storage account subject if the passed prefix does not already start with it
    if ($storageAccountFilterPrefix.StartsWith($subject))
    {
        $prefix = $storageAccountFilterPrefix
    }
    else
    {
        $prefix = ($subject + $storageAccountFilterPrefix)
    }

    Write-Host ("Using SubjectBeginsWith = " + $prefix)
}


# Looks like New-AzureRmEventGridSubscription is not tolerant of nulls/empties being passed for -SubjectBeginsWith or -SubjectEndsWith
# So have to break it out to four distinct cases... blech
if (!$storageAccountFilterPrefix -and !$storageAccountFilterSuffix)
{
    # Neither prefix nor suffix specified
    Write-Host "Neither prefix nor suffix specified"

    New-AzureRmEventGridSubscription `
        -Endpoint $functionEndpoint `
        -EventSubscriptionName $eventSubscriptionName `
        -ResourceId $storageAcct.Id `
        -EndpointType webhook
}
elseif (!$storageAccountFilterPrefix -and $storageAccountFilterSuffix)
{
    # Suffix, but no prefix
    Write-Host "Suffix was specified. Prefix was not specified."

    New-AzureRmEventGridSubscription `
        -Endpoint $functionEndpoint `
        -EventSubscriptionName $eventGridSubscriptionName `
        -ResourceId $storageAcct.Id `
        -EndpointType webhook `
        -SubjectEndsWith $storageAccountFilterSuffix
}
elseif ($storageAccountFilterPrefix -and !$storageAccountFilterSuffix)
{
    # Prefix, but no suffix
    Write-Host "Prefix was specified. Suffix was not specified."

    New-AzureRmEventGridSubscription `
        -Endpoint $functionEndpoint `
        -EventSubscriptionName $eventGridSubscriptionName `
        -ResourceId $storageAcct.Id `
        -EndpointType webhook `
        -SubjectBeginsWith $prefix
}
else
{
    # Both prefix and suffix
    Write-Host "Both prefix and suffix were specified."

    New-AzureRmEventGridSubscription `
        -Endpoint $functionEndpoint `
        -EventSubscriptionName $eventGridSubscriptionName `
        -ResourceId $storageAcct.Id `
        -EndpointType webhook `
        -SubjectBeginsWith $prefix `
        -SubjectEndsWith $storageAccountFilterSuffix
}
