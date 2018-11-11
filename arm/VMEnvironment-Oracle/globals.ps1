$global:DeploymentName = "OracleEnvironment"

$global:SubscriptionId = ""
$global:ResourceGroupNameVMs = ""
$global:AzureRegion = "centralus"

# General
$global:SourceIpAddressToAllow = ""		# External IP address of your location - this is so network security rules can be created allowing you access. You can find this using https://bing.com/search?q=what+is+my+ip+address

# SSH Public Key
# Provide only the public key value - no "ssh-rsa" prefix or username suffix. The deployment script handles those pieces.
$global:SSHPublicKeyValue = ""
# Do not alter the next line
$global:SSHPublicKey = "ssh-rsa " + $SSHPublicKeyValue

# Network: VNet, Subnets, NSGs
$global:ResourceGroupNameNetwork = $ResourceGroupNameVMs	# If you have existing, or want to deploy, network resources in a different resource group than the VMs, specify that network resource group name here
$global:VNetName = "datavnet"
$global:VNetAddressSpace = "172.16.0.0/16"
$global:SubnetNamePublic = "bastion"
$global:SubnetAddressSpacePublic = "172.16.1.0/24"
$global:SubnetNamePrivate1 = "oracle1"
$global:SubnetAddressSpacePrivate1 = "172.16.2.0/24"
$global:SubnetNamePrivate2 = "oracle2"
$global:SubnetAddressSpacePrivate2 = "172.16.3.0/24"
$global:NSGNamePublic = "bastion"
$global:NSGNamePrivate1 = "oracle1"
$global:NSGNamePrivate2 = "oracle2"

# Storage
$global:StorageAccountName = ""		# Storage account for the container that Linux VMs will mount.
$global:ResourceGroupNameStorage = $ResourceGroupNameVMs		# If you have existing, or want to deploy, storage resources in a different resource group than the VMs, specify that storage resource group name here
$global:LinuxMountPoint = "/mnt/azure"
$global:AzureStorageContainerName = "software"
$global:AzureStorageScriptsFolder = "scripts"
$global:ShellScriptFileName = "helloworld.sh"
$global:ShellScriptToUploadLocalPath = ".\BashScripts\" + $ShellScriptFileName
$global:ShellScriptToUploadAzurePath = $AzureStorageScriptsFolder + "/" + $ShellScriptFileName

# Bastion VM
$global:BastionVMSize = "Standard_DS3_v2"
$global:BastionVMAvailabilitySetName = ($ResourceGroupNameVMs + "-bastionavset")
$global:BastionVMName = ($ResourceGroupNameVMs + "-bastionvm1")
$global:BastionVMAdminUsername = "bastionadmin"
$global:BastionVMSSHKeyData = ConvertTo-SecureString -String ($SSHPublicKey + " " + $BastionVMAdminUsername) -AsPlainText -Force

# OEL VMs
$global:ServerVMSize = "Standard_E16s_v3"
$global:ServerVMAdminUsername = "oraadmin"
$global:ServerVMSSHKeyData = ConvertTo-SecureString -String ($SSHPublicKey + " " + $ServerVMAdminUsername) -AsPlainText -Force
$global:ServerVMDataDiskCountGroup1 = 16
$global:ServerVMDataDiskSizeGBGroup1 = 1023
$global:ServerVMDataDiskCountGroup2 = 4
$global:ServerVMDataDiskSizeGBGroup2 = 150

# Availability zones for server VMs
$global:ServerAZ1 = 1
$global:ServerAZ2 = 2

# Server Instance Names
$global:ServerNameAZ1VM1 = ($ResourceGroupNameVMs + "-oraaz1vm1")
$global:ServerNameAZ1VM2 = ($ResourceGroupNameVMs + "-oraaz1vm2")
$global:ServerNameAZ2VM1 = ($ResourceGroupNameVMs + "-oraaz2vm1")
$global:ServerNameAZ2VM2 = ($ResourceGroupNameVMs + "-oraaz2vm2")
