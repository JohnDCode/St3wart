$content = Get-Content .\output.txt

$scanFlag = $false

$currentBaselineFiles = @()
$currentSystemFiles = @()

$addedFiles = @()
$deletedFiles = @()

foreach($line in $content) {
		
	if($line -eq "") {


		#$currentBaselineFiles = $currentBaselineFiles[1..($currentBaselineFiles.Length - 2)]
		#$currentSystemFiles = $currentSystemFiles[1..($currentSystemFiles.Length - 2)]
		
		Write-Host ""
		Write-Host $currentSystemFiles
		Write-Host $currentBaselineFiles

		$currentBaselineFiles = @()
		$currentSystemFiles = @()



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