
# Function to export registry values to CSV
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
            $valueData = $key.GetValue($valueName)
            $valueType = $key.GetValueKind($valueName)

            # Create a custom object for each registry value
            $registryValue = [PSCustomObject]@{
                Name = $valueName
                Type = $valueType
                Data = $valueData
            }

            # Add the custom object to the array
            $registryValues += $registryValue
        }

        # Export the array to CSV
        $registryValues | Export-Csv -Path $outputCsv -NoTypeInformation
        Write-Host "Export successful. CSV file saved to: $outputCsv"

    } catch {
        Write-Host "Error: $_"
    }
}

# Example usage
$hive = "HKLM:"
$subkey = "SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules"
$outputCsv = "baseline.csv"

Export-RegistryToCSV -hive $hive -subkey $subkey -outputCsv $outputCsv
