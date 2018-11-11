# See the readme before running this

.\globals.ps1

$deployVNetSubnetsNSGs = $false
$deployStorage = $false
$deployBastionVM = $true
$deployOracleVMs = $true


# ##################################################
# Login to Azure and set subscription for deployment
Login-AzureRmAccount;
Select-AzureRmSubscription -SubscriptionID $SubscriptionId;
# ##################################################

# ##################################################
# Ensure VM resource group exists
$resourceGroupVMs = Get-AzureRmResourceGroup -Name $ResourceGroupNameVMs -Location $AzureRegion -ErrorAction SilentlyContinue

if (!$resourceGroupVMs) {
	New-AzureRmResourceGroup -Name $ResourceGroupNameVMs -Location $AzureRegion
}
# ##################################################


# ##################################################
# Deploy VNet, Subnets, and NSGs if so indicated above
if ($deployVNetSubnetsNSGs) {
	.\vnetSubnetsNsgs.deploy.ps1;
}
# ##################################################


# ##################################################
# Deploy storage account for Linux VM mount if so indicated above
if ($deployStorage) {
	.\storage.deploy.ps1;
}
# ##################################################


# ##################################################
# Storage Operations to prepare for Linux mounts to Azure storage
# These MUST be run whether a new storage account is created above, or an already-existing storage account was specified.

# Need storage account key for other operations
$storageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroupNameStorage -Name $StorageAccountName)[0].Value

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
# https://github.com/Azure/azure-storage-fuse/wiki/1.-Installation
# https://github.com/Azure/azure-storage-fuse/wiki/2.-Configuring-and-Running
$blobFuseTempPath_Ubuntu = "/mnt/blobfusetmp"
$blobFuseTempPath_OEL = "/mnt/blobfusetmp"
$blobFuseConfigPath = "/etc/blobfuse_azureblob.cfg"
$blobFuseConfigContent = "accountName " + $StorageAccountName + "\n" + "accountKey " + $storageAccountKey + "\n" + "containerName " + $AzureStorageContainerName
# ##################################################
# Ubuntu shell command to run at the end of VM deploy
$postDeployShellCmd_Ubuntu = `
	"sudo wget https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb && " + `
	"sudo dpkg -i packages-microsoft-prod.deb && " + `
	"sudo apt-get update -y && sudo apt-get upgrade -y -qq && " + `
	"sudo apt-get install -y blobfuse fuse && " + `
	"sudo apt-get update -y && sudo apt-get upgrade -y -qq && " + `
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
# Deploy Bastion VM
if ($deployBastionVM) {
	.\bastionvm.deploy.ps1 -PostDeployShellCmd $postDeployShellCmd_Ubuntu;
}
# ##################################################


# ##################################################
# Deploy Oracle VMs
if ($deployOracleVMs) {
	.\oraclevm.deploy.ps1 -AvailabilityZone $ServerAZ1 -VMName $ServerNameAZ1VM1 -SubnetName $SubnetNamePrivate1 -PostDeployShellCmd $postDeployShellCmd_OEL;
	.\oraclevm.deploy.ps1 -AvailabilityZone $ServerAZ1 -VMName $ServerNameAZ1VM2 -SubnetName $SubnetNamePrivate1 -PostDeployShellCmd $postDeployShellCmd_OEL;
	.\oraclevm.deploy.ps1 -AvailabilityZone $ServerAZ2 -VMName $ServerNameAZ2VM1 -SubnetName $SubnetNamePrivate2 -PostDeployShellCmd $postDeployShellCmd_OEL;
	.\oraclevm.deploy.ps1 -AvailabilityZone $ServerAZ2 -VMName $ServerNameAZ2VM2 -SubnetName $SubnetNamePrivate2 -PostDeployShellCmd $postDeployShellCmd_OEL;
}
