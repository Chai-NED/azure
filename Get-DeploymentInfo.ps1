# When an ARM deployment completes it will provide a tracking ID (a GUID). Provide that to get detailed deployment info, especially for failed deployments.
param
(
    [string]$CorrelationId = ''
)

Get-AzureRMLog -CorrelationId $CorrelationId -DetailedOutput