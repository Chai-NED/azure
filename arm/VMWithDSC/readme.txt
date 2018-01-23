This folder contains an ARM template to deploy a non-trivial Windows VM to Azure.

Pre-requisites:
- Azure subscription (duh)
- Existing resource group(s). You can use the same resource group (RG)for all resources, or split into a RG each for VM, network artifacts, and diagnostic storage.
-- Note you can let the deploy.ps1 script create the resource group for you, but since you have the opportunity to specify separate RGs for VM, network, diagnostics, just pre-create it/them.
- Existing VNet, subnet, and NSG. Can be in the same RG as VM or in different RG, hence ability to specify separate RGs for VM, network stuff, and diagnostics.
- Existing standard storage account for diagnostics. Again, can be in same RG as VM or in its own RG, hence ability to specify it separately.

Steps:
1. Edit the templates.json file and provide appropriate values.
2. From a Powershell prompt, run .\deploy.ps1 and specify appropriate parameters.
3. Wait.

DSC info
https://raw.githubusercontent.com/plzm/azure/master/dsc/IISNet.ps1
