<#
	.SYNOPSIS 
    Installs required PowerShell modules for the CDS commands

	.NOTES  
    File Name  : Module-Imports.ps1  
    Author     : Jim Novak - totally stolen from James Stephens - james@codevanguard.com
    
    .INPUTS
    None. You cannot pipe objects to ExportAndUnpackSolution.ps1.

    .OUTPUTS
    None. ExportAndUnpackSolution.ps1 does not generate any output.

    .EXAMPLE
    C:\PS> .\Module-Imports.ps1
#>

#import Powerapps cmdlets

# ***************** ***************** 
# Helper function that will check for module by name 
# if it exists, update if Update == true
# if not found, then install it. 
# ***************** ***************** 
function InstallUpdateImport-Module
{
   param
    (
    [Parameter(Mandatory = $true)]
    [string]$mod,
    [Parameter(Mandatory = $false)]
    [bool]$Update=$true
    )
    if (Get-Module -ListAvailable -Name $mod) {
	
        if ($Update) 
        {
            Write-Host "Updating module: " $mod
            Update-Module $mod
        }
        else {
            Write-Host "Module already installed: " $mod
        }
    } 
    else {
        Write-Host "Installing module: " $mod
        Install-Module $mod -Scope CurrentUser
    }

    Write-Host "Importing module: " $mod
    Import-Module $mod

}

## Imports!
Import-Module Microsoft.PowerShell.Utility
InstallUpdateImport-Module -mod 'Microsoft.PowerApps.Administration.PowerShell' -Update $UpdateModule
InstallUpdateImport-Module -mod 'Microsoft.PowerApps.PowerShell' -Update $UpdateModule
InstallUpdateImport-Module -mod 'MSOnline' -Update $UpdateModule