### NOTES
# This PS script uses params for New-AzureRmResourceGroupDeployment: -Verbose -DeploymentDebugLogLevel All
# These params WILL result in extra logging, including to Azure deployment results.
# This WILL result in sensitive values (like the ssh key) being potentially available after the fact.
# For Production deployments, you should remove these params from the New-AzureRmResourceGroupDeployment calls below.

# The Azure region below is set to "centralus". Not all Azure regions explicitly expose, or allow selection of, specific availability zones yet.
# See https://docs.microsoft.com/en-us/azure/virtual-machines/linux/create-cli-availability-zone#check-vm-sku-availability or use Azure CLI command 'az vm list-skus --location (REGION) --output table'
#	to check availability zone status for a given Azure region before using it here.

# ##################################################
# Parameters - provide values here or on the command line
param
(
	[string]$SubscriptionId = '',
	[string]$ResourceGroupName = '',
	[string]$AzureRegion = 'centralus',
	[string]$StorageAccountName = '',
	[string]$DeploymentName = 'OracleEnvironment'
)
# ##################################################


# ##################################################
# SENSITIVE - DO NOT CHECK INTO PUBLIC REPOS WITHOUT OBSCURING THESE, OR KNOWING EXACTLY WHAT YOU ARE DOING!!!!!!!!!!!
# Provide values here

# Provide this in one-line format. Do not append a username here; that is done below for bastion and server VMs respectively using the admin usernames specified there.
$sshKeyData = "ssh-rsa YOURKEY"

$plainTextPassword = ""			# If you do not want to enable password authentication to Linux VMs, you need to disable it in the parameter files. Then you do not need to specify a password.
$ourExternalIp = ""				# This is so you can access storage and VM resources from your network location. This should be a public IP that you are NATed behind. You can find this using https://bing.com/search?q=what+is+my+ip+address

# ##################################################


# ##################################################
# Variables

# Deployment file paths - change these if you change the deployment artifact folder/file names
$templateFilePath_VNetSubnetsNSGs = '.\VNetSubnetsNsgs\vnetSubnetsNsgs.deploy.json'
$parametersFilePath_VNetSubnetsNSGs = '.\VNetSubnetsNsgs\vnetSubnetsNsgs.parameters.json'

$templateFilePath_Storage = '.\Storage\storage.deploy.json'
$parametersFilePath_Storage = '.\Storage\storage.parameters.json'

$templateFilePath_BastionVM_Ubuntu = '.\BastionVM-Ubuntu\bastionvm.ubuntu.deploy.json'
$parametersFilePath_BastionVM_Ubuntu = '.\BastionVM-Ubuntu\bastionvm.ubuntu.parameters.json'

$templateFilePath_ServerVM_OEL = '.\ServerVM-OEL\servervm.oel.deploy.json'
$parametersFilePath_ServerVM_OEL = '.\ServerVM-OEL\servervm.oel.parameters.json'

# The following variables will be passed as dynamic parameters to the various New-AzureRmResourceGroupDeployment calls below so that redundant copy-paste to parameters files is minimized.
# The parameter files contain additional parameters but those are either only used in one template or are relatively invariant.
# The variables here represent settings that apply to more than one template and/or that are subject to variability depending on environment and context.
# These variables will override same-named parameter values specified in the parameter files.
# Change as needed, e.g. if you will use existing network or storage resources - remove these dynamic parameters from the calls below and edit parameters files instead.

# VNet/Subnets/NSGs
$vnetName = "datavnet"
$vnetAddressSpace = "172.16.0.0/16"
$subnetNamePublic = "public"
$subnetAddressSpacePublic = "172.16.1.0/24"
$subnetNamePrivate1 = "private1"
$subnetAddressSpacePrivate1 = "172.16.2.0/24"
$subnetNamePrivate2 = "private2"
$subnetAddressSpacePrivate2 = "172.16.3.0/24"
$nsgNamePublic = "public"
$nsgNamePrivate1 = "private1"
$nsgNamePrivate2 = "private2"

