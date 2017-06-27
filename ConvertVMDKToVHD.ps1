# ##############################
# Purpose: Convert a VMDK file to a fixed VHD for Azure VM
#
# Author: Patrick El-Azem
#
# NOTE you MUST have Microsoft Virtual Machine Converter installed. This script works with v3.1
#
# ##############################

# Arguments with defaults
param
(
    [string]$MSVMCModulePath = 'C:\Program Files\Microsoft Virtual Machine Converter\MvmcCmdlet.psd1',
    [string]$SourceVMDKFilePath = 'F:\Source\MyVM.vmdk',
    [string]$DestinationVHDFilePath = 'F:\Destination'
)


Import-Module $MSVMCModulePath

ConvertTo-MvmcVirtualHardDisk `
    -SourceLiteralPath $SourceVMDKFilePath `
    -VhdType FixedHardDisk `
    -VhdFormat vhd `
    -Destination $DestinationVHDFilePath
