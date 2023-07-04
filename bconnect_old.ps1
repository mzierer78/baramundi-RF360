$SecuredCredPath = "D:\PowerShell\baramundi\credentials.xml"
$UserName = "adm-ovoki@ma.prod"
Import-Module -Name bConnect

#check if credentials are already present
$CredFileExist = Test-Path -Path $SecuredCredPath

#create file if not already exist
if (!($CredFileExist)){
    Get-Credential | Export-clixml $SecuredCredPath
}

#Import Credentials from file
$ADMCreds = Import-Clixml -Path $SecuredCredPath

#establish Server connection
Initialize-bConnect -Server "svmucbaramain.ma.prod" -Credentials $ADMCreds #-AcceptSelfSignedCertifcate

#Read all Endpoints and create a collection
$Endpoints = @()
$Endpoints = Get-bConnectEndpoint

$Jobs = @()
$Jobs = Get-bConnectJob

$JobInstances = @()
$JobInstances = Get-bConnectJobInstance

Write-Debug -Message "end of script"