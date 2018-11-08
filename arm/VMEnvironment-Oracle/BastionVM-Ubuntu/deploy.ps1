param
(
	[string]$DeploymentName,
	[string]$TemplateFilePath,
	[string]$ParametersFilePath,
    [string]$ResourceGroupNameVM,
	[string]$AzureRegion,
    [string]$VMAvailabilitySetName,
    [string]$VMName,
    [string]$VMSize,
    [string]$VMAdminUsername,
    [securestring]$SSHPublicKeyData,
	[string]$ResourceGroupNameVNet,
    [string]$VNetName,
    [string]$SubnetName,
    [string]$PostDeployShellCmd
)

New-AzureRmResourceGroupDeployment `
	-Name $DeploymentName `
	-ResourceGroupName $ResourceGroupNameVM `
	-TemplateFile $TemplateFilePath `
	-TemplateParameterFile $ParametersFilePath `
	-location $AzureRegion `
	-availability_set_name $VMAvailabilitySetName `
	-resource_group_name_vm $ResourceGroupNameVM `
	-virtual_machine_name $VMName `
	-virtual_machine_size $VMSize `
	-admin_username $VMAdminUsername `
	-ssh_key_data $SSHPublicKeyData `
	-resource_group_name_network $ResourceGroupNameVNet `
	-vnet_name $VNetName `
	-subnet_name $SubnetName `
	-post_deploy_shell_command $PostDeployShellCmd `
	-Verbose `
	-DeploymentDebugLogLevel All
