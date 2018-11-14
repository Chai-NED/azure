.\globals.ps1

$TemplateFilePathBastion = ".\vnetSubnetsNsgs.bastion.template.json"
$ParametersFilePathBastion = ".\vnetSubnetsNsgs.bastion.parameters.json"
$TemplateFilePathCluster = ".\vnetSubnetsNsgs.cluster.template.json"
$ParametersFilePathCluster = ".\vnetSubnetsNsgs.cluster.parameters.json"

if ($DeployBastion) {
	New-AzureRmResourceGroupDeployment `
		-Name $DeploymentName `
		-ResourceGroupName $ResourceGroupNameNetworkBastion `
		-TemplateFile $TemplateFilePathBastion `
		-TemplateParameterFile $ParametersFilePathBastion `
		-location $AzureRegionBastion `
		-vnet_name $VNetNameBastion `
		-vnet_address_space $VNetAddressSpaceBastion `
		-subnet_name $SubnetNameBastion `
		-subnet_address_space $SubnetAddressSpaceBastion `
		-nsg_name $NSGNameBastion `
		-external_source_ip $SourceIpAddressToAllow `
		-Verbose `
		-DeploymentDebugLogLevel All
}

if ($DeployCluster1) {
	New-AzureRmResourceGroupDeployment `
		-Name $DeploymentName `
		-ResourceGroupName $ResourceGroupNameNetworkCluster1 `
		-TemplateFile $TemplateFilePathCluster `
		-TemplateParameterFile $ParametersFilePathCluster `
		-location $AzureRegionCluster1 `
		-vnet_name $VNetNameCluster1 `
		-vnet_address_space $VNetAddressSpaceCluster1 `
		-subnet_name $SubnetNameCluster1 `
		-subnet_address_space $SubnetAddressSpaceCluster1 `
		-nsg_name $NSGNameCluster1 `
		-Verbose `
		-DeploymentDebugLogLevel All
}

if ($DeployCluster2) {
	New-AzureRmResourceGroupDeployment `
		-Name $DeploymentName `
		-ResourceGroupName $ResourceGroupNameNetworkCluster2 `
		-TemplateFile $TemplateFilePathCluster `
		-TemplateParameterFile $ParametersFilePathCluster `
		-location $AzureRegionCluster2 `
		-vnet_name $VNetNameCluster2 `
		-vnet_address_space $VNetAddressSpaceCluster2 `
		-subnet_name $SubnetNameCluster2 `
		-subnet_address_space $SubnetAddressSpaceCluster2 `
		-nsg_name $NSGNameCluster2 `
		-Verbose `
		-DeploymentDebugLogLevel All
}

if ($DeployCluster3) {
	New-AzureRmResourceGroupDeployment `
		-Name $DeploymentName `
		-ResourceGroupName $ResourceGroupNameNetworkCluster3 `
		-TemplateFile $TemplateFilePathCluster `
		-TemplateParameterFile $ParametersFilePathCluster `
		-location $AzureRegionCluster3 `
		-vnet_name $VNetNameCluster3 `
		-vnet_address_space $VNetAddressSpaceCluster3 `
		-subnet_name $SubnetNameCluster3 `
		-subnet_address_space $SubnetAddressSpaceCluster3 `
		-nsg_name $NSGNameCluster3 `
		-Verbose `
		-DeploymentDebugLogLevel All
}