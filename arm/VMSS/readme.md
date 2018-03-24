This folder contains an ARM template to deploy an Azure Virtual Machine Scale Set (VMSS).

The VMs are Windows Server 2016, Datacenter, latest edition. The following extensions will be installed on each VMSS instance VM:
- Desired State Configuration (DSC), which in this template runs a configuration to install Internet Information Server (IIS), Application Server, and ASP.NET 4.6 features
- Microsoft Anti-Malware (Windows Defender), configured for a weekly quick scan every Saturday at 2AM
- Octopus tentacle
- A custom script which runs a Powershell script that downloads an installer and runs it. This template installs the .NET Core 2.0.6 Runtime, but substitute any EXE/MSI needed.

Full VM diagnostic logs will be sent from each VMSS instance VM to a specified storage account. From there, the VM diagnostic logs can be read as needed (e.g. in Microsoft OMS).

Full diagnostics are also activated for other VMSS components: the load balancer, the load balancer's public IP, as well as the network security group (NSG) that will protect each VMSS instance.

This template assumes that you have an existing Azure virtual network (VNet) and subnet into which you will deploy.

The template has links to DSC and script files in a public Azure storage acccount (see azuredeploy.parameters.json, _artifactLocation and related parameters). Those artifacts are public. To substitute your own DSC and script files, prepare them at URLs that are resolvable in your Azure environment.

To use this template:
1. Clone this repo (or clone a fork of this repo) and navigate to this folder (/arm/VMSS)
2. Edit deploy.ps1. Substitute appropriate default values for the parameters, including your Azure subscription ID and the resource group name and location to which you will deploy.
3. Edit azuredeploy.parameters.json. Provide appropriate values for all the parameters (many defaults are provided). Consult azuredeploy.json for descriptions for parameters.
4. Open a Powershell prompt in this folder.
5. Run deploy.ps1. If you did not provide parameter defaults in step 2, add them at the command line. For example, .\deploy.ps1 -SubscriptionId 'YOUR SUBSCRIPTION ID'

The deployment will take 15-25 minutes to complete.

__Deployment modalities:__
1. Powershell: use the deploy.ps1 in this folder, which deploys from both azuredeploy.json and azuredeploy.parameters.json. See https://docs.microsoft.com/azure/azure-resource-manager/resource-group-template-deploy
2. From Azure portal: use the "Deploy to Azure" button below. Note that this does not use the azuredeploy.parameters.json file; you will need to enter all parameter values in the Azure portal.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fplzm%2Fazure%2Fmaster%2Farm%2FVMSS%2Fazuredeploy.json" target="_blank" rel="noopener">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>