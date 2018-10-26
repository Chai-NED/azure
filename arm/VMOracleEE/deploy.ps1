### NOTE
# This PS script uses params for New-AzureRmResourceGroupDeployment: -Verbose -DeploymentDebugLogLevel All
# These params WILL result in extra logging, including to Azure deployment results.
# This WILL result in sensitive values (like the ssh key) being potentially available after the fact.
# For Production deployments, you should remove these params from the New-AzureRmResourceGroupDeployment calls below.

# Parameters
param
(
	[string]$subscriptionId = '',
	[string]$resourceGroupName = 'oracle-rg',
	[string]$resourceGroupLocation = 'centralus',
	[string]$storageAccountName = '',
	[string]$deploymentName = 'Oracle'
)

# Login to Azure and set subscription for deployment
Login-AzureRmAccount;
Select-AzureRmSubscription -SubscriptionID $subscriptionId;


# ##########
# Deployment file paths
$templateFilePath_VNetSubnetsNSGs = '.\VNetSubnetsNsgs\vnetSubnetsNsgs.deploy.json'
$parametersFilePath_VNetSubnetsNSGs = '.\VNetSubnetsNsgs\vnetSubnetsNsgs.parameters.json'

$templateFilePath_Storage = '.\Storage\storage.deploy.json'
$parametersFilePath_Storage = '.\Storage\storage.parameters.json'

$templateFilePath_BastionVM_Ubuntu = '.\BastionVM\vm.ubuntu.deploy.json'
$parametersFilePath_BastionVM_Ubuntu = '.\BastionVM\vm.ubuntu.parameters.json'

$templateFilePath_OracleVM = '.\OracleVM\vm.oracle.deploy.json'
$parametersFilePath_OracleVM = '.\OracleVM\vm.oracle.parameters.json'

$templateFilePath_BastionVM_Win2016 = '.\BastionVM\vm.win2016.deploy.json'
$parametersFilePath_BastionVM_Win2016 = '.\BastionVM\vm.win2016.parameters.json'
#

# Storage management for Linux VMs
$storageShareName = "software"
$storageMountPoint = "/mnt/azure"
# ##########


#Create or check for existing resource group
$resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue

if (!$resourceGroup) {
	Write-Host "Creating resource group '$resourceGroupName' in location '$resourceGroupLocation'";
	New-AzureRmResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation
}
else {
	Write-Host "Found existing resource group '$resourceGroupName'";
}



# Test the deployments
Write-Host "Testing deployment - VNet/Subnets/NSGs";
Test-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath_VNetSubnetsNSGs -TemplateParameterFile $parametersFilePath_VNetSubnetsNSGs -Verbose

Write-Host "Testing deployment - Storage";
Test-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath_Storage -TemplateParameterFile $parametersFilePath_Storage -Verbose

Write-Host "Testing deployment - Oracle VM";
Test-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath_OracleVM -TemplateParameterFile $parametersFilePath_OracleVM -virtualMachineName "test" -availabilityZones 1 -subnetName "test" -storageShellCommand "test" -Verbose

Write-Host "Testing deployment - Bastion VM - Ubuntu Server 18.10";
Test-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath_BastionVM_Ubuntu -TemplateParameterFile $parametersFilePath_BastionVM_Ubuntu -Verbose

Write-Host "Testing deployment - Bastion VM - Windows Server 2016 Datacenter";
Test-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath_BastionVM_Win2016 -TemplateParameterFile $parametersFilePath_BastionVM_Win2016 -Verbose



# Start the deployments
# Deploy VNet, Subnets, and NSGs
Write-Host "Deploying VNet/Subnets/NSGs";
New-AzureRmResourceGroupDeployment -Name ($deploymentName + '-Network') -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath_VNetSubnetsNSGs -TemplateParameterFile $parametersFilePath_VNetSubnetsNSGs -DeploymentDebugLogLevel All
# Get-AzureRmResourceGroupDeploymentOperation -DeploymentName ($deploymentName + '-Network') -ResourceGroupName $resourceGroupName

# Deploy Storage Account
Write-Host "Deploying Storage";
New-AzureRmResourceGroupDeployment -Name ($deploymentName + '-Storage') -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath_Storage -TemplateParameterFile $parametersFilePath_Storage -DeploymentDebugLogLevel All
# Get-AzureRmResourceGroupDeploymentOperation -DeploymentName ($deploymentName + '-Storage') -ResourceGroupName $resourceGroupName

