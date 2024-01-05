
# Function to export registry values to a CSV path
function Export-RegistryToCSV {
    param(
        [string]$hive,
        [string]$subkey,
        [string]$outputCsv
    )


    try {


        # Open the registry key
        $key = Get-Item -LiteralPath "$hive\$subkey"


        # Create an array to store registry values
        $registryValues = @()

        # Iterate through values in the registry key
        foreach ($valueName in $key.GetValueNames()) {

            # Get the key and data
            $valueData = $key.GetValue($valueName)
            $valueType = $key.GetValueKind($valueName)

            # Create a custom object for each registry value with name, type, and value
            $registryValue = [PSCustomObject]@{
                Name = $valueName
                Type = $valueType
                Data = $valueData
            }

            # Add the custom object to the array
            $registryValues += $registryValue
        }

        # Export the array to the specified CSV
        $registryValues | Export-Csv -Path $outputCsv -NoTypeInformation
        Write-Host "Export successful. CSV file saved to: $outputCsv"


    # Catch errors
    } catch {
        Write-Host "Error: $_"
    }
}



# Export firewall rules registry key to csv

# Get hive and key where firewall rules are stored
$hive = "HKLM:"
$subkey = "SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules"

# Get export CSV
$outputCsv = "baseline.csv"


# Export the keys
Export-RegistryToCSV -hive $hive -subkey $subkey -outputCsv $outputCsv
