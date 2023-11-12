# Created By: JohnDavid Abe
# Created On: 7/9/23
# Last Modified: 7/9/23
# Title: shields.ps1
# Description: Used to conform Windows Firewall to CIS recomendations
# Version: 1.0


# Log the script running
$date = Get-Date
Add-Content .\log.txt "Script Ran: shields.ps1"
Add-Content .\log.txt "Date: $date"
Add-Content .\log.txt ""

# Save the number of actions taken
$actionNumber = 0



$confirm = Read-Host -Prompt "Would you like to turn on all fireawll profiles? (Y/N)"

# If user wants to turn on firewall profiles
if ($confirm -eq "Y") {
	# Turn on each of the profiles
	netsh advfirewall set allprofiles state on
	$actionNumber += 1
}




# Check the state of each of the profiles

# Public Profile
$publicState = Get-NetFirewallProfile -Name Public

if($publicState.Enabled) {
	Add-Content .\log.txt "`nAction $actionNumber. Enabled public firewall profile (Success):"
	Add-Content .\log.txt ""
} else {
	Add-Content .\log.txt "`nAction $actionNumber. Enabled public firewall profile (Fail):"
	Add-Content .\log.txt ""
}




# Private Profile
$privateState = Get-NetFirewallProfile -Name Private

if($privateState.Enabled) {
	Add-Content .\log.txt "`nAction $actionNumber. Enabled private firewall profile (Success):"
	Add-Content .\log.txt ""
} else {
	Add-Content .\log.txt "`nAction $actionNumber. Enabled private firewall profile (Fail):"
	Add-Content .\log.txt ""
}




# Domain Profile
$domainState = Get-NetFirewallProfile -Name Domain

if($domainState.Enabled) {
	Add-Content .\log.txt "`nAction $actionNumber. Enabled domain firewall profile (Success):"
	Add-Content .\log.txt ""
} else {
	Add-Content .\log.txt "`nAction $actionNumber. Enabled domain firewall profile (Fail):"
	Add-Content .\log.txt ""
}







# Harden Public Profile

$confirm = Read-Host -Prompt "Would you like to harden the public profile? (Y/N)"

# If user wants to harden public profile
if ($confirm -eq "Y") {

	# Block incoming connections
	Set-NetFirewallProfile -Name Public -DefaultInbound Block

	# Allow outbound connections
	Set-NetFirewallProfile -Name Public -DefaultOutbound Allow

	# Turn off notifications
	Set-NetFirewallProfile -Name Public -NotifyOnListen False

	# Set log file name
	Set-NetFirewallProfile -Name Public -LogFileName %SystemRoot%\System32\logfiles\firewall\publicfw.log

	# Set max log file size
	Set-NetFirewallProfile -Name Public -LogMaxSizeKilobytes 16384

	# Log all connections
	Set-NetFirewallProfile -Name Public -LogAllowed True
	Set-NetFirewallProfile -Name Public -LogBlocked True
	Set-NetFirewallProfile -Name Public -LogIgnored True

	# Turn on response to multicast
	Set-NetFirewallProfile -Name Public -AllowUnicastResponseToMulticast True

	# Disallow local connection security rules
	Set-NetFirewallProfile -Name Public -AllowLocalFirewallRules False
	Set-NetFirewallProfile -name Public -AllowLocalIPsecRules False

	Add-Content .\log.txt "`nAction $actionNumber. Ran hardening script for public profile:"
	Add-Content .\log.txt ""


	$actionNumber += 1
}




# Harden Private Profile

$confirm = Read-Host -Prompt "Would you like to harden the private profile? (Y/N)"

# If user wants to harden private profile
if ($confirm -eq "Y") {

	# Block incoming connections
	Set-NetFirewallProfile -Name Private -DefaultInbound Block

	# Allow outbound connections
	Set-NetFirewallProfile -Name Private -DefaultOutbound Allow

	# Turn off notifications
	Set-NetFirewallProfile -Name Private -NotifyOnListen False

	# Set log file name
	Set-NetFirewallProfile -Name Private -LogFileName %SystemRoot%\System32\logfiles\firewall\privatefw.log

	# Set max log file size
	Set-NetFirewallProfile -Name Private -LogMaxSizeKilobytes 16384

	# Log all connections
	Set-NetFirewallProfile -Name Private -LogAllowed True
	Set-NetFirewallProfile -Name Private -LogBlocked True
	Set-NetFirewallProfile -Name Private -LogIgnored True

	# Turn on response to multicast
	Set-NetFirewallProfile -Name Private -AllowUnicastResponseToMulticast True

	Add-Content .\log.txt "`nAction $actionNumber. Ran hardening script for private profile:"
	Add-Content .\log.txt ""

	$actionNumber += 1
}





# Harden Domain Profile

$confirm = Read-Host -Prompt "Would you like to harden the domain profile? (Y/N)"

# If user wants to harden domain profile
if ($confirm -eq "Y") {

	# Block incoming connections
	Set-NetFirewallProfile -Name Domain -DefaultInbound Block

	# Allow outbound connections
	Set-NetFirewallProfile -Name Domain -DefaultOutbound Allow

	# Turn off notifications
	Set-NetFirewallProfile -Name Domain -NotifyOnListen False

	# Set log file name
	Set-NetFirewallProfile -Name Domain -LogFileName %SystemRoot%\System32\logfiles\firewall\domainfw.log

	# Set max log file size
	Set-NetFirewallProfile -Name Domain -LogMaxSizeKilobytes 16384

	# Log all connections
	Set-NetFirewallProfile -Name Domain -LogAllowed True
	Set-NetFirewallProfile -Name Domain -LogBlocked True
	Set-NetFirewallProfile -Name Domain -LogIgnored True

	# Turn on response to multicast
	Set-NetFirewallProfile -Name Domain -AllowUnicastResponseToMulticast True

	Add-Content .\log.txt "`nAction $actionNumber. Ran hardening script for domain profile:"
	Add-Content .\log.txt ""

	$actionNumber += 1
}




# Parts of the firewall yet to be looked into
# AllowInboundRules                                
# AllowUserApps                   
# AllowUserPorts             
# EnableStealthModeForIPsec                                
# DisabledInterfaceAliases