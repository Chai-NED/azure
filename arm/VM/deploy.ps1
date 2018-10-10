param(
 [string]
 $subscriptionId = '',

 [string]
 $resourceGroupName = '',

 [string]
 $resourceGroupLocation = '',

 [string]
 $deploymentName = 'VM',

 [string]
 $templateFilePath = 'azuredeploy.json',

 [string]
 $parametersFilePath = 'azuredeploy.parameters.PickOne.json'
)

Login-AzureRmAccount;

Select-AzureRmSubscription -SubscriptionID $subscriptionId;

#Create or check for existing resource group
$resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue

if(!$resourceGroup)
{
    Write-Host "Resource group '$resourceGroupName' does not exist. To create a new resource group, please enter a location.";
    if(!$resourceGroupLocation) {
        $resourceGroupLocation = Read-Host "resourceGroupLocation";
    }
    Write-Host "Creating resource group '$resourceGroupName' in location '$resourceGroupLocation'";
    New-AzureRmResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation
}
else{
    Write-Host "Using existing resource group '$resourceGroupName'";
}

# Test the deployment
Write-Host "Testing deployment...";
Test-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath -TemplateParameterFile $parametersFilePath -Verbose

# Start the deployment
Write-Host "Starting deployment...";
New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath -TemplateParameterFile $parametersFilePath -DeploymentDebugLogLevel All