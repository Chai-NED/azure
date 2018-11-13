$global:DeploymentName = "LinuxEnvironment-MultiRegion"

$global:SubscriptionId = ""

$global:AzureRegionBastion = "centralus"
$global:AzureRegionCluster1 = "eastus"
$global:AzureRegionCluster2 = "centralus"
$global:AzureRegionCluster3 = "westus"

$global:ResourceGroupNameVMsBastion = "srvenv-bastion"
$global:ResourceGroupNameVMsCluster1 = "srvenv-cluster1"
$global:ResourceGroupNameVMsCluster2 = "srvenv-cluster2"
$global:ResourceGroupNameVMsCluster3 = "srvenv-cluster3"

# General
$global:SourceIpAddressToAllow = ""		# External IP address of your location - this is so network security rules can be created allowing you access. You can find this using https://bing.com/search?q=what+is+my+ip+address

# SSH Public Key
# Provide only the public key value - no "ssh-rsa" prefix or username suffix. The deployment script handles those pieces.
$global:SSHPublicKeyValue = ""
# Do not alter the next line
$global:SSHPublicKey = "ssh-rsa " + $SSHPublicKeyValue

# Network: VNet, Subnets, NSGs
$global:ResourceGroupNameNetworkBastion = $ResourceGroupNameVMsBastion
$global:VNetNameBastion = "vnet-bastion"
$global:VNetAddressSpaceBastion = "10.1.0.0/16"
$global:SubnetNameBastion = "subnet-bastion"
$global:SubnetAddressSpaceBastion = "10.1.1.0/24"
$global:NSGNameBastion = "nsg-bastion"

$global:ResourceGroupNameNetworkCluster1 = $ResourceGroupNameVMsCluster1
$global:VNetNameCluster1 = "vnet-cluster1"
$global:VNetAddressSpaceCluster1 = "10.11.0.0/16"
$global:SubnetNameCluster1 = "subnet-cluster1"
$global:SubnetAddressSpaceCluster1 = "10.11.1.0/24"
$global:NSGNameCluster1 = "nsg-cluster1"

$global:ResourceGroupNameNetworkCluster2 = $ResourceGroupNameVMsCluster2
$global:VNetNameCluster2 = "vnet-cluster2"
$global:VNetAddressSpaceCluster2 = "10.12.0.0/16"
$global:SubnetNameCluster2 = "subnet-cluster2"
$global:SubnetAddressSpaceCluster2 = "10.12.1.0/24"
$global:NSGNameCluster2 = "nsg-cluster2"

$global:ResourceGroupNameNetworkCluster3 = $ResourceGroupNameVMsCluster3
$global:VNetNameCluster3 = "vnet-cluster3"
$global:VNetAddressSpaceCluster3 = "10.13.0.0/16"
$global:SubnetNameCluster3 = "subnet-cluster3"
$global:SubnetAddressSpaceCluster3 = "10.13.1.0/24"
$global:NSGNameCluster3 = "nsg-cluster3"

# Storage
$global:StorageAccountNameBastion = ""
$global:ResourceGroupNameStorageBastion = $ResourceGroupNameVMsBastion

$global:StorageAccountNameCluster1 = ""
$global:ResourceGroupNameStorageCluster1 = $ResourceGroupNameVMsCluster1

$global:StorageAccountNameCluster2 = ""
$global:ResourceGroupNameStorageCluster2 = $ResourceGroupNameVMsCluster2

$global:StorageAccountNameCluster3 = ""
$global:ResourceGroupNameStorageCluster3 = $ResourceGroupNameVMsCluster3

$global:LinuxMountPoint = "/mnt/azure"
$global:AzureStorageContainerName = "software"
$global:AzureStorageScriptsFolder = "scripts"
$global:ShellScriptFileName = "helloworld.sh"
$global:ShellScriptToUploadLocalPath = ".\bash_scripts\" + $ShellScriptFileName
$global:ShellScriptToUploadAzurePath = $AzureStorageScriptsFolder + "/" + $ShellScriptFileName

# Bastion VM
$global:BastionVMSize = "Standard_DS3_v2"
$global:BastionVMAvailabilitySetName = ($ResourceGroupNameVMsBastion + "-bastionavset")
$global:BastionVMName = ($ResourceGroupNameVMsBastion + "-bastionvm1")
$global:BastionVMAdminUsername = "bastionadmin"
$global:BastionVMSSHKeyData = ConvertTo-SecureString -String ($SSHPublicKey + " " + $BastionVMAdminUsername) -AsPlainText -Force

# Server VMs - for a list of available sizes see https://docs.microsoft.com/en-us/azure/virtual-machines/linux/sizes or use Azure CLI command 'az vm list-sizes' with appropriate arguments.
$global:ServerVMSize = "Standard_E16s_v3"
$global:ServerVMAdminUsername = "serveradmin"
$global:ServerVMSSHKeyData = ConvertTo-SecureString -String ($SSHPublicKey + " " + $ServerVMAdminUsername) -AsPlainText -Force
$global:ServerVMDataDiskCount = 1
$global:ServerVMDataDiskSizeGB = 1023

# Server Instance Names
$VM1 = "srvvm1"
$VM2 = "srvvm2"
$VM3 = "srvvm3"

$global:VMAvailabilitySetNameCluster1 = ($ResourceGroupNameVMsCluster1 + "-serveravset")
$global:VMAvailabilitySetNameCluster2 = ($ResourceGroupNameVMsCluster1 + "-serveravset")
$global:VMAvailabilitySetNameCluster3 = ($ResourceGroupNameVMsCluster1 + "-serveravset")

$global:ServerNameC1VM1 = ($ResourceGroupNameVMsCluster1 + "-" + $VM1)
$global:ServerNameC1VM2 = ($ResourceGroupNameVMsCluster1 + "-" + $VM2)
$global:ServerNameC1VM3 = ($ResourceGroupNameVMsCluster1 + "-" + $VM3)

$global:ServerNameC2VM1 = ($ResourceGroupNameVMsCluster2 + "-" + $VM1)
$global:ServerNameC2VM2 = ($ResourceGroupNameVMsCluster2 + "-" + $VM2)
$global:ServerNameC2VM3 = ($ResourceGroupNameVMsCluster2 + "-" + $VM3)

$global:ServerNameC3VM1 = ($ResourceGroupNameVMsCluster3 + "-" + $VM1)
$global:ServerNameC3VM2 = ($ResourceGroupNameVMsCluster3 + "-" + $VM2)
$global:ServerNameC3VM3 = ($ResourceGroupNameVMsCluster3 + "-" + $VM3)
