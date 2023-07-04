#Prepare Variables
#$DebugPreference = "Continue"
$SecuredCredPathOld = "D:\PowerShell\baramundi\credentialssvmucbaramain01.xml"
$SecuredCredPathNew = "D:\PowerShell\baramundi\credentialssvmucbaramain.xml"
$baraOld = "svmucbaramain01.ma.prod"
$baraNew = "svmucbaramain.ma.prod"
$maxCount = 4400

#Prepare Modules
Import-Module -Name bConnect

#Import Credentials from file
$ADMCredsOld = Import-Clixml -Path $SecuredCredPathOld
$ADMCredsNew = Import-Clixml -Path $SecuredCredPathNew

#establish Server connection
Write-Debug -Message "Connecting to old bMS"
Initialize-bConnect -Server $baraOld -Credentials $ADMCredsOld #-AcceptSelfSignedCertifcate

#region Read Information
Remove-Variable -Name EndpointsOld
Remove-Variable -Name JobsOld
Remove-Variable -Name JobInstancesOld

#Read all Endpoints from Old System and create a collection
Write-Debug -Message "Read Endpoints"
$EndpointsOld = @()
$EndpointsOld = Get-bConnectEndpoint

Write-Debug -Message "Read Jobs"
$JobsOld = @()
$JobsOld = Get-bConnectJob

Write-Debug -Message "Read Job Instances"
$JobInstancesOld = @()
$JobInstancesOld = Get-bConnectJobInstance

#Disconnect from Old System
Write-Debug -Message "Close Connection to old bMS"
Reset-bConnect

#Establish Connection to new Server
Write-Debug -Message "Connect to new bMS"
Initialize-bConnect -Server $baraNew -Credentials $ADMCredsNew #-AcceptSelfSignedCertifcate

#Read Informations from New System
$EndpointsNew = @()
$EndpointsNew = Get-bConnectEndpoint
$EndpointsNewHostnames = @()
foreach ($Endpoint in $EndpointsNew) {
    $EndpointsNewHostnames += $Endpoint.Hostname
}

$JobsNew = @()
$JobsNew = Get-bConnectJob


#endregion

#Region Processing Endpoints
#Check Endpoint & create if needed
$Count = 0 
foreach ($EndpointOld in $EndpointsOld) {
    $count++
    if ($Count -eq $maxCount) {
        break
    }
    #Prepare Variables
    $EndPointToCheck = $EndpointOld.HostName

    #$EndpointExist = $EndpointsNew -contains $EndPointToCheck
    $EndpointExist = $EndpointsNewHostnames -contains $EndPointToCheck
    #Check Endpoint & create if needed
    if (!($EndpointExist)) {
        $Type = "WindowsEndpoint"
        $Hostname = $EndPointToCheck
        $PrimaryMAC = $EndpointOld.PrimaryMAC
        New-bConnectEndpoint -Type $Type -HostName $Hostname -DisplayName $Hostname -PrimaryMac $PrimaryMAC
    }
}

#Refresh Endpoint List New
Remove-Variable -Name EndpointsNew
Remove-Variable -Name EndpointsNewHostnames
$EndpointsNew = Get-bConnectEndpoint
$EndpointsNewHostnames = @()
foreach ($Endpoint in $EndpointsNew) {
    $EndpointsNewHostnames += $Endpoint.Hostname
}

foreach ($EndpointOld in $EndpointsOld) {
    $EndPointToCheck = $EndpointOld.HostName
    $EndpointExist = $EndpointsNewHostnames -contains $EndpointOld.HostName
    if (!($EndpointExist)) {
        break
    }
    
    #Get Endpoint GUID
    foreach ($Endpoint in $EndpointsNew) {
        if ($Endpoint.Hostname -eq $EndPointToCheck) {
            $EndpointNewGUID = $Endpoint.Id
        }
        <# $Endpoint is tEndpoints$EndpointsNew #>
    }

    #Evaluate JobInstances
    $AssignedJobs = @()
    foreach ($JobInstance in $JobInstancesOld) {
        if ($JobInstance.EndpointName -eq $EndPointToCheck) {
            $AssignedJobs += $JobInstance
        }
        <# $JobInstance is tJobInstancesOld item #>
    }

    if (!($AssignedJobs.Count -eq 0)) {
        Write-Debug -Message "Endpoint $EndpointToCheck has jobs assigned"
        foreach ($Job in $AssignedJobs) {
            #Extract Display Name from existing Job
            $DisplayName = $Job.JobDefinitionDisplayName

            Remove-Variable -Name Job
            foreach ($Job in $JobsNew) {
                if ($Job.DisplayName -eq $DisplayName) {
                    $JobGuidNew = $Job.Id
                }
            }
            
            #Assign Job to Endpoint
            Write-Debug -Message "Assign Job $DisplayName"
            New-bConnectJobInstance -EndpointGuid $EndpointNewGUID -JobGuid $JobGuidNew

            <# $Job is tAssigned$
            AssignedJobs item #>
            Remove-Variable -Name Job
            #Remove-Variable -Name EndpointNewGUID
            Remove-Variable -Name JobGuidNew
            Remove-Variable -Name DisplayName
        }        
    } else {
        Write-Debug -Message "No Jobs assigned to Endpoint $EndpointToCheck"
    }
    
    Remove-Variable -Name EndpointNewGUID
    Remove-Variable -Name EndPointToCheck
    remove-variable -Name EndpointExist
    Remove-Variable -Name AssignedJobs
}
#Evaluate JobInstances
#endregion

Write-Debug -Message "end of script"
