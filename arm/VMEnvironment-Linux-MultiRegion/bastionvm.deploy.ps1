param
(
	[string]$PostDeployShellCmd
)

.\globals.ps1

$TemplateFilePath = ".\bastionvm.template.json"
$ParametersFilePath = ".\bastionvm.parameters.json"

New-AzureRmResourceGroupDeployment `
	-Name $DeploymentName `
	-ResourceGroupName $ResourceGroupNameVMsBastion `
	-TemplateFile $TemplateFilePath `
	-TemplateParameterFile $ParametersFilePath `
	-location $AzureRegionBastion `
	-availability_set_name $BastionVMAvailabilitySetName `
	-resource_group_name_vm $ResourceGroupNameVMsBastion `
	-virtual_machine_name $BastionVMName `
	-virtual_machine_size $BastionVMSize `
	-admin_username $BastionVMAdminUsername `
	-ssh_key_data $BastionVMSSHKeyData `
	-resource_group_name_network $ResourceGroupNameNetworkBastion `
	-vnet_name $VNetNameBastion `
	-subnet_name $SubnetNameBastion `
	-post_deploy_shell_command $PostDeployShellCmd `
	-Verbose `
	-DeploymentDebugLogLevel All
