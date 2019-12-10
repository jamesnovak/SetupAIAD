# SetupAIAD
PowerShell scripts that will automate setting up one or more CDS users and Power Apps environments
This script is based on those provided with the Microsoft App In A Day trainer package.  Adjustments have been made for parameterizing your credentials and capturing error conditions.

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
