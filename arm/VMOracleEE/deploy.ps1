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

$templateFilePath_Storage = '.\Storage\azuredeploy.json'
$parametersFilePath_Storage = '.\Storage\azuredeploy.parameters.json'

$templateFilePath_Network = '.\Network\azuredeploy.json'
$parametersFilePath_Network = '.\Network\azuredeploy.parameters.json'

$templateFilePath_VM = '.\VM\azuredeploy.json'
$parametersFilePath_VM = '.\VM\azuredeploy.parameters.json'

function New-DeploymentResultException([Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResourceManagerError]$error)
{
    $errorMessage = "$($error.Message) ($($error.Code)) [Target: $($error.Target)]"

    if ($error.Details)
    {
        $innerExceptions =  $error.Details | ForEach-Object { New-DeploymentResultException $_ }
        return New-Object System.AggregateException $errorMessage, $innerExceptions
    }
    else 
    { 
        return New-Object System.Configuration.ConfigurationErrorsException $errorMessage
    }
}

Login-AzureRmAccount;

Select-AzureRmSubscription -SubscriptionID $subscriptionId;

#Create or check for existing resource group
$resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue

if(!$resourceGroup)
{
    Write-Host "Creating resource group '$resourceGroupName' in location '$resourceGroupLocation'";
    New-AzureRmResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation
}
else
{
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
