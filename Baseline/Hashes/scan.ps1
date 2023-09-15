# Define the baseline CSV file path (created by the previous script)
$baselineFilePath = "C:\Path\To\Baseline\File.csv"

# Read which system policies to apply from input
Write-Host "Which OS baseline would you like to import?"
$osInput = Read-Host -Prompt "[1] Windows 10  [2] Windows 11  [3] Server 19  [4] Server 22"


# Import csv baselines based on the input
switch ($osInput) {
    "1" { $baselineFilePath = ".\win10.csv" }
    "2" { $baselineFilePath = ".\win11.csv" }
    "3" { $baselineFilePath = ".\win19.csv" }
    "4" { $baselineFilePath = ".\win22.csv" }
}


# Define the directory path on the different system
$remoteDirectoryPath = "\\RemoteSystem\SharedFolder\Path"

# Define the output log file paths
$dllLogFilePath = "C:\Path\To\Output\DllLog.txt"
$exeLogFilePath = "C:\Path\To\Output\ExeLog.txt"

# Load the baseline file information from the CSV
$baselineFileInfo = Import-Csv -Path $baselineFilePath

# Initialize arrays to store log entries for new, changed, and deleted files
$newModifiedFiles = @()
$deletedFiles = @()

# Get all files in the remote directory
$remoteFiles = Get-ChildItem -Path $remoteDirectoryPath -File -Recurse

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
            $newModifiedFiles += "File changed: $($remoteFile.Name)"
        }
    } else {
        # File doesn't exist in baseline (new file)
        $newModifiedFiles += "New file: $($remoteFile.Name)"
    }
}

# Check for missing files
foreach ($baselineEntry in $baselineFileInfo) {
    $baselineFilePath = $baselineEntry.FilePath
    if (-not (Test-Path -Path $baselineFilePath)) {
        $deletedFiles += "Missing file: $($baselineEntry.FileName)"
    }
}

# Filter log entries for .dll and .exe files
$dllEntries = $newModifiedFiles | Where-Object { $_ -match "\.dll$" }
$exeEntries = $newModifiedFiles | Where-Object { $_ -match "\.exe$" }

# Write log entries to the respective log files
if ($dllEntries.Count -gt 0) {
    $dllEntries | Out-File -FilePath $dllLogFilePath
}

if ($exeEntries.Count -gt 0) {
    $exeEntries | Out-File -FilePath $exeLogFilePath
}

# Append deleted files to both log files if they match the criteria
if ($deletedFiles.Count -gt 0) {
    $deletedFiles | Out-File -FilePath $dllLogFilePath -Append
    $deletedFiles | Out-File -FilePath $exeLogFilePath -Append
}

Write-Host "Comparison and logging complete."
