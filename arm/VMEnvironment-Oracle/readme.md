# Azure Oracle Deployment

## Summary

This repo contains Azure Resource Manager (ARM) templates to create Oracle virtual machines, bastion host virtual machines, and associated resources (VNet, subnets, network security groups) in Azure. The Oracle virtual machines are deployed to multiple Availability Zones within the specified Azure region.

The deployment is split into distinct templates for more flexibility, e.g. to use existing network or storage resources instead of creating new ones.

PLEASE NOTE the summary disclaimer for this entire github repo: https://github.com/plzm/azure. By using anything in this entire github repo in any way, you agree to that disclaimer.

## References

- Oracle solutions on Azure: https://docs.microsoft.com/azure/virtual-machines/workloads/oracle/oracle-considerations
- Create Oracle database in Azure VM: https://docs.microsoft.com/azure/virtual-machines/workloads/oracle/oracle-database-quick-create
- Configure Oracle ASM: https://docs.microsoft.com/azure/virtual-machines/workloads/oracle/configure-oracle-asm
- Implement Oracle Data Guard on an Azure VM: https://docs.microsoft.com/azure/virtual-machines/workloads/oracle/configure-oracle-dataguard

- Azure Linux VM sizes: https://docs.microsoft.com/azure/virtual-machines/linux/sizes
- Azure Linux VM premium storage: https://docs.microsoft.com/azure/virtual-machines/linux/premium-storage
- Azure Windows VM sizes: https://docs.microsoft.com/azure/virtual-machines/linux/sizes
- Azure Windows VM premium storage: https://docs.microsoft.com/azure/virtual-machines/linux/premium-storage
- How to add a Swap File in Azure Linux VMs: https://support.microsoft.com/en-us/help/4010058/how-to-add-a-swap-file-in-linux-azure-virtual-machines
- SwingBench: http://dominicgiles.com/swingbench.html

- Azure ARM template Reference for VMs: https://docs.microsoft.com/en-us/azure/templates/microsoft.compute/virtualmachines

## Pre-Requisites

1. A valid Azure subscription with sufficient resources to spin up VMs, premium storage managed disks, etc.
2. Owner or Contributor access to the Azure subscription, or at least to the resource group(s) to be used with this deployment

## Steps

1. Clone this repo.
2. Open the root folder of this repo in Visual Studio Code (VS Code)
3. Open deploy.ps1. Fill in appropriate values for the params at the top of the file.
4. Open all the Azure Resource Manager (ARM) template parameters files (*.parameters.json) in the subfolders and fill in appropriate values in each.
   * The deploy templates (*.deploy.json) do not contain specific parameter values. You only need to edit these to change how this deployment functions.
5. Note the following points that apply to deploy.ps1 and the ARM parameter files:
   * Use short Azure region names where location is needed. Example: centralus, eastus, westus, etc. (see https://azure.microsoft.com/regions/ or use CLI command:\
```az account list-locations -o table```
   * Be consistent across files with location names, resource group names, etc. Much is pre-filled for you. Find and Replace is your friend, but don't invite that friend right away.
   * None of the named resources need to exist yet. The deploy.ps1 script will create the resource group if it does not exist yet, and the ARM templates will create the other resources.
6. Oracle VM template:
   * provide appropriate values for publisher, offer, sku, and version. The parameters file as delivered uses the latest (as of this date) Oracle 12 EE version. You can find which ones are available on Azure with this CLI command:\
```az vm image list --publisher oracle --offer Oracle-Database-Ee -o table --all```
   * provide a value for param sshKeyData that is in the single-line format:\
```ssh-rsa {your public SSH key} {your username}```
7. Once all param values are provided in deploy.ps1 and the .parameters.json files, I recommend stepping through deploy.ps1 in the VS Code Powershell debugger so that you can run the `Test-AzureRmResourceGroupDeployment` calls one by one, and address any problems found, before running the actual deployments with `New-AzureRmResourceGroupDeployment`.
8. As deploy.ps1 completes VM deployments, it will output various networking info for the newly-created VMs.
9. If you intend to install Oracle Automatic Storage Management, please SSH to each Oracle VM and proceed with the steps in the file `readme_asm_and_grid.md` also found in this repo.