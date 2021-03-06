﻿<#
	.SYNOPSIS 
    Create new users and Power Apps environment environments in a given Tenant

	.NOTES  
    File Name  : SetupAIAD.ps1  
    Author     : Jim Novak - jim@thefuturez.com
    
    .PARAMETER TargetTenant 
    Name of the target tenant. Ex: 'contoso' for admin@contoso.onmicrosoft.com

    .PARAMETER UserName
    The username with appropriate permission in the target tenant. Ex: 'admin' for admin@contoso.onmicrosoft.com

    .PARAMETER Password
    The password for the user with appropriate permission in the target tenant

    .PARAMETER TenantRegion
    The region in which the target tenant is deployed

    .PARAMETER CDSLocation
    The location in which the target CDS environment is deployed.  Available CDSLocation values
        * `unitedstates`             (United States)
        * `europe`                   (Europe)
        * `asia`                     (Asia)
        * `australia`                (Australia)
        * `india`                    (India)
        * `japan`                    (Japan)
        * `canada`                   (Canada)
        * `unitedkingdom`            (United Kingdom)
        * `unitedstatesfirstrelease` (Preview (United States))
        * `southamerica`             (South America)
        * `france`                   (France)

    .PARAMETER NewUserPassword
    The default password for the new users that will be created in the target tenant

    .PARAMETER UserCount
    The number new users that will be created in the target tenant. Default: 20

    .PARAMETER MaxRetryCount
    The number of retries when an error occurs. Default: 3

    .PARAMETER SleepTime
    The time to sleep between retries when an error occurs. Default: 5

    .PARAMETER ForceUpdateModule
    Flag indicating whether to force an update of the required PS modules.  Default: false

    .INPUTS
    None. You cannot pipe objects to SetupAIAD.ps1.

    .OUTPUTS
    None. SetupAIAD.ps1 does not generate any output.

    .EXAMPLE
    C:\PS> .\SetupAIAD.ps1 -TargetTenant 'demotenant' -UserName 'admin' -Password 'password' -TenantRegion 'US' -CDSLocation unitedstates -NewUserPassword 'password' -UserCount 20 -MaxRetryCount 3 -SleepTime 5 
#>
 param (
    [Parameter(Mandatory=$true, ParameterSetName="Credentials", HelpMessage="Enter the name of the target tenant. Ex: 'contoso' for admin@contoso.onmicrosoft.com.") ] 
    [string]$TargetTenant,

    [Parameter(Mandatory=$true, ParameterSetName="Credentials", HelpMessage="Enter the username with appropriate permission in the target tenant. Ex: 'admin' for admin@contoso.onmicrosoft.com.")]
    [string]$UserName,

    [Parameter(Mandatory=$true, ParameterSetName="Credentials", HelpMessage="Enter the password for the user with appropriate permission in the target tenant.")]
    [string]$Password,

    [Parameter(Mandatory = $true, ParameterSetName="Credentials", HelpMessage="Enter the region code in which the target tenant is deployed.")]
    [string]$TenantRegion="US",

    [Parameter(Mandatory = $true, ParameterSetName="Credentials", HelpMessage="Enter the location name in which the target CDS environment is deployed.")]
    [string]$CDSLocation="unitedstates",

    [Parameter(Mandatory=$false, HelpMessage="Enter the default password for the new users that will be created in the target tenant.")]
    [string]$NewUserPassword = 'pass@word1',

    [Parameter(Mandatory=$false, HelpMessage="Enter the number new users that will be created in the target tenant.")]
    [int]$UserCount = 20,

    [Parameter(Mandatory=$false, HelpMessage="Enter the number of retries when an error occurs.")]
    [int]$MaxRetryCount = 3,

    [Parameter(Mandatory=$false, HelpMessage="Enter the time to sleep between retries when an error occurs.")]
    [int]$SleepTime = 5,

    [Parameter(Mandatory=$false, HelpMessage="Flag indicating whether to force an update of the required PS modules.")]
    [bool]$ForceUpdateModule = $false
 )

# ***************** ***************** 
# Set default parameters if null, 
#   global variables
# ***************** ***************** 
 
if ($NewUserPassword -eq $null) { $NewUserPassword = "pass@word1" }
if ($SleepTime -eq $null)       { $SleepTime = 5 }
if ($MaxRetryCount -eq $null)   { $MaxRetryCount= 3 }
if ($UserCount -eq $null)       { $UserCount = 20 }

