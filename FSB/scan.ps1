# Created By: JohnDavid Abe
# Created On: 11/26/24
# Last Modified: 11/26/24
# Title: scan.ps1
# Description: Uses c and powershell to scan and filter C:/Windows
# Version: 9.0



# Get all the files in C:\Windows using powershell


Write-Host "Which folder to baseline?"
$pathInput = Read-Host -Prompt "[1] Main (Windows) [2] Program Files [3] Program Files (x86) [4] Program Data"


# Import csv baselines based on the input (move it to root baselines directory so c binary knows which one to use)
switch ($pathInput) {
    "1" {
		$files = Get-ChildItem "C:\Windows\" -Force -File -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
		Move-Item -Path ".\Baselines\Windows 10\Main\baseline.csv" -Destination ".\Baselines\Windows 10\baseline.csv"
		Move-Item -Path ".\Baselines\Windows 11\Main\baseline.csv" -Destination ".\Baselines\Windows 11\baseline.csv"
		Move-Item -Path ".\Baselines\Sever 19\Main\baseline.csv" -Destination ".\Baselines\Server 19\baseline.csv"
		Move-Item -Path ".\Baselines\Server 22\Main\baseline.csv" -Destination ".\Baselines\Server 22\baseline.csv"
 	}

    "2" {
		$files = Get-ChildItem "C:\Program Files\" -Force -File -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
		Move-Item -Path ".\Baselines\Windows 10\ProgramFiles\baseline.csv" -Destination ".\Baselines\Windows 10\baseline.csv"
		Move-Item -Path ".\Baselines\Windows 11\ProgramFiles\baseline.csv" -Destination ".\Baselines\Windows 11\baseline.csv"
		Move-Item -Path ".\Baselines\Sever 19\ProgramFiles\baseline.csv" -Destination ".\Baselines\Server 19\baseline.csv"
		Move-Item -Path ".\Baselines\Server 22\ProgramFiles\baseline.csv" -Destination ".\Baselines\Server 22\baseline.csv"
	}

    "3" {
		$files = Get-ChildItem "C:\Program Files (x86)\" -Force -File -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
		Move-Item -Path ".\Baselines\Windows 10\ProgramFiles86\baseline.csv" -Destination ".\Baselines\Windows 10\baseline.csv"
		Move-Item -Path ".\Baselines\Windows 11\ProgramFiles86\baseline.csv" -Destination ".\Baselines\Windows 11\baseline.csv"
		Move-Item -Path ".\Baselines\Sever 19\ProgramFiles86\baseline.csv" -Destination ".\Baselines\Server 19\baseline.csv"
		Move-Item -Path ".\Baselines\Server 22\ProgramFiles86\baseline.csv" -Destination ".\Baselines\Server 22\baseline.csv"
	}

    "4" {
		$files = Get-ChildItem "C:\ProgramData\" -Force -File -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
		Move-Item -Path ".\Baselines\Windows 10\ProgramData\baseline.csv" -Destination ".\Baselines\Windows 10\baseline.csv"
		Move-Item -Path ".\Baselines\Windows 11\ProgramData\baseline.csv" -Destination ".\Baselines\Windows 11\baseline.csv"
		Move-Item -Path ".\Baselines\Sever 19\ProgramData\baseline.csv" -Destination ".\Baselines\Server 19\baseline.csv"
		Move-Item -Path ".\Baselines\Server 22\ProgramData\baseline.csv" -Destination ".\Baselines\Server 22\baseline.csv"
	}
}


# Save the files to a csv (with specific encoding so c binary can read it)
"File Path, File Hash" | Add-Content -Path .\Output\system.csv -Encoding UTF8
$files | Add-Content -Path .\Output\system.csv -Encoding UTF8



# Whitespace
Write-Host ""


# Read which baseline to load from input
Write-Host "Which OS baseline would you like to import?"
$osInput = Read-Host -Prompt "[1] Windows 10 [2] Windows 11 [3] Server 19 [4] Server 22"


# Import csv baselines based on the input (move it to root baselines directory so c binary knows which one to use)
switch ($osInput) {
    "1" {
		Move-Item -Path ".\Baselines\Windows 10\baseline.csv" -Destination ".\Baselines\baseline.csv"
 	}

    "2" {
		Move-Item -Path ".\Baselines\Windows 11\baseline.csv" -Destination ".\Baselines\baseline.csv"
	}

    "3" {
		Move-Item -Path ".\Baselines\Server 19\baseline.csv" -Destination ".\Baselines\baseline.csv"
	}

    "4" {
		Move-Item -Path ".\Baselines\Server 22\baseline.csv" -Destination ".\Baselines\baseline.csv"
	}
}





# Run the c binary to filter and diff system to baseline files
.\Binaries\scan.exe







# Further filter the files using what the c binary output



# Create separate lists based on file types
$exeFiles = @()
$scriptFiles = @()
$msiFiles = @()
$dllFiles = @()
$txtFiles = @()

$otherFiles = @()


# Get output from c binary
$outputContent = Get-Content .\Output\added.txt


# Ensure first few lines are skipped from the added file (header / blank line at the top)
$firstFlag = 0



# Filter out files not signed by microsoft
foreach($line in $outputContent) {
	
	# Skip first few lines
	if($firstFlag -lt 2) {
		$firstFlag = $firstFlag + 1
		continue;
	}

	
	# Try to get the signature of the file
	try {
        $signature = Get-AuthenticodeSignature -FilePath $line -ErrorAction SilentlyContinue
        $signer = $signature.SignerCertificate.Subject
	$bool = $signer -like "*Microsoft Corporation*"


	# If no signature is found, flag it and organize it based on extension
        if (-not($bool)) {


            if ($line -match "\.exe$") {
        	$exeFiles += $line
    	    } elseif (($line -match "\.ps1$") -or ($line -match "\.bat$") -or ($line -match "\.vbs$") -or ($line -match "\.cmd$")) {
        	$scriptFiles += $line
    	    } elseif ($line -match "\.msi$") {
        	$msiFiles += $line
    	    } elseif ($line -match "\.dll$") {
        	$dllFiles += $line
    	    } elseif ($line -match "\.txt$") {
        	$txtFiles += $line
    	    } else {
        	$otherFiles += $line
    	    }

        }
    }
    catch {
        Write-Host "Error: $_"
    }
}




# Combine the lists in the desired order
$sortedFilePaths = $exeFiles + "`n" + $scriptFiles + "`n" + $msiFiles + "`n" + $dllFiles + "`n" + $txtFiles + "`n" + $otherFiles

# Overwrite the input file with the sorted paths
$sortedFilePaths | Set-Content -Path .\Output\filter.txt


















