# ##############################
# Purpose: Create an RM web app
#
# Author: Patrick El-Azem
# ##############################

# Arguments with defaults
param
(
    [string]$ResourceGroupName = '',
    [string]$Location = '',
    [string]$WebAppName = '',
    [string]$AppServicePlanName = ''
)

# ##########
# Check if web app exists already and if not, create and get it
try
{
    $wa = Get-AzureRmWebApp -Name $WebAppName -ResourceGroupName $ResourceGroupName -ErrorAction Stop
    Write-Host('Found existing web app: ' + $WebAppName)
}
catch
{
    Write-Host('Web app ' + $WebAppName + ': not found!')
    Write-Host('Web app ' + $WebAppName + ': creating...')

    $wa = New-AzureRmWebApp `
        -ResourceGroupName $ResourceGroupName `
        -Location $Location `
        -Name $WebAppName `
        -AppServicePlan $AppServicePlanName
    
    Write-Host('Web app ' + $WebAppName + ': created.')
}
# ##########

return $wa