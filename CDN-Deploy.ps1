# ##############################
# Purpose: Create an Azure CDN with two endpoints. Origins are assumed to exist!
#
# Author: Patrick El-Azem
#
# NOTE:
# IsCompressionEnabled param does NOT work for New-AzureRmCdnEndpoint. => BadRequest. Seems this is so for both Verizon SKUs.
# New-AzureRmCdnEndpoint call that works for Standard_Verizon fails for Premium_Verizon. Have not yet figured out which parameter(s) are not supported in Premium.
# ##############################

# Arguments with defaults
param
(
    [string]$ResourceGroupName = '',
    [string]$Location = '',

    [string]$ProfileName = '',
    [Microsoft.Azure.Commands.Cdn.Models.Profile.PSSkuName]$CdnSkuName = '',

    [string]$EndPointNameBlob = ($ProfileName + 'epsas'),
    [string]$OriginHostNameBlob = '.blob.core.windows.net',
    [string]$OriginNameBlob = ($ProfileName + '-origin'),
    [bool]$IsCompressionEnabledBlob = $true,
    [bool]$IsHttpAllowedBlob = $true,
    [bool]$IsHttpsAllowedBlob = $false,
    [string]$OriginPathBlob = '/cdnassets',

    [string]$EndPointNameApi = ($ProfileName + 'epapi'),
    [string]$OriginHostNameApi = '.azurewebsites.net',
    [string]$OriginNameApi = ($ProfileName + '-origin'),
    [bool]$IsCompressionEnabledApi = $true,
    [bool]$IsHttpAllowedApi = $true,
    [bool]$IsHttpsAllowedApi = $false
)

# Create the CDN itself
$cdnprofile = New-AzureRmCdnProfile -ResourceGroupName $ResourceGroupName -Location $Location -ProfileName $ProfileName -Sku $CdnSkuName

# For query string caching behavior, see https://github.com/Azure/azure-powershell/pull/1972/files and search for "public enum PSQueryStringCachingBehavior" for the enum/values
# Create a query string caching behavior. We'll set both to use query string.
$QSCacheBehavior = New-Object Microsoft.Azure.Commands.Cdn.Models.Endpoint.PSQueryStringCachingBehavior
$QSCacheBehavior.value__ = 2  # UseQueryString

#Create endpoint that uses a blob storage account origin
New-AzureRmCdnEndpoint `
    -CdnProfile $cdnprofile `
    -EndpointName $EndPointNameBlob `
    -OriginHostName $OriginHostNameBlob `
    -OriginHostHeader $OriginHostNameBlob `
    -OriginName $OriginNameBlob `
    -OriginPath $OriginPathBlob `
    -IsHttpAllowed $IsHttpAllowedBlob `
    -IsHttpsAllowed $IsHttpsAllowedBlob `
    -QueryStringCachingBehavior $QSCacheBehavior

#Create endpoint that uses an API app origin
New-AzureRmCdnEndpoint `
    -CdnProfile $cdnprofile `
    -EndpointName $EndPointNameApi `
    -OriginHostName $OriginHostNameApi `
    -OriginHostHeader $OriginHostNameApi `
    -OriginName $OriginNameApi `
    -IsHttpAllowed $IsHttpAllowedApi `
    -IsHttpsAllowed $IsHttpsAllowedApi `
    -QueryStringCachingBehavior $QSCacheBehavior
