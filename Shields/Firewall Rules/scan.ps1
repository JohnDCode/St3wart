
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
$outputCsv = "system.csv"
$baselineCsv = "baseline.csv"

Export-RegistryToCSV -hive $hive -subkey $subkey -outputCsv $outputCsv


$baselineLines = Get-Content $baselineCsv
$rawBaseline = Get-Content $baselineCsv -Raw


$systemLines = Get-Content $outputCsv
$rawSystem = Get-Content $outputCsv -Raw


Write-Host "Deleted Rules: "
foreach($rule in $baselineLines) {
	if(!($rawSystem.Contains($rule))) { Write-Host $rule }
}


Write-Host "Added Rules: "
foreach($rule in $systemLines) {
	if(!($rawBaseline.Contains($rule))) { Write-Host $rule }
}
