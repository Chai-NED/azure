### NOTE
# This PS script uses params for New-AzureRmResourceGroupDeployment: -Verbose -DeploymentDebugLogLevel All
# These params WILL result in extra logging, including to Azure deployment results.
# This WILL result in sensitive values (like the ssh key) being potentially available after the fact.
# For Production deployments, you should remove these params from the New-AzureRmResourceGroupDeployment calls below.

param
(
	[string]$subscriptionId = '',

	[string]$resourceGroupName = 'oracle-rg',

	[string]$resourceGroupLocation = 'centralus',

	[string]$storageAccountName = '',

	[string]$deploymentName = 'Oracle'
)

$templateFilePath_Storage = '.\Storage\storage.deploy.json'
$parametersFilePath_Storage = '.\Storage\storage.parameters.json'

$templateFilePath_Network = '.\VNetSubnetsNsgs\vnetSubnetsNsgs.deploy.json'
$parametersFilePath_Network = '.\VNetSubnetsNsgs\vnetSubnetsNsgs.parameters.json'

$templateFilePath_OracleVM = '.\OracleVM\vm.oracle.deploy.json'
$parametersFilePath_OracleVM1 = '.\OracleVM\vm1.oracle.parameters.json'
$parametersFilePath_OracleVM2 = '.\OracleVM\vm2.oracle.parameters.json'

$templateFilePath_BastionVM_Win2016 = '.\BastionVM\vm.win2016.deploy.json'
$parametersFilePath_BastionVM_Win2016 = '.\BastionVM\vm.win2016.parameters.json'

$templateFilePath_BastionVM_Ubuntu = '.\BastionVM\vm.ubuntu.deploy.json'
$parametersFilePath_BastionVM_Ubuntu = '.\BastionVM\vm.ubuntu.parameters.json'

# Values for storage management
$storageShareName = "software"
$storageMountPoint = "/mnt/azure"

Login-AzureRmAccount;

Select-AzureRmSubscription -SubscriptionID $subscriptionId;

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
Write-Host "Testing deployment - network";
Test-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath_Network -TemplateParameterFile $parametersFilePath_Network -Verbose

Write-Host "Testing deployment - storage";
Test-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath_Storage -TemplateParameterFile $parametersFilePath_Storage -Verbose

Write-Host "Testing deployment - Oracle VM1";
Test-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath_OracleVM -TemplateParameterFile $parametersFilePath_OracleVM1 -Verbose

Write-Host "Testing deployment - Oracle VM2";
Test-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath_OracleVM -TemplateParameterFile $parametersFilePath_OracleVM2 -Verbose

Write-Host "Testing deployment - Bastion VM - Ubuntu Server 18.10";
Test-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath_BastionVM_Ubuntu -TemplateParameterFile $parametersFilePath_BastionVM_Ubuntu -Verbose

Write-Host "Testing deployment - Bastion VM - Windows Server 2016 Datacenter";
Test-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath_BastionVM_Win2016 -TemplateParameterFile $parametersFilePath_BastionVM_Win2016 -Verbose



# Start the deployments
# Deploy VNet, Subnets, and NSGs
Write-Host "Deploying network";
New-AzureRmResourceGroupDeployment -Name ($deploymentName + '-Network') -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath_Network -TemplateParameterFile $parametersFilePath_Network -DeploymentDebugLogLevel All
# Get-AzureRmResourceGroupDeploymentOperation -DeploymentName ($deploymentName + '-Network') -ResourceGroupName $resourceGroupName

# Deploy Storage Account
Write-Host "Deploying storage";
New-AzureRmResourceGroupDeployment -Name ($deploymentName + '-Storage') -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath_Storage -TemplateParameterFile $parametersFilePath_Storage -DeploymentDebugLogLevel All
# Get-AzureRmResourceGroupDeploymentOperation -DeploymentName ($deploymentName + '-Storage') -ResourceGroupName $resourceGroupName


