<# Scriptheader
.Synopsis 
    Create Credential files to store username and password
.DESCRIPTION 
    This script queryis credentials from the logged on user and stores them encrypted in txt files for later
    use by a corresponding script
.NOTES 
   Created by: Markus Zierer, maxxys AG
   Modified by: 
 
   Changelog: 
 
   To Do: 
.PARAMETER Debug 
    If the Parameter is specified, script runs in Debug mode
.EXAMPLE 
   Write-Log -Message 'Folder does not exist.' -Path c:\Logs\Script.log -Level Error 
   Writes the message to the specified log file as an error message, and writes the message to the error pipeline. 
.LINK 
   https://gallery.technet.microsoft.com/scriptcenter/Write-Log-PowerShell-999c32d0 
#>

param (
    [switch]$Debug
)

#region prepare variables
$CredXML = Join-Path $here -ChildPath "credentialssvmucbaramain.xml"
$Logfile = "Default"

#region loading modules, scripts & files
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
#
# we write one logfile and append each script execution
[string]$global:Logfile = $ConfigFile.Conf.LogfileName.Name
If ($Logfile -eq "Default"){
    $global:Logfile = Join-Path $here -ChildPath "Credentialssvmucbaramain.log"
}
$lfTmp = $global:Logfile.Split(".")
$global:Logfile = $lfTmp[0] + (Get-Date -Format yyyyMMdd) + "." + $lfTmp[1]
#
# Debug Mode
# If the parameter '-Debug' is specified or debug in XMLfile is set to "true", script activates debug mode
# when debug mode is active, debug messages will be dispalyed in console windows
#
If ($Debug){
    $DebugPreference = "Continue"
} else {$DebugPreference = "SilentlyContinue"}
#
#endregion

#region functions
function  Write-Log {
    param
    (
      [Parameter(Mandatory=$true)]
      $Message
    )
    If($Debug){
      Write-Debug -Message $Message
    }
  
    $msgToWrite =  ('{0} :: {1}' -f (Get-Date -Format yyy-MM-dd_HH-mm-ss),$Message)
  
    if($global:Logfile)
    {
      $msgToWrite | out-file -FilePath $global:Logfile -Append -Encoding utf8
    }
  }
#endregion  

#region write basic infos to log
Write-Log -Message '------------------------------- START -------------------------------'
$ScriptStart = "Script started at:               " + (Get-date)
Write-Log -Message $ScriptStart
If($Debug){
  Write-Log -Message "Debug Mode is:                   enabled"
} else {
  Write-Log -Message "Debug Mode is:                   disabled"
}
Write-Log -Message "PowerShell Script Path is:       $here"
#Write-Log -Message "XML Config file is:              $XMLPath"
Write-Log -Message "LogFilePath is:                  $LogFile"
#endregion

# dump Variables used:
Write-Log -Message "Dumping used variables to Log..."
Write-Log -Message ('Debug Mode enabled:             {0}' -f $Debug)
Write-Log -Message ('Credential XML File:            {0}' -f $CredXML)

$XMLExist = Test-Path -Path $CredXML
if ($Debug) {
    if ($XMLExist) {
        $Credential = Import-Clixml -Path $CredXML
        $securepwd = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credential.Password)
        $DecryptedPwd = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($securepwd)
        Write-Log -Message ('Stored Username:                 {0}' -f $Credential.UserName)
        Write-Log -Message ('Stored encrypted Password:       {0}' -f $securepwd)
    }
}

#endregion

Write-Log -Message "Prompt user for credentials"
#$Credential = $host.ui.PromptForCredential("Need credentials", "Please enter your user name and password.", "UserNameDefault", "DomainPrefixDefault")
$Credential = $host.ui.PromptForCredential("Need credentials", "Please specify credentials to authenticate with bConnect", "", "")

Write-Log -Message "Create XML file containing username"
$XMLExist = Test-Path -Path $CredXML
If ($XMLExist){
    Write-Log -Message "File already exist. It will be overwritten!"
}
$Credential | Export-Clixml $CredXML

Write-Log -Message '-------------------------------- End --------------------------------'