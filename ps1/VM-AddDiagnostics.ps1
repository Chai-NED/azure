# ##############################
# Purpose: Add diagnostics to an existing RM VM
#
# Author: Patrick El-Azem
# ##############################

# Arguments with defaults
param
(
	[string]$SubscriptionId = '',
    [string]$Location = 'East US',
	[string]$ResourceGroupNameVM = '',
	[string]$ResourceGroupNameStorageAccountDiagnostics = '',
	[string]$StorageAccountNameDiagnostics = '',
    [string]$StorageAccountSkuNameDiagnostics = 'Standard_LRS',
	[string]$VMName = '',
	[string]$DiagnosticsXMLFilePath = ((Get-Location).Path + '\VM-Diagnostics.xml')
)

$diagnosticsXMLFilePathSource = $DiagnosticsXMLFilePath
$diagnosticsXMLFilePathForVM = ((Get-Location).Path + '\VM-Diagnostics-' + $VMName + '.xml')

$tokenSubscriptionId = '###SUBSCRIPTIONID###'
$tokenResourceGroupName = '###RGNAME###'
$tokenVMName = '###VMNAME###'

$configXml = [string](Get-Content -Path $diagnosticsXMLFilePathSource)
$configXml = $configXml.Replace($tokenSubscriptionId, $SubscriptionId)
$configXMl = $configXml.Replace($tokenResourceGroupName, $ResourceGroupNameVM)
$configXMl = $configXml.Replace($tokenVMName, $VMName)

New-Item -Path $diagnosticsXMLFilePathForVM -Value $configXMl -ItemType File -Force

# Ensure diagnostics storage account exists
$sa = .\StorageAccount-CreateGet.ps1 -ResourceGroupName $ResourceGroupNameStorageAccountDiagnostics -Location $Location -StorageAccountName $StorageAccountNameDiagnostics -StorageAccountSkuName $StorageAccountSkuNameDiagnostics

# Set boot diagnostics
$vm = Get-AzureRmVm -ResourceGroupName $ResourceGroupNameVM -Name $VMName

if ($null -ne $vm)
{
    Set-AzureRmVMBootDiagnostics -Enable -ResourceGroupName $ResourceGroupNameVM -VM $vm -StorageAccountName $StorageAccountNameDiagnostics | Out-Null
}

# Set guest OS diagnostics
Set-AzureRmVMDiagnosticsExtension `
	-ResourceGroupName $ResourceGroupNameVM `
	-VMName $VMName `
	-StorageAccountName $StorageAccountNameDiagnostics `
	-DiagnosticsConfigurationPath $diagnosticsXMLFilePathForVM `
	-AutoUpgradeMinorVersion $true

Remove-Item -Path $diagnosticsXMLFilePathForVM -Force