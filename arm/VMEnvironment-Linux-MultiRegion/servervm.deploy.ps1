param
(
	[string]$AzureRegion,
	[string]$ResourceGroupNameVM,
	[string]$AvailabilitySetName,
    [string]$VMName,
	[string]$ResourceGroupNameNetwork,
    [string]$VNetName,
    [string]$SubnetName,
	[string]$PostDeployShellCmd
)

.\globals.ps1

$TemplateFilePath = ".\servervm.template.json"
$ParametersFilePath = ".\servervm.parameters.json"

New-AzureRmResourceGroupDeployment `
	-Name $DeploymentName `
	-ResourceGroupName $ResourceGroupNameVM `
	-TemplateFile $TemplateFilePath `
	-TemplateParameterFile $ParametersFilePath `
	-location $AzureRegion `
	-availability_set_name $AvailabilitySetName `
	-virtual_machine_name $VMName `
	-virtual_machine_size $ServerVMSize `
	-admin_username $ServerVMAdminUsername `
	-ssh_key_data $ServerVMSSHKeyData `
	-data_disk_count $ServerVMDataDiskCount `
	-data_disk_size_gb $ServerVMDataDiskSizeGB `
	-resource_group_name_network $ResourceGroupNameNetwork `
	-vnet_name $VNetName `
	-subnet_name $SubnetName `
	-post_deploy_shell_command $PostDeployShellCmd `
	-Verbose `
	-DeploymentDebugLogLevel All
