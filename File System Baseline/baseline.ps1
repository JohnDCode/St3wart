# Created By: JohnDavid Abe
# Created On: 11/4/24
# Last Modified: 11/5/24
# Title: baseline.ps1
# Description: Baselines C:/Windows now using powershell instead of C
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
$files = Get-ChildItem C:/Windows/system32 -Recurse -Force -File -ErrorAction SilentlyContinue | 
    Where-Object { Test-FileCondition $_.FullName } | 
    Select-Object -ExpandProperty FullName



$fileObjs = $files | Select-Object @{Name='FullPath';Expression={$_}}
$fileObjs | Export-Csv .\baseline.csv -NoTypeInformation