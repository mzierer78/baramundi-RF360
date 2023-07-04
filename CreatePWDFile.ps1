#This is an example of how to store credentials securely in a file
#only the account that stores \ encrypts the files can decrypt them
#
#Reference
#https://frankfu.click/microsoft/powershell/working-with-passwords-secure-strings-and-credentials-in-windows-powershell/
#

Clear-Host
#To Set or Change the Credental create the below text file and enter the password.  Then trigger the script to run under the context of the 
#user that will be doing the task. It will load and save the info, then delete the file for security.
$OriginalCredPath = "D:\PowerShell\baramundi\FirstRun.txt"
$SecuredCredPath = "D:\PowerShell\baramundi\EncryptedScriptPassword.txt"
if(Test-Path -Path $OriginalCredPath)
{
    Write-Host "First Run Tasks Begining:" -ForegroundColor Cyan
    #load the original plain text credential
    $PlainPassword = Get-Content -Path $OriginalCredPath
    #Write-Host "Plain Text Credential From Disk: " $PlainPassword -ForegroundColor Yellow   
    $SecurePassword = $PlainPassword | ConvertTo-SecureString -AsPlainText -Force
    $SecureStringAsPlainText = $SecurePassword | ConvertFrom-SecureString

    Set-Content -path $SecuredCredPath $SecureStringAsPlainText
    write-host "Encrypted Auth Info Saved" -ForegroundColor Cyan
}

if((Test-Path -Path $OriginalCredPath) -and (Test-Path -Path $SecuredCredPath))
{
    #Remove the original plaintext credential, We don't want passwords laying around where they can be stolen!
    Remove-Item -Path $OriginalCredPath
    Write-Host "Plain Text Credential Deleted: " $OriginalCredPath -ForegroundColor Green
}
if(!(Test-Path -Path $SecuredCredPath))
{
    #check for the encrypted credentials Exit if not present
    write-host "Error:" $SecuredCredPath "Doesn't Exist! Create The File:" $OriginalCredPath "and run this script again" -ForegroundColor Red
    Exit
}