param(
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId = "31f0afb7-c415-4ea4-95ea-514736714108",

    [Parameter(Mandatory = $false)]
    [string]$ResourceGroup = "dwpai-lab-rg",

    [Parameter(Mandatory = $false)]
    [string]$Location = "eastus",

    [Parameter(Mandatory = $false)]
    [string]$HostPoolName = "POOL-FIN-01",

    [Parameter(Mandatory = $false)]
    [string]$WorkspaceName = "FinBridge-Workspace",

    [Parameter(Mandatory = $false)]
    [string]$AppGroupName = "POOL-FIN-01-DAG"
)

$ErrorActionPreference = "Stop"

az account set --subscription $SubscriptionId | Out-Null

Write-Host "Creating host pool..."
az desktopvirtualization hostpool create `
    --resource-group $ResourceGroup `
    --name $HostPoolName `
    --location $Location `
    --host-pool-type Pooled `
    --load-balancer-type BreadthFirst `
    --preferred-app-group-type Desktop `
    --max-session-limit 5 `
    --custom-rdp-property "targetisaadjoined:i:1;" `
    --friendly-name $HostPoolName `
    --description "Pooled AVD host pool for FinBridge workplace migration" `
    --output table

$hostPoolId = az desktopvirtualization hostpool show `
    --resource-group $ResourceGroup `
    --name $HostPoolName `
    --query id --output tsv

Write-Host "Creating workspace..."
az desktopvirtualization workspace create `
    --resource-group $ResourceGroup `
    --name $WorkspaceName `
    --location $Location `
    --friendly-name $WorkspaceName `
    --description "Workspace for FinBridge AVD desktops" `
    --output table

Write-Host "Creating desktop application group..."
az desktopvirtualization applicationgroup create `
    --resource-group $ResourceGroup `
    --name $AppGroupName `
    --location $Location `
    --application-group-type Desktop `
    --host-pool-arm-path $hostPoolId `
    --friendly-name $AppGroupName `
    --description "Desktop app group for $HostPoolName" `
    --output table

$appGroupId = az desktopvirtualization applicationgroup show `
    --resource-group $ResourceGroup `
    --name $AppGroupName `
    --query id --output tsv

Write-Host "Registering application group to workspace..."
az desktopvirtualization workspace update `
    --resource-group $ResourceGroup `
    --name $WorkspaceName `
    --application-group-references $appGroupId `
    --output table

Write-Host "Verifying control plane objects..."
az desktopvirtualization hostpool show --resource-group $ResourceGroup --name $HostPoolName --query "{name:name,hostPoolType:hostPoolType,loadBalancerType:loadBalancerType,maxSessionLimit:maxSessionLimit,customRdpProperty:customRdpProperty}" --output table
az desktopvirtualization workspace show --resource-group $ResourceGroup --name $WorkspaceName --query "{name:name,applicationGroupReferences:applicationGroupReferences}" --output json
az desktopvirtualization applicationgroup show --resource-group $ResourceGroup --name $AppGroupName --query "{name:name,type:applicationGroupType,hostPoolArmPath:hostPoolArmPath}" --output table