# Get Storage Account Key and use it to create an Azure File Share called software
$key = (Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccountName)[0].Value
# $keySecure = ConvertTo-SecureString -String $key -AsPlainText -Force
$storageContext = New-AzureStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $key
$share = New-AzureStorageShare $storageShareName -Context $storageContext

# Prepare shell command to run in Linux VMs for persistent mount point to Azure Files storage
$storageShellCommand = `
"sudo apt-get update && sudo apt-get install cifs-utils && " + `
"sudo mkdir " + $storageMountPoint + " && " + `
"if [ ! -d ""/etc/smbcredentials"" ]; then sudo mkdir /etc/smbcredentials; fi && " + `
"if [ ! -f ""/etc/smbcredentials/" + $storageAccountName + ".cred"" ]; then sudo bash -c 'echo -e ""username=" + $storageAccountName + "\npassword=" + $key + """ >> /etc/smbcredentials/" + $storageAccountName + ".cred'; fi && " + `
"sudo chmod 600 /etc/smbcredentials/" + $storageAccountName + ".cred && " + `
"sudo bash -c 'echo ""//" + $storageAccountName + ".file.core.windows.net/" + $storageShareName + " " + $storageMountPoint + " cifs nofail,vers=3.0,credentials=/etc/smbcredentials/" + $storageAccountName + ".cred,dir_mode=0777,file_mode=0777,serverino"" >> /etc/fstab' && " + `
"sudo mount -a;"


# Deploy first of two Oracle VMs
Write-Host "Deploying Oracle VM1";
New-AzureRmResourceGroupDeployment -Name ($deploymentName + '-OracleVM1') -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath_OracleVM -TemplateParameterFile $parametersFilePath_OracleVM1 -Verbose -DeploymentDebugLogLevel All
# Get-AzureRmResourceGroupDeploymentOperation -DeploymentName ($deploymentName + '-OracleVM1') -ResourceGroupName $resourceGroupName

# Deploy second of two Oracle VMs
Write-Host "Deploying Oracle VM2";
New-AzureRmResourceGroupDeployment -Name ($deploymentName + '-OracleVM2') -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath_OracleVM -TemplateParameterFile $parametersFilePath_OracleVM2 -Verbose -DeploymentDebugLogLevel All
# Get-AzureRmResourceGroupDeploymentOperation -DeploymentName ($deploymentName + '-OracleVM2') -ResourceGroupName $resourceGroupName

# Deploy Bastion Host - Ubuntu
# We pass the Azure Files storage mount info as dynamic params on the command line, as the storage account was created above and we got the storage account key there.
# The key is needed for the shell script that mounts Azure Files share inside the VM.
# Obviously, if you will use an already-existing storage account with a static, known key you can change this call by removing the dynamic parameters, and instead providing the storage
#    values in the VM parameters.json file itself. The dynamic-param approach is used here to show how a programmatically just-created storage account can be used with Linux VMs.
# In the VM deploy.json file, see the resource entry for the custom script extension to see the bash command that runs using these params.
Write-Host "Deploying Bastion VM - Ubuntu Server 18.10";
New-AzureRmResourceGroupDeployment -Name ($deploymentName + '-BastionUbuntu') -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath_BastionVM_Ubuntu -TemplateParameterFile $parametersFilePath_BastionVM_Ubuntu -storageShellCommand $storageShellCommand -DeploymentDebugLogLevel All
# Get-AzureRmResourceGroupDeploymentOperation -DeploymentName ($deploymentName + '-BastionUbuntu') -ResourceGroupName $resourceGroupName

# Deploy Bastion Host - Windows
Write-Host "Deploying Bastion VM - Windows Server 2016 Datacenter";
New-AzureRmResourceGroupDeployment -Name ($deploymentName + '-BastionWindows') -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath_BastionVM_Win2016 -TemplateParameterFile $parametersFilePath_BastionVM_Win2016 -Verbose -DeploymentDebugLogLevel All
# Get-AzureRmResourceGroupDeploymentOperation -DeploymentName ($deploymentName + '-BastionWindows') -ResourceGroupName $resourceGroupName
