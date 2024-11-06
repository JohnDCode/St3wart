# Created By: JohnDavid Abe
# Created On: 11/4/24
# Last Modified: 11/5/24
# Title: scan.ps1
# Description: Scans C:/Windows now using powershell instead of C based on baseline/backup
# Version: 0.1



# Tests if file is signed by microsoft or from specific directories
function Test-FileCondition {
    param (
        [string]$filePath
    )

    $signature = Get-AuthenticodeSignature -FilePath $filePath -ErrorAction SilentlyContinue
    $signer = $signature.SignerCertificate.Subject


    if ((-not($signer -like "*Microsoft Corporation*"))) { # -and (-not($filePath -like "*C:\Windows\servicing*")) -and (-not($filePath -like "*C:\Windows\WinSxS*")) -and (-not($filePath -like "*C:\Windows\SoftwareDistribution*")) -and (-not($filePath -like "*C:\Windows\assembly\NativeImages_*"))) {
	return $true
    }
    return $false
}


# Get all files recursively and filter based on the function
$files = Get-ChildItem C:/Windows/system32 -Recurse -File -Force -ErrorAction SilentlyContinue | 
    Where-Object { Test-FileCondition $_.FullName } | 
    Select-Object -ExpandProperty FullName



$fileObjs = $files | Select-Object @{Name='FullPath';Expression={$_}}
$fileObjs | Export-Csv .\system.csv -NoTypeInformation


$diff = Compare-Object (Get-Content .\baseline.csv) (Get-Content .\system.csv)


# Define the output file
$outputFile = ".\diff.txt"



# Function to write a section to the file
function Write-Section {
    param (
        [string]$Indicator,
        [string]$Title
    )
    
    # Write the section title
    Add-Content -Path $outputFile -Value "`n$Title`n" -NoNewline
    
    # Filter and write the relevant differences
    $diffedFiles = $diff | Where-Object { $_.SideIndicator -eq $Indicator } | Select-Object -ExpandProperty InputObject

    # Create separate lists based on file types
    $exeFiles = @()
    $scriptFiles = @()
    $msiFiles = @()
    $dllFiles = @()
    $txtFiles = @()

    $otherFiles = @()

    foreach($item in $diffedFiles) {

	$item = $item.Trim('"')

	
           
   		 if ($item -match "\.exe$") {
        		$exeFiles += $item
    		} elseif (($item -match "\.ps1$") -or ($item -match "\.bat$") -or ($item -match "\.vbs$") -or ($item -match "\.cmd$")) {
        		$scriptFiles += $item
    		} elseif ($item -match "\.msi$") {
        		$msiFiles += $item
    		} elseif ($item -match "\.dll$") {
        		$dllFiles += $item
    		} elseif ($item -match "\.txt$") {
        		$txtFiles += $item
    		} else {
        		$otherFiles += $item
    		}
	
    }

	$exeFiles + "`n" + $scriptFiles + "`n" + $msiFiles + "`n" + $dllFiles + "`n" + $txtFiles + "`n" + $otherFiles | Add-Content -Path $outputFile -Force 
    
}

# Write sections based on side indicators
Write-Section "=>" "New Files on System:"
#"`n`n`n`n`n`n" | Add-Content -Path $outputFile -Force 
#Write-Section "<=" "Deleted Files from Baseline:"
