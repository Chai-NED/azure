param
(
	[string]$DeploymentName,
	[string]$TemplateFilePath,
	[string]$ParametersFilePath,
    [string]$SubscriptionId,
    [string]$ResourceGroupNameStorage,
	[string]$AzureRegion,
    [string]$StorageAccountName,
	[string]$ResourceGroupNameVNet,
    [string]$VNetName,
    [string]$SubnetNamePublic,
    [string]$SubnetNamePrivate1,
    [string]$SubnetNamePrivate2,
	[string]$ExternalSourceIpAddress
)

New-AzureRmResourceGroupDeployment `
	-Name $DeploymentName `
	-ResourceGroupName $ResourceGroupNameStorage `
	-TemplateFile $TemplateFilePath `
	-TemplateParameterFile $ParametersFilePath `
	-subscription_id $SubscriptionId `
	-location $AzureRegion `
	-storage_account_name $StorageAccountName `
	-resource_group_name_vnet $ResourceGroupNameVNet `
	-vnet_name $VNetName `
	-subnet_names $SubnetNamePublic, $SubnetNamePrivate1, $SubnetNamePrivate2 `
	-external_source_ip $ExternalSourceIpAddress `
	-Verbose `
	-DeploymentDebugLogLevel All
