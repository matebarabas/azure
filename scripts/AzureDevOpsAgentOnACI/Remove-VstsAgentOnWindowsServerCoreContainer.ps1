########################################################################################################################
# Script Disclaimer
########################################################################################################################
# This script is not supported under any Microsoft standard support program or service.
# This script is provided AS IS without warranty of any kind.
# Microsoft disclaims all implied warranties including, without limitation, any implied warranties of
# merchantability or of fitness for a particular purpose. The entire risk arising out of the use or
# performance of this script and documentation remains with you. In no event shall Microsoft, its authors,
# or anyone else involved in the creation, production, or delivery of this script be liable for any damages
# whatsoever (including, without limitation, damages for loss of business profits, business interruption,
# loss of business information, or other pecuniary loss) arising out of the use of or inability to use
# this script or documentation, even if Microsoft has been advised of the possibility of such damages.

<#
.SYNOPSIS
    This script removes the selected Azure Container Instance(s).
.DESCRIPTION
    This script removes the selected Azure Container Instance(s). It leaves the Resource Group (and other resources
     within it) intact. This script is designed and tested to be run from Azure Cloud Shell.
.PARAMETER SubscriptionName
    Name of the Subscription.
.PARAMETER ResourceGroupName
    Name of the Resource Group.
.PARAMETER ContainerName
    Name of the ACI container(s).
.EXAMPLE
    .\Remove-VstsAgentOnWindowsServerCoreContainer.ps1 -SubscriptionName "<subscription name>" -ResourceGroupName "ctso-cloud-mgmt-01-rg-vstsaci-01" -ContainerName "ctso-cloud-mgmt-01-euw-aci-vsts-01", "ctso-cloud-mgmt-01-euw-aci-vsts-02"
    This removes the 2 containers requested. It leaves the Resource Group (and other resources within) intact.
.INPUTS
    <none>
.OUTPUTS
    <none>
.NOTES
    Version:        1.0
    Author:         Mate Barabas
    Creation Date:  2018-08-29
#>

param(

    [Parameter(Mandatory=$true)][string]$SubscriptionName,
    [Parameter(Mandatory=$true)][string]$ResourceGroupName,
    [Parameter(Mandatory=$true)][array]$ContainerName

)


#region Functions

    function Set-AzureContext {

        param (

            [Parameter(Mandatory=$false)][string]$SubscriptionName

        )


        # Select the desired Subscription based on the Subscription name provided
        if ($SubscriptionName)
        {
            $Subscription = (Get-AzureRmSubscription | Where-Object {$_.Name -eq $SubscriptionName})
            
            if (-not $Subscription)
            {
                Write-Error "There's no Subscription available with the provided name."
                return
            }
            else
            {
                $SubscriptionId = $Subscription.Id
                Select-AzureRmSubscription -SubscriptionId $SubscriptionId| Out-Null
                Write-Output "The following subscription was selected: ""$SubscriptionName"""
            }
        }
        # If no Subscription name was provided select the active Subscription based on the existing context
        else
        {
            $SubscriptionName = (Get-AzureRmContext).Subscription.Name
            $Subscription = (Get-AzureRmSubscription | Where-Object {$_.Name -eq $SubscriptionName})
            Write-Output "The following subscription was selected: ""$SubscriptionName"""
        }

        if ($Subscription.Count -gt 1)
        {
            Write-Error "You have more then 1 Subscription with the same name. Exiting..."
            return
        }
    }

    function Remove-Container {

        param (

            [Parameter(Mandatory=$true)][array]$ContainerName

        )

        foreach ($Name in $ContainerName)
        {
            $Container = Get-AzureRmContainerGroup -ResourceGroupName $ResourceGroupName -Name $Name -ErrorAction SilentlyContinue
            if (-not $Container)
            {
                Write-Error "No ACI container exists with the provided name ($Name)."
            }
            else 
            {
                Write-Warning "Removing selected ACI container ($Name)..."    
                Remove-AzureRmContainerGroup -ResourceGroupName $ResourceGroupName -Name $Name -Confirm:$false

                # Check success
                $Container = Get-AzureRmContainerGroup -ResourceGroupName $ResourceGroupName -Name $Name -ErrorAction SilentlyContinue
                if ($null -eq $Container)
                {
                    Write-Output "ACI container ""$Name"" successfully deleted."
                    Write-Warning "One or more containers have been deleted. Don't forget to clean your Agent pool in VSTS (remove any agents that were created in a previous iteration and are now offline)!"
                }
            }
        }

    }

#endregion


#region Main

    # Login to Azure and select Subscription
    Set-AzureContext -SubscriptionName $SubscriptionName

    # Delete selected containers
    Remove-Container -ContainerName $ContainerName

#endregion
