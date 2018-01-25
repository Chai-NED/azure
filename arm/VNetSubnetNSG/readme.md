This folder contains an ARM template to deploy a Virtual Network (VNet) with one subnet, and one Network Security Group (NSG) with one inbound rule in addition to the default inbound rules.

The VM will have a public IP address and at least one data disk. If either of those conditions are inappropriate for your context, please edit the template and parameters file accordingly.

__Pre-requisites:__
- Azure subscription (duh)
- Existing resource group (RG) into which to deploy

__ARM template preparation:__
- Edit the azuredeploy.parameters.json file and provide appropriate values.
- Consult azuredeploy.json for parameter descriptions if uncertain what to provide for any parameter value.

__Deployment modalities:__
1. Powershell: use the deploy.ps1 in this folder, which deploys from both azuredeploy.json and azuredeploy.parameters.json. Provide values for the parameters in azuredeploy.parameters.json and run it from a Powershell prompt. For more info, see https://docs.microsoft.com/azure/azure-resource-manager/resource-group-template-deploy
2. From Azure portal: use the "Deploy to Azure" button below.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fplzm%2Fazure%2Fmaster%2Farm%2FVNetSubnetNSG%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
