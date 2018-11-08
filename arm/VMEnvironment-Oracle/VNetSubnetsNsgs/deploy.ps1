param
(
	[string]$DeploymentName,
	[string]$TemplateFilePath,
	[string]$ParametersFilePath,
    [string]$ResourceGroupName,
    [string]$AzureRegion,
    [string]$VNetName,
    [string]$VNetAddressSpace,
    [string]$SubnetNamePublic,
    [string]$SubnetAddressSpacePublic,
    [string]$SubnetNamePrivate1,
    [string]$SubnetAddressSpacePrivate1,
    [string]$SubnetNamePrivate2,
    [string]$SubnetAddressSpacePrivate2,
    [string]$NSGNamePublic,
    [string]$NSGNamePrivate1,
	[string]$NSGNamePrivate2,
	[string]$ExternalSourceIpAddress
)

New-AzureRmResourceGroupDeployment `
	-Name $DeploymentName `
	-ResourceGroupName $ResourceGroupName `
	-TemplateFile $TemplateFilePath `
	-TemplateParameterFile $ParametersFilePath `
	-location $AzureRegion `
	-vnet_name $VNetName `
	-vnet_address_space $VNetAddressSpace `
	-subnet_public_name $SubnetNamePublic `
	-subnet_public_address_space $SubnetAddressSpacePublic `
	-subnet_private1_name $SubnetNamePrivate1 `
	-subnet_private1_address_space $SubnetAddressSpacePrivate1 `
	-subnet_private2_name $SubnetNamePrivate2 `
	-subnet_private2_address_space $SubnetAddressSpacePrivate2 `
	-nsg_public_name $NSGNamePublic `
	-nsg_private1_name $NSGNamePrivate1 `
	-nsg_private2_name $NSGNamePrivate2 `
	-external_source_ip $ExternalSourceIpAddress `
	-Verbose `
	-DeploymentDebugLogLevel All
