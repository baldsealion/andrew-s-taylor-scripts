##Creates a multi-tenant App Reg
##Secret is randomly generated
##App ID and Secret passed to the output

#Install MS Graph if not available
if (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication) {
    write-output "Microsoft Graph Authentication Already Installed"
} 
else {
        Install-Module -Name Microsoft.Graph.Authentication -Scope CurrentUser -Repository PSGallery -Force
        write-output "Microsoft Graph Authentication Installed"
}

#Install MS Graph if not available
if (Get-Module -ListAvailable -Name Microsoft.Graph.Applications) {
    write-output "Microsoft Graph Applications Already Installed"
} 
else {
        Install-Module -Name Microsoft.Graph.Applications -Scope CurrentUser -Repository PSGallery -Force
        write-output "Microsoft Graph Applications Installed"
}

#Import Module
Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Applications

Connect-MgGraph -Scopes "Application.Read.All","Application.ReadWrite.All","User.Read.All"


function Get-RandomPassword {
    param (
        [Parameter(Mandatory)]
        [int] $length,
        [int] $amountOfNonAlphanumeric = 1
    )
    Add-Type -AssemblyName 'System.Web'
    return [System.Web.Security.Membership]::GeneratePassword($length, $amountOfNonAlphanumeric)
}

###############################################################################
#Create AAD Application
###############################################################################
$AppName =  "IntuneBackup"
$App = New-MgApplication -DisplayName $AppName -SignInAudience AzureADMultipleOrgs
$APPObjectID = $App.Id

###############################################################################
#Add a ClientSecret
###############################################################################
$passwordCred = @{
    "displayName" = "IntuneBackupSecret"
    "endDateTime" = (Get-Date).AddMonths(+24)
}
$ClientSecret2 = Add-MgApplicationPassword -ApplicationId $APPObjectID -PasswordCredential $passwordCred

$appsecret = $ClientSecret2.SecretText

###############################################################################
#Add Permissions
###############################################################################
#Add Delegated Permission
$params = @{
    RequiredResourceAccess = @(
        @{
            ResourceAppId = "00000003-0000-0000-c000-000000000000"
            ResourceAccess = @(
                @{
                    Id = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
                    Type = "Scope"
                },
                @{
                    Id = "62a82d76-70ea-41e2-9197-370581804d09"
                    Type = "Role"
                },            
                @{
                    Id = "dc149144-f292-421e-b185-5953f2e98d7f"
                    Type = "Role"
                },
                @{
                    Id = "9e3f62cf-ca93-4989-b6ce-bf83c28f9fe8"
                    Type = "Role"
                },
                @{
                    Id = "246dd0d5-5bd0-4def-940b-0421030a5b68"
                    Type = "Role"
                },
                @{
                    Id = "7e05723c-0bb0-42da-be95-ae9f08a6e53c"
                    Type = "Role"
                },
                @{
                    Id = "19dbc75e-c2e2-444c-a770-ec69d8559fc7"
                    Type = "Role"
                },
                @{
                    Id = "78145de6-330d-4800-a6ce-494ff2d33d07"
                    Type = "Role"
                },
                @{
                    Id = "9241abd9-d0e6-425a-bd4f-47ba86e767a4"
                    Type = "Role"
                },
                @{
                    Id = "243333ab-4d21-40cb-a475-36241daa0842"
                    Type = "Role"
                },
                @{
                    Id = "e330c4f0-4170-414e-a55a-2f022ec2b57b"
                    Type = "Role"
                },
                @{
                    Id = "5ac13192-7ace-4fcf-b828-1a26f28068ee"
                    Type = "Role"
                },
                @{
                    Id = "dbaae8cf-10b5-4b86-a4a1-f871c94c6695"
                    Type = "Role"
                },
                @{
                    Id = "01c0a623-fc9b-48e9-b794-0756f8e8f067"
                    Type = "Role"
                },
                @{
                    Id = "a402ca1c-2696-4531-972d-6e5ee4aa11ea"
                    Type = "Role"
                },
                @{
                    Id = "3b4349e1-8cf5-45a3-95b7-69d1751d3e6a"
                    Type = "Role"
                },
                @{
                    Id = "1c6e93a6-28e2-4cbb-9f64-1a46a821124d"
                    Type = "Role"
                }
            )
        }
    )
}
Update-MgApplication -ApplicationId $APPObjectID -BodyParameter $params

###############################################################################
#Redirect URI
#If you need to add Redirect URI's.
###############################################################################
#Redirect URI
$App = Get-MgApplication -ApplicationId $APPObjectID -Property *
$AppId = $App.AppId
$RedirectURI = @()
$RedirectURI += "https://login.microsoftonline.com/common/oauth2/nativeclient"
$RedirectURI += "msal" + $AppId + "://auth"
$RedirectURI += "https://intunebackup.com"

$params = @{
    RedirectUris = @($RedirectURI)
}
Update-MgApplication -ApplicationId $APPObjectID -IsFallbackPublicClient -PublicClient $params

###############################################################################
#Grant Admin Consent - Opens URL in Browser
###############################################################################
#https://login.microsoftonline.com/{tenant-id}/adminconsent?client_id={client-id}
$App = Get-MgApplication | Where-Object {$_.DisplayName -eq $AppName}
$TenantID = $App.PublisherDomain
$AppID = $App.AppID
$URL = "https://login.microsoftonline.com/$TenantID/adminconsent?client_id=$AppID"
Start-Process $URL

write-host "Your App ID is $APPObjectID"

write-host "Your App Secret is $appsecret"