param
(
	[string]$PostDeployShellCmd
)

.\globals.ps1

$TemplateFilePath = ".\bastionvm.template.json"
$ParametersFilePath = ".\bastionvm.parameters.json"

New-AzureRmResourceGroupDeployment `
	-Name $DeploymentName `
	-ResourceGroupName $ResourceGroupNameVMs `
	-TemplateFile $TemplateFilePath `
	-TemplateParameterFile $ParametersFilePath `
	-location $AzureRegion `
	-availability_set_name $BastionVMAvailabilitySetName `
	-resource_group_name_vm $ResourceGroupNameVMs `
	-virtual_machine_name $BastionVMName `
	-virtual_machine_size $BastionVMSize `
	-admin_username $BastionVMAdminUsername `
	-ssh_key_data $BastionVMSSHKeyData `
	-resource_group_name_network $ResourceGroupNameNetwork `
	-vnet_name $VNetName `
	-subnet_name $SubnetNamePublic `
	-post_deploy_shell_command $PostDeployShellCmd `
	-Verbose `
	-DeploymentDebugLogLevel All
