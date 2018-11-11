# Azure Oracle Deployment

## PLEASE NOTE

Summary disclaimer for this entire repo: https://github.com/plzm/azure. By using anything in this repo in any way, you agree to that disclaimer.

## Summary

This repo contains Azure Resource Manager (ARM) templates to create:

- VNet, subnets, and Network Security Groups
- Storage account for Linux VM storage mount point
- Bastion host virtual machine (VM)
- Oracle Enterprise Linux (OEL) VMs

The bastion and OEL VMs also get the Azure Blob Fuse driver installed, and an Azure storage location is mounted on the VMs' file systems.

The OEL VMs are deployed to multiple Availability Zones within the specified Azure region.

The OEL VMs do not have Oracle database software installed or configured. That work is outside the scope of this deployment.

The deployment is split into distinct templates for more flexibility, e.g. to use existing network or storage resources instead of creating new ones.

## References

- Azure ARM template Reference for VMs: https://docs.microsoft.com/en-us/azure/templates/microsoft.compute/virtualmachines

- Azure Linux VM sizes: https://docs.microsoft.com/azure/virtual-machines/linux/sizes
- Azure Linux VM premium storage: https://docs.microsoft.com/azure/virtual-machines/linux/premium-storage

- Azure Blob Fuse Driver
- https://github.com/Azure/azure-storage-fuse/wiki/1.-Installation
- https://github.com/Azure/azure-storage-fuse/wiki/2.-Configuring-and-Running

- Oracle solutions on Azure: https://docs.microsoft.com/azure/virtual-machines/workloads/oracle/oracle-considerations
- Create Oracle database in Azure VM: https://docs.microsoft.com/azure/virtual-machines/workloads/oracle/oracle-database-quick-create
- Configure Oracle ASM: https://docs.microsoft.com/azure/virtual-machines/workloads/oracle/configure-oracle-asm
- Implement Oracle Data Guard on an Azure VM: https://docs.microsoft.com/azure/virtual-machines/workloads/oracle/configure-oracle-dataguard

## Pre-Requisites

1. A valid Azure subscription with sufficient resources to spin up VMs, premium storage managed disks, etc.
2. Owner or Contributor access to the Azure subscription, or at least to the resource group(s) to be used with this deployment

## Steps

1. Clone this repo.
2. Open the root folder of this repo in Visual Studio Code (VS Code) or another Powershell IDE with debug/step-through capability
3. Open globals.ps1. Fill in appropriate values for all variables.
4. Open main.deploy.ps1. Set whether you want VNet/Subnets/NSGs and Storage deploys to happen (set these to $false to use existing network and storage resources).
5. Note the following points for globals.ps1:
   * Use short Azure region names where location is needed. Example: centralus, eastus, westus, etc. (see https://azure.microsoft.com/regions/ or use CLI command:\
```az account list-locations -o table```
6. After preparing globals.ps1, I recommend stepping through main.deploy.ps1 in the VS Code Powershell debugger so that you can fix any problems found before completing automation.

main.deploy.ps1 is the main controller script for this deployment. However, the various *.deploy.ps1 scripts can be run independently.