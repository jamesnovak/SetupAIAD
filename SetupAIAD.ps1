#Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

Import-Module Microsoft.PowerShell.Utility

#import Powerapps cmdlet
cd .\PowerAppsCmdlets-V5
dir . | Unblock-File
Import-Module .\Microsoft.PowerApps.Administration.PowerShell.psm1 -Force
Import-Module .\Microsoft.PowerApps.PowerShell.psm1 -Force
cd ..

Install-Module MSOnline

$global:sleepTime = 5
$global:maxRetryCount = 3
$global:lastErrorCode = $null
$global:UserPassword="pass@word1"

function Create-CDSUsers
{
   param
    (
    [Parameter(Mandatory = $true)]
    [string]$Tenant,
    [Parameter(Mandatory = $true)]
    [int]$Count,
    [Parameter(Mandatory = $false)]
    [string]$TenantRegion="GB",
    [Parameter(Mandatory = $false)]
    [string]$password=$global:UserPassword
    )

    $DomainName = $Tenant+".onmicrosoft.com"
    
    Write-Host "Tenant: " $Tenant
    Write-Host "Domain Name: " $DomainName
    Write-Host "Count: " $Count
    Write-Host "Licence Plans: " (Get-MsolAccountSku).AccountSkuId
    Write-Host "TenantRegion: " $TenantRegion
    Write-Host "CDSlocation: " $CDSlocation
    Write-Host "password: " $password
  
    $securepassword = ConvertTo-SecureString -String $password -AsPlainText -Force
    $firstnames = @("Bryant","Walter","Emilio","Alejandro","Jenny","Thelma","Leo","Lori","Rudolph","Ann","Veronica","Darnell","Kathy","Jenna","Heather","Allison","Mary","Terence","Harvey","Frances","Kelly","Grace","Darryl","Michelle","Jorge")
    $lastnames =  @("Malone","Reeves","Rice","Guerrero","Elliott","Rogers","Porter","Castillo","Chambers","Stevenson","Wood","Bowman","Burke","Boyd","Roberson","Kelley","Hopkins","Watkins","Day","Castro","Foster","Nguyen","Fernandez","Owen","Manning")
 
       Write-Host "creating users " -ForegroundColor Green
   
       for ($i=1;$i -lt $Count+1; $i++) {
       

        $randf = Get-Random -Maximum ($firstnames.length - 1)
        $randl = Get-Random -Maximum ($lastnames.length - 1)

        $firstname = $firstnames[$randf]
        $lastname = $lastnames[$randl]
        $displayname = $firstname + " " + $lastname
        $email = ("user" + $i + "@" + $DomainName).ToLower()
       
         New-MsolUser -DisplayName $displayname -FirstName $firstname -LastName $lastname -UserPrincipalName $email -UsageLocation $TenantRegion -Password $password -LicenseAssignment (Get-MsolAccountSku).AccountSkuId -PasswordNeverExpires $true -ForceChangePassword $false  

         #Set-MsolUserLicense -UserPrincipalName $email -AddLicenses (Get-MsolAccountSku).AccountSkuId -Verbose
         
        }
        Write-Host "*****************Lab Users Created ***************" -ForegroundColor Green
        Get-MsolUser | where {$_.UserPrincipalName -like 'user*'}|fl displayname,licenses
}


function Create-CDSenvironment {

    param(
    [Parameter(Mandatory = $false)]
    [string]$password=$global:UserPassword,
    [Parameter(Mandatory = $false)]
    [string]$CDSlocation="europe",
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
            new-Environment -Displayname $envDisplayname -sku Trial -CDSlocation $CDSlocation
        }

        if ($AddProd -eq $true)
        {
            $envDisplayname = $user.UserPrincipalName.Split('@')[0] + "-Prod"

            # call the helper function for the environment 
            new-Environment -Displayname $envDisplayname -sku Production -CDSlocation $CDSlocation
        }

        # check to see if an error occurred in the overall user loop
        if ($lastErrorCode -ne $null){
            break
        }
    }
    $endtime = Get-Date -DisplayHint Time
    $duration = $("{0:hh\:mm\:ss}" -f ($endtime-$starttime))
    Write-Host "End of CreateCDSEnvironment at : " $endtime "  Duration: " $duration -ForegroundColor Green
}

function new-Environment {
    param(
    [Parameter(Mandatory = $true)]
    [string]$Displayname=$null,
    [Parameter(Mandatory = $true)]
    [string]$sku='Trial',
    [Parameter(Mandatory = $true)]
    [string]$CDSlocation=$null
    )

    $global:incre = 1
    $currEnv=$null

    while ($currEnv.EnvironmentName -eq $null)
    {
        $errorVal = $null

        Write-Host "New environment for user: " $Displayname ", Location: " $CDSlocation ", Sku:" $sku ", Attempt number " $global:incre
            
        $currEnv = New-AdminPowerAppEnvironment -DisplayName  $Displayname -LocationName $CDSlocation -EnvironmentSku $sku -Verbose -ErrorVariable errorVal

        # check whether to retry or to break
        if ($currEnv.EnvironmentName -eq $null) 
        {
            if ($global:incre++ -eq $global:maxRetryCount) 
            {
                Write-Host "Error creating environment:" $errorVal -ForegroundColor DarkYellow
                $global:lastErrorCode = $errorVal
                break
            }
            elseif ($errorVal -ne $null) 
            {
                # pause between retries
                Write-Host "Pause before retry" -ForegroundColor Yellow
                Start-Sleep -s $sleepTime
            }
        }
    }

    Write-Host " Created CDS Environment with id :" $currEnv.EnvironmentName -ForegroundColor Green
}