# Get Storage Account Key and use it to create an Azure File Share called software
$key = (Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccountName)[0].Value
# $keySecure = ConvertTo-SecureString -String $key -AsPlainText -Force
$storageContext = New-AzureStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $key
$share = New-AzureStorageShare $storageShareName -Context $storageContext


# Linux VMs - we will pass several parameters dynamically in addition to the parameters file.
# Dynamic params include a shell script to mount Azure storage, and for the Oracle VMs, we also pass per-VM name, availability zone, and subnet.

# Prepare shell command to run in Linux VMs for persistent mount point to Azure Files storage
$shell_start_ubuntu = "sudo apt-get update && sudo apt-get install cifs-utils && "

# Oracle Enterprise Linux 6.6 uses Linux kernel 3.8. I have not been able to get OEL to mount Azure Files shares, even after downgrading to SMB 2.1.
# See for example https://community.oracle.com/thread/3650780
# $shell_start_oracle = "sudo yum -y install cifs-utils && "

$shell_main = `
"sudo mkdir " + $storageMountPoint + " && " + `
"if [ ! -d ""/etc/smbcredentials"" ]; then sudo mkdir /etc/smbcredentials; fi && " + `
"if [ ! -f ""/etc/smbcredentials/" + $storageAccountName + ".cred"" ]; then sudo bash -c 'echo -e ""username=" + $storageAccountName + "\npassword=" + $key + """ >> /etc/smbcredentials/" + $storageAccountName + ".cred'; fi && " + `
"sudo chmod 600 /etc/smbcredentials/" + $storageAccountName + ".cred && " + `
"sudo bash -c 'echo ""//" + $storageAccountName + ".file.core.windows.net/" + $storageShareName + " " + $storageMountPoint + " cifs nofail,vers=3.0,credentials=/etc/smbcredentials/" + $storageAccountName + ".cred,dir_mode=0777,file_mode=0777,serverino"" >> /etc/fstab' && " + `
"sudo mount -a;"

$shell_ubuntu = $shell_start_ubuntu + $shell_main
# $shell_oracle = $shell_start_oracle + $shell_main

# Deploy Bastion Host - Ubuntu
Write-Host "Deploying Bastion VM - Ubuntu Server 18.10";
New-AzureRmResourceGroupDeployment -Name ($deploymentName + '-BastionUbuntu') -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath_BastionVM_Ubuntu -TemplateParameterFile $parametersFilePath_BastionVM_Ubuntu -storageShellCommand $shell_ubuntu -DeploymentDebugLogLevel All
# Get-AzureRmResourceGroupDeploymentOperation -DeploymentName ($deploymentName + '-BastionUbuntu') -ResourceGroupName $resourceGroupName

# Deploy first of two Oracle VMs
Write-Host "Deploying Oracle VM1";
New-AzureRmResourceGroupDeployment -Name ($deploymentName + '-OracleVM1') -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath_OracleVM -TemplateParameterFile $parametersFilePath_OracleVM -virtualMachineName "oravm1" -availabilityZones 1 -subnetName "private1" -Verbose -DeploymentDebugLogLevel All
# Get-AzureRmResourceGroupDeploymentOperation -DeploymentName ($deploymentName + '-OracleVM1') -ResourceGroupName $resourceGroupName

# Deploy second of two Oracle VMs
Write-Host "Deploying Oracle VM2";
New-AzureRmResourceGroupDeployment -Name ($deploymentName + '-OracleVM2') -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath_OracleVM -TemplateParameterFile $parametersFilePath_OracleVM -virtualMachineName "oravm2" -availabilityZones 2 -subnetName "private2" -Verbose -DeploymentDebugLogLevel All
# Get-AzureRmResourceGroupDeploymentOperation -DeploymentName ($deploymentName + '-OracleVM2') -ResourceGroupName $resourceGroupName

# Deploy Bastion Host - Windows
Write-Host "Deploying Bastion VM - Windows Server 2016 Datacenter";
New-AzureRmResourceGroupDeployment -Name ($deploymentName + '-BastionWindows') -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath_BastionVM_Win2016 -TemplateParameterFile $parametersFilePath_BastionVM_Win2016 -Verbose -DeploymentDebugLogLevel All
# Get-AzureRmResourceGroupDeploymentOperation -DeploymentName ($deploymentName + '-BastionWindows') -ResourceGroupName $resourceGroupName
