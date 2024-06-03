# Created By: JohnDavid Abe
# Created On: 5/28/24
# Last Modified: 5/30/24
# Title: services.ps1
# Description: Uses the registry to find vulnerabilities in Windows services
# Version: 0.1



# Log the script running
$date = Get-Date
Add-Content .\log.txt "Script Ran: services.ps1"
Add-Content .\log.txt "Date: $date`n"


# Save the number of actions taken
$actionNumber = 0



# Function to extract registry service keys from a .reg file
function ExtractKeys {
    param (
        [string]$filePath
    )

	# Base File Path is all of the keys in \Services
	$tempbasePath = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services'
	$basePath = [regex]::Escape($tempbasePath)

    # Read the file content
    $fileContent = Get-Content -Path $filePath

    # Extract lines that start with "[" which denote registry keys within the specified base path

    $keys = $fileContent | Where-Object { $_ -match "^\[$basePath\\.*\]$" }

    # Remove the base path and subsequent brackets "[" and "]"
    $keys = $keys -replace "^\[$basePath\\", ""
    $keys = $keys -replace "\]$", ""

    # Extract only the base keys (the part before the first backslash)
    $baseKeys = $keys | ForEach-Object { ($_ -split '\\')[0] } | Sort-Object -Unique
    return $baseKeys
}


function ConvertHexToServiceList {
    param (
        [string]$hexString
    )

    # Extract the hex values from the input string
    $hexValues = $hexString -replace '^.*?hex\(\d+\):', '' -replace '\\', '' -split ',\s*'

    # Convert hex values to bytes and handle null-termination
    $byteArray = @()
    foreach ($hex in $hexValues) {
        if ($hex -match '^[0-9a-fA-F]{2}$') {
            $byteArray += [convert]::ToByte($hex, 16)
        }
    }

    # Convert the byte array to a UTF-16LE string (Windows registry encoding)
    $resultString = [System.Text.Encoding]::Unicode.GetString($byteArray)

    # Split the string by null characters (`0x00`)
    $strings = $resultString -split [char]0x00

    # Filter out empty strings and return
    $strings = $strings | Where-Object { $_ -ne '' }

    return $strings
}


