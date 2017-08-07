# ##############################
# Purpose: Add alerts to an existing RM VM. This script adds some specific ones; customize as needed.
#
# Author: Patrick El-Azem
# ##############################

# Arguments with defaults
param
(
    [string]$SubscriptionId = '',
    [string]$ResourceGroupName = '',
    [string]$Location = '',
    [string]$VMName = ''
)

$resource = Get-AzureRmResource -ResourceGroupName $ResourceGroupName -ResourceName $VMName

# CPU High - >= 80% over 5 minutes
Add-AzureRmMetricAlertRule `
    -ResourceGroup $ResourceGroupName `
    -Location $Location `
    -TargetResourceId $resource.ResourceId `
    -MetricName "\Processor(_Total)\% Processor Time" `
    -Name "CPU High" `
    -Operator GreaterThanOrEqual `
    -Threshold 80 `
    -TimeAggregationOperator Average `
    -WindowSize 00:05:00

# CPU Low - >= 80% over 5 minutes
Add-AzureRmMetricAlertRule `
    -ResourceGroup $ResourceGroupName `
    -Location $Location `
    -TargetResourceId $resource.ResourceId `
    -MetricName "\Processor(_Total)\% Processor Time" `
    -Name "CPU Low" `
    -Operator LessThanOrEqual `
    -Threshold 5 `
    -TimeAggregationOperator Average `
    -WindowSize 01:00:00

# RAM High - >= 80% over 5 minutes
Add-AzureRmMetricAlertRule `
    -ResourceGroup $ResourceGroupName `
    -Location $Location `
    -TargetResourceId $resource.ResourceId `
    -MetricName "\Memory\% Committed Bytes In Use" `
    -Name "RAM High" `
    -Operator GreaterThanOrEqual `
    -Threshold 80 `
    -TimeAggregationOperator Average `
    -WindowSize 00:05:00

# RAM Low - >= 80% over 5 minutes
Add-AzureRmMetricAlertRule `
    -ResourceGroup $ResourceGroupName `
    -Location $Location `
    -TargetResourceId $resource.ResourceId `
    -MetricName "\Memory\% Committed Bytes In Use" `
    -Name "RAM Low" `
    -Operator LessThanOrEqual `
    -Threshold 5 `
    -TimeAggregationOperator Average `
    -WindowSize 01:00:00
