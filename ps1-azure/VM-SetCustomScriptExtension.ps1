# ##############################
# Purpose: Apply script extension to Azure VM and run a script
#
# Author: Patrick El-Azem
#
# See https://docs.microsoft.com/powershell/module/azurerm.compute/set-azurermvmcustomscriptextension
# This can either run a script at a URI (which I do here) or can get a script from Azure storage. See the doc link for details.
#
# The custom script extension runs under NTAUTHORITY\SYSTEM but does not have admin privileges. That's why RunPS1AsAdmin.ps1 is called here.
# See https://azure.microsoft.com/blog/automating-sql-server-vm-configuration-using-custom-script-extension/
# You can get my RunPS1AsAdmin.ps1 here: https://github.com/plzm/azure/ps1-general/
#
# NOTE for the $Run parameter. The custom script extension will run from its install folder at c:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\1.9\Downloads\0\ (your values may differ for version and download folder index)
# HOWEVER! Your scripts may have been downloaded into a subfolder of this downloads folder. $Run will need to include that subfolder name as a relative path.
# For example: $Run = 'ps1-general/RunPS1AsAdmin.ps1'
#
# This script may emit an error message. That happens sometimes even though the operation succeeded. If you get an error message... first check whether what you tried to do actually did succeed!
# Reviewing the custom script extension's logs on the 
# ##############################

# Arguments with defaults
param
(
    [string]$Location = '',
    [string]$ResourceGroupName = '',
    [string]$VMName = '',
    [string]$RunAsFileUri = '{Your URL}/RunPS1AsAdmin.ps1',
    [string]$ScriptFileUri = '',	# Actual PS1 file to run URI
    [string]$Run = 'RunPS1AsAdmin.ps1',		# If this script fails, check whether the PS1 files are downloaded into a subfolder on target VM and add the relative folder path here
    [string]$Script = '',	# Actual PS1 script file for RunPS1AsAdmin to call
    [string]$ExtensionName = 'VMExtension',		# Your descriptive name for this extension deployment
    [string]$VMAdminUserName = '',
    [SecureString]$VMAdminPassword = ''
)

Remove-AzureRmVMCustomScriptExtension -Name $ExtensionName -ResourceGroupName $ResourceGroupName -VMName $VMName -Force

Set-AzureRmVMCustomScriptExtension `
    -Location $Location `
    -ResourceGroupName $ResourceGroupName `
    -VMName $VMName `
    -FileUri $RunAsFileUri, $ScriptFileUri `
    -Run $Run `
    -Argument (' -AdminAccountName "' + $VMAdminUserName + '" -AdminPassword "' + $VMAdminPassword + '" -ScriptFileName "' + $Script + '" ') `
    -Name $ExtensionName
    