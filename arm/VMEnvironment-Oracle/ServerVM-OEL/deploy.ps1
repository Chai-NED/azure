param
(
	[string]$DeploymentName,
	[string]$TemplateFilePath,
	[string]$ParametersFilePath,
    [string]$ResourceGroupNameVM,
	[string]$AzureRegion,
    [int]$AvailabilityZone,
    [string]$VMName,
    [string]$VMSize,
    [string]$VMAdminUsername,
	[securestring]$SSHPublicKeyData,
	[int]$DataDiskCountGroup1,
	[int]$DataDiskSizeGBGroup1,
	[int]$DataDiskCountGroup2,
	[int]$DataDiskSizeGBGroup2,
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
	-availability_zones $AvailabilityZone `
	-virtual_machine_name $VMName `
	-virtual_machine_size $VMSize `
	-admin_username $VMAdminUsername `
	-ssh_key_data $SSHPublicKeyData `
	-data_disk_count_group1 $DataDiskCountGroup1 `
	-data_disk_size_gb_group1 $DataDiskSizeGBGroup1 `
	-data_disk_count_group2 $DataDiskCountGroup2 `
	-data_disk_size_gb_group2 $DataDiskSizeGBGroup2 `
	-resource_group_name_network $ResourceGroupNameVNet `
	-vnet_name $VNetName `
	-subnet_name $SubnetName `
	-post_deploy_shell_command $PostDeployShellCmd `
	-Verbose `
	-DeploymentDebugLogLevel All
