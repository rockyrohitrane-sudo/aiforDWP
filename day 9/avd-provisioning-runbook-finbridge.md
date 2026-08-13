# AVD Provisioning Runbook - FinBridge (Day 9)

## Scope
This runbook documents the Azure Virtual Desktop provisioning flow executed for the FinBridge migration lab and stores reusable scripts in the same folder.

Environment:
- Subscription: `31f0afb7-c415-4ea4-95ea-514736714108`
- Resource Group: `dwpai-lab-rg`
- Region: `eastus`
- Tenant domain: `zippyops.in`
- End user: `p52@zippyops.in`

## Pre-check performed
Before provisioning, current signed-in identity and RBAC were validated.

Result:
- Signed in principal: `traininguser72@zippyops.in`
- Role at subscription scope: `Owner`
- Role assignment write permission: available (role assignment operations succeeded)

## Artifacts created in Day 9
- `01-create-avd-control-plane.ps1`
- `02-deploy-avd-session-host.ps1`
- `03-assign-access-and-verify.ps1`

## Provisioning sequence followed

### 1) Create AVD control plane
Script: `01-create-avd-control-plane.ps1`

Creates:
- Host pool: `POOL-FIN-01`
  - Type: `Pooled`
  - Load balancer: `BreadthFirst`
  - Max sessions: `5`
  - Custom RDP: `targetisaadjoined:i:1;`
- Workspace: `FinBridge-Workspace`
- Desktop app group: `POOL-FIN-01-DAG`
- Registers app group to workspace

Validation done:
- Host pool properties confirmed (pool type, LB type, max session, custom RDP).
- Workspace and app group mapping confirmed.

### 2) Deploy one Entra-joined session host VM
Script: `02-deploy-avd-session-host.ps1`

Method used:
- Generated host pool registration token.
- Deployed from Microsoft AVD ARM template:
  - `https://raw.githubusercontent.com/Azure/RDS-Templates/master/ARM-wvd-templates/AddVirtualMachinesToHostPool/AddVirtualMachinesTemplate.json`

VM configuration submitted:
- VM name prefix: `finavdsh`
- Count: `1`
- Size: `Standard_B2ms`
- Image: `MicrosoftWindowsDesktop:windows-11:win11-24h2-avd:latest`
- Security: `TrustedLaunch`
- Secure Boot: `true`
- vTPM: `true`
- Join type: `aadJoin=true` (Entra join path)
- Subnet: `dwp-p52-winSubnet` in `dwp-p52-winVNET`
- NSG attached: `dwp-p52-winNSG`

Validation done:
- VM resource exists as `finavdsh-0`.
- VM shows expected image SKU and trusted launch settings.

### 3) Assign user access for AVD and VM sign-in
Script: `03-assign-access-and-verify.ps1`

Role assignments completed:
- `Desktop Virtualization User` at app group scope:
  - scope: `.../applicationgroups/POOL-FIN-01-DAG`
- `Virtual Machine User Login` at VM scope:
  - scope: `.../virtualMachines/finavdsh-0`

Validation done:
- Role assignment create commands returned success.
- Role assignment list commands show both assignments for `p52@zippyops.in`.

## Current state observed in this run
At last verification during execution:
- Host pool/workspace/app group: created and linked.
- VM: running, provisioning state remained `Updating`.
- Extension: `Microsoft.PowerShell.DSC` remained in `Creating`.
- Session host resource under `Microsoft.DesktopVirtualization/hostpools/sessionhosts`: not yet materialized at that check point.

This means AVD desktop connection readiness depends on the extension and registration path finishing successfully.

## How to execute from this folder
From `day 9`:

```powershell
# 1. Control plane
.\01-create-avd-control-plane.ps1

# 2. Session host deployment
.\02-deploy-avd-session-host.ps1

# 3. Access assignment and verification
.\03-assign-access-and-verify.ps1
```

## Post-deploy verification checklist
Use after script execution:

1. Confirm deployment state:
```powershell
az deployment group show --resource-group dwpai-lab-rg --name avd-sh-add-01 --query properties.provisioningState -o tsv
```

2. Confirm VM and extension health:
```powershell
az vm get-instance-view --resource-group dwpai-lab-rg --name finavdsh-0 -o table
az vm extension list --resource-group dwpai-lab-rg --vm-name finavdsh-0 -o table
```

3. Confirm session host object appears:
```powershell
az resource list --resource-group dwpai-lab-rg --resource-type Microsoft.DesktopVirtualization/hostpools/sessionhosts -o table
```

4. Confirm app group access:
```powershell
az role assignment list --assignee p52@zippyops.in --scope /subscriptions/31f0afb7-c415-4ea4-95ea-514736714108/resourcegroups/dwpai-lab-rg/providers/Microsoft.DesktopVirtualization/applicationgroups/POOL-FIN-01-DAG -o table
```

## Connection notes
- AVD client path:
  - Sign in with `p52@zippyops.in`.
  - Subscribe to workspace `FinBridge-Workspace`.
  - Launch the published desktop from `POOL-FIN-01-DAG`.
- Direct VM sign-in path:
  - Requires network path to VM and uses `Virtual Machine User Login` role already assigned.

## Notes about scripts
No pre-existing scripts were found in workspace for this provisioning. The scripts in this folder were created from the executed command flow and saved directly under `day 9`.