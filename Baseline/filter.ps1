# Created By: JohnDavid Abe
# Created On: 11/24/23
# Last Modified: 11/24/23
# Title: filter.ps1
# Description: Used to filter output of baseline scripts
# Version: 1.0





$outputFile = Read-Host -Prompt "Path to file to filter"

$outputContent = Get-Content $outputFile

foreach($line in $outputContent) {
	try {
        $signature = Get-AuthenticodeSignature -FilePath $line
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