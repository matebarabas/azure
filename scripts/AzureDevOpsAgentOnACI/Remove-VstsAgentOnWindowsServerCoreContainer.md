# Remove-VstsAgentOnWindowsServerCoreContainer.ps1

## SYNOPSIS

This script removes the selected Azure Container Instance(s).

## DESCRIPTION

This script removes the selected Azure Container Instance(s). It leaves the Resource Group (and other resources within it) intact. This script is designed and tested to be run from Azure Cloud Shell.

## PARAMETERS

- `SubscriptionName`: Name of the Azure Subscription.
- `ResourceGroupName`: Name of the Resource Group.
- `ContainerName`: Name of the ACI container(s).

## EXAMPLE

```powershell
Remove-VstsAgentOnWindowsServerCoreContainer.ps1 -SubscriptionName "<subscription name>" -ResourceGroupName "<resource group name>" -ContainerName "<container 1 name>", "<container 2 name>", "<container n name>"
```

This removes the 2 containers requested. It leaves the Resource Group (and other resources within) intact.

## INPUTS

    <none>

## OUTPUTS

    <none>

## RELEASE INFORMATION

- Version:        1.0
- Author:         Mate Barabas
- Creation Date:  2018-08-29