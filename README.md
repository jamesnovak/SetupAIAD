# SetupAIAD
Please review the document [Creating Office 365 PowerApps Trial Environments.docx](/Creating%20Office%20365%20PowerApps%20Trial%20Environments.docx) if you require a Power Apps environment.

PowerShell scripts that will automate setting up one or more CDS users and Power Apps environments. The script will:
* Create one or more user accounts with randomly generated names
* Create a new Power Apps environment for each new user
* Create a new CDS data base for each environment 
* Grant the new user rights to create apps within the new environment

The script will check for the correct licenses for the assigned user before proceeding. A Power Apps P2 license is required.

Before running this script, you will need to login to the [https://make.powerapps.com](https://make.powerapps.com) site at least once.

This script is based on those provided with the Microsoft [App In A Day](https://aka.ms/AIADEvent) trainer package.  Adjustments have been made for parameterizing your credentials and capturing error conditions.

## PARAMETERS

* `TargetTenant`
Name of the target tenant. Ex: `'contoso'` for admin@contoso.onmicrosoft.com

* `UserName`
The username with appropriate permission in the target tenant. Ex: `'admin'` for admin@contoso.onmicrosoft.com

* `Password`
The password for the user with appropriate permission in the target tenant

* `TenantRegion`
The region in which the target tenant is deployed

* `NewUserPassword`
The default password for the new users that will be created in the target tenant. Default: `'pass@word1'`

* `UserCount`
The number new users that will be created in the target tenant. Default: `20`

* `MaxRetryCount`
The number of retries when an error occurs. Default: `3`

* `SleepTime`
The time to sleep between retries when an error occurs. Default: `5`

## EXAMPLE USAGE
`C:\PS> .\SetupAIAD.ps1 -TargetTenant 'demotenant' -UserName 'admin' -Password 'password' -TenantRegion 'US' -NewUserPassword 'password' -UserCount 20 -MaxRetryCount 3 -SleepTime 5` 
