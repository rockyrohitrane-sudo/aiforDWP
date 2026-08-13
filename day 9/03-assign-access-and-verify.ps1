param(
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId = "31f0afb7-c415-4ea4-95ea-514736714108",

    [Parameter(Mandatory = $false)]
    [string]$ResourceGroup = "dwpai-lab-rg",

    [Parameter(Mandatory = $false)]
    [string]$AppGroupName = "POOL-FIN-01-DAG",

    [Parameter(Mandatory = $false)]
    [string]$VmName = "finavdsh-0",

    [Parameter(Mandatory = $false)]
    [string]$UserUpn = "p52@zippyops.in"
)

$ErrorActionPreference = "Stop"

az account set --subscription $SubscriptionId | Out-Null

$appGroupId = az desktopvirtualization applicationgroup show --resource-group $ResourceGroup --name $AppGroupName --query id --output tsv
$vmId = az vm show --resource-group $ResourceGroup --name $VmName --query id --output tsv

Write-Host "Assigning Desktop Virtualization User on app group..."
az role assignment create --assignee $UserUpn --role "Desktop Virtualization User" --scope $appGroupId --output table

Write-Host "Assigning Virtual Machine User Login on VM..."
az role assignment create --assignee $UserUpn --role "Virtual Machine User Login" --scope $vmId --output table

Write-Host "Verifying role assignments..."
az role assignment list --assignee $UserUpn --scope $appGroupId --output table
az role assignment list --assignee $UserUpn --scope $vmId --output table

Write-Host "Current deployment and extension status..."
az deployment group show --resource-group $ResourceGroup --name avd-sh-add-01 --query "{state:properties.provisioningState,timestamp:properties.timestamp}" --output json
az vm get-instance-view --resource-group $ResourceGroup --name $VmName --output table
az vm extension list --resource-group $ResourceGroup --vm-name $VmName --output table

Write-Host "Current registered session hosts (if any):"
az resource list --resource-group $ResourceGroup --resource-type Microsoft.DesktopVirtualization/hostpools/sessionhosts --output table
