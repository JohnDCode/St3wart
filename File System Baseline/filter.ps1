# Created By: JohnDavid Abe
# Created On: 11/24/23
# Last Modified: 11/24/23
# Title: filter.ps1
# Description: Used to filter output of baseline scripts
# Version: 1.0





$outputFile = Read-Host -Prompt "Path to file to filter"

$outputContent = Get-Content $outputFile
$firstFlag = 0


# Filter out files not signed by microsoft
foreach($line in $outputContent) {
	
	if($firstFlag -lt 2) {
		$firstFlag = $firstFlag + 1
		continue;
	}

	try {
        $signature = Get-AuthenticodeSignature -FilePath $line -ErrorAction SilentlyContinue
        $signer = $signature.SignerCertificate.Subject
	$bool = $signer -like "*Microsoft Corporation*"

        if (-not($bool)) {
            $line | Add-Content -Path .\filter.txt
        }
    }
    catch {
        Write-Host "Error: $_"
    }
}



# Sort files by file extension


# Get the now filtered content
$filePaths = Get-Content .\filter.txt

# Create separate lists based on file types
$exeFiles = @()
$scriptFiles = @()
$msiFiles = @()
$dllFiles = @()
$txtFiles = @()

$otherFiles = @()



# Classify each file path based on its extension
foreach ($path in $filePaths) {
    if ($path -match "\.exe$") {
        $exeFiles += $path
    } elseif (($path -match "\.ps1$") -or ($path -match "\.bat$") -or ($path -match "\.vbs$") -or ($path -match "\.cmd$")) {
        $scriptFiles += $path
    } elseif ($path -match "\.msi$") {
        $msiFiles += $path
    } elseif ($path -match "\.dll$") {
        $dllFiles += $path
    } elseif ($path -match "\.txt$") {
        $txtFiles += $path
    } else {
        $otherFiles += $path
    }
}

# Combine the lists in the desired order
$sortedFilePaths = $exeFiles + "`n" + $scriptFiles + "`n" + $msiFiles + "`n" + $dllFiles + "`n" + $txtFiles + "`n" + $otherFiles

# Overwrite the input file with the sorted paths
$sortedFilePaths | Set-Content -Path .\filter.txt

Write-Output "File paths have been filtered / sorted and saved back to filter.txt"


