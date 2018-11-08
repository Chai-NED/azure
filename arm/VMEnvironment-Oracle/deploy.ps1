# ##################################################
# NOTES
# This PS script uses params for New-AzureRmResourceGroupDeployment: -Verbose -DeploymentDebugLogLevel All
# These params WILL result in extra logging, including to Azure deployment results.
# This WILL result in sensitive values (like the ssh key) being potentially available after the fact.
# For Production deployments, you should remove these params from the New-AzureRmResourceGroupDeployment calls below.

# The Azure region below is set to "centralus". Not all Azure regions yet explicitly expose, or allow selection of, specific availability zones yet.
# See https://docs.microsoft.com/en-us/azure/virtual-machines/linux/create-cli-availability-zone#check-vm-sku-availability or use Azure CLI command 'az vm list-skus --location (REGION) --output table'
#	to check availability zone status for a given Azure region before using it here.
# ##################################################
# Parameters - provide default values here or pass on the command line
param
(
	[string]$DeploymentName = "DataEnvironment",
	[string]$SubscriptionId = '',
	[string]$ResourceGroupName = '',
	[string]$AzureRegion = 'centralus',
	[string]$StorageAccountName = '',
	# Source IP Address is so you can access storage and VM resources from your network location. This should be a public IP that you are NATed behind. You can find this using https://bing.com/search?q=what+is+my+ip+address
	[string]$SourceIpAddressToAllow = '',
	# Provide ONLY the SSH public key value itself, not "ssh-rsa" prefix or a username suffix. The script handles these correctly.
	[string]$SSHPublicKeyValue = ""
)
# ##################################################
# Variables

$SSHPublicKey = "ssh-rsa " + $SSHPublicKeyValue

# The following variables will be passed as dynamic parameters to the various New-AzureRmResourceGroupDeployment calls below so that redundant copy-paste to parameters files is minimized.
# The parameter files contain additional parameters but those are either only used in one template or are relatively invariant.
# The variables here represent settings that apply to more than one template and/or that are subject to variability depending on environment and context.
# These variables will override same-named parameter values specified in the parameter files when passed dynamically.
# Change as needed, e.g. if you will use existing network or storage resources - remove these dynamic parameters from the calls below and edit parameters files instead.

# VNet/Subnets/NSGs
$ResourceGroupNameNetwork = $ResourceGroupName	# If you have existing, or want to deploy, network resources in a different resource group than the VMs, specify that network resource group name here
$VNetName = "datavnet"
$VNetAddressSpace = "172.16.0.0/16"
$SubnetNamePublic = "public"
$SubnetAddressSpacePublic = "172.16.1.0/24"
$SubnetNamePrivate1 = "private1"
$SubnetAddressSpacePrivate1 = "172.16.2.0/24"
$SubnetNamePrivate2 = "private2"
$SubnetAddressSpacePrivate2 = "172.16.3.0/24"
$NSGNamePublic = "public"
$NSGNamePrivate1 = "private1"
$NSGNamePrivate2 = "private2"

# Storage management for Linux VMs
$ResourceGroupNameStorage = $ResourceGroupName		# If you have existing, or want to deploy, storage resources in a different resource group than the VMs, specify that storage resource group name here
$LinuxMountPoint = "/mnt/azure"
$AzureStorageContainerName = "software"
$AzureStorageScriptsFolder = "scripts"
$ShellScriptFileName = "helloworld.sh"
$ShellScriptToUploadLocalPath = ".\BashScripts\" + $shellScriptFileName
$ShellScriptToUploadAzurePath = $azureStorageScriptsFolder + "/" + $shellScriptFileName

# Bastion VM
$BastionVMSize = "Standard_DS3_v2"
$BastionVMAvailabilitySetName = "bastionubuntu_avset"
$BastionVMName = ($ResourceGroupName + "-bastionvm1")
$BastionVMAdminUsername = "bastionadmin"
$BastionVMSSHKeyData = ConvertTo-SecureString -String ($SSHPublicKey + " " + $bastionVMAdminUsername) -AsPlainText -Force

# OEL VMs
$ServerVMSize = "Standard_E16s_v3"
$ServerVMAdminUsername = "oraadmin"
$ServerVMSSHKeyData = ConvertTo-SecureString -String ($SSHPublicKey + " " + $serverVMAdminUsername) -AsPlainText -Force
$ServerVMDataDiskCountGroup1 = 16
$ServerVMDataDiskSizeGBGroup1 = 1023
$ServerVMDataDiskCountGroup2 = 4
$ServerVMDataDiskSizeGBGroup2 = 150

# Availability zones for server VMs
$ServerAZ1 = 1
$ServerAZ2 = 2

