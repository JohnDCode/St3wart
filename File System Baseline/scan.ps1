# Get all files recursively and filter based on the function
$files = Get-ChildItem C:/Windows/ -Recurse -File -Force -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName



$fileObjs = $files | Select-Object @{Name='FullPath';Expression={$_}}
$fileObjs | Export-Csv .\system.csv -NoTypeInformation


fc.exe /A .\baseline.csv .\system.csv > output.txt

$content = Get-Content .\output.txt
$content = $content[1..$($content.Length - 1)]

$scanFlag = $false

$currentBaselineFiles = @()
$currentSystemFiles = @()

$addedFiles = @()
$deletedFiles = @()

foreach($line in $content) {
		
	if($line -eq "") {


		if($currentBaselineFiles.Length -gt $currentSystemFiles.Length) {
			$currentBaselineFiles = $currentBaselineFiles[1..($currentBaselineFiles.Length - 2)]
			$deletedFiles += $currentBaselineFiles
		} else {
			$currentSystemFiles = $currentSystemFiles[1..($currentSystemFiles.Length - 2)]
			$addedFiles += $currentSystemFiles
		}
	

		$currentBaselineFiles = @()
		$currentSystemFiles = @()
		$scanFlag = (-not($scanFlag))



	} elseif ($line -match '\*\*\*\*\*') {
		$scanFlag = (-not($scanFlag))
	} else {
		if($scanFlag) {
			$currentBaselineFiles += $line
		} else {
			$currentSystemFiles += $line
		}
	}

}



# Added files
$exeFiles = @()
$scriptFiles = @()
$msiFiles = @()
$dllFiles = @()
$txtFiles = @()

$otherFiles = @()


foreach($added in $addedFiles) {

	$added = $added.Trim('"')

	$signature = Get-AuthenticodeSignature -FilePath $added -ErrorAction SilentlyContinue
    	$signer = $signature.SignerCertificate.Subject


    	if ((-not($signer -like "*Microsoft Corporation*"))) { # -and (-not($added -like "*C:\Windows\servicing*")) -and (-not($added -like "*C:\Windows\WinSxS*")) -and (-not($added -like "*C:\Windows\SoftwareDistribution*")) -and (-not($added -like "*C:\Windows\assembly\NativeImages_*"))) {

		if ($added -match "\.exe$") {
        		$exeFiles += $added
    		} elseif (($added -match "\.ps1$") -or ($added -match "\.bat$") -or ($added -match "\.vbs$") -or ($added -match "\.cmd$")) {
        		$scriptFiles += $added
    		} elseif ($added -match "\.msi$") {
        		$msiFiles += $added
    		} elseif ($added -match "\.dll$") {
        		$dllFiles += $added
    		} elseif ($added -match "\.txt$") {
        		$txtFiles += $added
    		} else {
        		$otherFiles += $added
    		}
    	}

}
"Added Files from Baseline: " + "`n" + $exeFiles + "`n" + $scriptFiles + "`n" + $msiFiles + "`n" + $dllFiles + "`n" + $txtFiles + "`n" + $otherFiles | Add-Content -Path .\diff.txt -Force







# Deleted files
$exeFiles = @()
$scriptFiles = @()
$msiFiles = @()
$dllFiles = @()
$txtFiles = @()

$otherFiles = @()


foreach($deleted in $deletedFiles) {

	$deleted = $deleted.Trim('"')

	$signature = Get-AuthenticodeSignature -FilePath $deleted -ErrorAction SilentlyContinue
    	$signer = $signature.SignerCertificate.Subject


    	if ((-not($signer -like "*Microsoft Corporation*"))) { # -and (-not($deleted -like "*C:\Windows\servicing*")) -and (-not($deleted -like "*C:\Windows\WinSxS*")) -and (-not($deleted -like "*C:\Windows\SoftwareDistribution*")) -and (-not($deleted -like "*C:\Windows\assembly\NativeImages_*"))) {

		if ($deleted -match "\.exe$") {
        		$exeFiles += $deleted
    		} elseif (($deleted -match "\.ps1$") -or ($deleted -match "\.bat$") -or ($deleted -match "\.vbs$") -or ($deleted -match "\.cmd$")) {
        		$scriptFiles += $deleted
    		} elseif ($deleted -match "\.msi$") {
        		$msiFiles += $deleted
    		} elseif ($deleted -match "\.dll$") {
        		$dllFiles += $deleted
    		} elseif ($deleted -match "\.txt$") {
        		$txtFiles += $deleted
    		} else {
        		$otherFiles += $deleted
    		}
    	}

}
"`n" + "`n" + "`n" + "Deleted Files from Baseline: " + "`n" + $exeFiles + "`n" + $scriptFiles + "`n" + $msiFiles + "`n" + $dllFiles + "`n" + $txtFiles + "`n" + $otherFiles | Add-Content -Path .\diff.txt -Force 