# See the readme and edit globals.ps1 before running this script.

.\globals.ps1

# ##################################################
# Login to Azure and set subscription for deployment
Login-AzureRmAccount;
Select-AzureRmSubscription -SubscriptionID $SubscriptionId;
# ##################################################


# ##################################################
# Ensure resource groups exist

function DoResourceGroup()
{
	param
	(
		[string]$ResourceGroupName,
		[string]$AzureRegion
	)

	$rg = Get-AzureRmResourceGroup -Name $ResourceGroupName -Location $AzureRegion -ErrorAction SilentlyContinue

	if (!$rg) {
		New-AzureRmResourceGroup -Name $ResourceGroupName -Location $AzureRegion
	}
}

# Network resource groups
if ($DeployBastion) {DoResourceGroup -ResourceGroupName $ResourceGroupNameNetworkBastion -AzureRegion $AzureRegionBastion}
if ($DeployCluster1) {DoResourceGroup -ResourceGroupName $ResourceGroupNameNetworkCluster1 -AzureRegion $AzureRegionCluster1}
if ($DeployCluster2) {DoResourceGroup -ResourceGroupName $ResourceGroupNameNetworkCluster2 -AzureRegion $AzureRegionCluster2}
if ($DeployCluster3) {DoResourceGroup -ResourceGroupName $ResourceGroupNameNetworkCluster3 -AzureRegion $AzureRegionCluster3}

# Storage resource groups
if ($DeployBastion) {DoResourceGroup -ResourceGroupName $ResourceGroupNameStorageBastion -AzureRegion $AzureRegionBastion}
if ($DeployCluster1) {DoResourceGroup -ResourceGroupName $ResourceGroupNameStorageCluster1 -AzureRegion $AzureRegionCluster1}
if ($DeployCluster2) {DoResourceGroup -ResourceGroupName $ResourceGroupNameStorageCluster2 -AzureRegion $AzureRegionCluster2}
if ($DeployCluster3) {DoResourceGroup -ResourceGroupName $ResourceGroupNameStorageCluster3 -AzureRegion $AzureRegionCluster3}

if ($DeployBastion) {DoResourceGroup -ResourceGroupName $ResourceGroupNameVMsBastion -AzureRegion $AzureRegionBastion}
if ($DeployCluster1) {DoResourceGroup -ResourceGroupName $ResourceGroupNameVMsCluster1 -AzureRegion $AzureRegionCluster1}
if ($DeployCluster2) {DoResourceGroup -ResourceGroupName $ResourceGroupNameVMsCluster2 -AzureRegion $AzureRegionCluster2}
if ($DeployCluster3) {DoResourceGroup -ResourceGroupName $ResourceGroupNameVMsCluster3 -AzureRegion $AzureRegionCluster3}
# ##################################################


# ##################################################
# Deploy VNets, Subnets, and NSGs, then VNet peerings, if so indicated above
if ($DeployVNetSubnetsNSGs) {
	.\vnetSubnetsNsgs.deploy.ps1;
	.\vnetPeerings.deploy.ps1;
}
# ##################################################


# ##################################################
# Deploy storage accounts for Linux VMs mounts if so indicated above
if ($DeployStorage) {
	.\storage.deploy.ps1;
}
# ##################################################


# ##################################################
# Storage Operations to prepare for Linux mounts to Azure storage
# These MUST be run whether new storage accounts are created above, or already-existing storage accounts are used.

# Need storage account keys for other operations
if ($DeployBastion) {$storageAccountKeyBastion = (Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroupNameStorageBastion -Name $StorageAccountNameBastion)[0].Value}
if ($DeployCluster1) {$storageAccountKeyCluster1 = (Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroupNameStorageCluster1 -Name $StorageAccountNameCluster1)[0].Value}
if ($DeployCluster2) {$storageAccountKeyCluster2 = (Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroupNameStorageCluster2 -Name $StorageAccountNameCluster2)[0].Value}
if ($DeployCluster3) {$storageAccountKeyCluster3 = (Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroupNameStorageCluster3 -Name $StorageAccountNameCluster3)[0].Value}