Write-Host "SleepTime: " $SleepTime
Write-Host "MaxRetryCount: " $MaxRetryCount
Write-Host "UserCount: " $UserCount
Write-Host "Tenant: " $Tenant
Write-Host "CDSLocation: " $CDSLocation
Write-Host "ForceUpdateModule: " $ForceUpdateModule

$global:lastErrorCode = $null

#Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# ***************** ***************** 
# Import required modules
# ***************** ***************** 
$UpdateModule = $ForceUpdateModule
. $PSScriptRoot\Module-Imports.ps1

# ***************** ***************** 
# Create-CDSUsers
# ***************** ***************** 
function Create-CDSUsers
{
   param
    (
    [Parameter(Mandatory = $true)]
    [string]$Tenant=$TargetTenant,
    [Parameter(Mandatory = $true)]
    [int]$Count=$UserCount,
    [Parameter(Mandatory = $false)]
    [string]$Region=$TenantRegion,
    [Parameter(Mandatory = $false)]
    [string]$password=$NewUserPassword
    )

    $DomainName = $Tenant + ".onmicrosoft.com"
    
    Write-Host "Tenant: " $Tenant
    Write-Host "Domain Name: " $DomainName
    Write-Host "Count: " $Count
    Write-Host "Licence Plans: " (Get-MsolAccountSku).AccountSkuId
    Write-Host "Region: " $Region
    Write-Host "Location: " $CDSlocation
    Write-Host "password: " $password
  
    $securepassword = ConvertTo-SecureString -String $password -AsPlainText -Force
    $firstnames = @("Bryant","Walter","Emilio","Alejandro","Jenny","Thelma","Leo","Lori","Rudolph","Ann","Veronica","Darnell","Kathy","Jenna","Heather","Allison","Mary","Terence","Harvey","Frances","Kelly","Grace","Darryl","Michelle","Jorge")
    $lastnames =  @("Malone","Reeves","Rice","Guerrero","Elliott","Rogers","Porter","Castillo","Chambers","Stevenson","Wood","Bowman","Burke","Boyd","Roberson","Kelley","Hopkins","Watkins","Day","Castro","Foster","Nguyen","Fernandez","Owen","Manning")
 
    Write-Host "Begin creating users " -ForegroundColor Green
   
    for ($i=1;$i -lt $Count+1; $i++) {
        $randf = Get-Random -Maximum ($firstnames.length - 1)
        $randl = Get-Random -Maximum ($lastnames.length - 1)

        $firstname = $firstnames[$randf]
        $lastname = $lastnames[$randl]
        $displayname = $firstname + " " + $lastname
        $email = ("user" + $i + "@" + $DomainName).ToLower()
       
         New-MsolUser -DisplayName $displayname -FirstName $firstname -LastName $lastname -UserPrincipalName $email -UsageLocation $Region -Password $password -LicenseAssignment (Get-MsolAccountSku).AccountSkuId -PasswordNeverExpires $true -ForceChangePassword $false

         #Set-MsolUserLicense -UserPrincipalName $email -AddLicenses (Get-MsolAccountSku).AccountSkuId -Verbose
         
        }
        Write-Host "***************** Lab Users Created ***************" -ForegroundColor Green
        Get-MsolUser | where {$_.UserPrincipalName -like 'user*'}|fl displayname,licenses
}

# ***************** ***************** 
# Create-CDSenvironment
# ***************** ***************** 
function Create-CDSenvironment {

    param(
    [Parameter(Mandatory = $false)]
    [string]$password=$NewUserPassword,
    [Parameter(Mandatory = $false)]
    [string]$Location="unitedstates",
    [Parameter(Mandatory = $false)]
    [bool]$AddTrial=$true,
    [Parameter(Mandatory = $false)]
    [bool]$AddProd=$false
    )

    $starttime= Get-Date -DisplayHint Time
    Write-Host " Starting CreateCDSEnvironment :" $starttime  -ForegroundColor Green

    $securepassword = ConvertTo-SecureString -String $password -AsPlainText -Force
    $users = Get-MsolUser | where {$_.UserPrincipalName -like 'user*'} | Sort-Object UserPrincipalName
    
    ForEach ($user in $users) 
    { 
        if ($user.isLicensed -eq $false)
        {
            write-host " skiping user " $user.UserPrincipalName " - not licensed" -ForegroundColor Red
            continue
        }

        Add-PowerAppsAccount -Username $user.UserPrincipalName -Password $securepassword -Verbose

        if ($AddTrial -eq $true)
        {
            $envDisplayname = $user.UserPrincipalName.Split('@')[0] + "-Dev"

            # call the helper function for the environment 
            new-Environment -Displayname $envDisplayname -sku Trial -Location $Location
        }

        if ($AddProd -eq $true)
        {
            $envDisplayname = $user.UserPrincipalName.Split('@')[0] + "-Prod"

            # call the helper function for the environment 
            new-Environment -Displayname $envDisplayname -sku Production -Location $Location
        }

        # check to see if an error occurred in the overall user loop
        if ($lastErrorCode -ne $null) {
            break
        }
    }
    $endtime = Get-Date -DisplayHint Time
    $duration = $("{0:hh\:mm\:ss}" -f ($endtime-$starttime))
    Write-Host "End of CreateCDSEnvironment at : " $endtime "  Duration: " $duration -ForegroundColor Green
}

