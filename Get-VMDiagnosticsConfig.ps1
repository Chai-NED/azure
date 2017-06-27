$ResourceGroupName = ''
$VMName = ''
$DiagXMLFilePath = '.\diagnostics.xml'

$extension = Get-AzureRmVMDiagnosticsExtension -ResourceGroupName $ResourceGroupName -VMName $VMName

$publicsettings = $extension.PublicSettings

$encodedconfig = (ConvertFrom-Json -InputObject $publicsettings).xmlCfg

$xmlconfig = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encodedconfig))

$xmlconfig | Out-File -FilePath $DiagXMLFilePath -Force
