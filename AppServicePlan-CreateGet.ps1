# ##############################
# Purpose: Create an app service plan
#
# Author: Patrick El-Azem
# ##############################

# Arguments with defaults
param
(
    [string]$ResourceGroupName = '',
    [string]$Location = '',
    [string]$AppServicePlanName = '',
    [string]$Tier = 'Standard',
    [int]$NumberOfWorkers = 2,
    [string]$WorkerSize = 'Medium'
)

# ##########
# Check if ASP exists already and if not, create and get it
try
{
    $asp = Get-AzureRmAppServicePlan -Name $AppServicePlanName -ResourceGroupName $ResourceGroupName -ErrorAction Stop
    Write-Host('Found existing app service plan: ' + $AppServicePlanName)
}
catch
{
    Write-Host('App service plan ' + $AppServicePlanName + ': not found!')
    Write-Host('App service plan ' + $AppServicePlanName + ': creating...')

    $asp = New-AzureRmAppServicePlan `
        -ResourceGroupName $ResourceGroupName `
        -Location $Location `
        -Name $AppServicePlanName `
        -Tier $Tier `
        -NumberOfWorkers $NumberOfWorkers `
        -WorkerSize $WorkerSize
    
    Write-Host('App service plan ' + $AppServicePlanName + ': created.')
}
# ##########

return $asp