# ***************** ***************** 
# New-Environment
# ***************** ***************** 
function new-Environment {
    param(
    [Parameter(Mandatory = $true)]
    [string]$Displayname=$null,
    [Parameter(Mandatory = $true)]
    [string]$sku='Trial',
    [Parameter(Mandatory = $true)]
    [string]$Location=$null
    )

    $global:incre = 1
    $currEnv=$null

    while ($currEnv.EnvironmentName -eq $null)
    {
        $errorVal = $null

        Write-Host "New environment for user: " $Displayname ", Location: " $Location ", Sku:" $sku ", Attempt number " $global:incre
            
        $currEnv = New-AdminPowerAppEnvironment -DisplayName  $Displayname -LocationName $Location -EnvironmentSku $sku -ErrorVariable errorVal # -Verbose 

        # check whether to retry or to break
        if ($currEnv.EnvironmentName -eq $null) 
        {
            if ($global:incre++ -eq $MaxRetryCount) 
            {
                Write-Host "Error creating environment:" $errorVal -ForegroundColor DarkYellow
                $global:lastErrorCode = $errorVal
                break
            }
            elseif ($errorVal -ne $null) 
            {
                # pause between retries
                Write-Host "Pause before retry" -ForegroundColor Yellow
                Start-Sleep -s $SleepTime
            }
        }
    }

    # Write-Host "New Environment with id:" $currEnv.EnvironmentName ", Display Name" $currEnv.DisplayName -ForegroundColor Green
}

# ***************** ***************** 
# create-CDSDatabases
# ***************** ***************** 
function create-CDSDatabases {

    $starttime= Get-Date -DisplayHint Time
    Write-Host "Starting CreateCDSDatabases :" $starttime -ForegroundColor Green

    $CDSenvs = Get-AdminPowerAppEnvironment | where { ($_.CommonDataServiceDatabaseType -eq "none") -and ($_.EnvironmentType  -ne 'Default')} | Sort-Object displayname

    ForEach ($CDSenv in $CDSenvs) 
    {
        $global:incre = 1

        Write-Host "Creating CDS databases for environment '"$CDSenv.DisplayName"' with id '"$CDSenv.EnvironmentName"', Attempt number: " $global:incre -ForegroundColor White

        # check whether to retry or to break
        while ($CDSenv.CommonDataServiceDatabaseType -eq "none")
        {
            $errorVal = $null

            # Write-Host "Current CDS DBType: " $CDSenv.CommonDataServiceDatabaseType
            New-AdminPowerAppCdsDatabase -EnvironmentName $CDSenv.EnvironmentName -CurrencyName USD -LanguageName 1033 -ErrorVariable errorVal -ErrorAction Continue #-Verbose 

            $CDSenv=Get-AdminPowerAppEnvironment -EnvironmentName $CDSenv.EnvironmentName
            
            if ($CDSenv.CommonDataServiceDatabaseType -eq "none")
            {
                # pause between retries
                if ($global:incre++ -eq $MaxRetryCount) 
                {
                    Write-Host "Error creating database:" $errorVal -ForegroundColor DarkYellow
                    $lastErrorCode = $errorVal
                    break
                }
                elseif ($errorVal -ne $null) 
                {
                    Write-Host "Pause before retry" -ForegroundColor Yellow
                    Start-Sleep -s $SleepTime
                }
            }
            Write-Host "New '"$CDSenv.CommonDataServiceDatabaseType"' created for" $CDSenv.DisplayName -ForegroundColor White
        }

        # check to see if an error occurred in the overall user loop
        if ($lastErrorCode -ne $null){
            break
        }
    }

    $endtime = Get-Date -DisplayHint Time
    $duration = $("{0:hh\:mm\:ss}" -f ($endtime-$starttime))
    Write-Host "End of CreateCDSDatabases at :" $endtime ", Duration: " $duration -ForegroundColor Green
}

