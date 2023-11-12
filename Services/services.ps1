# Created By: JohnDavid Abe
# Created On: 7/9/23
# Last Modified: 11/12/23
# Title: services.ps1
# Description: Used to detect new/deleted services, as well as enable critical/disable malicious services on cyberpatriot competition images
# Version: 1.3



# Log the script running
$date = Get-Date
Add-Content .\log.txt "Script Ran: services.ps1"
Add-Content .\log.txt "Date: $date"
Add-Content .\log.txt ""

# Save the number of actions taken
$actionNumber = 0








# Read which system policies to apply from input
Write-Host "Which OS baseline would you like to import?"
$osInput = Read-Host -Prompt "[1] Windows 10 [2] Server 22"


# Import csv baselines based on the input
switch ($osInput) {
    "1" { $serviceCSV = Import-Csv -Path .\Baseline\win10.csv }
    "2" { $serviceCSV = Import-Csv -Path .\Baseline\server22.csv }
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
                

                # Ignore instance specific services
                if (-not($service -match '_.{3,}$')) {
		    $count += 1
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
    
        # Log that the search was a success
        Add-Content .\log.txt "`nAction $actionNumber. Searched for added system services (Success):"
        Add-Content .\log.txt ""
    
        # Loop through the system services
        foreach($service in $sysServices) {
            if(-not($baselineNames.contains($service))) {
            # If the service isn't on the system, log it
                $displayName = Get-Service $service | Select-Object -ExpandProperty DisplayName
                
                

                # Ignore instance specific services
                if (-not($service -match '_.{3,}$')) {
		    $count += 1
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







# Find modified services

# Retrieve all service (names) on the system
$sysServices = Get-Service


# Modified Services
$modifiedServices = @()

$count = 0


$confirm = Read-Host -Prompt "Would you like to search the system for modified services? (Y/N)"

# If user wants to identify modified services
if ($confirm -eq "Y") {

	# Compare services
	foreach ($service in $serviceCSV) {

    		# No need to audit new / removed services, will investigate from log anyways
    		if($addedServiceName.contains($service.Name) -or $removedServiceName.contains($service.Name)) { 
    			continue
    		}

		# Ignore instance specific services
                if ($service.Name -match '_.{3,}$') {
			continue
                }
		


    		$baselineStartType = $service.StartType
    		$baselineStatus = $service.Status

    		# Find the corresponding service in the current machine
    		$currentService = $sysServices | Where-Object { $_.Name -eq $service.Name }


    		# Compare StartType and Status
    		if (($baselineStartType -ne $currentService.StartType) -or ($baselineStatus -ne $currentService.Status)) {
        		$modifiedServices += $service.Name
			$count += 1
    		}
	}
}

Write-Host "Found $count modified services"


if($modifiedServices) {

	# Log that the search was a success
        Add-Content .\log.txt "`nAction $actionNumber. Searched for modified system services (Success):"
        Add-Content .\log.txt ""

	# Create a table of the identified service names and display names
        $tableData = for ($i = 0; $i -lt $modifiedServices.Count; $i++) {
            [PSCustomObject]@{
                Name = $modifiedServices[$i]
		DisplayName = Get-Service $modifiedServices[$i] | Select-Object -ExpandProperty DisplayName
            }
        }

        # Write the table to the logs
        $table = $tableData | Format-Table -AutoSize | Out-String
        Add-Content .\log.txt $table

} else {

	# Else log an error
	if($confirm -eq "Y") {
        	Add-Content .\log.txt "`nAction $actionNumber. Searched for modified system services (Found None)"
	}

}

$actionNumber += 1











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
    $serviceDisplay = Get-Service $service -ErrorAction SilentlyContinue | Select-Object -ExpandProperty DisplayName 

    # Check to see if the service exists on the system
    if(Get-Service $service -ErrorAction SilentlyContinue) {

        # Retrieve the status and start types of the service
        $start = Get-Service $service | Select-Object -ExpandProperty StartType
        $status = Get-Service $service | Select-Object -ExpandProperty Status

        # If the service is not disabled, disable the service
        if($start -ne "Disabled") {
            $confirm = Read-Host -Prompt "Would you like to disable $serviceDisplay (Y/N)"

            # If desired, disable the sevice
            if ($confirm -eq "Y") {
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
            } else {
                # Log ignorance of non-disabled service
                Add-Content .\log.txt "`nAction $actionNumber. Declined to set $service to Disabled"
                $actionNumber += 1
            }
            
        }

        

        # If the service is running, stop the service
        if($status -ne "Stopped") {
            $confirm = Read-Host -Prompt "Would you like to stop $serviceDisplay (Y/N)"

            # If desired, disable the sevice
            if ($confirm -eq "Y") {
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

            
            } else {
                # Log ignorance of non-stopped service
                Add-Content .\log.txt "`nAction $actionNumber. Declined to stop $service"
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
