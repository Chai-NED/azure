.\globals.ps1

$TemplateFilePath = ".\storage.template.json"
$ParametersFilePath = ".\storage.parameters.json"

New-AzureRmResourceGroupDeployment `
	-Name $DeploymentName `
	-ResourceGroupName $ResourceGroupNameStorage `
	-TemplateFile $TemplateFilePath `
	-TemplateParameterFile $ParametersFilePath `
	-subscription_id $SubscriptionId `
	-location $AzureRegion `
	-storage_account_name $StorageAccountName `
	-resource_group_name_vnet $ResourceGroupNameNetwork `
	-vnet_name $VNetName `
	-subnet_names $SubnetNamePublic, $SubnetNamePrivate1, $SubnetNamePrivate2 `
	-external_source_ip $SourceIpAddressToAllow `
	-Verbose `
	-DeploymentDebugLogLevel All
