.\globals.ps1

$TemplateFilePath = ".\vnetPeerings.template.json"
$ParametersFilePath = ".\vnetPeerings.parameters.json"

function DoPeering()
{
	param
	(
		[string]$ResourceGroupNameLocal,
		[string]$ResourceGroupNameRemote,
		[string]$VNetNameLocal,
		[string]$VNetNameRemote,
		[string]$VNetAddressSpaceRemote
	)

	New-AzureRmResourceGroupDeployment `
		-Name $DeploymentName `
		-ResourceGroupName $ResourceGroupNameLocal `
		-TemplateFile $TemplateFilePath `
		-TemplateParameterFile $ParametersFilePath `
		-subscription_id $SubscriptionId `
		-resource_group_name_remote $ResourceGroupNameRemote `
		-vnet_name_local $VNetNameLocal `
		-vnet_name_remote $VNetNameRemote `
		-vnet_address_space_remote $VNetAddressSpaceRemote `
		-Verbose `
		-DeploymentDebugLogLevel All
}

# Bastion -> Cluster1
if ($DeployBastion -and $DeployCluster1) {
	DoPeering -ResourceGroupNameLocal $ResourceGroupNameNetworkBastion -ResourceGroupNameRemote $ResourceGroupNameNetworkCluster1 -VNetNameLocal $VNetNameBastion -VNetNameRemote $VNetNameCluster1 -VNetAddressSpaceRemote $VNetAddressSpaceCluster1
}

# Bastion -> Cluster2
if ($DeployBastion -and $DeployCluster2) {
	DoPeering -ResourceGroupNameLocal $ResourceGroupNameNetworkBastion -ResourceGroupNameRemote $ResourceGroupNameNetworkCluster2 -VNetNameLocal $VNetNameBastion -VNetNameRemote $VNetNameCluster2 -VNetAddressSpaceRemote $VNetAddressSpaceCluster2
}

# Bastion -> Cluster3
if ($DeployBastion -and $DeployCluster3) {
	DoPeering -ResourceGroupNameLocal $ResourceGroupNameNetworkBastion -ResourceGroupNameRemote $ResourceGroupNameNetworkCluster3 -VNetNameLocal $VNetNameBastion -VNetNameRemote $VNetNameCluster3 -VNetAddressSpaceRemote $VNetAddressSpaceCluster3
}

# Cluster1 -> Bastion
if ($DeployCluster1 -and $DeployBastion) {
	DoPeering -ResourceGroupNameLocal $ResourceGroupNameNetworkCluster1 -ResourceGroupNameRemote $ResourceGroupNameNetworkBastion -VNetNameLocal $VNetNameCluster1 -VNetNameRemote $VNetNameBastion -VNetAddressSpaceRemote $VNetAddressSpaceBastion
}

# Cluster1 -> Cluster2
if ($DeployCluster1 -and $DeployCluster2) {
	DoPeering -ResourceGroupNameLocal $ResourceGroupNameNetworkCluster1 -ResourceGroupNameRemote $ResourceGroupNameNetworkCluster2 -VNetNameLocal $VNetNameCluster1 -VNetNameRemote $VNetNameCluster2 -VNetAddressSpaceRemote $VNetAddressSpaceCluster2
}

# Cluster1 -> Cluster3
if ($DeployCluster1 -and $DeployCluster3) {
	DoPeering -ResourceGroupNameLocal $ResourceGroupNameNetworkCluster1 -ResourceGroupNameRemote $ResourceGroupNameNetworkCluster3 -VNetNameLocal $VNetNameCluster1 -VNetNameRemote $VNetNameCluster3 -VNetAddressSpaceRemote $VNetAddressSpaceCluster3
}

# Cluster2 -> Bastion
if ($DeployCluster2 -and $DeployBastion) {
	DoPeering -ResourceGroupNameLocal $ResourceGroupNameNetworkCluster2 -ResourceGroupNameRemote $ResourceGroupNameNetworkBastion -VNetNameLocal $VNetNameCluster2 -VNetNameRemote $VNetNameBastion -VNetAddressSpaceRemote $VNetAddressSpaceBastion
}

# Cluster2 -> Cluster1
if ($DeployCluster2 -and $DeployCluster1) {
	DoPeering -ResourceGroupNameLocal $ResourceGroupNameNetworkCluster2 -ResourceGroupNameRemote $ResourceGroupNameNetworkCluster1 -VNetNameLocal $VNetNameCluster2 -VNetNameRemote $VNetNameCluster1 -VNetAddressSpaceRemote $VNetAddressSpaceCluster1
}

# Cluster2 -> Cluster3
if ($DeployCluster2 -and $DeployCluster3) {
	DoPeering -ResourceGroupNameLocal $ResourceGroupNameNetworkCluster2 -ResourceGroupNameRemote $ResourceGroupNameNetworkCluster3 -VNetNameLocal $VNetNameCluster2 -VNetNameRemote $VNetNameCluster3 -VNetAddressSpaceRemote $VNetAddressSpaceCluster3
}

# Cluster3 -> Bastion
if ($DeployCluster3 -and $DeployBastion) {
	DoPeering -ResourceGroupNameLocal $ResourceGroupNameNetworkCluster3 -ResourceGroupNameRemote $ResourceGroupNameNetworkBastion -VNetNameLocal $VNetNameCluster3 -VNetNameRemote $VNetNameBastion -VNetAddressSpaceRemote $VNetAddressSpaceBastion
}

# Cluster3 -> Cluster1
if ($DeployCluster3 -and $DeployCluster1) {
	DoPeering -ResourceGroupNameLocal $ResourceGroupNameNetworkCluster3 -ResourceGroupNameRemote $ResourceGroupNameNetworkCluster1 -VNetNameLocal $VNetNameCluster3 -VNetNameRemote $VNetNameCluster1 -VNetAddressSpaceRemote $VNetAddressSpaceCluster1
}

# Cluster3 -> Cluster2
if ($DeployCluster3 -and $DeployCluster2) {
	DoPeering -ResourceGroupNameLocal $ResourceGroupNameNetworkCluster3 -ResourceGroupNameRemote $ResourceGroupNameNetworkCluster2 -VNetNameLocal $VNetNameCluster3 -VNetNameRemote $VNetNameCluster2 -VNetAddressSpaceRemote $VNetAddressSpaceCluster2
}
