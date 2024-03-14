# Import and Run Hardening Kitty ps Module
Import-Module .\HardeningKitty.psm1
Invoke-HardeningKitty -EmojiSupport -Mode Audit -Log -Report -LogFile .\log.log

# Get the log output
$log = Get-Content .\log.log


# Loop through the generated log output
foreach($line in $log) {

	# Reached start of new list
	if($line.contains("- Starting ")) {

		Add-Content .\high.txt ""
		Add-Content .\high.txt $line

		Add-Content .\medium.txt ""
		Add-Content .\medium.txt $line

		Add-Content .\low.txt ""
		Add-Content .\low.txt $line

	}

	if($line.contains("High")) { Add-Content .\high.txt $line }
	if($line.contains("Medium")) { Add-Content .\medium.txt $line }
	if($line.contains("Low")) { Add-Content .\low.txt $line }

}