function create-CDSDatabases {

    $starttime= Get-Date -DisplayHint Time
    Write-Host "Starting CreateCDSDatabases :" $starttime -ForegroundColor Green

    $CDSenvs = Get-AdminPowerAppEnvironment | where { ($_.CommonDataServiceDatabaseType -eq "none") -and ($_.EnvironmentType  -ne 'Default')} | Sort-Object displayname

    ForEach ($CDSenv in $CDSenvs) 
    {
        $CDSenv.EnvironmentName

        $global:incre = 1

        Write-Host "Creating CDS databases for:" $CDSenv.DisplayName " id:" $CDSenv.EnvironmentName ", Attempt number: " $global:incre -ForegroundColor White
        
        # check whether to retry or to break
        while ($CDSenv.CommonDataServiceDatabaseType -eq "none")
        {
            $errorVal = $null

            $CDSenv.CommonDataServiceDatabaseType

            New-AdminPowerAppCdsDatabase -EnvironmentName $CDSenv.EnvironmentName -CurrencyName USD -LanguageName 1033 -Verbose -ErrorVariable errorVal -ErrorAction Continue

            $CDSenv=Get-AdminPowerAppEnvironment -EnvironmentName $CDSenv.EnvironmentName
            
            if ($CDSenv.CommonDataServiceDatabaseType -eq "none")
            {
                # pause between retries
                if ($global:incre++ -eq $maxRetryCount) 
                {
                    Write-Host "Error creating database:" $errorVal -ForegroundColor DarkYellow
                    $lastErrorCode = $errorVal
                    break
                }
                elseif ($errorVal -ne $null) 
                {
                    Write-Host "Pause before retry" -ForegroundColor Yellow
                    Start-Sleep -s $sleepTime
                }
            }
        }

        # check to see if an error occurred in the overall user loop
        if ($lastErrorCode -ne $null){
            break
        }
    }

    $endtime = Get-Date -DisplayHint Time
    $duration = $("{0:hh\:mm\:ss}" -f ($endtime-$starttime))
    Write-Host "End of CreateCDSDatabases at : " $endtime " Duration: " $duration -ForegroundColor Green
}

function Setup-CDSenvironments 
{
    param(
    [Parameter(Mandatory = $false)]
    [string]$CDSlocation="europe",
    [Parameter(Mandatory = $false)]
    [bool]$AddTrial=$true,
    [Parameter(Mandatory = $false)]
    [bool]$AddProd=$false
    )

    create-CDSenvironment -CDSlocation $CDSlocation -AddTrial $AddTrial -AddProd $AddProd

    Add-PowerAppsAccount -Username $UserCredential.UserName -Password $UserCredential.Password -Verbose

    Get-AdminPowerAppEnvironment | Sort-Object displayname  | fl displayname

    Write-Host "Start creating the CDS Databases in a few seconds" -ForegroundColor Yellow
    Start-Sleep -s 15

    create-CDSDatabases

    Get-AdminPowerAppEnvironment | Sort-Object displayname  | fl displayname
}

function Delete-CDSenvironment
{
    #Connect to Powerapps with your admin credential
    Add-PowerAppsAccount -Username $UserCredential.UserName -Password $UserCredential.Password -Verbose

    #delete all environemnts
    $envlist=Get-AdminPowerAppEnvironment | where {$_.EnvironmentType  -ne 'Default'}

    ForEach ($environemnt in $envlist) { 
        Remove-AdminPowerAppEnvironment -EnvironmentName $environemnt.EnvironmentName
    }
}
#Delete-CDSenvironment

function Delete-CDSUsers{

    #remove users
    Get-MsolUser | where {$_.UserPrincipalName -like 'user*'}|Remove-MsolUser -Force

    Write-Host "
    *****************Lab Users Deleted ***************" -ForegroundColor Green
    Get-MsolUser |fl displayname,licenses
}

# UPDATE CREDENTIALS HERE
$tenant = "[TENANT]"
$User = "admin@" + $tenant + ".onmicrosoft.com"
$pass = ConvertTo-SecureString "[ADMIN PASSWORD]" -AsPlainText -Force
$usercount = 20

Add-PowerAppsAccount -Username $User -Password $pass

$UserCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $pass

# IF YOU WANT TO BE PROMPTED, YOU CAN USE THIS
#$UserCredential = Get-Credential

Connect-MsolService -Credential $UserCredential

#Check if you have POWERFLOW_P2  License 
if(((Get-MsolUser -UserPrincipalName $UserCredential.UserName | select licenses).licenses| where {$_.AccountSkuId -like '*POWERFLOW_P2'}) -eq $Null) 
{
    #Set-MsolUserLicense -UserPrincipalName $UserCredential.UserName -AddLicenses (Get-MsolAccountSku | where {$_.AccountSkuId -like '*POWERFLOW_P2'}).AccountSkuId -Verbose
    Write-Host " You don't have POWERAPPS Plan2 license assigned, please assign license to Admin from O365 Admin center "    -ForegroundColor Red
    exit
}

#connect to powerapps
Add-PowerAppsAccount -Username $UserCredential.UserName -Password $UserCredential.Password -Verbose
Write-Host "**********Existing CDS environment**************"
Get-AdminPowerAppEnvironment | Sort-Object displayname  | fl displayname
 
#Delete-Users and environments
# BE AWARE THAT THIS WILL DELETE ALL ENVIRONMENTS
Delete-CDSenvironment

Delete-CDSUsers

Create-CDSUsers -Tenant $tenant -Count $usercount -TenantRegion IT -password $global:UserPassword

Write-Host "Start creating the Environments in a few seconds" -ForegroundColor Yellow
Start-Sleep -s 15

Setup-CDSenvironments -CDSlocation unitedstates -AddTrial $true -AddProd $false