# ***************** ***************** 
# Delete-CDSenvironment
# ***************** ***************** 
function Setup-CDSenvironments 
{
    param(
    [Parameter(Mandatory = $false)]
    [string]$Location="unitedstates",
    [Parameter(Mandatory = $false)]
    [bool]$AddTrial=$true,
    [Parameter(Mandatory = $false)]
    [bool]$AddProd=$false
    )

    create-CDSenvironment -Location $Location -AddTrial $AddTrial -AddProd $AddProd

    Add-PowerAppsAccount -Username $UserCredential.UserName -Password $UserCredential.Password -Verbose

    Write-Host "Start creating the CDS Databases in a few seconds" -ForegroundColor Yellow
    Start-Sleep -s 15

    create-CDSDatabases

    Write-Host "Current list of CDS Environments:"
    Get-AdminPowerAppEnvironment | Sort-Object displayname  | fl displayname
}

# ***************** ***************** 
# Delete-CDSenvironment
# ***************** ***************** 
function Delete-CDSenvironment
{
    #Connect to Powerapps with your admin credential
    Add-PowerAppsAccount -Username $UserCredential.UserName -Password $UserCredential.Password -Verbose

    #delete all environemnts
    $envlist=Get-AdminPowerAppEnvironment | where {$_.EnvironmentType  -ne 'Default'}

    ForEach ($env in $envlist) { 
        Write-Host "Delete CDS Environment :" $env.EnvironmentName -ForegroundColor Green
        Remove-AdminPowerAppEnvironment -EnvironmentName $env.EnvironmentName
    }
}

# ***************** ***************** 
# Delete-CDSUsers
# ***************** ***************** 
function Delete-CDSUsers{

    Get-MsolUser | where {$_.UserPrincipalName -like 'user*'}|Remove-MsolUser -Force
    Write-Host "*****************Lab Users Deleted ***************" -ForegroundColor Green
}

# ***************** ***************** 
# Build the username/pw for the module call
# ***************** ***************** 
$user = $UserName + "@" + $TargetTenant + ".onmicrosoft.com"
$pass = ConvertTo-SecureString $Password -AsPlainText -Force

Add-PowerAppsAccount -Username $User -Password $pass

$UserCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $pass

# ***************** ***************** 
# IF YOU WANT TO BE PROMPTED, YOU CAN USE THIS
#$UserCredential = Get-Credential
# ***************** ***************** 
Connect-MsolService -Credential $UserCredential

# Get-AdminPowerAppEnvironmentLocations 

Exit-PSSession 

# ***************** ***************** 
# Check if you have POWERFLOW_P2  License 
# ***************** ***************** 
if(((Get-MsolUser -UserPrincipalName $UserCredential.UserName | select licenses).licenses| where {$_.AccountSkuId -like '*POWERFLOW_P2'}) -eq $Null) 
{
    #Set-MsolUserLicense -UserPrincipalName $UserCredential.UserName -AddLicenses (Get-MsolAccountSku | where {$_.AccountSkuId -like '*POWERFLOW_P2'}).AccountSkuId -Verbose
    Write-Host " You don't have POWERAPPS Plan2 license assigned, please assign license to Admin from O365 Admin center "    -ForegroundColor Red
    exit
}

#connect to powerapps
Add-PowerAppsAccount -Username $UserCredential.UserName -Password $UserCredential.Password -Verbose

Write-Host "********** Existing CDS environments **************"
Get-AdminPowerAppEnvironment | Sort-Object displayname  | fl displayname

#Delete-Users and environments
# BE AWARE THAT THIS WILL DELETE ALL ENVIRONMENTS EXCEPT DEFAULT
Delete-CDSenvironment

Delete-CDSUsers
Start-Sleep -s 10

if ($UserCount -gt 0) 
{
    Create-CDSUsers -Tenant $TargetTenant -Count $UserCount -Region $TenantRegion -password $NewUserPassword
    Write-Host "Start creating the Environments in a few seconds" -ForegroundColor Yellow
    Start-Sleep -s 10

    Setup-CDSenvironments -Location $CDSLocation -AddTrial $true -AddProd $false
}