#Source Control Auto Sync test by Jimmy

Param(
 [string]$resourceGroup,
 [string]$VMName,
 [string]$method,
 [string]$UAMI 
)

$automationAccount = "AA-test-bianji"

# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process | Out-Null

# Connect using a Managed Service Identity
try {
        Connect-AzAccount -Identity -ErrorAction stop -WarningAction SilentlyContinue | Out-Null
    }
catch{
        Write-Output "There is no system-assigned user identity. Aborting."; 
        exit
    }

if ($method -eq "SA")
    {
        Write-Output "Using system-assigned managed identity"
    }
elseif ($method -eq "UA")
    {
        Write-Output "Using user-assigned managed identity"

        # Connects using the Managed Service Identity of the named user-assigned managed identity
        $identity = Get-AzUserAssignedIdentity -ResourceGroupName $resourceGroup -Name $UAMI

        # validates assignment only, not perms
        if ((Get-AzAutomationAccount -ResourceGroupName $resourceGroup -Name $automationAccount).Identity.UserAssignedIdentities.Values.PrincipalId.Contains($identity.PrincipalId))
            {
                Connect-AzAccount -Identity -AccountId $identity.ClientId | Out-Null
            }
        else {
                Write-Output "Invalid or unassigned user-assigned managed identity"
                exit
            }
    }
else {
        Write-Output "Invalid method. Choose UA or SA."
        exit
     }

# Get current state of VM
$status = (Get-AzVM -ResourceGroupName $resourceGroup -Name $VMName -Status).Statuses[1].Code

Write-Output "`r`n Beginning VM status: $status `r`n"

# Start or stop VM based on current state
if($status -eq "Powerstate/deallocated")
    {
        Start-AzVM -Name $VMName -ResourceGroupName $resourceGroup
    }
elseif ($status -eq "Powerstate/running")
    {
        Stop-AzVM -Name $VMName -ResourceGroupName $resourceGroup -Force
    }

# Get new state of VM
$status = (Get-AzVM -ResourceGroupName $resourceGroup -Name $VMName -Status).Statuses[1].Code  

Write-Output "`r`n Ending VM status: $status `r`n `r`n"

Write-Output "Account ID of current context: " (Get-AzContext).Account.Id
