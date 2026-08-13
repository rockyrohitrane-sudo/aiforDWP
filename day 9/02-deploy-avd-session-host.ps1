param(
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId = "31f0afb7-c415-4ea4-95ea-514736714108",

    [Parameter(Mandatory = $false)]
    [string]$ResourceGroup = "dwpai-lab-rg",

    [Parameter(Mandatory = $false)]
    [string]$HostPoolName = "POOL-FIN-01",

    [Parameter(Mandatory = $false)]
    [string]$VmNamePrefix = "finavdsh",

    [Parameter(Mandatory = $false)]
    [string]$VmSize = "Standard_B2ms",

    [Parameter(Mandatory = $false)]
    [string]$VnetName = "dwp-p52-winVNET",

    [Parameter(Mandatory = $false)]
    [string]$SubnetName = "dwp-p52-winSubnet",

    [Parameter(Mandatory = $false)]
    [string]$NetworkResourceGroup = "dwpai-lab-rg",

    [Parameter(Mandatory = $false)]
    [string]$NsgResourceId = "/subscriptions/31f0afb7-c415-4ea4-95ea-514736714108/resourceGroups/dwpai-lab-rg/providers/Microsoft.Network/networkSecurityGroups/dwp-p52-winNSG",

    [Parameter(Mandatory = $false)]
    [string]$Location = "eastus",

    [Parameter(Mandatory = $false)]
    [string]$VmAdminUser = "avdadmin",

    [Parameter(Mandatory = $false)]
    [string]$DeploymentName = "avd-sh-add-01"
)

$ErrorActionPreference = "Stop"

az account set --subscription $SubscriptionId | Out-Null

Write-Host "Generating host pool registration token (4 hours)..."
$expiry = (Get-Date).ToUniversalTime().AddHours(4).ToString("yyyy-MM-ddTHH:mm:ss.fffffffZ")
az desktopvirtualization hostpool update `
    --resource-group $ResourceGroup `
    --name $HostPoolName `
    --registration-info expiration-time=$expiry registration-token-operation=Update `
    --output table

$token = az desktopvirtualization hostpool retrieve-registration-token `
    --resource-group $ResourceGroup `
    --name $HostPoolName `
    --query token --output tsv

if ([string]::IsNullOrWhiteSpace($token)) {
    throw "Failed to retrieve host pool registration token."
}

$vmAdminPassword = "P!" + [guid]::NewGuid().ToString("N") + "a9"
$templateUri = "https://raw.githubusercontent.com/Azure/RDS-Templates/master/ARM-wvd-templates/AddVirtualMachinesToHostPool/AddVirtualMachinesTemplate.json"
$paramFile = Join-Path $PSScriptRoot "02-deploy-avd-session-host.parameters.json"

Write-Host "Building ARM parameters file..."
$params = @{
    '$schema' = "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#"
    contentVersion = "1.0.0.0"
    parameters = @{
        hostpoolName = @{ value = $HostPoolName }
        hostpoolToken = @{ value = $token }
        vmResourceGroup = @{ value = $ResourceGroup }
        vmLocation = @{ value = $Location }
        vmSize = @{ value = $VmSize }
        vmInitialNumber = @{ value = 0 }
        vmNumberOfInstances = @{ value = 1 }
        vmNamePrefix = @{ value = $VmNamePrefix }
        vmImageType = @{ value = "Gallery" }
        vmGalleryImagePublisher = @{ value = "MicrosoftWindowsDesktop" }
        vmGalleryImageOffer = @{ value = "windows-11" }
        vmGalleryImageSKU = @{ value = "win11-24h2-avd" }
        vmGalleryImageVersion = @{ value = "latest" }
        vmDiskType = @{ value = "Premium_LRS" }
        existingVnetName = @{ value = $VnetName }
        existingSubnetName = @{ value = $SubnetName }
        virtualNetworkResourceGroupName = @{ value = $NetworkResourceGroup }
        createNetworkSecurityGroup = @{ value = $false }
        networkSecurityGroupId = @{ value = $NsgResourceId }
        aadJoin = @{ value = $true }
        intune = @{ value = $false }
        vmAdministratorAccountUsername = @{ value = $VmAdminUser }
        vmAdministratorAccountPassword = @{ value = $vmAdminPassword }
        systemData = @{ value = @{ aadJoinPreview = $false } }
        securityType = @{ value = "TrustedLaunch" }
        secureBoot = @{ value = $true }
        vTPM = @{ value = $true }
        bootDiagnostics = @{ value = @{ enabled = $true } }
    }
}

$params | ConvertTo-Json -Depth 8 | Set-Content -Path $paramFile -Encoding ascii

Write-Host "Deploying session host via ARM template..."
az deployment group create `
    --resource-group $ResourceGroup `
    --name $DeploymentName `
    --template-uri $templateUri `
    --parameters @$paramFile `
    --output table

Write-Host "Session host deployment submitted."
Write-Host "Temporary local admin password used during deployment (store securely if needed): $vmAdminPassword"

az vm show `
    --resource-group $ResourceGroup `
    --name ($VmNamePrefix + "-0") `
    --query "{name:name,provisioningState:provisioningState,securityType:securityProfile.securityType,secureBoot:securityProfile.uefiSettings.secureBootEnabled,vTPM:securityProfile.uefiSettings.vTpmEnabled,imageSku:storageProfile.imageReference.sku}" `
    --output table
