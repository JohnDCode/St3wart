# Created By: JohnDavid Abe
# Created On: 6/15/23
# Last Modified: 6/15/23
# Title: services.ps1
# Description: Used to detect new/deleted services, as well as enable critical/disable malicious services on cyberpatriot competition images
# Version: 1.0



# Log the script running
$date = Get-Date
Add-Content .\log.txt "Script Ran: services.ps1"
Add-Content .\log.txt "Date: $date"
Add-Content .\log.txt ""

# Save the number of actions taken
$actionNumber = 0








# Read which system policies to apply from input
Write-Host "Which OS baseline would you like to import?"
$osInput = Read-Host -Prompt "[1] Windows 10  [2] Windows 11  [3] Server 19  [4] Server 22"


# Import csv baselines based on the input
switch ($osInput) {
    "1" { $serviceCSV = Import-Csv -Path .\Baselines\ServiceBaselines\win10.csv }
    "2" { $serviceCSV = Import-Csv -Path .\Baselines\ServiceBaselines\win11.csv }
    "3" { $serviceCSV = Import-Csv -Path .\Baselines\ServiceBaselines\server19.csv }
    "4" { $serviceCSV = Import-Csv -Path .\Baselines\ServiceBaselines\server22.csv }
}



# Retrieve all the service names from the baseline
$baselineNames = $serviceCSV | Select-Object -ExpandProperty Name










# Identify removed services on the machine

$removedServiceName = @()
$removedServiceDisplay = @()

$confirm = Read-Host -Prompt "Would you like to search the system for removed services? (Y/N)"

# If user wants to identify removed services
if ($confirm -eq "Y") {

    # Retrieve all service (names) on the system
    $sysServices = Get-Service | Select-Object -ExpandProperty Name

    # If retrieving the names was a success then log the removed services
    if ($?) {
        # Count the number of found services
        $count = 0
    
        # Log that the serach was a success
        Add-Content .\log.txt "`nAction $actionNumber. Searched for removed system services (Success):"
        Add-Content .\log.txt ""
    
        # Loop through the baseline services
        foreach($service in $baselineNames) {
            if(-not($sysServices.contains($service))) {
                # If the service isn't on the system, log it
                $displayName = ($serviceCSV | Where-Object { $_.Name -eq $service }).DisplayName
                $count += 1

                # Ignore instance specific services
                if (-not($service -match '_.{3,}$')) {
                    $removedServiceName += $service
                    $removedServiceDisplay += $displayName
                }
                
            }
        }

        Write-Host "Found $count removed services"

        # Create a table of the identified service names and display names
        $tableData = for ($i = 0; $i -lt $removedServiceName.Count; $i++) {
            [PSCustomObject]@{
                Name = $removedServiceName[$i]
                DisplayName = $removedServiceDisplay[$i]
            }
        }

        # Write the table to the logs
        $table = $tableData | Format-Table -AutoSize | Out-String
        Add-Content .\log.txt $table


    } else {
        # Else log an error
        Add-Content .\log.txt "`nAction $actionNumber. Searched for removed system services (Fail)"
    }

    $actionNumber += 1

}








# Identify added services on the machine

$addedServiceName = @()
$addedServiceDisplay = @()

$confirm = Read-Host -Prompt "Would you like to search the system for added services? (Y/N)"

# If user wants to identify added services
if ($confirm -eq "Y") {

    # Retrieve all service (names) on the system
    $sysServices = Get-Service | Select-Object -ExpandProperty Name

    # If retrieving the names was a success then log the added services
    if ($?) {
        # Count the number of found services
        $count = 0
    
        # Log that the serach was a success
        Add-Content .\log.txt "`nAction $actionNumber. Searched for added system services (Success):"
        Add-Content .\log.txt ""
    
        # Loop through the system services
        foreach($service in $sysServices) {
            if(-not($baselineNames.contains($service))) {
            # If the service isn't on the system, log it
                $displayName = Get-Service $service | Select-Object -ExpandProperty DisplayName
                $count += 1
                

                # Ignore instance specific services
                if (-not($service -match '_.{3,}$')) {
                    $addedServiceName += $service
                    $addedServiceDisplay += $displayName
                }


            }
        }

        Write-Host "Found $count added services"

        # Create a table of the identified service names and display names
        $tableData = for ($i = 0; $i -lt $addedServiceName.Count; $i++) {
            [PSCustomObject]@{
                Name = $addedServiceName[$i]
                DisplayName = $addedServiceDisplay[$i]
            }
        }

        # Write the table to the logs
        $table = $tableData | Format-Table -AutoSize | Out-String
        Add-Content .\log.txt $table


    } else {
        # Else log an error
        Add-Content .\log.txt "`nAction $actionNumber. Searched for added system services (Fail)"
    }

    $actionNumber += 1

}








# Harden services



# Create list of services that should be enabled/automatic

