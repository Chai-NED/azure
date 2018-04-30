# Assumptions
# 1. The resource group referred to by $eventGridTopicResourceGroup already exists (though eventGrid.deploy.ps1 will create it if not)
# 2. The Azure Function referred to by $functionEndpoint already exists, and has an Event Grid event trigger
# 3. The Azure Event Hub (Namespace and actual event hub in the namespace) already exists

# Notes
# The event grid topic to be created can be in a different resource group than the Azure function as well as the event hub. This is consistent with a multi-use utility resource group pattern.

# This script creates an Event Grid topic. It then creates subscriptions for both an Azure function (see note 2 above) as well as an Azure event hub. This is to illustrate both kinds of Event Grid subscribers. Clearly, you will need to implement what happens when those subscribers receive Event Grid events (e.g. write the events to some storage... do processing on the event like calling an ML model in a Stream Analytics job to score the event... etc.)

param(
    [string]
    $subscriptionId = '',

    [string]
    $eventGridTopicName = '',

    [string]
    $eventGridTopicResourceGroup = '',

    [string]
    $eventGridTopicLocation = '',

    [string]
    $functionSubscriptionName = 'HandleEvents-AzureFunction',

    [string]
    $functionEndpoint = '',

    [string]
    $eventHubSubscriptionName = 'HandleEvents-AzureEventHub',

    [string]
    $eventHubResourceGroup = '',

    [string]
    $eventHubNamespace = '',

    [string]
    $eventHubName = ''
)

# sign in
Write-Host "Logging in...";
Login-AzureRmAccount;

# Select Azure subscription
Write-Host "Selecting subscription '$subscriptionId'";
Select-AzureRmSubscription -SubscriptionID $subscriptionId;


# Deploy new Event Grid Topic
New-AzureRmEventGridTopic -ResourceGroupName $eventGridTopicResourceGroup -Name $eventGridTopicName -Location $eventGridTopicLocation


# Subscribe an Azure Function to the Event Grid topic - note there is no dependency on any event SOURCE here
New-AzureRmEventGridSubscription `
    -ResourceGroupName $eventGridResourceGroupName `
    -TopicName $eventGridTopicName `
    -Endpoint $functionEndpoint `
    -EventSubscriptionName $functionSubscriptionName `
    -EndpointType webhook


# Subscribe an Azure Event Hub to the Event Grid topic - note there is no dependency on any event SOURCE here
# Get the event hub's resource ID from the Namespace plus standard suffix and event hub name
$eventHubNamespace = Get-AzureRmEventHubNamespace -ResourceGroupName $eventHubResourceGroup -Name $eventHubNamespace
$eventHubEndpoint = ($eventHubNamespace.Id + '/eventhubs/' + $eventHubName)

New-AzureRmEventGridSubscription `
    -ResourceGroupName $eventGridResourceGroupName `
    -TopicName $eventGridTopicName `
    -Endpoint $eventHubEndpoint `
    -EventSubscriptionName $eventHubSubscriptionName `
    -EndpointType eventhub