# Storage management for Linux VMs
$linuxMountPoint = "/mnt/azure"
$azureStorageContainerName = "software"
$azureStorageScriptsFolder = "scripts"
$shellScriptFileName = "script1.sh"
$shellScriptToUploadLocalPath = ".\BashScripts\" + $shellScriptFileName
$shellScriptToUploadAzurePath = $azureStorageScriptsFolder + "/" + $shellScriptFileName

# Bastion VM
$bastionVMSize = "Standard_DS3_v2"
$bastionVMAvailabilitySetName = "bastionubuntu_avset"
$bastionVMName = "bastionubuntu1"
$bastionVMAdminUsername = "bastionadmin"
$bastionVMAdminPassword = ConvertTo-SecureString -String $plainTextPassword -AsPlainText -Force
$bastionVMSSHKeyData = ConvertTo-SecureString -String ($sshKeyData + " " + $bastionVMAdminUsername) -AsPlainText -Force

# OEL VMs
$serverVMSize = "Standard_E16s_v3"
$serverVMAdminUsername = "oraadmin"
$serverVMAdminPassword = ConvertTo-SecureString -String $plainTextPassword -AsPlainText -Force
$serverVMSSHKeyData = ConvertTo-SecureString -String ($sshKeyData + " " + $serverVMAdminUsername) -AsPlainText -Force
$serverVMDataDiskCountGroup1 = 16
$serverVMDataDiskSizeGBGroup1 = 1023
$serverVMDataDiskCountGroup2 = 4
$serverVMDataDiskSizeGBGroup2 = 150

# Server VM1
$server1VMName = "oelvm1"
$server1AvailabilityZone = 1

# Server VM2
$server2VMName = "oelvm2"
$server2AvailabilityZone = 2

# ##################################################



# ##################################################
# Login to Azure and set subscription for deployment
Login-AzureRmAccount;
Select-AzureRmSubscription -SubscriptionID $SubscriptionId;
# ##################################################



# ##################################################
# Create or get existing resource group
$resourceGroup = Get-AzureRmResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue

if (!$resourceGroup) {
	Write-Host "Creating resource group '$ResourceGroupName' in location '$AzureRegion'";
	New-AzureRmResourceGroup -Name $ResourceGroupName -Location $AzureRegion
}
else {
	Write-Host "Found existing resource group '$ResourceGroupName'";
}
# ##################################################



# ##################################################
# Resource Deployments
# You can use a call like the next commented-out line to retrieve details for any deployment
# Get-AzureRmResourceGroupDeploymentOperation -DeploymentName 'PROVIDE' -ResourceGroupName $ResourceGroupName

# ##########
# Deploy VNet, Subnets, and NSGs

Write-Host "Testing deployment - VNet/Subnets/NSGs";
Test-AzureRmResourceGroupDeployment `
	-ResourceGroupName $ResourceGroupName `
	-TemplateFile $templateFilePath_VNetSubnetsNSGs `
	-TemplateParameterFile $parametersFilePath_VNetSubnetsNSGs `
	-location $AzureRegion `
	-vnet_name $vnetName `
	-vnet_address_space $vnetAddressSpace `
	-subnet_public_name $subnetNamePublic `
	-subnet_public_address_space $subnetAddressSpacePublic `
	-subnet_private1_name $subnetNamePrivate1 `
	-subnet_private1_address_space $subnetAddressSpacePrivate1 `
	-subnet_private2_name $subnetNamePrivate2 `
	-subnet_private2_address_space $subnetAddressSpacePrivate2 `
	-nsg_public_name $nsgNamePublic `
	-nsg_private1_name $nsgNamePrivate1 `
	-nsg_private2_name $nsgNamePrivate2 `
	-external_source_ip $ourExternalIp `
	-Verbose

Write-Host "Deploying VNet/Subnets/NSGs";
New-AzureRmResourceGroupDeployment `
	-Name ($DeploymentName + "-Network") `
	-ResourceGroupName $ResourceGroupName `
	-TemplateFile $templateFilePath_VNetSubnetsNSGs `
	-TemplateParameterFile $parametersFilePath_VNetSubnetsNSGs `
	-location $AzureRegion `
	-vnet_name $vnetName `
	-vnet_address_space $vnetAddressSpace `
	-subnet_public_name $subnetNamePublic `
	-subnet_public_address_space $subnetAddressSpacePublic `
	-subnet_private1_name $subnetNamePrivate1 `
	-subnet_private1_address_space $subnetAddressSpacePrivate1 `
	-subnet_private2_name $subnetNamePrivate2 `
	-subnet_private2_address_space $subnetAddressSpacePrivate2 `
	-nsg_public_name $nsgNamePublic `
	-nsg_private1_name $nsgNamePrivate1 `
	-nsg_private2_name $nsgNamePrivate2 `
	-external_source_ip $ourExternalIp `
	-Verbose `
	-DeploymentDebugLogLevel All
