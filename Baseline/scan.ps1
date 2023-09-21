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
$osInput = Read-Host -Prompt "[1] Windows 10 [2] Server 22"


# Import csv baselines based on the input
switch ($osInput) {
    "1" { $baselineFile = Import-Csv -Path .\win10.csv }
    "2" { $baselineFile = Import-Csv -Path .\server22.csv }
}


# Define the directory to compare to
$scanPath = "C:/Windows/system32/"

# Initialize arrays to store log entries for new, changed, and deleted files
$newFiles = @()
$modFiles = @()
$deletedFiles = @()



Write-Host "Getting files."

# Get all files in the new directory
$sysFiles = Get-ChildItem -Path $scanPath -File -Force




Write-Host "Got files."




# Loop through each sys file
foreach ($sysFile in $sysFiles) {
    $path = $sysFile.FullName
    $hash = (Get-FileHash $path).Hash

    # Find the matching baseline file entry by name
    $baselineEntry = $baselineFile | Where-Object { $_.FileName -eq $sysFile.Name }

    if ($baselineEntry) {
        # File exists in baseline, compare hashes
        if ($baselineEntry.Hash -ne $hash) {
            # File has changed
            $modFiles += $sysFile.name
            Write-Host $hash
        }
    } else {
        # File doesn't exist in baseline (new file)
        $newFiles += $sysFile.Name
    }
}



Write-Host "Found new and mod files."


$dirName = "Results - $(Get-Date -Format 'yyyy-MM-dd HH-mm-ss')"
New-Item -ItemType Directory -Name "Results - $(Get-Date -Format 'yyyy-MM-dd HH-mm-ss')"

# Check for missing files
foreach ($baselineEntry in $baselineFile) {
    $baselineFilePath = $baselineEntry.FilePath
    if (-not (Test-Path -Path $baselineFilePath)) {
        $deletedFiles += $baselineEntry.FileName
    }
}




Write-Host "Found deleted files."





$dllEntries = @()
$mainEntries = @()

# Filter modified log entries for .dll files
$dllEntries = $modFiles | Where-Object { $_ -match "\.dll$" }
$mainEntries = $modFiles | Where-Object { $_ -notmatch "\.dll$" }


Write-Host "Prepared lists through .dll and main files!."


# Write log entries to the respective log files
if ($dllEntries.Count -gt 0) {
    $dllPath = Join-Path -Path $dirName -ChildPath "dllLog.txt"
    "Modified .dll files from scan:" | Out-File -FilePath $dllPath -Append
    "" | Out-File -FilePath $dllPath -Append
    "" | Out-File -FilePath $dllPath -Append 
    $dllEntries | Out-File -FilePath $dllPath -Append
}

$mainPath = Join-Path -Path $dirName -ChildPath "mainLog.txt"


"Modified files from search:" | Out-File -FilePath $mainPath -Append
"" | Out-File -FilePath $mainPath -Append


$mainEntries | Out-File $mainPath -Append


"" | Out-File -FilePath $mainPath -Append
"" | Out-File -FilePath $mainPath -Append
"New files from search:" | Out-File -FilePath $mainPath -Append
"" | Out-File -FilePath $mainPath -Append



$newFiles | Out-File -FilePath $mainPath -Append


"" | Out-File -FilePath $mainPath -Append
"" | Out-File -FilePath $mainPath -Append
"Deleted files from search:" | Out-File -FilePath $mainPath -Append
"" | Out-File -FilePath $mainPath -Append



$deletedFiles | Out-File -FilePath $mainPath -Append


Write-Host "Comparison and logging complete."
