# Azure Oracle Deployment

## Summary

This repo contains three Azure Resource Manager (ARM) templates to create an Oracle virtual machine and associated resources in Azure.

The deployment is split into three templates for more flexibility, e.g. to use existing network or storage resources instead of creating new ones.

## References

- Oracle solutions on Azure: https://docs.microsoft.com/azure/virtual-machines/workloads/oracle/oracle-considerations
- Create Oracle database in Azure VM: https://docs.microsoft.com/azure/virtual-machines/workloads/oracle/oracle-database-quick-create
- Configure Oracle ASM: https://docs.microsoft.com/azure/virtual-machines/workloads/oracle/configure-oracle-asm
- Implement Oracle Data Guard on an Azure VM: https://docs.microsoft.com/azure/virtual-machines/workloads/oracle/configure-oracle-dataguard

- Azure Linux VM sizes: https://docs.microsoft.com/azure/virtual-machines/linux/sizes
- Azure Linux VM premium storage: https://docs.microsoft.com/azure/virtual-machines/linux/premium-storage
- Azure Windows VM sizes: https://docs.microsoft.com/azure/virtual-machines/linux/sizes
- Azure Windows VM premium storage: https://docs.microsoft.com/azure/virtual-machines/linux/premium-storage

- SwingBench: http://dominicgiles.com/swingbench.html

## Pre-Requisites

1. A valid Azure subscription with sufficient resources to spin up VMs, premium storage managed disks, etc.
2. Owner or Contributor access to the Azure subscription, or at least to the resource group(s) to be used with this deployment

## Steps

1. Clone this repo.
2. Open the root folder of this repo in Visual Studio Code (VS Code)
3. Open deploy.ps1. Fill in appropriate values for the params in lines 3-13.
4. Open these Azure Resource Manager (ARM) template parameters files and fill in appropriate values in each.
   * Network/azuredeploy.parameters.json
   * Storage/azuredeploy.parameters.json
   * VM/azuredeploy.parameters.json
5. Note the following points that apply to deploy.ps1 and the three ARM parameter files:
   * Use short Azure region names where location is needed. Example: eastus, westus, etc. (see https://azure.microsoft.com/regions/ or use CLI command:\ ```az account list-locations -o table```
   * Be consistent across files with location names, resource group names, etc.
   * None of the named resources need to exist yet. The deploy.ps1 script will create the resource group if it does not exist yet, and the ARM templates will create the other resources.
6. Network template: this template creates an initial inbound rule, e.g. to enable SSH or RDP access from your public IP address. Please provide your public IP address (e.g. go to bing.com and search "what is my IP").
7. Storage template: this template creates a storage account which will be used for diagnostic logs by. If you prefer to use an existing storage account for diagnostics, do not run the Storage template (comment it out in deploy.ps1), and provide appropriate storage account info in VM/azuredeploy.parameters.json, lines 74-78.
8. VM template:
   * provide appropriate values for publisher, offer, sku, and version. The parameters file as delivered uses the latest (as of this date) Oracle 12 EE version. You can find which ones are available on Azure with this CLI command:\ ```az vm image list --publisher oracle --offer Oracle-Database-Ee -o table --all```
   * provide a value for param sshKeyData that is in the single-line format:\ ```ssh-rsa {your public SSH key} {your username}```
9. Once all param values are provided in deploy.ps1 and the three azuredeploy.parameters.json files, I recommend stepping through deploy.ps1 in the VS Code Powershell debugger so that you can run the `Test-AzureRmResourceGroupDeployment` calls one by one, and address any problems found, before running the actual deployments with `New-AzureRmResourceGroupDeployment`.
10. When deploy.ps1 completes, it will output the DNS hostname for the newly-created Oracle VM as well as an ssh command line to connect to the VM. Ensure that you have the SSH private key file (.ppk) available that corresponds to the public key you provided in the VM ARM parameters file.
11. If you provided a source IP in the Network ARM parameters file, you should be able to SSH to the VM right away. Otherwise - and/or if you have other network security between you and this Azure deployment - you may need to address SSH being blocked from you to Azure.