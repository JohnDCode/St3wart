# Define the baseline CSV file path (created by the previous script)
$baselineFilePath = ".\output.csv"

# Define the directory path on the different system
$remoteDirectoryPath = "C:/Windows/system32/"

# Define the output log file path
$outputLogFilePath = ".\log.txt"

# Load the baseline file information from the CSV
$baselineFileInfo = Import-Csv -Path $baselineFilePath

# Initialize an empty array to store log entries
$logEntries = @()

# Get all files in the remote directory
$remoteFiles = Get-ChildItem -Path $remoteDirectoryPath -File

Write-Host "Gotten files"

# Loop through each remote file
foreach ($remoteFile in $remoteFiles) {
    $remoteFilePath = $remoteFile.FullName
    $remoteHash = Get-FileHash -Path $remoteFilePath -Algorithm SHA256

    # Find the matching baseline file entry by name
    $baselineEntry = $baselineFileInfo | Where-Object { $_.FileName -eq $remoteFile.Name }

    if ($baselineEntry) {
        # File exists in baseline, compare hashes
        if ($baselineEntry.Hash -ne $remoteHash.Hash) {
            # File has changed
            $logEntries += "File changed: $($remoteFile.Name)"
        }
    } else {
        # File doesn't exist in baseline (new file)
        $logEntries += "New file: $($remoteFile.Name)"
    }
}

# Check for missing files
foreach ($baselineEntry in $baselineFileInfo) {
    $baselineFilePath = $baselineEntry.FilePath
    if (-not (Test-Path -Path $baselineFilePath)) {
        $logEntries += "Missing file: $($baselineEntry.FileName)"
    }
}

# Write log entries to the output log file
$logEntries | Out-File -FilePath $outputLogFilePath -Append

Write-Host "Comparison and logging complete. Check $outputLogFilePath for results."
