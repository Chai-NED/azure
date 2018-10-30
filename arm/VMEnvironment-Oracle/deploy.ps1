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
	[string]$ResourceGroupName = 'OracleEnvironment',
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
$azureFilesShareName = "software"
$azureFilesShareFolder = "scripts"
$shellScriptFileName = "script1.sh"
$shellScriptLocalPath = ".\BashScripts\" + $shellScriptFileName

# Bastion VM
$bastionVMSize = "Standard_DS3_v2"
$bastionVMAvailabilitySetName = "bastionubuntu_avset"
$bastionVMName = "bastionubuntu1"
$bastionVMAdminUsername = "bastionadmin"
$bastionVMAdminPassword = ConvertTo-SecureString -String $plainTextPassword -AsPlainText -Force
$bastionVMSSHKeyData = ConvertTo-SecureString -String ($sshKeyData + " " + $bastionVMAdminUsername) -AsPlainText -Force

# OEL VMs
$serverVMSize = "Standard_DS3_v2"
$serverVMAdminUsername = "oraadmin"
$serverVMAdminPassword = ConvertTo-SecureString -String $plainTextPassword -AsPlainText -Force
$serverVMSSHKeyData = ConvertTo-SecureString -String ($sshKeyData + " " + $serverVMAdminUsername) -AsPlainText -Force
$serverVMDataDiskCountGroup1 = 1
$serverVMDataDiskSizeGBGroup1 = 129
$serverVMDataDiskCountGroup2 = 1
$serverVMDataDiskSizeGBGroup2 = 129

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
$azureFileShare = New-AzureStorageShare $azureFilesShareName -Context $storageContext
$azureFileShareDir = New-AzureStorageDirectory -Share $azureFileShare -Path $azureFilesShareFolder
$azureFileUpload = Set-AzureStorageFileContent -Source $shellScriptLocalPath -Directory $azureFileShareDir

# Prepare shell commands to run in Linux VMs immediately following deployment in Azure, to create persistent mount point to Azure Files share
$postDeployShellCmdSuffix = `
	"sudo mkdir " + $linuxMountPoint + " && " + `
	"if [ ! -d ""/etc/smbcredentials"" ]; then sudo mkdir /etc/smbcredentials; fi && " + `
	"if [ ! -f ""/etc/smbcredentials/" + $StorageAccountName + ".cred"" ]; then sudo bash -c 'echo -e ""username=" + $StorageAccountName + "\npassword=" + $storageAccountKey + """ >> /etc/smbcredentials/" + $StorageAccountName + ".cred'; fi && " + `
	"sudo chmod 600 /etc/smbcredentials/" + $StorageAccountName + ".cred && " + `
	"sudo bash -c 'echo ""//" + $StorageAccountName + ".file.core.windows.net/" + $azureFilesShareName + " " + $linuxMountPoint + " cifs nofail,vers=3.0,credentials=/etc/smbcredentials/" + $StorageAccountName + ".cred,dir_mode=0777,file_mode=0777,serverino"" >> /etc/fstab' && " + `
	"sudo mount -a && " + `
	"sudo bash " + $linuxMountPoint + "/" + $azureFilesShareFolder + "/" + $shellScriptFileName + ";"

$postDeployShellCmd_OEL = "sudo yum -y install cifs-utils && " + $postDeployShellCmdSuffix
$postDeployShellCmd_Ubuntu = "sudo apt-get update && sudo apt-get install cifs-utils && " + $postDeployShellCmdSuffix
# ##########


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
	-Verbose `
	-DeploymentDebugLogLevel All

Write-Host "Please SSH to the OEL server VMs from the bastion VM to run the post-deploy shell command."
Write-Host "This needs to be done interactively as OEL 7.5 disables password-less sudo for all users in /etc/sudoers,"
Write-Host "    which prevents the Azure Custom Script Extension from automatically/silently running the post-deploy shell script."
Write-Host "This script is writing the shell command to run to local file server_cmd.txt."
Write-Host "Please SSH to each Oracle VM and paste the command from that file to the command prompt in the Oracle VM and run it there."

$postDeployShellCmd_OEL | Out-File "server_cmd.txt"

# ##########
# ##################################################
