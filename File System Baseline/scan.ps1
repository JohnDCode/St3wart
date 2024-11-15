# Created By: JohnDavid Abe
# Created On: 11/4/24
# Last Modified: 11/5/24
# Title: baseline.ps1
# Description: Scans C:/Windows for use by c script now using powershell instead of C
# Version: 0.1


# Get all files recursively and filter based on the function
$files = Get-ChildItem C:/Windows -Recurse -Force -File -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName



$fileObjs = $files | Select-Object @{Name='FullPath';Expression={$_}}
$fileObjs | Export-Csv .\system.csv -NoTypeInformation
