# Azure Multi-Region Linux Environment Deployment

## PLEASE NOTE

Summary disclaimer for this entire repo: https://github.com/plzm/azure. By using anything in this repo in any way, you agree to that disclaimer.

## Summary

This repo contains Azure Resource Manager (ARM) templates to create:

- VNets, subnets, and Network Security Groups. Four VNets are created; one bastion VNet and three server cluster VNets. The cluster VNets are created in three distinct Azure regions for geographic redundancy. All VNets are peered to each other to allow cross-VNet communications.
- Storage accounts for Linux VMs storage mount points. A storage account is created for each VNet (bastion and cluster), in the same region as that VNet. Each storage account is secured through encryption at rest, refusal of non-encrypted network connections, and use of Azure service endpoints to refuse connections from anywhere other than the VNets in this deployment or the allowed public IP address specified in globals.ps1 (e.g. the external public IP of your network).
- Bastion host virtual machine (VM) using Ubuntu Server 18.10
- Cluster server VMs using Ubuntu Server 18.10

The bastion and OEL VMs also get the Azure Blob Fuse driver installed, and an Azure storage location is mounted on the VMs' file systems. This deployment defaults to /mnt/azure but you can set this as needed in globals.ps1. This deployment also executes a helloworld.sh script from Azure storage during deployment, to prove that Azure storage was successfully mounted. The helloworld.sh script creates an /azure_was_here directory. Customize this as needed by providing your own .sh script to run as part of the deployment and specifying paths and file names in global.ps1.

In each VNet/region, the cluster server VMs are deployed into an Azure Availability Set for region-level HA.

Only the bastion VM is deployed with a public IP address. All cluster server VMs are deployed with private IP addresses only. All subnets (and the VMs within them) across all VNets in this deployment are protected by Azure Network Security Groups (NSGs) which are deployed with minimal rules. As part of testing and customizing this deployment, you should add suitable NSG rules and consider adding network security appliances and other security measures appropriate to your environment and requirements.

The deployment is split into distinct templates for more flexibility, e.g. to use existing network or storage resources instead of creating new ones.

![Azure Multi-Region VM Deployment Schematic](images/AzureMultiRegionVMDeployment.png?raw=true)

## References

- Azure ARM template Reference for VMs: https://docs.microsoft.com/en-us/azure/templates/microsoft.compute/virtualmachines

- Azure Linux VM sizes: https://docs.microsoft.com/azure/virtual-machines/linux/sizes
- Azure Linux VM premium storage: https://docs.microsoft.com/azure/virtual-machines/linux/premium-storage

- Azure Blob Fuse Driver
  - https://github.com/Azure/azure-storage-fuse/wiki/1.-Installation
  - https://github.com/Azure/azure-storage-fuse/wiki/2.-Configuring-and-Running

## Pre-Requisites

1. A valid Azure subscription with sufficient resources to spin up VMs, premium storage managed disks, etc.
2. Owner or Contributor access to the Azure subscription, or at least to the resource group(s) to be used with this deployment
3. A Powershell execution environment. I recommend Microsoft Visual Studio Code with at minimum the following extensions: Azure Account, Azure CLI Tools, Azure Resource Manager Tools, Azure Storage, JSON Tools, Powershell. You will also need the Azure Powershell install, which you can get at https://azure.microsoft.com/downloads/.

## Steps

1. Clone this repo. (Or fork it, if you'd consider improving this artifact and contributing back with Pull Requests!)
2. Open the root folder of this repo in Visual Studio Code (VS Code) or another Powershell IDE with debug/step-through capability
3. Open globals.ps1. Fill in appropriate values for all variables. This is the only file in this deployment where you need to provide values; everything else is driven off what is provided there.
  - Note that I use global Powershell variables so that the various .ps1 files can see the values. Due to this, you should not mingle other Powershell work into your Powershell session while working on this deployment. I have not been able to get a lesser variable scope (e.g. Script or Local) to correctly share variables among multiple .ps1 scripts. The trade-off is that this deployment is highly modular, for easier mixing/matching/customization.
4. Open main.deploy.ps1. Set whether you want VNet/Subnets/NSGs and Storage deploys to happen (set these to $false to use existing network and storage resources).
5. Note the following points for globals.ps1:
  - Use short Azure region names where location is needed. Example: centralus, eastus, westus, etc. (see https://azure.microsoft.com/regions/ or use CLI command:\
```az account list-locations -o table```
6. After preparing globals.ps1, I recommend stepping through main.deploy.ps1 in the VS Code Powershell debugger so that you can fix any problems found before completing automation.

main.deploy.ps1 is the main controller script for this deployment. However, the various *.deploy.ps1 scripts can be run independently.