# Need storage context for other operations
if ($DeployBastion) {$storageContextBastion = New-AzureStorageContext -StorageAccountName $StorageAccountNameBastion -StorageAccountKey $storageAccountKeyBastion -Verbose}
if ($DeployCluster1) {$storageContextCluster1 = New-AzureStorageContext -StorageAccountName $StorageAccountNameCluster1 -StorageAccountKey $storageAccountKeyCluster1 -Verbose}
if ($DeployCluster2) {$storageContextCluster2 = New-AzureStorageContext -StorageAccountName $StorageAccountNameCluster2 -StorageAccountKey $storageAccountKeyCluster2 -Verbose}
if ($DeployCluster3) {$storageContextCluster3 = New-AzureStorageContext -StorageAccountName $StorageAccountNameCluster3 -StorageAccountKey $storageAccountKeyCluster3 -Verbose}

# Ensure the containers for Linux VM storage mounts exist
function DoStorageContainer()
{
	param
	(
		[Microsoft.WindowsAzure.Commands.Storage.AzureStorageContext]$StorageContext
	)

	$storageContainer = Get-AzureStorageContainer -Context $StorageContext -Name $AzureStorageContainerName -Verbose -ErrorAction SilentlyContinue

	if ($null -eq $storageContainer) {
		$storageContainer = New-AzureStorageContainer -Context $StorageContext -Name $AzureStorageContainerName -Permission Off -Verbose
	}
}

if ($DeployBastion) {DoStorageContainer -StorageContext $storageContextBastion}
if ($DeployCluster1) {DoStorageContainer -StorageContext $storageContextCluster1}
if ($DeployCluster2) {DoStorageContainer -StorageContext $storageContextCluster2}
if ($DeployCluster3) {DoStorageContainer -StorageContext $storageContextCluster3}

# Upload the bash script with overwrite if exists
if ($DeployBastion) {$storageBlobBastion = Set-AzureStorageBlobContent -Context $storageContextBastion -Container $AzureStorageContainerName -File $shellScriptToUploadLocalPath -Blob $shellScriptToUploadAzurePath -BlobType Block -Force -Verbose}
if ($DeployCluster1) {$storageBlobCluster1 = Set-AzureStorageBlobContent -Context $storageContextCluster1 -Container $AzureStorageContainerName -File $shellScriptToUploadLocalPath -Blob $shellScriptToUploadAzurePath -BlobType Block -Force -Verbose}
if ($DeployCluster2) {$storageBlobCluster2 = Set-AzureStorageBlobContent -Context $storageContextCluster2 -Container $AzureStorageContainerName -File $shellScriptToUploadLocalPath -Blob $shellScriptToUploadAzurePath -BlobType Block -Force -Verbose}
if ($DeployCluster3) {$storageBlobCluster3 = Set-AzureStorageBlobContent -Context $storageContextCluster3 -Container $AzureStorageContainerName -File $shellScriptToUploadLocalPath -Blob $shellScriptToUploadAzurePath -BlobType Block -Force -Verbose}
# ##################################################
# Azure Blob Fuse driver install prep
# https://github.com/Azure/azure-storage-fuse/wiki/1.-Installation
# https://github.com/Azure/azure-storage-fuse/wiki/2.-Configuring-and-Running
$blobFuseTempPath_Ubuntu = "/mnt/blobfusetmp";
$blobFuseConfigPath = "/etc/blobfuse_azureblob.cfg";

if ($DeployBastion) {$blobFuseConfigContentBastion = "accountName " + $StorageAccountNameBastion + "\n" + "accountKey " + $storageAccountKeyBastion + "\n" + "containerName " + $AzureStorageContainerName}
if ($DeployCluster1) {$blobFuseConfigContentCluster1 = "accountName " + $StorageAccountNameCluster1 + "\n" + "accountKey " + $storageAccountKeyCluster1 + "\n" + "containerName " + $AzureStorageContainerName}
if ($DeployCluster2) {$blobFuseConfigContentCluster2 = "accountName " + $StorageAccountNameCluster2 + "\n" + "accountKey " + $storageAccountKeyCluster2 + "\n" + "containerName " + $AzureStorageContainerName}
if ($DeployCluster3) {$blobFuseConfigContentCluster3 = "accountName " + $StorageAccountNameCluster3 + "\n" + "accountKey " + $storageAccountKeyCluster3 + "\n" + "containerName " + $AzureStorageContainerName}
# ##################################################
# Ubuntu shell command to run at the end of VM deploy