# Server Instance Names
$ServerNameAZ1VM1 = ($ResourceGroupName + "-oraaz1vm1")
$ServerNameAZ1VM2 = ($ResourceGroupName + "-oraaz1vm2")
$ServerNameAZ2VM1 = ($ResourceGroupName + "-oraaz2vm1")
$ServerNameAZ2VM2 = ($ResourceGroupName + "-oraaz2vm2")
# ##################################################



# ##################################################
# Login to Azure and set subscription for deployment
Login-AzureRmAccount;
Select-AzureRmSubscription -SubscriptionID $SubscriptionId;
# ##################################################


# ##################################################
# Ensure VM resource group exists
$resourceGroup = Get-AzureRmResourceGroup -Name $ResourceGroupName -Location $AzureRegion -ErrorAction SilentlyContinue

if (!$resourceGroup) {
	New-AzureRmResourceGroup -Name $ResourceGroupName -Location $AzureRegion
}
# ##################################################


# ##################################################
# VNet, Subnets, NSGs
# Uncomment this if you would like to create these resources as part of this script
# .\VNetSubnetsNsgs\deploy.ps1 `
# 	-DeploymentName $DeploymentName `
# 	-TemplateFilePath ".\VNetSubnetsNsgs\vnetSubnetsNsgs.deploy.json" `
# 	-ParametersFilePath ".\VNetSubnetsNsgs\vnetSubnetsNsgs.parameters.json" `
# 	-ResourceGroupName $ResourceGroupNameNetwork `
# 	-AzureRegion $AzureRegion `
# 	-VNetName $VNetName `
# 	-VNetAddressSpace $VNetAddressSpace `
# 	-SubnetNamePublic $SubnetNamePublic `
# 	-SubnetAddressSpacePublic $SubnetAddressSpacePublic `
# 	-SubnetNamePrivate1 $SubnetNamePrivate1 `
# 	-SubnetAddressSpacePrivate1 $SubnetAddressSpacePrivate1 `
# 	-SubnetNamePrivate2 $SubnetNamePrivate2 `
# 	-SubnetAddressSpacePrivate2 $SubnetAddressSpacePrivate2 `
# 	-NSGNamePublic $NSGNamePublic `
# 	-NSGNamePrivate1 $NSGNamePrivate1 `
# 	-NSGNamePrivate2 $NSGNamePrivate2 `
# 	-ExternalSourceIpAddress $SourceIpAddressToAllow
# ##################################################
# Storage Deployment
# Uncomment this if you would like to create these resources as part of this script
# .\Storage\deploy.ps1 `
# 	-DeploymentName $DeploymentName `
# 	-TemplateFilePath ".\Storage\storage.deploy.json" `
# 	-ParametersFilePath ".\Storage\storage.parameters.json" `
# 	-SubscriptionId $SubscriptionId `
# 	-ResourceGroupNameStorage $ResourceGroupNameStorage `
# 	-AzureRegion $AzureRegion `
# 	-StorageAccountName $StorageAccountName `
# 	-ResourceGroupNameVNet $ResourceGroupNameNetwork `
# 	-VNetName $VNetName `
# 	-SubnetNamePublic $SubnetNamePublic `
# 	-SubnetNamePrivate1 $SubnetNamePrivate1 `
# 	-SubnetNamePrivate2 $SubnetNamePrivate2 `
# 	-ExternalSourceIpAddress $SourceIpAddressToAllow
# ##################################################


# ##################################################
# Storage Operations to prepare for Linux mounts to Azure storage
# Need storage account key for other operations
$storageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName)[0].Value
# Need storage context for other operations
$storageContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $storageAccountKey -Verbose

# Ensure the container for Linux VM storage mounts exists
$storageContainer = Get-AzureStorageContainer -Context $storageContext -Name $AzureStorageContainerName -Verbose -ErrorAction SilentlyContinue

if ($null -eq $storageContainer) {
	$storageContainer = New-AzureStorageContainer -Context $storageContext -Name $azureStorageContainerName -Permission Off -Verbose
}

