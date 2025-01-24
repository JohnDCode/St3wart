# Created By: JohnDavid Abe
# Created On: 11/26/24
# Last Modified: 11/26/24
# Title: baseline.ps1
# Description: Uses c and powershell to baseline all of C:\Windows
# Version: 9.0



# Get all the files in C:\Windows using powershell

$path = ""


# Read which folder to baseline on the box

Write-Host "Which folder to baseline?"
$pathInput = Read-Host -Prompt "[1] Main (Windows) [2] Program Files [3] Program Files (x86) [4] Program Data"


# Import csv baselines based on the input (move it to root baselines directory so c binary knows which one to use)
switch ($pathInput) {
    "1" {
		$files = Get-ChildItem "C:\Windows\" -Force -File -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
 	}

    "2" {
		$files = Get-ChildItem "C:\Program Files\" -Force -File -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
	}

    "3" {
		$files = Get-ChildItem "C:\Program Files (x86)\" -Force -File -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
	}

    "4" {
		$files = Get-ChildItem "C:\ProgramData\" -Force -File -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
	}
}



# Save the files to a csv (with specific encoding so c binary can read it)
"File Path, File Hash" | Add-Content -Path .\Output\system.csv -Encoding UTF8
$files | Add-Content -Path .\Output\system.csv -Encoding UTF8



# Run the c binary to filter and diff system to baseline files
.\Binaries\baseline.exe