# ##########


# ##########
# Deploy Storage Account and perform Storage operations

Write-Host "Testing deployment - Storage";
Test-AzureRmResourceGroupDeployment `
	-ResourceGroupName $ResourceGroupName `
	-TemplateFile $templateFilePath_Storage `
	-TemplateParameterFile $parametersFilePath_Storage `
	-subscription_id $SubscriptionId `
	-location $AzureRegion `
	-storage_account_name $StorageAccountName `
	-resource_group_name_vnet $ResourceGroupName `
	-vnet_name $vnetName `
	-subnet_names $subnetNamePublic, $subnetNamePrivate1, $subnetNamePrivate2 `
	-external_source_ip $ourExternalIp `
	-Verbose

Write-Host "Deploying Storage";
New-AzureRmResourceGroupDeployment `
	-Name ($DeploymentName + "-Storage") `
	-ResourceGroupName $ResourceGroupName `
	-TemplateFile $templateFilePath_Storage `
	-TemplateParameterFile $parametersFilePath_Storage `
	-subscription_id $SubscriptionId `
	-location $AzureRegion `
	-storage_account_name $StorageAccountName `
	-resource_group_name_vnet $ResourceGroupName `
	-vnet_name $vnetName `
	-subnet_names $subnetNamePublic, $subnetNamePrivate1, $subnetNamePrivate2 `
	-external_source_ip $ourExternalIp `
	-Verbose `
	-DeploymentDebugLogLevel All

# Get Storage Account Key and use it to create an Azure File Share
$storageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName)[0].Value
$storageContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $storageAccountKey
$storageContainer = New-AzureStorageContainer -Context $storageContext -Name $azureStorageContainerName -Permission Off -ConcurrentTaskCount 50 
$storageBlob = Set-AzureStorageBlobContent  -Context $storageContext -Container $azureStorageContainerName -File $shellScriptToUploadLocalPath -Blob $shellScriptToUploadAzurePath -BlobType Block -Force

# Azure Blob Fuse driver install prep
# References
# https://github.com/Azure/azure-storage-fuse/wiki/1.-Installation
# https://github.com/Azure/azure-storage-fuse/wiki/2.-Configuring-and-Running
$blobFuseTempPath_Ubuntu = "/mnt/blobfusetmp"
$blobFuseTempPath_OEL = "/mnt/blobfusetmp"
$blobFuseConfigPath = "/etc/blobfuse_azureblob.cfg"
$blobFuseConfigContent = "accountName " + $StorageAccountName + "\n" + "accountKey " + $storageAccountKey + "\n" + "containerName " + $azureStorageContainerName

# Ubuntu shell command - AT THIS POINT BLOBFUSE DOES ---NOT--- INSTALL ON UBUNTU SERVER 18.10 DUE TO A libcurl3/4 CONFLICT
# SEE https://github.com/Azure/azure-storage-fuse/issues/236
# $postDeployShellCmd_Ubuntu = `
# 	"sudo wget https://packages.microsoft.com/config/ubuntu/16.04/packages-microsoft-prod.deb && " + `
# 	"sudo dpkg -i packages-microsoft-prod.deb && " + `
# 	"sudo apt-get update && sudo apt-get upgrade -y -qq && " + `
# 	"sudo apt-get install blobfuse fuse && " + `
# 	"sudo mkdir " + $blobFuseTempPath_Ubuntu + " && " + `
# 	"sudo chown " + $bastionVMAdminUsername + " " + $blobFuseTempPath_Ubuntu + " && " + `
# 	"sudo bash -c 'echo -e """ + $blobFuseConfigContent + """ >> " + $blobFuseConfigPath + "' && " + `
# 	"sudo mkdir " + $linuxMountPoint + " && " + `
# 	"sudo blobfuse " + $linuxMountPoint + " --tmp-path=" + $blobFuseTempPath_Ubuntu + " --config-file=" + $blobFuseConfigPath + "  -o allow_other -o attr_timeout=240 -o entry_timeout=240 -o negative_timeout=120 --file-cache-timeout-in-seconds=120 --log-level=LOG_DEBUG && " + `
# 	"sudo bash " + $linuxMountPoint + "/" + $shellScriptToUploadAzurePath + ";"

