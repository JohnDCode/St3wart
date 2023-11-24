# Created By: JohnDavid Abe
# Created On: 11/24/23
# Last Modified: 11/24/23
# Title: filter.ps1
# Description: Used to filter output of baseline scripts
# Version: 1.0





$outputContent = Get-Content .\output.txt
foreach($line in $outputContent) {
	try {
        $signature = Get-AuthenticodeSignature -FilePath $line
        $signer = $signature.SignerCertificate.Subject

        if ($signer -like "*Microsoft Corporation*") {
            
        } else {
            $line | Add-Content -Path .\Filter\filtered.txt
        }
    }
    catch {
        Write-Host "Error: $_"
    }
}