# Created By: JohnDavid Abe
# Created On: 9/14/23
# Last Modified: 9/15/23
# Title: services.ps1
# Description: Used to compare a baseline csv of a file directory to a similar directory using file hashe
# Version: 1.0




# Log the script running
$date = Get-Date
Add-Content .\log.txt "Script Ran: scan.ps1"
Add-Content .\log.txt "Date: $date"
Add-Content .\log.txt ""

# Save the number of actions taken
$actionNumber = 0



# Read which system policies to apply from input
Write-Host "Which OS baseline would you like to import?"
$osInput = Read-Host -Prompt "[1] Windows 10  [2] Windows 11  [3] Server 19  [4] Server 22"


# Import csv baselines based on the input
switch ($osInput) {
    "1" { $baselineFile = Import-Csv -Path .\win10.csv }
    "2" { $baselineFile = Import-Csv -Path .\win11.csv }
    "3" { $baselineFile = Import-Csv -Path .\win19.csv }
    "4" { $baselineFile = Import-Csv -Path .\win22.csv }
}


# Define the directory to compare to
$scanPath = "C:/Windows/system32"

# Define the output log file paths
$dllLog = ".\dllScanLog.txt"
$mainLog = ".\scanLog.txt"

# Initialize arrays to store log entries for new, changed, and deleted files
$newModifiedFiles = @()
$deletedFiles = @()

# Get all files in the remote directory
$sysFiles = Get-ChildItem -Path $scanPath -File -Recurse

# Loop through each remote file
foreach ($sysFile in $sysFiles) {
    $path = $sysFile.FullName
    $hash = Get-FileHash $path

    # Find the matching baseline file entry by name
    $baselineEntry = $baselineFile | Where-Object { $_.FileName -eq $sysFile.Name }

    if ($baselineEntry) {
        # File exists in baseline, compare hashes
        if ($baselineEntry.Hash -ne $hash) {
            # File has changed
            $newModifiedFiles += "File changed: $($sysFile.Name)"
        }
    } else {
        # File doesn't exist in baseline (new file)
        $newModifiedFiles += "New file: $($sysFile.Name)"
    }
}

# Check for missing files
foreach ($baselineEntry in $baselineFile) {
    $baselineFilePath = $baselineEntry.FilePath
    if (-not (Test-Path -Path $baselineFilePath)) {
        $deletedFiles += "Missing file: $($baselineEntry.FileName)"
    }
}

# Filter log entries for .dll and .exe files
$dllEntries = $newModifiedFiles | Where-Object { $_ -match "\.dll$" }
$mainEntries = $newModifiedFiles | Where-Object { $_ -notmatch "\.dll$" }

# Write log entries to the respective log files
if ($dllEntries.Count -gt 0) {
    $dllEntries | Out-File -FilePath $dllLog
}

if ($exeEntries.Count -gt 0) {
    $exeEntries | Out-File -FilePath $mainLog
}

# Append deleted files to both log files if they match the criteria
if ($deletedFiles.Count -gt 0) {
    $deletedFiles | Out-File -FilePath $dllLog -Append
    $deletedFiles | Out-File -FilePath $mainLog -Append
}

Write-Host "Comparison and logging complete."
