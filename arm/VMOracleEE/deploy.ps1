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
New-AzureRmResourceGroupDeployment -Name $deploymentName -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath_Network -TemplateParameterFile $parametersFilePath_Network -DeploymentDebugLogLevel All

# Deploy Storage Account
Write-Host "Deploying storage";
New-AzureRmResourceGroupDeployment -Name $deploymentName -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath_Storage -TemplateParameterFile $parametersFilePath_Storage -DeploymentDebugLogLevel All

# Get Storage Account Key and use it to create an Azure File Share called software
$key = (Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccountName)[0].Value
$storageContext = New-AzureStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $key
$share = New-AzureStorageShare 'software' -Context $storageContext

# Deploy first of two Oracle VMs
Write-Host "Deploying Oracle VM1";
New-AzureRmResourceGroupDeployment -Name $deploymentName -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath_OracleVM -TemplateParameterFile $parametersFilePath_OracleVM1 -Verbose -DeploymentDebugLogLevel All

# Deploy second of two Oracle VMs
Write-Host "Deploying Oracle VM2";
New-AzureRmResourceGroupDeployment -Name $deploymentName -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath_OracleVM -TemplateParameterFile $parametersFilePath_OracleVM2 -Verbose -DeploymentDebugLogLevel All

# Deploy Bastion Host - Ubuntu
Write-Host "Deploying Bastion VM - Ubuntu Server 18.10";
New-AzureRmResourceGroupDeployment -Name $deploymentName -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath_BastionVM_Ubuntu -TemplateParameterFile $parametersFilePath_BastionVM_Ubuntu -Verbose -DeploymentDebugLogLevel All

# Deploy Bastion Host - Windows
Write-Host "Deploying Bastion VM - Windows Server 2016 Datacenter";
New-AzureRmResourceGroupDeployment -Name $deploymentName -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath_BastionVM_Win2016 -TemplateParameterFile $parametersFilePath_BastionVM_Win2016 -Verbose -DeploymentDebugLogLevel All