function GetShellCmd()
{
	param
	(
		[string]$userName,
		[string]$blobFuseConfigContent
	)

	$result = `
		"sudo wget https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb && " + `
		"sudo dpkg -i packages-microsoft-prod.deb && " + `
		"sudo apt-get update -y && sudo apt-get upgrade -y -qq && " + `
		"sudo apt-get install -y blobfuse fuse && " + `
		"sudo apt-get update -y && sudo apt-get upgrade -y -qq && " + `
		"sudo mkdir " + $blobFuseTempPath_Ubuntu + " && " + `
		"sudo chown " + $userName + " " + $blobFuseTempPath_Ubuntu + " && " + `
		"sudo bash -c 'echo -e """ + $blobFuseConfigContent + """ >> " + $blobFuseConfigPath + "' && " + `
		"sudo mkdir " + $LinuxMountPoint + " && " + `
		"sudo blobfuse " + $LinuxMountPoint + " --tmp-path=" + $s + " --config-file=" + $blobFuseConfigPath + "  -o allow_other -o attr_timeout=240 -o entry_timeout=240 -o negative_timeout=120 --file-cache-timeout-in-seconds=120 --log-level=LOG_DEBUG && " + `
		"sudo bash " + $LinuxMountPoint + "/" + $ShellScriptToUploadAzurePath + ";"
	
	return $result;
}

if ($DeployBastion) {$postDeployShellCmd_Bastion = GetShellCmd -userName $BastionVMAdminUsername -blobFuseConfigContent $blobFuseConfigContentBastion}
if ($DeployCluster1) {$postDeployShellCmd_Cluster1 = GetShellCmd -userName $ServerVMAdminUsername -blobFuseConfigContent $blobFuseConfigContentCluster1}
if ($DeployCluster2) {$postDeployShellCmd_Cluster2 = GetShellCmd -userName $ServerVMAdminUsername -blobFuseConfigContent $blobFuseConfigContentCluster2}
if ($DeployCluster3) {$postDeployShellCmd_Cluster3 = GetShellCmd -userName $ServerVMAdminUsername -blobFuseConfigContent $blobFuseConfigContentCluster3}

# OPTIONAL: Write shell command to file for inspection	
# $postDeployShellCmd_Bastion | Out-File "post_deploy_cmd_bastion.txt"
# $postDeployShellCmd_Cluster1 | Out-File "post_deploy_cmd_cluster1.txt"
# $postDeployShellCmd_Cluster2 | Out-File "post_deploy_cmd_cluster2.txt"
# $postDeployShellCmd_Cluster3 | Out-File "post_deploy_cmd_cluster3.txt"
# ##################################################


# ##################################################
# Deploy Bastion VM
if ($DeployBastion) {
	.\bastionvm.deploy.ps1 -PostDeployShellCmd $postDeployShellCmd_Bastion;
}
# ##################################################


# ##################################################
# Deploy Server VMs
if ($DeployCluster1) {
	.\servervm.deploy.ps1 -AzureRegion $AzureRegionCluster1 -ResourceGroupNameVM $ResourceGroupNameVMsCluster1 -AvailabilitySetName $VMAvailabilitySetNameCluster1 -VMName $ServerNameC1VM1 -ResourceGroupNameNetwork $ResourceGroupNameNetworkCluster1 -VNetName $VNetNameCluster1 -SubnetName $SubnetNameCluster1 -PostDeployShellCmd $postDeployShellCmd_Cluster1;
	.\servervm.deploy.ps1 -AzureRegion $AzureRegionCluster1 -ResourceGroupNameVM $ResourceGroupNameVMsCluster1 -AvailabilitySetName $VMAvailabilitySetNameCluster1 -VMName $ServerNameC1VM2 -ResourceGroupNameNetwork $ResourceGroupNameNetworkCluster1 -VNetName $VNetNameCluster1 -SubnetName $SubnetNameCluster1 -PostDeployShellCmd $postDeployShellCmd_Cluster1;
	.\servervm.deploy.ps1 -AzureRegion $AzureRegionCluster1 -ResourceGroupNameVM $ResourceGroupNameVMsCluster1 -AvailabilitySetName $VMAvailabilitySetNameCluster1 -VMName $ServerNameC1VM3 -ResourceGroupNameNetwork $ResourceGroupNameNetworkCluster1 -VNetName $VNetNameCluster1 -SubnetName $SubnetNameCluster1 -PostDeployShellCmd $postDeployShellCmd_Cluster1;
}

if ($DeployCluster2) {
	.\servervm.deploy.ps1 -AzureRegion $AzureRegionCluster2 -ResourceGroupNameVM $ResourceGroupNameVMsCluster2 -AvailabilitySetName $VMAvailabilitySetNameCluster2 -VMName $ServerNameC2VM1 -ResourceGroupNameNetwork $ResourceGroupNameNetworkCluster2 -VNetName $VNetNameCluster2 -SubnetName $SubnetNameCluster2 -PostDeployShellCmd $postDeployShellCmd_Cluster2;
	.\servervm.deploy.ps1 -AzureRegion $AzureRegionCluster2 -ResourceGroupNameVM $ResourceGroupNameVMsCluster2 -AvailabilitySetName $VMAvailabilitySetNameCluster2 -VMName $ServerNameC2VM2 -ResourceGroupNameNetwork $ResourceGroupNameNetworkCluster2 -VNetName $VNetNameCluster2 -SubnetName $SubnetNameCluster2 -PostDeployShellCmd $postDeployShellCmd_Cluster2;
	.\servervm.deploy.ps1 -AzureRegion $AzureRegionCluster2 -ResourceGroupNameVM $ResourceGroupNameVMsCluster2 -AvailabilitySetName $VMAvailabilitySetNameCluster2 -VMName $ServerNameC2VM3 -ResourceGroupNameNetwork $ResourceGroupNameNetworkCluster2 -VNetName $VNetNameCluster2 -SubnetName $SubnetNameCluster2 -PostDeployShellCmd $postDeployShellCmd_Cluster2;
}

if ($DeployCluster3) {
	.\servervm.deploy.ps1 -AzureRegion $AzureRegionCluster3 -ResourceGroupNameVM $ResourceGroupNameVMsCluster3 -AvailabilitySetName $VMAvailabilitySetNameCluster3 -VMName $ServerNameC3VM1 -ResourceGroupNameNetwork $ResourceGroupNameNetworkCluster3 -VNetName $VNetNameCluster3 -SubnetName $SubnetNameCluster3 -PostDeployShellCmd $postDeployShellCmd_Cluster3;
	.\servervm.deploy.ps1 -AzureRegion $AzureRegionCluster3 -ResourceGroupNameVM $ResourceGroupNameVMsCluster3 -AvailabilitySetName $VMAvailabilitySetNameCluster3 -VMName $ServerNameC3VM2 -ResourceGroupNameNetwork $ResourceGroupNameNetworkCluster3 -VNetName $VNetNameCluster3 -SubnetName $SubnetNameCluster3 -PostDeployShellCmd $postDeployShellCmd_Cluster3;
	.\servervm.deploy.ps1 -AzureRegion $AzureRegionCluster3 -ResourceGroupNameVM $ResourceGroupNameVMsCluster3 -AvailabilitySetName $VMAvailabilitySetNameCluster3 -VMName $ServerNameC3VM3 -ResourceGroupNameNetwork $ResourceGroupNameNetworkCluster3 -VNetName $VNetNameCluster3 -SubnetName $SubnetNameCluster3 -PostDeployShellCmd $postDeployShellCmd_Cluster3;
}
