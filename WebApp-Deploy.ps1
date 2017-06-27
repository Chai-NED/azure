# ##############################
# Purpose: Create a new RG, SA, ASP, and web app
#
# Author: Patrick El-Azem
## ##############################

# Arguments with defaults
param
(
    [string]$SubscriptionId = '',
    [string]$ResourceGroupName = '',
    [string]$Location = 'East US',
    [string]$StorageAccountName = '',
    [string]$StorageAccountType = 'Standard_LRS',
    [string]$StorageContainerNameForDiagnostics = 'logs',
    [string]$AppServicePlanName = '',
    [string]$AppServicePlanTier = 'Standard',
    [string]$AppServicePlanWorkerSize = 'Medium',
    [int]$AppServicePlanNumOfWorkers = 2,
    [string]$WebAppName = '',
    [bool]$DetailedErrorLoggingEnabled = $true,
    [bool]$HttpLoggingEnabled = $true,
    [bool]$RequestTracingEnabled = $true,
    [string]$NetFrameworkVersion = 'v4.6',
    [string]$PHPVersion = 'Off',
    [bool]$Use32BitWorkerProcess = $false,
    [bool]$WebSocketsEnabled = $false,
    [bool]$ClientAffinityEnabled = $false,
    [string[]]$CustomDomains = @('sample.azurewebsites.net'),
    [string[]]$DefaultDocuments = @("default.aspx", "index.html"),
    [bool]$AlwaysOn = $false,
    [string]$TrafficManagerProfileName = 'tm1',
    [string]$TrafficManagerMonitorPath = '/health.aspx',
    [int]$TrafficManagerMonitorPort = 80,
    [string]$TrafficManagerMonitorProtocol = 'HTTP',
    [string]$TrafficManagerRelativeDnsName = '',
    [string]$TrafficManagerRoutingMethod = 'Performance',
    [int]$TrafficManagerTtl = 30,
    [string]$TrafficManagerEndpointName = ''
)

# Set default subscription
Set-AzureRmContext -SubscriptionId $SubscriptionId

#Variables
$WebAppResourceType = 'microsoft.web/sites'
$WebAppPropertiesObject = @{"siteConfig" = @{"AlwaysOn" = $AlwaysOn}}


# Resource group
$rg = .\ResourceGroup-CreateGet.ps1 -ResourceGroupName $ResourceGroupName -Location $Location
$rg

# Storage account and diagnostic container
$sa = .\StorageAccount-CreateGet.ps1 -ResourceGroupName $ResourceGroupName -Location $Location -StorageAccountName $StorageAccountName -StorageAccountType $StorageAccountType
Set-AzureRmCurrentStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
New-AzureStorageContainer $StorageContainerNameForDiagnostics
$sa

# App service plan
$asp = .\AppServicePlan-CreateGet.ps1 -ResourceGroupName $ResourceGroupName -Location $Location -AppServicePlanName $AppServicePlanName -Tier $AppServicePlanTier -WorkerSize $AppServicePlanWorkerSize -NumberOfWorkers $AppServicePlanNumOfWorkers
$asp

# Web App
$webapp = .\WebApp-CreateGet.ps1 -ResourceGroupName $ResourceGroupName -Location $Location -AppServicePlanName $AppServicePlanName -WebAppName $WebAppName
$webapp

# Web App additional settings
# Ensure CNAME record is created first
Set-AzureRmWebApp `
    -ResourceGroupName $ResourceGroupName `
    -Name $WebAppName `
    -AppServicePlan $AppServicePlanName `
    -HostNames $CustomDomains `
    -DetailedErrorLoggingEnabled $DetailedErrorLoggingEnabled `
    -HttpLoggingEnabled $HttpLoggingEnabled `
    -RequestTracingEnabled $RequestTracingEnabled `
    -NetFrameworkVersion $NetFrameworkVersion `
    -PhpVersion $PHPVersion `
    -Use32BitWorkerProcess $Use32BitWorkerProcess `
    -WebSocketsEnabled $WebSocketsEnabled `
    -DefaultDocuments $DefaultDocuments

$webAppResource = Get-AzureRmResource -ResourceType $WebAppResourceType -ResourceGroupName $ResourceGroupName -ResourceName $WebAppName
$webAppResource.Properties.ClientAffinityEnabled = $ClientAffinityEnabled
$webAppResource | Set-AzureRmResource -PropertyObject $WebAppPropertiesObject -Force


New-AzureRmAutoscaleProfile
New-AzureRmAutoscaleRule




New-AzureRmTrafficManagerProfile `
    -ResourceGroupName $ResourceGroupName `
    -Name $TrafficManagerProfileName `
    -MonitorPath $TrafficManagerMonitorPath `
    -MonitorPort $TrafficManagerMonitorPort `
    -MonitorProtocol $TrafficManagerMonitorProtocol `
    -RelativeDnsName $TrafficManagerRelativeDnsName `
    -TrafficRoutingMethod $TrafficManagerRoutingMethod `
    -Ttl $TrafficManagerTtl `
    -ProfileStatus Enabled


New-AzureRmTrafficManagerEndpoint `
    -ResourceGroupName $ResourceGroupName `
    -Name $TrafficManagerEndpointName `
    -ProfileName $TrafficManagerProfileName `
    -Type 'AzureEndpoints' `
    -EndpointStatus 'Enabled' `
    -TargetResourceId (Get-AzureRmResource -ResourceGroupName $ResourceGroupName -ResourceName $WebAppName).ResourceId