$enableServices = @("DHCP", "EventLog", "wuauserv")


# Create list of services that should be disabled

$disableServices = @("BTAGService", "bthserv", "Browser", "MapsBroker", "lfsvc", "IISADMIN", "irmon", "ICS", "SharedAccess", "lltdsvc", "LxssManager", "FTPSVC", "MSiSCSI", "sshd", "PNRPsvc", "p2psvc", "p2pimsvc", "PNRPAutoReg", "Spooler", "wercplsupport", "RasAuto", "SessionEnv", "TermService", "UmRdpService", "RPC", "RpcLocator", "RemoteRegistry", "RemoteAccess", "LanmanServer", "simptcp", "SNMP", "sacsvr", "SSDPSRV", "upnphost", "WMSvc", "WerSvc", "Wecsvc", "WMPNetworkSvc", "iccsvc", "WpnService", "PushToInstall", "WS-Management", "WinRM", "W3SVC", "XboxGipSvc", "XblAuthManager", "XblGameSave", "XboxNetApiSvc", "SNMPTRAP", "LanmanWorkstation")




# Enable Services

# Loop through the services to enable
foreach($service in $enableServices) {

    # Check to see if the service exists on the system
    if(Get-Service $service -ErrorAction SilentlyContinue) {

        # Retrieve the status and start types of the service
        $start = Get-Service $service | Select-Object -ExpandProperty StartType
        $status = Get-Service $service | Select-Object -ExpandProperty Status

        # If the service does not start automatically, set it to automatic
        if($start -ne "Automatic") {
            Set-Service -Name $service -StartupType Automatic

            # Ensure the action completed
            $start = Get-Service $service | Select-Object -ExpandProperty StartType
            if($start -ne "Automatic") {
                Write-Host "Failed to set startup of $service to Automatic"
                Add-Content .\log.txt "`nAction $actionNumber. Set startup of service $service to Automatic (Fail)"
                $actionNumber += 1
            } else {
                Write-Host "Set startup type of $service to Automatic"
                Add-Content .\log.txt "`nAction $actionNumber. Set startup of service $service to Automatic (Success)"
                $actionNumber += 1
            }

            
        }

        # If the service isn't running, start the service
        if($status -ne "Running") {
            Start-Service $service

            # Ensure the action completed
            $status = Get-Service $service | Select-Object -ExpandProperty Status
            if($status -ne "Running") {
                Write-Host "Failed to start $service"
                Add-Content .\log.txt "`nAction $actionNumber. Started service $service (Fail)"
                $actionNumber += 1
            } else {
                Write-Host "Started $service"
                Add-Content .\log.txt "`nAction $actionNumber. Started service $service (Success)"
                $actionNumber += 1
            }

            
        }

    } else {
        Write-Host "Critical service $service not found"
        Add-Content .\log.txt "`nAction $actionNumber. Critical service $service not found"
    }
}








# Loop through the services to disable
foreach($service in $disableServices) {

    # Check to see if the service exists on the system
    if(Get-Service $service -ErrorAction SilentlyContinue) {

        # Retrieve the status and start types of the service
        $start = Get-Service $service | Select-Object -ExpandProperty StartType
        $status = Get-Service $service | Select-Object -ExpandProperty Status

        # If the service is not disabled, disable the service
        if($start -ne "Disabled") {
            Set-Service -Name $service -StartupType Disabled

            # Ensure the action completed
            $start = Get-Service $service | Select-Object -ExpandProperty StartType
            if($start -ne "Disabled") {
                Write-Host "Failed to set startup of $service to Disabled"
                Add-Content .\log.txt "`nAction $actionNumber. Set startup of service $service to Disabled (Fail)"
                $actionNumber += 1
            } else {
                Write-Host "Set startup type of $service to Disabled"
                Add-Content .\log.txt "`nAction $actionNumber. Set startup of service $service to Disabled (Success)"
                $actionNumber += 1
            }

            
        }

        # If the service is running, stop the service
        if($status -ne "Stopped") {
            Stop-Service $service -Force

            # Ensure the action completed
            $status = Get-Service $service | Select-Object -ExpandProperty Status
            if($status -ne "Stopped") {
                Write-Host "Failed to stop $service"
                Add-Content .\log.txt "`nAction $actionNumber. Stopped service $service (Fail)"
                $actionNumber += 1
            } else {
                Write-Host "Stopped $service"
                Add-Content .\log.txt "`nAction $actionNumber. Stopped service $service (Success)"
                $actionNumber += 1
            }

            
        }

    }
}





# Script has finished, leave space before next script executes
Add-Content .\log.txt "`n"
Add-Content .\log.txt "`n"
Add-Content .\log.txt "`n"
Add-Content .\log.txt "`n"
Add-Content .\log.txt "`n"





# Notes:

# Improve identification of instance specific services
# Research instance specific services
# Update harden services (STIG/CCM)
# Update to interact with registry instead of sc.exe
