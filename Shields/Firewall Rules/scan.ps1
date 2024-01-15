
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

# Registry key for firewall rules
$hive = "HKLM:"
$subkey = "SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules"

# Paths for system and baseline firewall rules CSV's
$outputCsv = "system.csv"
$baselineCsv = "baseline.csv"


# Export system firewall rules to the CSV
Export-RegistryToCSV -hive $hive -subkey $subkey -outputCsv $outputCsv


# Get the baseline firewall rules as a list (lines) and as one large collection of strings (raw)
$baselineLines = Get-Content $baselineCsv
$rawBaseline = Get-Content $baselineCsv -Raw


# Get the system firewall rules as a list (lines) and as one large collection of strings (raw)
$systemLines = Get-Content $outputCsv
$rawSystem = Get-Content $outputCsv -Raw

# Save the flagged rules in lists for later to extract executables
$allRules = @()


# Find added rules by searching through each line in the list of system rules and checking to see if the line exists in the raw baseline string
"Added Rules: " | Out-File .\output.txt -Append
foreach($rule in $systemLines) {
    if(!($rawBaseline.Contains($rule))) {
        $rule | Out-File .\output.txt -Append
        $allRules += $rule

    }
}

"" | Out-File .\output.txt -Append
"" | Out-File .\output.txt -Append


# Find deleted rules by searching through each line in the list of baseline rules and checking to see if the line exists in the raw system string
"Deleted Rules: " | Out-File .\output.txt -Append
foreach($rule in $baselineLines) {
	if(!($rawSystem.Contains($rule))) {
        $rule | Out-File .\output.txt -Append
        $allRules += $rule
    }
}

"" | Out-File .\output.txt -Append
"" | Out-File .\output.txt -Append


foreach($rule in $allRules) {

    # Use regular expression to extract text between "|App=" and "|"
    $match = [regex]::Match($rule, '\|App=(.*?)\|')

    # Check if a match is found
    if ($match.Success) {
        # Extracted text is in the captured group at index 1
        $match.Groups[1].Value | Out-File .\output.txt -Append
    }

}