function FindDependenciesRecursive {
    param (
        [array]$services,
        [string]$contentPath
    )

    $content = Get-Content $contentPath

    $dependencies = @()


    $inCritKey = $false
    $inDependency = $true
    $tempDependency = ""

    # Loop through each crit service and add the full registry path to it
    $critRegKeys = @()
    foreach($crit in $services) { $critRegKeys += ("[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\" + $crit + "]") }

    # Iterate through the reg file
    foreach($rawLine in $content) {

	    # 1st Type of Line, the line is the header for the base critical service reg key (ignore case sensitivity since reg keys are not case sensitive)
	    if($critRegKeys.ToLower() -contains $rawLine.ToLower()) {
		    $inCritKey = $true
	
	    # 2nd Type of Line, the line is the header to a different reg key
	    } elseif ($rawLine.StartsWith("[")) {
		    $inCritKey = $false

	    # 3rd Type of Line, the line is a value under the base reg key
	    } elseif ($inCritKey) {

		    # In crit service key, and at the beginning of the depend on service value
		    if($rawLine.Contains("DependOnService")) {
			    $inDependency = $true
			    $tempDependency = $rawLine

		    # In crit service key but moved on from depend on service value
		    } elseif ($rawLine.Contains("=")) {
			    $inDependency = $false
			    if($tempDependency -ne "") {
				    $decodedList = (ConvertHexToServiceList -hexString $tempDependency)
				    $dependencies += $decodedList
				    $tempDependency = ""
			    }
	
		    # In continuation of the depend on service value
		    } elseif ($inDependency) {
			    $tempDependency += $rawLine
		    }
	    }
    }

    if($dependencies.Length -eq 0) {
        return $dependencies
    } else {
	$new = $dependencies + (FindDependenciesRecursive -services $dependencies -contentPath $contentPath)
    	return $new
    }
    

}


function SetRegValue {
    param (
        [string]$RegistryPath,
        [string]$ValueName,
        [string]$ValueData
    )

    try {
        # Check if the registry path exists
        if (Test-Path -Path $RegistryPath -ErrorAction SilentlyContinue) {
            # Set the registry value
            Set-ItemProperty -Path $RegistryPath -Name $ValueName -Value $ValueData -ErrorAction SilentlyContinue
        } else {
            Write-Error "Registry path $RegistryPath does not exist."
        }
    } catch {
        Write-Error "An error occurred: $_"
    }
}



# Whitespace
Write-Host ""


# Read which baseline to load from input
Write-Host "Which OS baseline would you like to import?"
$osInput = Read-Host -Prompt "[1] Windows 11 [2] Server 22"


# Import csv baselines based on the input
switch ($osInput) {
    "1" {
	    # Baseline of services for windows 11
		$baseKeys = ExtractKeys -filePath ".\Baselines\Windows 11\base.reg"
		$instanceKeys = Get-Content ".\Baselines\Windows 11\instanceBasedServices.txt"
        Add-Content .\log.txt "Selected Windows 11 baseline`n"
 	}

    "2" {
		# Baseline of services for server 22
    	$baseKeys = ExtractKeys -filePath ".\Baselines\Server 22\base.reg"
		$instanceKeys = Get-Content ".\Baselines\Server 22\instanceBasedServices.txt"
        Add-Content .\log.txt "Selected Server 22 baseline`n"
	}
}

# Whitespace
Write-Host ""


# Ensure the system reg keys is exported
$proceedConfirm = Read-Host -Prompt "Export the HKLM\SYSTEM\CurrentControlSet\Services reg key as system.reg (Y/N)"


# Confirm system reg keys are exported
switch ($proceedConfirm) {
    "N" { 
	    exit
 	}
}


# Whitespace
Write-Host ""


# Read the critical services from the user
$critServices = @()

Write-Host "Enter critical services (service name not display name's):"
while ($true) {
    $tempCrit = Read-Host -Prompt "Enter 'exit' to continue"
	if($tempCrit -eq "exit") {
		break
	}
	$critServices += $tempCrit
}


# Extract the list of services on the system
$systemKeys = ExtractKeys -filePath .\system.reg




# Loop through the raw system reg keys data and look for dependenices (recursive: find dependencies of each dependency)
$rawSystemPath = ".\system.reg"
if($critServices.Length -ne 0) {
    $dependencies = FindDependenciesRecursive -services $critServices -contentPath $rawSystemPath
} else {
    $dependencies = @()
}


# Whitespace
Write-Host ""
Write-Host ""

$dependLen = $dependencies.Length
Write-Host "Found $dependLen critical service dependencies: "
Add-Content .\log.txt "Found $dependLen critical service dependencies for critical services: $critServices`n"
$dependencies


# Store the services that are not instance based
$filteredKeys = @()

# Stores the services that are instance based
$cloudServices = @()

# Filter the system services for cloud based (instance based) services
foreach($service in $systemKeys) {
	
	# Used to save if the service was found to be instance based
	$temp = $true

	# Compare each system key to the instance based keys
	foreach($instance in $instanceKeys) {
		# If the service is such, ensure to not add it to the filtered list
		if($service.Contains($instance)) {
			$cloudServices += $service
			$temp = $false
			break;
		}
	}

	if($temp) {
		$filteredKeys += $service
	}
}

# Find the lengths of the cloud services found on system and the baseline
$cloudLen = $cloudServices.Length
$baseCloudLen = $instanceKeys.Length

# Whitespace
Write-Host ""
Write-Host ""

# Display the cloud services found
Write-Host "$cloudLen/$baseCloudLen cloud services found: "
Add-Content .\log.txt  "$cloudLen/$baseCloudLen cloud services found`n"

foreach($cloud in $cloudServices) { Write-Host $cloud }


# Whitespace
Write-Host ""
Write-Host ""


# Find keys (services) on the system that are not in the baseline
$newKeys = Compare-Object -ReferenceObject $baseKeys -DifferenceObject $filteredKeys -PassThru | Where-Object { $_ -notin $baseKeys }
$newKeysLen = $newKeys.Length
Write-Host "Found $newKeysLen new services"
Add-Content .\log.txt  "Found $newKeysLen new services`n"
$newKeys

# Whitespace
Write-Host ""
Write-Host ""
Add-Content .\log.txt  "`n`n"

# Enable services and also dependencies and critical services
$enableServices = @("DHCP", "EventLog", "wuauserv", "mpssvc", "WinDefend", "WdNisSvc")
$enableServices += FindDependenciesRecursive -services $enableServices -contentPath $rawSystemPath
$enableServices += $critServices
$enableServices += $dependencies

# Remove duplicates in the list for clarity
$enableServices = $enableServices | Select-Object -Unique

# Reverse the list of services to enable (want to enable dependencies first, than the critical services themselves)
[array]::Reverse($enableServices)

$disableServices = @("tapisrv", "PlugPlay", "NetTcpPortSharing", "BTAGService", "bthserv", "MapsBroker", "lfsvc", "IISADMIN", "irmon", "ICS", "SharedAccess", "lltdsvc", "LxssManager", "FTPSVC", "MSiSCSI", "sshd", "PNRPsvc", "p2psvc", "p2pimsvc", "PNRPAutoReg", "Spooler", "wercplsupport", "RasAuto", "SessionEnv", "TermService", "UmRdpService", "RPC", "RpcLocator", "RemoteRegistry", "RemoteAccess", "LanmanServer", "simptcp", "SNMP", "sacsvr", "SSDPSRV", "upnphost", "WMSvc", "WerSvc", "Wecsvc", "WMPNetworkSvc", "iccsvc", "WpnService", "PushToInstall", "WS-Management", "WinRM", "W3SVC", "XboxGipSvc", "XblAuthManager", "XblGameSave", "XboxNetApiSvc", "SNMPTRAP", "LanmanWorkstation")


Write-Host "Starting and setting critical services, their dependencies, and other vital services to automatic"




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
            # Set-Service -Name $service -StartupType Automatic
            # Set using the registry instead of sc
            SetRegValue -RegistryPath ("HKLM:\SYSTEM\CurrentControlSet\Services\" + $service) -ValueName "Start" -ValueData "2"

            # Ensure the action completed
            $start = Get-Service $service | Select-Object -ExpandProperty StartType
            if($start -ne "Automatic") {
                Write-Host "Failed to set startup of $service to Automatic"
                Add-Content .\log.txt "Action $actionNumber. Failed to set startup of $service to Automatic`n"
            } else {
                Add-Content .\log.txt "Action $actionNumber. Set startup of $service to Automatic`n"
                
            }

            $actionNumber += 1

        }

        # If the service isn't running, start the service
        if($status -ne "Running") {
            Start-Service $service

            # Ensure the action completed
            $status = Get-Service $service | Select-Object -ExpandProperty Status
            if($status -ne "Running") {
                Write-Host "Failed to start $service"
                Add-Content .\log.txt "Action $actionNumber. Failed to start $service`n"
            } else {
                Add-Content .\log.txt "Action $actionNumber. Started $service`n"
            }

            $actionNumber += 1
            
        }

    } else {
        Write-Host "Service $service not found"
    }
}



