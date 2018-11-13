# See the readme and edit globals.ps1 before running this script.

.\globals.ps1

$deployVNetSubnetsNSGs = $true
$deployStorage = $true
$deployBastionVM = $true
$deployServerVMs = $true


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
DoResourceGroup -ResourceGroupName $ResourceGroupNameNetworkBastion -AzureRegion $AzureRegionBastion
DoResourceGroup -ResourceGroupName $ResourceGroupNameNetworkCluster1 -AzureRegion $AzureRegionCluster1
DoResourceGroup -ResourceGroupName $ResourceGroupNameNetworkCluster2 -AzureRegion $AzureRegionCluster2
DoResourceGroup -ResourceGroupName $ResourceGroupNameNetworkCluster3 -AzureRegion $AzureRegionCluster3

# Storage resource groups
DoResourceGroup -ResourceGroupName $ResourceGroupNameStorageBastion -AzureRegion $AzureRegionBastion
DoResourceGroup -ResourceGroupName $ResourceGroupNameStorageCluster1 -AzureRegion $AzureRegionCluster1
DoResourceGroup -ResourceGroupName $ResourceGroupNameStorageCluster2 -AzureRegion $AzureRegionCluster2
DoResourceGroup -ResourceGroupName $ResourceGroupNameStorageCluster3 -AzureRegion $AzureRegionCluster3

if ($deployBastionVM) {
	DoResourceGroup -ResourceGroupName $ResourceGroupNameVMsBastion -AzureRegion $AzureRegionBastion
}

if ($deployServerVMs) {
	DoResourceGroup -ResourceGroupName $ResourceGroupNameVMsCluster1 -AzureRegion $AzureRegionCluster1
	DoResourceGroup -ResourceGroupName $ResourceGroupNameVMsCluster2 -AzureRegion $AzureRegionCluster2
	DoResourceGroup -ResourceGroupName $ResourceGroupNameVMsCluster3 -AzureRegion $AzureRegionCluster3
}
# ##################################################


# ##################################################
# Deploy VNets, Subnets, and NSGs, then VNet peerings, if so indicated above
if ($deployVNetSubnetsNSGs) {
	.\vnetSubnetsNsgs.deploy.ps1;
	.\vnetPeerings.deploy.ps1;
}
# ##################################################


# ##################################################
# Deploy storage accounts for Linux VMs mounts if so indicated above
if ($deployStorage) {
	.\storage.deploy.ps1;
}
# ##################################################


# ##################################################
# Storage Operations to prepare for Linux mounts to Azure storage
# These MUST be run whether new storage accounts are created above, or already-existing storage accounts are used.

# Need storage account keys for other operations
$storageAccountKeyBastion = (Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroupNameStorageBastion -Name $StorageAccountNameBastion)[0].Value
$storageAccountKeyCluster1 = (Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroupNameStorageCluster1 -Name $StorageAccountNameCluster1)[0].Value
$storageAccountKeyCluster2 = (Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroupNameStorageCluster2 -Name $StorageAccountNameCluster2)[0].Value
$storageAccountKeyCluster3 = (Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroupNameStorageCluster3 -Name $StorageAccountNameCluster3)[0].Value

# Need storage context for other operations
$storageContextBastion = New-AzureStorageContext -StorageAccountName $StorageAccountNameBastion -StorageAccountKey $storageAccountKeyBastion -Verbose
$storageContextCluster1 = New-AzureStorageContext -StorageAccountName $StorageAccountNameCluster1 -StorageAccountKey $storageAccountKeyCluster1 -Verbose
$storageContextCluster2 = New-AzureStorageContext -StorageAccountName $StorageAccountNameCluster2 -StorageAccountKey $storageAccountKeyCluster2 -Verbose
$storageContextCluster3 = New-AzureStorageContext -StorageAccountName $StorageAccountNameCluster3 -StorageAccountKey $storageAccountKeyCluster3 -Verbose

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

DoStorageContainer -StorageContext $storageContextBastion
DoStorageContainer -StorageContext $storageContextCluster1
DoStorageContainer -StorageContext $storageContextCluster2
DoStorageContainer -StorageContext $storageContextCluster3

