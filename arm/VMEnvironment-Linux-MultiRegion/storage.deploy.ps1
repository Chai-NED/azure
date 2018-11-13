.\globals.ps1

$TemplateFilePath = ".\storage.template.json"
$ParametersFilePath = ".\storage.parameters.json"

# Bastion
New-AzureRmResourceGroupDeployment `
	-Name $DeploymentName `
	-ResourceGroupName $ResourceGroupNameStorageBastion `
	-TemplateFile $TemplateFilePath `
	-TemplateParameterFile $ParametersFilePath `
	-subscription_id $SubscriptionId `
	-location $AzureRegionBastion `
	-storage_account_name $StorageAccountNameBastion `
	-resource_group_name_vnet $ResourceGroupNameNetworkBastion `
	-vnet_name $VNetNameBastion `
	-subnet_names $SubnetNameBastion `
	-external_source_ip $SourceIpAddressToAllow `
	-Verbose `
	-DeploymentDebugLogLevel All

# Cluster1
New-AzureRmResourceGroupDeployment `
	-Name $DeploymentName `
	-ResourceGroupName $ResourceGroupNameStorageCluster1 `
	-TemplateFile $TemplateFilePath `
	-TemplateParameterFile $ParametersFilePath `
	-subscription_id $SubscriptionId `
	-location $AzureRegionCluster1 `
	-storage_account_name $StorageAccountNameCluster1 `
	-resource_group_name_vnet $ResourceGroupNameNetworkCluster1 `
	-vnet_name $VNetNameCluster1 `
	-subnet_names $SubnetNameCluster1 `
	-external_source_ip $SourceIpAddressToAllow `
	-Verbose `
	-DeploymentDebugLogLevel All

# Cluster2
New-AzureRmResourceGroupDeployment `
	-Name $DeploymentName `
	-ResourceGroupName $ResourceGroupNameStorageCluster2 `
	-TemplateFile $TemplateFilePath `
	-TemplateParameterFile $ParametersFilePath `
	-subscription_id $SubscriptionId `
	-location $AzureRegionCluster2 `
	-storage_account_name $StorageAccountNameCluster2 `
	-resource_group_name_vnet $ResourceGroupNameNetworkCluster2 `
	-vnet_name $VNetNameCluster2 `
	-subnet_names $SubnetNameCluster2 `
	-external_source_ip $SourceIpAddressToAllow `
	-Verbose `
	-DeploymentDebugLogLevel All

# Cluster3
New-AzureRmResourceGroupDeployment `
	-Name $DeploymentName `
	-ResourceGroupName $ResourceGroupNameStorageCluster3 `
	-TemplateFile $TemplateFilePath `
	-TemplateParameterFile $ParametersFilePath `
	-subscription_id $SubscriptionId `
	-location $AzureRegionCluster3 `
	-storage_account_name $StorageAccountNameCluster3 `
	-resource_group_name_vnet $ResourceGroupNameNetworkCluster3 `
	-vnet_name $VNetNameCluster3 `
	-subnet_names $SubnetNameCluster3 `
	-external_source_ip $SourceIpAddressToAllow `
	-Verbose `
	-DeploymentDebugLogLevel All