# Set recovery actions (do after startup types/status set to see output of sc.exe clearly)
Write-Host "Setting critical service recovery actions `n"

# Setting recovery actions for each important service
foreach($service in $enableServices) {

    # Try and set the recovery actions (suppress output, catch will log errors)
    $null = sc.exe failure $service reset= 0 actions= restart/60000/restart/60000/restart/60000

    if($?) {
        # Log success
        Add-Content .\log.txt "Action $actionNumber. Set recovery actions of $service`n"
    } else {
        # Catch sc.exe errors and log properly
        Add-Content .\log.txt "Action $actionNumber. Failed to set recovery actions of $service`n"
        Write-Host "Couldn't set the recovery actions of $service to restart"
    }

    $actionNumber += 1
    
}



# Whitespace
Write-Host ""
Write-Host ""
Add-Content .\log.txt "`n`n"


Write-Host "Stopping and disabling other services to reduce attack surface"



# Loop through the services to disable
foreach($service in $disableServices) {

    # Check to see if the service exists on the system
    if(Get-Service $service -ErrorAction SilentlyContinue) {

        # Retrieve the status and start types of the service
        $start = Get-Service $service | Select-Object -ExpandProperty StartType
        $status = Get-Service $service | Select-Object -ExpandProperty Status

        # If the service is not disabled, disable the service
        if($start -ne "Disabled") {


            # Ensure the service is not critical or a dependency
            if (-not($enableServices.Contains($service))) {
                # Set-Service -Name $service -StartupType Disabled
                # Set using the registry instead of sc
                SetRegValue -RegistryPath ("HKLM:\SYSTEM\CurrentControlSet\Services\" + $service) -ValueName "Start" -ValueData "4"
                
                # Ensure the action completed
                $start = Get-Service $service | Select-Object -ExpandProperty StartType
                if($start -ne "Disabled") {
                    Write-Host "Failed to set startup of $service to Disabled"
                    Add-Content .\log.txt "Action $actionNumber. Failed to set startup of $service to Disabled`n"
                } else {
                    Add-Content .\log.txt "Action $actionNumber. Set startup of $service to Disabled`n"
                }

                $actionNumber += 1

            } else {
                # Ignoring service because it is critical
		        Write-Host "Not disabling $service as it is critical"
            }
            
        }

        

        # If the service is running, stop the service
        if($status -ne "Stopped") {

            # Ensure the service is not critical or a dependency
            if (-not($enableServices.Contains($service))) {
                Stop-Service $service -Force

                # Ensure the action completed
                $status = Get-Service $service | Select-Object -ExpandProperty Status
                if($status -ne "Stopped") {
                    Write-Host "Failed to stop $service"
                    Add-Content .\log.txt "Action $actionNumber. Failed to stop $service`n"
                } else {
                    Add-Content .\log.txt "Action $actionNumber. Stopped $service`n"
                }

                $actionNumber += 1

            
            } else {
                # Ignoring service because it is critical
		        Write-Host "Not stopping $service as it is critical"
            }

        }
    }
}



# Whitespace
Write-Host ""
Write-Host ""
Add-Content .\log.txt "`n`n"
Add-Content .\log.txt "`n`n"
Add-Content .\log.txt "`n`n"
Add-Content .\log.txt "`n`n"
Add-Content .\log.txt "`n`n"


# Notes:
# Figure out a way to handle browser (features)
# Review services to disable and enable
