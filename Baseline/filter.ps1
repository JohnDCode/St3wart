# Created By: JohnDavid Abe
# Created On: 11/24/23
# Last Modified: 11/24/23
# Title: shields.ps1
# Description: Used to filter output of baseline scripts
# Version: 1.0





$outputContent = Get-Content .\output.txt
foreach($line in $outputContent) {
	$signature = Get-AuthenticodeSignature -ErrorAction SilentlyContinue -FilePath $line
        $signer = $signature.SignerCertificate.Subject

        if (-not($signer -like "*Microsoft Corporation*")) {
		$line | Add-Content -Path .\Filter\filtered.txt
        }
}