# Minimal shell script for bastion VM just to update it
$postDeployShellCmd_Ubuntu = "sudo apt-get update && sudo apt-get upgrade -y -qq;"

# OEL shell command
$postDeployShellCmd_OEL = `
	"sudo rpm -Uvh https://packages.microsoft.com/config/rhel/7/packages-microsoft-prod.rpm && " + `
	"sudo yum clean all && sudo yum update -y --releasever=7.5 && " + `
	"sudo yum install -y blobfuse fuse && " + `
	"sudo mkdir " + $blobFuseTempPath_OEL + " && " + `
	"sudo chown " + $serverVMAdminUsername + " " + $blobFuseTempPath_OEL + " && " + `
	"sudo bash -c 'echo -e """ + $blobFuseConfigContent + """ >> " + $blobFuseConfigPath + "' && " + `
	"sudo mkdir " + $linuxMountPoint + " && " + `
	"sudo blobfuse " + $linuxMountPoint + " --tmp-path=" + $blobFuseTempPath_OEL + " --config-file=" + $blobFuseConfigPath + "  -o allow_other -o attr_timeout=240 -o entry_timeout=240 -o negative_timeout=120 --file-cache-timeout-in-seconds=120 --log-level=LOG_DEBUG && " + `
	"sudo bash " + $linuxMountPoint + "/" + $shellScriptToUploadAzurePath + ";"

# OPTIONAL: Write shell commands to file for inspection	
# $postDeployShellCmd_Ubuntu | Out-File "server_cmd_ubuntu.txt"
# $postDeployShellCmd_OEL | Out-File "server_cmd_oel.txt"

 ##########


# ##########
# Deploy Bastion Host - Ubuntu
Write-Host "Testing deployment - Bastion VM - Ubuntu Server 18.10";
Test-AzureRmResourceGroupDeployment `
	-ResourceGroupName $ResourceGroupName `
	-TemplateFile $templateFilePath_BastionVM_Ubuntu `
	-TemplateParameterFile $parametersFilePath_BastionVM_Ubuntu `
	-location $AzureRegion `
	-availability_set_name $bastionVMAvailabilitySetName `
	-resource_group_name_vm $ResourceGroupName `
	-virtual_machine_name $bastionVMName `
	-virtual_machine_size $bastionVMSize `
	-admin_username $bastionVMAdminUsername `
	-admin_password $bastionVMAdminPassword `
	-ssh_key_data $bastionVMSSHKeyData `
	-resource_group_name_network $ResourceGroupName `
	-vnet_name $vnetName `
	-subnet_name $subnetNamePublic `
	-post_deploy_shell_command $postDeployShellCmd_Ubuntu `
	-Verbose

Write-Host "Deploying Bastion VM - Ubuntu Server";
New-AzureRmResourceGroupDeployment `
	-Name ($DeploymentName + "-BastionUbuntu") `
	-ResourceGroupName $ResourceGroupName `
	-TemplateFile $templateFilePath_BastionVM_Ubuntu `
	-TemplateParameterFile $parametersFilePath_BastionVM_Ubuntu `
	-location $AzureRegion `
	-availability_set_name $bastionVMAvailabilitySetName `
	-resource_group_name_vm $ResourceGroupName `
	-virtual_machine_name $bastionVMName `
	-virtual_machine_size $bastionVMSize `
	-admin_username $bastionVMAdminUsername `
	-admin_password $bastionVMAdminPassword `
	-ssh_key_data $bastionVMSSHKeyData `
	-resource_group_name_network $ResourceGroupName `
	-vnet_name $vnetName `
	-subnet_name $subnetNamePublic `
	-post_deploy_shell_command $postDeployShellCmd_Ubuntu `
	-Verbose `
	-DeploymentDebugLogLevel All
# ##########


# ##########
# Deploy Server VMs - OEL 7.5
Write-Host "Testing deployment - Server VM1 - OEL";
Test-AzureRmResourceGroupDeployment `
	-ResourceGroupName $ResourceGroupName `
	-TemplateFile $templateFilePath_ServerVM_OEL `
	-TemplateParameterFile $parametersFilePath_ServerVM_OEL `
	-location $AzureRegion `
	-availability_zones $server1AvailabilityZone `
	-virtual_machine_name $server1VMName `
	-virtual_machine_size $serverVMSize `
	-admin_username $serverVMAdminUsername `
	-admin_password $serverVMAdminPassword `
	-ssh_key_data $serverVMSSHKeyData `
	-data_disk_count_group1 $serverVMDataDiskCountGroup1 `
	-data_disk_size_gb_group1 $serverVMDataDiskSizeGBGroup1 `
	-data_disk_count_group2 $serverVMDataDiskCountGroup2 `
	-data_disk_size_gb_group2 $serverVMDataDiskSizeGBGroup2 `
	-resource_group_name_network $ResourceGroupName `
	-vnet_name $vnetName `
	-subnet_name $subnetNamePrivate1 `
	-post_deploy_shell_command $postDeployShellCmd_OEL `
	-Verbose

Write-Host "Deploying Server VM1 - OEL";
New-AzureRmResourceGroupDeployment `
	-Name ($DeploymentName + "-Server1OEL") `
	-ResourceGroupName $ResourceGroupName `
	-TemplateFile $templateFilePath_ServerVM_OEL `
	-TemplateParameterFile $parametersFilePath_ServerVM_OEL `
	-location $AzureRegion `
	-availability_zones $server1AvailabilityZone `
	-virtual_machine_name $server1VMName `
	-virtual_machine_size $serverVMSize `
	-admin_username $serverVMAdminUsername `
	-admin_password $serverVMAdminPassword `
	-ssh_key_data $serverVMSSHKeyData `
	-data_disk_count_group1 $serverVMDataDiskCountGroup1 `
	-data_disk_size_gb_group1 $serverVMDataDiskSizeGBGroup1 `
	-data_disk_count_group2 $serverVMDataDiskCountGroup2 `
	-data_disk_size_gb_group2 $serverVMDataDiskSizeGBGroup2 `
	-resource_group_name_network $ResourceGroupName `
	-vnet_name $vnetName `
	-subnet_name $subnetNamePrivate1 `
	-post_deploy_shell_command $postDeployShellCmd_OEL `
	-Verbose `
	-DeploymentDebugLogLevel All

Write-Host "Deploying Server VM2 - OEL";
New-AzureRmResourceGroupDeployment `
	-Name ($DeploymentName + "-Server2OEL") `
	-ResourceGroupName $ResourceGroupName `
	-TemplateFile $templateFilePath_ServerVM_OEL `
	-TemplateParameterFile $parametersFilePath_ServerVM_OEL `
	-location $AzureRegion `
	-availability_zones $server2AvailabilityZone `
	-virtual_machine_name $server2VMName `
	-virtual_machine_size $serverVMSize `
	-admin_username $serverVMAdminUsername `
	-admin_password $serverVMAdminPassword `
	-ssh_key_data $serverVMSSHKeyData `
	-data_disk_count_group1 $serverVMDataDiskCountGroup1 `
	-data_disk_size_gb_group1 $serverVMDataDiskSizeGBGroup1 `
	-data_disk_count_group2 $serverVMDataDiskCountGroup2 `
	-data_disk_size_gb_group2 $serverVMDataDiskSizeGBGroup2 `
	-resource_group_name_network $ResourceGroupName `
	-vnet_name $vnetName `
	-subnet_name $subnetNamePrivate2 `
	-post_deploy_shell_command $postDeployShellCmd_OEL `
	-Verbose `
	-DeploymentDebugLogLevel All


# ##########
# ##################################################