# Upload the bash script with overwrite if exists
$storageBlob = Set-AzureStorageBlobContent -Context $storageContext -Container $azureStorageContainerName -File $shellScriptToUploadLocalPath -Blob $shellScriptToUploadAzurePath -BlobType Block -Force -Verbose
# ##################################################
# Azure Blob Fuse driver install prep
# References
# https://github.com/Azure/azure-storage-fuse/wiki/1.-Installation
# https://github.com/Azure/azure-storage-fuse/wiki/2.-Configuring-and-Running
$blobFuseTempPath_Ubuntu = "/mnt/blobfusetmp"
$blobFuseTempPath_OEL = "/mnt/blobfusetmp"
$blobFuseConfigPath = "/etc/blobfuse_azureblob.cfg"
$blobFuseConfigContent = "accountName " + $StorageAccountName + "\n" + "accountKey " + $storageAccountKey + "\n" + "containerName " + $azureStorageContainerName
# ##################################################
# Ubuntu shell command to run at the end of VM deploy
$postDeployShellCmd_Ubuntu = `
	"sudo wget https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb && " + `
	"sudo dpkg -i packages-microsoft-prod.deb && " + `
	"sudo apt-get update -y && sudo apt-get upgrade -y -qq && " + `
	"sudo apt-get install -y blobfuse fuse && " + `
	"sudo mkdir " + $blobFuseTempPath_Ubuntu + " && " + `
	"sudo chown " + $bastionVMAdminUsername + " " + $blobFuseTempPath_Ubuntu + " && " + `
	"sudo bash -c 'echo -e """ + $blobFuseConfigContent + """ >> " + $blobFuseConfigPath + "' && " + `
	"sudo mkdir " + $linuxMountPoint + " && " + `
	"sudo blobfuse " + $linuxMountPoint + " --tmp-path=" + $blobFuseTempPath_Ubuntu + " --config-file=" + $blobFuseConfigPath + "  -o allow_other -o attr_timeout=240 -o entry_timeout=240 -o negative_timeout=120 --file-cache-timeout-in-seconds=120 --log-level=LOG_DEBUG && " + `
	"sudo bash " + $linuxMountPoint + "/" + $shellScriptToUploadAzurePath + ";"

# OEL shell command to run at the end of VM deploy
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
# $postDeployShellCmd_Ubuntu | Out-File "post_deploy_cmd_ubuntu.txt"
# $postDeployShellCmd_OEL | Out-File "post_deploy_cmd_oel.txt"
# ##################################################


# ##################################################
# Deploy Bastion Host - Ubuntu
.\BastionVM-Ubuntu\deploy.ps1 `
	-DeploymentName $DeploymentName `
	-TemplateFilePath '.\BastionVM-Ubuntu\bastionvm.ubuntu.deploy.json' `
	-ParametersFilePath '.\BastionVM-Ubuntu\bastionvm.ubuntu.parameters.json' `
	-ResourceGroupNameVM $ResourceGroupName `
	-AzureRegion $AzureRegion `
	-VMAvailabilitySetName $BastionVMAvailabilitySetName `
	-VMName $BastionVMName `
	-VMSize $BastionVMSize `
	-VMAdminUsername $BastionVMAdminUsername `
	-SSHPublicKeyData $BastionVMSSHKeyData `
	-ResourceGroupNameVNet $ResourceGroupNameNetwork `
	-VNetName $VNetName `
	-SubnetName $SubnetNamePublic `
	-PostDeployShellCmd $postDeployShellCmd_Ubuntu
# ##################################################
# Deploy Server VMs - OEL 7.5
function DeployServerVM()
{
	param
	(
        [int]$avlZone,
		[string]$vmName,
		[string]$subnetName
	)

	.\ServerVM-OEL\deploy.ps1 `
		-DeploymentName $DeploymentName `
		-TemplateFilePath '.\ServerVM-OEL\servervm.oel.deploy.json' `
		-ParametersFilePath '.\ServerVM-OEL\servervm.oel.parameters.json' `
		-ResourceGroupNameVM $ResourceGroupName `
		-AzureRegion $AzureRegion `
		-AvailabilityZone $avlZone `
		-VMName $vmName `
		-VMSize $ServerVMSize `
		-VMAdminUsername $ServerVMAdminUsername `
		-SSHPublicKeyData $ServerVMSSHKeyData `
		-DataDiskCountGroup1 $ServerVMDataDiskCountGroup1 `
		-DataDiskSizeGBGroup1 $ServerVMDataDiskSizeGBGroup1 `
		-DataDiskCountGroup2 $ServerVMDataDiskCountGroup2 `
		-DataDiskSizeGBGroup2 $ServerVMDataDiskSizeGBGroup2 `
		-ResourceGroupNameVNet $ResourceGroupNameNetwork `
		-VNetName $VNetName `
		-SubnetName $subnetName `
		-PostDeployShellCmd $postDeployShellCmd_OEL
}

DeployServerVM -avlZone $serverAZ1 -vmName $serverNameAZ1VM1 -subnetName $subnetNamePrivate1;
DeployServerVM -avlZone $serverAZ1 -vmName $serverNameAZ1VM2 -subnetName $subnetNamePrivate1;
DeployServerVM -avlZone $serverAZ2 -vmName $serverNameAZ2VM1 -subnetName $subnetNamePrivate2;
DeployServerVM -avlZone $serverAZ2 -vmName $serverNameAZ2VM2 -subnetName $subnetNamePrivate2;
# ##################################################
