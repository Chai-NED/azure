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

$templateFilePath_OracleVM = '.\VM\vm.deploy.json'
$parametersFilePath_OracleVM1 = '.\VM\vm1.parameters.json'
$parametersFilePath_OracleVM2 = '.\VM\vm2.parameters.json'

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

# Start the deployments
Write-Host "Deploying network";
New-AzureRmResourceGroupDeployment -Name $deploymentName -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath_Network -TemplateParameterFile $parametersFilePath_Network -DeploymentDebugLogLevel All

Write-Host "Deploying storage";
New-AzureRmResourceGroupDeployment -Name $deploymentName -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath_Storage -TemplateParameterFile $parametersFilePath_Storage -DeploymentDebugLogLevel All

$key = (Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccountName)[0].Value
$storageContext = New-AzureStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $key
$share = New-AzureStorageShare 'software' -Context $storageContext

Write-Host "Deploying Oracle VM1";
New-AzureRmResourceGroupDeployment -Name $deploymentName -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath_OracleVM -TemplateParameterFile $parametersFilePath_OracleVM1 -DeploymentDebugLogLevel All

Write-Host "Deploying Oracle VM2";
New-AzureRmResourceGroupDeployment -Name $deploymentName -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath_OracleVM -TemplateParameterFile $parametersFilePath_OracleVM2 -DeploymentDebugLogLevel All