# Upload the bash script with overwrite if exists
$storageBlobBastion = Set-AzureStorageBlobContent -Context $storageContextBastion -Container $AzureStorageContainerName -File $shellScriptToUploadLocalPath -Blob $shellScriptToUploadAzurePath -BlobType Block -Force -Verbose;
$storageBlobCluster1 = Set-AzureStorageBlobContent -Context $storageContextCluster1 -Container $AzureStorageContainerName -File $shellScriptToUploadLocalPath -Blob $shellScriptToUploadAzurePath -BlobType Block -Force -Verbose;
$storageBlobCluster2 = Set-AzureStorageBlobContent -Context $storageContextCluster2 -Container $AzureStorageContainerName -File $shellScriptToUploadLocalPath -Blob $shellScriptToUploadAzurePath -BlobType Block -Force -Verbose;
$storageBlobCluster3 = Set-AzureStorageBlobContent -Context $storageContextCluster3 -Container $AzureStorageContainerName -File $shellScriptToUploadLocalPath -Blob $shellScriptToUploadAzurePath -BlobType Block -Force -Verbose;
# ##################################################
# Azure Blob Fuse driver install prep
# https://github.com/Azure/azure-storage-fuse/wiki/1.-Installation
# https://github.com/Azure/azure-storage-fuse/wiki/2.-Configuring-and-Running
$blobFuseTempPath_Ubuntu = "/mnt/blobfusetmp";
$blobFuseConfigPath = "/etc/blobfuse_azureblob.cfg";

$blobFuseConfigContentBastion = "accountName " + $StorageAccountNameBastion + "\n" + "accountKey " + $storageAccountKeyBastion + "\n" + "containerName " + $AzureStorageContainerName;
$blobFuseConfigContentCluster1 = "accountName " + $StorageAccountNameCluster1 + "\n" + "accountKey " + $storageAccountKeyCluster1 + "\n" + "containerName " + $AzureStorageContainerName;
$blobFuseConfigContentCluster2 = "accountName " + $StorageAccountNameCluster2 + "\n" + "accountKey " + $storageAccountKeyCluster2 + "\n" + "containerName " + $AzureStorageContainerName;
$blobFuseConfigContentCluster3 = "accountName " + $StorageAccountNameCluster3 + "\n" + "accountKey " + $storageAccountKeyCluster3 + "\n" + "containerName " + $AzureStorageContainerName;
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

$postDeployShellCmd_Bastion = GetShellCmd -userName $BastionVMAdminUsername -blobFuseConfigContent $blobFuseConfigContentBastion;
$postDeployShellCmd_Cluster1 = GetShellCmd -userName $ServerVMAdminUsername -blobFuseConfigContent $blobFuseConfigContentCluster1;
$postDeployShellCmd_Cluster2 = GetShellCmd -userName $ServerVMAdminUsername -blobFuseConfigContent $blobFuseConfigContentCluster2;
$postDeployShellCmd_Cluster3 = GetShellCmd -userName $ServerVMAdminUsername -blobFuseConfigContent $blobFuseConfigContentCluster3;

# OPTIONAL: Write shell command to file for inspection	
# $postDeployShellCmd_Bastion | Out-File "post_deploy_cmd_bastion.txt"
# $postDeployShellCmd_Cluster1 | Out-File "post_deploy_cmd_cluster1.txt"
# $postDeployShellCmd_Cluster2 | Out-File "post_deploy_cmd_cluster2.txt"
# $postDeployShellCmd_Cluster3 | Out-File "post_deploy_cmd_cluster3.txt"
# ##################################################


# ##################################################
# Deploy Bastion VM
if ($deployBastionVM) {
	.\bastionvm.deploy.ps1 -PostDeployShellCmd $postDeployShellCmd_Bastion;
}
# ##################################################


