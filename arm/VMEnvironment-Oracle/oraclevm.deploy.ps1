param
(
    [int]$AvailabilityZone,
    [string]$VMName,
    [string]$SubnetName,
	[string]$PostDeployShellCmd
)

.\globals.ps1

$TemplateFilePath = ".\oraclevm.template.json"
$ParametersFilePath = ".\oraclevm.parameters.json"

New-AzureRmResourceGroupDeployment `
	-Name $DeploymentName `
	-ResourceGroupName $ResourceGroupNameVMs `
	-TemplateFile $TemplateFilePath `
	-TemplateParameterFile $ParametersFilePath `
	-location $AzureRegion `
	-availability_zones $AvailabilityZone `
	-virtual_machine_name $VMName `
	-virtual_machine_size $ServerVMSize `
	-admin_username $ServerVMAdminUsername `
	-ssh_key_data $ServerVMSSHKeyData `
	-data_disk_count_group1 $ServerVMDataDiskCountGroup1 `
	-data_disk_size_gb_group1 $ServerVMDataDiskSizeGBGroup1 `
	-data_disk_count_group2 $ServerVMDataDiskCountGroup2 `
	-data_disk_size_gb_group2 $ServerVMDataDiskSizeGBGroup2 `
	-resource_group_name_network $ResourceGroupNameNetwork `
	-vnet_name $VNetName `
	-subnet_name $SubnetName `
	-post_deploy_shell_command $PostDeployShellCmd `
	-Verbose `
	-DeploymentDebugLogLevel All
