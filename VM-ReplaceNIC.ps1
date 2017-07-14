# Arguments with defaults
param
(
    [string]$ResourceGroupName = '',
    [string]$VMName = '',
    [string]$NSGName = '',
    [string]$NICNameInitial = '',
    [string]$NICNameNew = '',
    [string]$PIPNameNew = ''
)

$vm = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $VMName

$nicInitial = Get-AzureRmNetworkInterface -ResourceGroupName $ResourceGroupName -Name $NICNameInitial

Remove-AzureRmVMNetworkInterface -VM $vm -NetworkInterfaceIDs $nicInitial.Id
Remove-AzureRmNetworkInterface -ResourceGroupName $ResourceGroupName -Name $NICNameInitial -Force

$nsg = Get-AzureRmNetworkSecurityGroup  -ResourceGroupName $ResourceGroupName -Name $NSGName
$pipNew = Get-AzureRmPublicIpAddress -ResourceGroupName $ResourceGroupName -Name $PIPNameNew
$nicNew = Get-AzureRmNetworkInterface -ResourceGroupName $ResourceGroupName -Name $NICNameNew
$nicNew.IpConfigurations[0].PublicIpAddress = $pipNew

$nicNew.NetworkSecurityGroup = $nsg

Set-AzureRmNetworkInterface -NetworkInterface $nicNew

Add-AzureRmVMNetworkInterface -VM $vm -NetworkInterface $nicNew

Update-AzureRmVM -ResourceGroupName $ResourceGroupName -VM $vm