# ##################################################
# Deploy Server VMs
if ($deployServerVMs) {
	.\servervm.deploy.ps1 -AzureRegion $AzureRegionCluster1 -ResourceGroupNameVM $ResourceGroupNameVMsCluster1 -AvailabilitySetName $VMAvailabilitySetNameCluster1 -VMName $ServerNameC1VM1 -ResourceGroupNameNetwork $ResourceGroupNameNetworkCluster1 -VNetName $VNetNameCluster1 -SubnetName $SubnetNameCluster1 -PostDeployShellCmd $postDeployShellCmd_Cluster1;
	.\servervm.deploy.ps1 -AzureRegion $AzureRegionCluster1 -ResourceGroupNameVM $ResourceGroupNameVMsCluster1 -AvailabilitySetName $VMAvailabilitySetNameCluster1 -VMName $ServerNameC1VM2 -ResourceGroupNameNetwork $ResourceGroupNameNetworkCluster1 -VNetName $VNetNameCluster1 -SubnetName $SubnetNameCluster1 -PostDeployShellCmd $postDeployShellCmd_Cluster1;
	.\servervm.deploy.ps1 -AzureRegion $AzureRegionCluster1 -ResourceGroupNameVM $ResourceGroupNameVMsCluster1 -AvailabilitySetName $VMAvailabilitySetNameCluster1 -VMName $ServerNameC1VM3 -ResourceGroupNameNetwork $ResourceGroupNameNetworkCluster1 -VNetName $VNetNameCluster1 -SubnetName $SubnetNameCluster1 -PostDeployShellCmd $postDeployShellCmd_Cluster1;

	.\servervm.deploy.ps1 -AzureRegion $AzureRegionCluster2 -ResourceGroupNameVM $ResourceGroupNameVMsCluster2 -AvailabilitySetName $VMAvailabilitySetNameCluster2 -VMName $ServerNameC2VM1 -ResourceGroupNameNetwork $ResourceGroupNameNetworkCluster2 -VNetName $VNetNameCluster2 -SubnetName $SubnetNameCluster2 -PostDeployShellCmd $postDeployShellCmd_Cluster2;
	.\servervm.deploy.ps1 -AzureRegion $AzureRegionCluster2 -ResourceGroupNameVM $ResourceGroupNameVMsCluster2 -AvailabilitySetName $VMAvailabilitySetNameCluster2 -VMName $ServerNameC2VM2 -ResourceGroupNameNetwork $ResourceGroupNameNetworkCluster2 -VNetName $VNetNameCluster2 -SubnetName $SubnetNameCluster2 -PostDeployShellCmd $postDeployShellCmd_Cluster2;
	.\servervm.deploy.ps1 -AzureRegion $AzureRegionCluster2 -ResourceGroupNameVM $ResourceGroupNameVMsCluster2 -AvailabilitySetName $VMAvailabilitySetNameCluster2 -VMName $ServerNameC2VM3 -ResourceGroupNameNetwork $ResourceGroupNameNetworkCluster2 -VNetName $VNetNameCluster2 -SubnetName $SubnetNameCluster2 -PostDeployShellCmd $postDeployShellCmd_Cluster2;

	.\servervm.deploy.ps1 -AzureRegion $AzureRegionCluster3 -ResourceGroupNameVM $ResourceGroupNameVMsCluster3 -AvailabilitySetName $VMAvailabilitySetNameCluster3 -VMName $ServerNameC3VM1 -ResourceGroupNameNetwork $ResourceGroupNameNetworkCluster3 -VNetName $VNetNameCluster3 -SubnetName $SubnetNameCluster3 -PostDeployShellCmd $postDeployShellCmd_Cluster3;
	.\servervm.deploy.ps1 -AzureRegion $AzureRegionCluster3 -ResourceGroupNameVM $ResourceGroupNameVMsCluster3 -AvailabilitySetName $VMAvailabilitySetNameCluster3 -VMName $ServerNameC3VM2 -ResourceGroupNameNetwork $ResourceGroupNameNetworkCluster3 -VNetName $VNetNameCluster3 -SubnetName $SubnetNameCluster3 -PostDeployShellCmd $postDeployShellCmd_Cluster3;
	.\servervm.deploy.ps1 -AzureRegion $AzureRegionCluster3 -ResourceGroupNameVM $ResourceGroupNameVMsCluster3 -AvailabilitySetName $VMAvailabilitySetNameCluster3 -VMName $ServerNameC3VM3 -ResourceGroupNameNetwork $ResourceGroupNameNetworkCluster3 -VNetName $VNetNameCluster3 -SubnetName $SubnetNameCluster3 -PostDeployShellCmd $postDeployShellCmd_Cluster3;
}
