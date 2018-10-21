# Azure DevOps (formerly VSTS) Agents on Windows Server Core containers, using Azure Container Instances (ACI)

## 0. Table of content

- [Azure DevOps (formerly VSTS) Agents on Windows Server Core containers, using Azure Container Instances (ACI)](#azure-devops-formerly-vsts-agents-on-windows-server-core-containers-using-azure-container-instances-aci)
    - [0. Table of content](#0-table-of-content)
    - [1. Concept](#1-concept)
    - [2. How does the solution work?](#2-how-does-the-solution-work)
    - [3. Prerequisites](#3-prerequisites)
    - [4. How to manage the solution's lifecycle](#4-how-to-manage-the-solutions-lifecycle)
        - [4.1. Initialize ACI containers in Azure Cloud Shell](#41-initialize-aci-containers-in-azure-cloud-shell)
        - [4.2. Update ACI containers](#42-update-aci-containers)
        - [4.3. Delete ACI containers](#43-delete-aci-containers)

## 1. Concept

The customer needed a solution to run Azure DevOps (VSTS) agents to enable CI/CD pipeline automation. The company prefers using PaaS services over IaaS VMs, and has strict security requirements.

Azure offers a relatively new service, called Azure Container Instances (ACI), using which customers can run containers without managing the underlying infrastructure. This service is now generally availble (GA).

This solution is simple, secure and has multiple benefits over a VM:

- It does not use public IPs.
- It does not have any exposed ports.
- Logging in to these containers is not possible (console and network access is not available) - only the configuration script's outputs can be read, as these are printed to the console.
- There's no need to maintain a VNET or any other infrastructure pieces.
- Has a lightweight footprint.
- Can be provisioned very quickly: to fully configure a container instance with the required components takes 5-10 minutes.
- Is immutable: it does not need patching/management. For version upgrades, the existing instances have to be deleted, and the new ones can easily be re-created by running the provision scripts again.

## 2. How does the solution work?

The solution consists of 3 scripts - all have to be placed to the same folder:
- [Initialize-VstsAgentOnWindowsServerCoreContainer.ps1](Initialize-VstsAgentOnWindowsServerCoreContainer.md) - the external, "wrapper" script,
- [Install-VstsAgentOnWindowsServerCoreContainer.ps1](Install-VstsAgentOnWindowsServerCoreContainer.md) - the container configuration script (internal script, runs inside of the containers) - this should never be invoked directly.
- [Remove-VstsAgentOnWindowsServerCoreContainer.ps1](Remove-VstsAgentOnWindowsServerCoreContainer.md) - removal script that can be used to remove containers that are no longer required

The wrapper script can be invoked from any location (including Azure Cloud Shell), that has the required components intalled (see the [prerequisites](#Prerequisites)  below). The wrapper script copies the internal, container configuration script to a publicly available storage container of the requested Storage Acccount, it creates a new Resource Group (if one doesn't exist with the provided name), removes any pre-existing ACI containers with the same name, within the same Resource Group, then creates new ACI container instance(s) based on the provided names and invokes the container configuration script inside the container(s). The container(s) are based on the latest version of the official Windows Server Core image (microsoft/windowsservercore LTSC) available on Docker Hub.

The internal, container configuration script downloads and installs the latest available version of the Azure DevOps agent, and registers the instance(s) to the selected Agent Pool. It also configures the instance(s) with the latest version of Terrafom and the selected PowerShell modules (by default AzureRM, AzureAD, Pester). 
After the successful configuration, it prints the available disk space and keeps periodically checking that the "vstsagent" service is in running state. Failure of this service will cause the Container instance to be re-initialized. If this happens and the PAT token is still valid, the container will auto-heal itself. If the PAT token has already been revoked, or has been expired by this time, the container re-creation will fail.

This removal script removes the selected Azure Container Instance(s). It leaves the Resource Group (and other resources within it) intact.

## 3. Prerequisites

- Azure Subscription, with an existing Storage Account
- You need to have admin rights:
  - To create a storage container within the already existing Storage Account *- OR -*  a storage container with the public access type of "Blob" has to exist,
  - To create a new Resource Group *- OR -*  an existing Resource Group for the Azure Container Intances,
  - To create resources in the selected Resource Group.
- Azure DevOps account with the requested Agent Pool has to exist.
- Permission in the Azure DevOps account to add agents to the chosen Agent Pool.
- A PAT token.
  - A PAT token can only be read once, at the time of creation.
  - PAT tokens cannot be used for privilege escalation.
  - To learn more about PAT tokens, visit the [Use Personal Access Tokens to Authenticate](https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=vsts) site.
- AzureRM PowerShell modules, AZ CLI

## 4. How to manage the solution's lifecycle

### 4.1. Initialize ACI containers in Azure Cloud Shell

- Get access to the Azure DevOps account where you would like to create the new agents. You might need to have rights to create a new Agent Pool if the requested one doesn't exist.
- Get a PAT token for agent registration (Agent Pools: read, manage; Deployment group: read, maange). To see detailed description of this step, visist the [Deploy an agent on Windows](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/v2-windows?view=vsts) page of Azure DevOps documentation.
- Get access to the Azure Subscription where you need to deploy the ACI containers. See more details in the [Prerequisites](#Prerequisites) section above.
- Get access to Azure Cloud Shell. See "[Quickstart for PowerShell in Azure Cloud Shell](https://docs.microsoft.com/en-us/azure/cloud-shell/quickstart-powershell)" for more details.
- Copy the below .ps1 script files to your Cloud Shell area:
  - [Initialize-VstsAgentOnWindowsServerCoreContainer.ps1](Initialize-VstsAgentOnWindowsServerCoreContainer.md)
  - [Install-VstsAgentOnWindowsServerCoreContainer.ps1](Install-VstsAgentOnWindowsServerCoreContainer.md)
  - [Remove-VstsAgentOnWindowsServerCoreContainer.ps1](Remove-VstsAgentOnWindowsServerCoreContainer.md)
- Run the below script to create containers in your selected region:

```powershell
Initialize-VstsAgentOnWindowsServerCoreContainer.ps1 -SubscriptionName "<subscription name>" -ResourceGroupName "<resource group name>" -ContainerName "<container 1 name>", "<container 2 name>", "<container n name>" -Location "<azure region 1>" -StorageAccountName "<storage account name>" -VSTSAccountName "<azure devops account name>" -PATToken "<PAT token>" -PoolName "<agent pool name>"
```

- In case you would like to have containers in any additional regions, re-run the script with a different "Locaion" parameter:

```powershell
Initialize-VstsAgentOnWindowsServerCoreContainer.ps1 -SubscriptionName "<subscription name>" -ResourceGroupName "<resource group name>" -ContainerName "<container 1 name>", "<container 2 name>", "<container n name>" -Location "<azure region 2>" -StorageAccountName "<storage account name>" -VSTSAccountName "<azure devops account name>" -PATToken "<PAT token>" -PoolName "<agent pool name>"
```

- If the container creation precedure fails, Azure automatically retries creating a new instance.
- Read the logs of each container.
  - In case of success, you can decide if you want to delete your PAT token. See more in "[Revoke personal access tokens to remove access](https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=vsts#revoke-personal-access-tokens-to-remove-access)".
  - In case any undhandled errors occured, you can re-run the the script for the instance in question, using the "-ReplaceExistingContainer" switch (see the description below in the [Update ACI containers](#Update-ACI-containers) section).
- As long as your PAT token is valid, you can remove the agents' registration on the Azure DevOps portal. This will trigger the container to stop the Azure DevOps (VSTS) service, restart, and reapply all the settings defined in the container configuration script ("Install-VstsAgentOnWindowsServerCoreContainer").
- If the PAT token has already been removed, in order to update/re-register the containers, you'll have generate a new PAT token, remove the existing containers, and re-run the "Initialize-VstsAgentOnWindowsServerCoreContainer.ps1" script.

### 4.2. Update ACI containers

- If you would like to update your existing ACI containers, you can re-run the same ".\Initialize-VstsAgentOnWindowsServerCoreContainer.ps1" scipt using the "-RequiredPowerShellModules" switch as follows:

```powershell
Initialize-VstsAgentOnWindowsServerCoreContainer.ps1 -SubscriptionName "<subscription name>" -ResourceGroupName "<resource group name>" -ContainerName "<container 1 name>", "<container 2 name>", "<container n name>" -Location "<azure region 2>" -StorageAccountName "<storage account name>" -VSTSAccountName "<azure devops account name>" -PATToken "<PAT token>" -PoolName "<agent pool name>" -ReplaceExistingContainer
```

- This will wipe out the existing container(s), and re-register the new one(s) with the same name. Note that this will create a new agent registration in Azure DevOps, as the agent names are generated based on the following pattern: `<ACI container name>-<Date-Time in the format of yyyyMMdd-mmhhss>`
- Once the new container(s) have bee provisioned, the old agents become orphaned. These have to be manually deprovisioned on the Azure DevOps portal.

### 4.3. Delete ACI containers

- To remove the ACI containers that are no longer required, run the below script:

```powershell
Remove-VstsAgentOnWindowsServerCoreContainer.ps1 -SubscriptionName "<subscription name>" -ResourceGroupName "<resource group name>" -ContainerName "<container 1 name>", "<container 2 name>", "<container n name>"
```

- Once the containers have been removed, the agents on the Azure DevOps portal become orphaned. These have to be manually deprovisioned (deleted) on the portal.