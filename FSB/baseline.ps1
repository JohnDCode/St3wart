# Created By: JohnDavid Abe
# Created On: 11/26/24
# Last Modified: 11/26/24
# Title: baseline.ps1
# Description: Uses c and powershell to baseline all of C:\Windows
# Version: 9.0



# Get all the files in C:\Windows using powershell

$files = Get-ChildItem C:\Windows\ -Force -File -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName


# Save the files to a csv (with specific encoding so c binary can read it)
"File Path, File Hash" | Add-Content -Path .\Output\system.csv -Encoding UTF8
$files | Add-Content -Path .\Output\system.csv -Encoding UTF8



# Run the c binary to filter and diff system to baseline files
.\Binaries\baseline.exe
