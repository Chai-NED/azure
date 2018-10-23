param
(
 [string]
 $subscriptionId = '',

 [string]
 $resourceGroupName = '',

 [string]
 $resourceGroupLocation = 'eastus',

 [string]
 $deploymentName = 'Oracle'
)

$templateFilePath_Storage = '.\Storage\storage.deploy.json'
$parametersFilePath_Storage = '.\Storage\storage.parameters.json'

$templateFilePath_Network = '.\VNetSubnetsNsgs\vnetSubnetsNsgs.deploy.json'
$parametersFilePath_Network = '.\VNetSubnetsNsgs\vnetSubnetsNsgs.parameters.json'

$templateFilePath_VM = '.\VM\vm.deploy.json'
$parametersFilePath_VM = '.\VM\vm.parameters.json'

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
Write-Host "Testing deployment - storage";
Test-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath_Storage -TemplateParameterFile $parametersFilePath_Storage -Verbose

Write-Host "Testing deployment - network";
Test-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath_Network -TemplateParameterFile $parametersFilePath_Network -Verbose

Write-Host "Testing deployment - VM";
Test-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath_VM -TemplateParameterFile $parametersFilePath_VM -Verbose

# Start the deployments
Write-Host "Deploying storage";
New-AzureRmResourceGroupDeployment -Name $deploymentName -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath_Storage -TemplateParameterFile $parametersFilePath_Storage -DeploymentDebugLogLevel All

Write-Host "Deploying network";
New-AzureRmResourceGroupDeployment -Name $deploymentName -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath_Network -TemplateParameterFile $parametersFilePath_Network -DeploymentDebugLogLevel All

Write-Host "Deploying VM";
New-AzureRmResourceGroupDeployment -Name $deploymentName -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath_VM -TemplateParameterFile $parametersFilePath_VM -DeploymentDebugLogLevel All
