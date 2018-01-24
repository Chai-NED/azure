This folder contains an ARM template to deploy a non-trivial Windows VM to Azure. The VM will have anti-malware as well as Powershell DSC, with a specific DSC script applied.

Pre-requisites:
- Azure subscription (duh)
- Existing resource group(s). You can use the same resource group (RG)for all resources, or split into a RG each for VM, network artifacts, and diagnostic storage.
-- Note you can let the deploy.ps1 script create the resource group for you, but since you have the opportunity to specify separate RGs for VM, network, diagnostics, just pre-create it/them.
- Existing VNet, subnet, and NSG. Can be in the same RG as VM or in different RG, hence ability to specify separate RGs for VM, network stuff, and diagnostics.
- Existing standard storage account for diagnostics. Again, can be in same RG as VM or in its own RG, hence ability to specify it separately.
- Upload the DSC resource(s) to an accessible URL. In my template, I'm using a publicly visible Azure storage location. Ensure that azuredeploy.parameters.json lines 75-89 match your DSC script.

Steps:
1. Edit the azuredeploy.parameters.json file and provide appropriate values.
2. From a Powershell prompt, run .\deploy.ps1 with the needed parameters.
3. Wait.
