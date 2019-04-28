# Remove-VstsAgentOnWindowsServerCoreContainer.ps1

## SYNOPSIS

This script removes the selected Azure Container Instance(s).

## DESCRIPTION

This script removes the selected Azure Container Instance(s). It leaves the Resource Group (and other resources within it) intact. This script is designed and tested to be run from Azure Cloud Shell.

## PARAMETERS

- `SubscriptionName`: Name of the Azure Subscription.
- `ResourceGroupName`: Name of the Resource Group.
- `ContainerName`: Name of the ACI container(s).
- `PatToken`: PAT token required to log in to Azure DevOps to delete the Agent's registration from the pool.
- `AzureDevOpsAccountName`: Name of the Azure DevOps account that the Agent is registered to.
- `AgentPoolName`: Name of the Agent Pool that holds the Agent to delete.

## EXAMPLE

```powershell
Remove-VstsAgentOnWindowsServerCoreContainer.ps1 -SubscriptionName "<subscription name>" -ResourceGroupName "<resource group name>" -ContainerName "<container 1 name>", "<container 2 name>" -PatToken "<pat token to log in>" -AzureDevOpsAccountName "<ADOS account name>" -AgentPoolName "<name of the Agent Pool>"
```

This removes the 2 requested containers and their registrations from Azure DevOps. It leaves the Resource Group (and other resources within) intact.

## INPUTS

    <none>

## OUTPUTS

    <none>

## RELEASE INFORMATION

    Version:        1.1
    Author:         Mate Barabas
    Creation Date:  2018-08-29
    Change log:
      - v1.1 (2019-04-06): the script now removes the Agent's registration from the Agent pool