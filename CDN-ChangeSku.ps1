# ##############################
# Purpose: Update an existing CDN profile to a different pricing SKU
#
# Author: Patrick El-Azem
#
# NOTE: 1/17/2017 while this code runs successfully, it does not appear to change the CDN profile's SKU even after several minutes. TBD.
# ##############################

# Arguments with defaults
param
(
    [string]$ResourceGroupName = '',
    [string]$ProfileName = '',
    [string]$Location = '',
    [Microsoft.Azure.Commands.Cdn.Models.Profile.PSSkuName]$CdnSkuName = ''
)

$cdnprofile = Get-AzureRmCdnProfile -ProfileName $ProfileName -ResourceGroupName $ResourceGroupName

$pssku = New-Object Microsoft.Azure.Commands.Cdn.Models.Profile.PSSku
$pssku.Name = $CdnSkuName

$cdnprofile.Sku = $pssku

Set-AzureRmCdnProfile -CdnProfile $cdnprofile