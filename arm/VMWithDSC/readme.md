This folder contains an ARM template to deploy a Windows VM to Azure. The VM will have anti-malware as well as Powershell DSC, with a specific DSC script applied. The DSC script to apply is specified in the azuredeploy.parameters.json file (see DSC resource preparation below), which means you can adapt this template to your own DSC script easily by changing the relevant parameters and uploading your own DSC resources to an appropriate location.

The VM will have a public IP address and at least one data disk. If either of those conditions are inappropriate for your context, please edit the template and parameters file accordingly.

__Pre-requisites:__
- Azure subscription (duh)
- Existing resource groups (RGs). The template contains parameters for separate resource groups for the VM itself, for networking resources, and for diagnostics logging. You can use the same RG for all of these (good for "try it out" where you'll delete the whole RG), or use a different RG for each purpose (good when there are durable networking and diagnostics resources already in place).
- Existing VNet, subnet, and NSG in the RG you'll specify that contains network resources ("resourceGroupNameNetwork" parameter).
- Existing standard storage account for diagnostics.
- The DSC resources uploaded to an accessible URL. This template does not provide for a security key, i.e. assumes the URL is public/open. Plenty of templates in our Azure Quickstart repo include security key functionality, if needed.

__DSC resource preparation:__
- See the last five parameters in azuredeploy.parameters.json: "_artifactsLocation", "dscFolder", "dscFileName", "dscModule", "dscFunction".
- The "_artifactsLocation" is the root URL where your DSC resources will be available. In this template, you can see I'm using a public Azure storage location.
- "dscFolder" is the folder path under the "_artifactsLocation" where the DSC resources specifically for this template can be found.
- "dscFileName" is the .zip file that contains your DSC .ps1 file(s).
- "dscModule" is the .ps1 filename within the .zip file.
- "dscFunction" is the name of the actual DSC function to call within the .ps1 filename.
- To better understand all this, check out azuredeploy.parameters.json and an example DSC zip file and its contents: https://pz17sa.blob.core.windows.net/public/dsc/IISDotNetWebServer/IISDotNetWebServer.zip (this file installs IIS, ASP.NET 4.6, and .NET 3.5/2.0)

__ARM template preparation:__
- Edit the azuredeploy.parameters.json file and provide appropriate values.
- Consult azuredeploy.json for parameter descriptions if uncertain what to provide for any parameter value.

__Notes:__
- An availability set name is required (whether it exists or not). This parameter value cannot be blank.
- An NSG is optional. If left blank, the VM NIC will not be associated with an NSG. In this case, I suggest that the subnet where the VM will be deployed has an NSG so that the VM inherits its subnet's NSG protection.
- The number of data disks must be between 1 and 800. Negative numbers are not allowed. Zero is also not allowed due to a current limitation in the ARM template language: see https://docs.microsoft.com/azure/azure-resource-manager/resource-group-create-multiple#resource-iteration

__Deployment modalities:__
1. Powershell: use the deploy.ps1 in this folder, which deploys from both azuredeploy.json and azuredeploy.parameters.json. Provide values for the parameters in azuredeploy.parameters.json and run it from a Powershell prompt. For more info, see https://docs.microsoft.com/azure/azure-resource-manager/resource-group-template-deploy
2. From Azure portal: use the "Deploy to Azure" button below. Note that this does not use the azuredeploy.parameters.json file; you will need to enter all parameter values in the Azure portal.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fplzm%2Fazure%2Fmaster%2Farm%2FVMWithDSC%2Fazuredeploy.json" target="_blank" rel="noopener">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>