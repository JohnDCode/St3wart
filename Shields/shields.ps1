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





# Harden Defender

$confirm = Read-Host -Prompt "Would you like to add Defender configurations? (Y/N)"

# If user wants to harden defender
if ($confirm -eq "Y") {

	# Delete Existing Exclusions
	Write-Host ""
	Write-Host "DELETING KEYS: " -ForegroundColor Green
	REG DELETE 'HKLM\Software\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR' /v 'ExploitGuard_ASR_ASROnlyExclusions' /f
	REG DELETE 'HKLM\Software\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\Controlled Folder Access' /v 'ExploitGuard_ControlledFolderAccess_AllowedApplications' /f
	REG DELETE 'HKLM\Software\Policies\Microsoft\Windows Defender\Exclusions' /v 'Exclusions_Extensions' /f
	REG DELETE 'HKLM\Software\Policies\Microsoft\Windows Defender\Exclusions' /v 'Exclusions_Paths' /f
	REG DELETE 'HKLM\Software\Policies\Microsoft\Windows Defender\Exclusions' /v 'Exclusions_Processes' /f
	REG DELETE 'HKLM\Software\Policies\Microsoft\Windows Defender\Real-Time Protection' /v 'RealtimeScanDirection' /f
	REG DELETE 'HKLM\Software\Policies\Microsoft\Windows Defender\Signature Updates' /f
	REG DELETE 'HKLM\Software\Policies\Microsoft\Windows Defender\Threats' /v 'Threats_ThreatSeverityDefaultAction' /f


	# Ransomeware Protection
	REG DELETE 'HKLM\Software\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\Controlled Folder Access\AllowedApplications' /f



	Write-Host "ADDING KEYS: " -ForegroundColor Green

	# Ransomware (cont.)
	REG ADD 'HKLM\Software\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\Controlled Folder Access' /v 'EnableControlledFolderAccess' /t 'REG_DWORD' /d '1' /f

	# Removable Device Protection
	REG ADD 'HKLM\Software\Policies\Microsoft\Windows\DeviceInstall\Restrictions' /v 'DenyRemovableDevices' /t 'REG_DWORD' /d '1' /f

	# Network Protection
	REG ADD 'HKLM\Software\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\Network Protection' /v 'EnableNetworkProtection' /t 'REG_DWORD' /d '1' /f
	REG ADD 'HKLM\Software\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\AllowNetworkProtectionOnWinServer' /v 'EnableNetworkProtection' /t 'REG_DWORD' /d '1' /f

	# Defender Configs
	REG ADD 'HKLM\Software\Policies\Microsoft\Windows Defender' /v 'PUAProtection' /t 'REG_DWORD' /d '1' /f
	REG ADD 'HKLM\Software\Policies\Microsoft\Windows Defender' /v 'DisableAntiSpyware' /t 'REG_DWORD' /d '0' /f
	REG ADD 'HKLM\Software\Policies\Microsoft\Windows Defender\Signature Updates' /v 'ASSignatureDue' /t 'REG_DWORD' /d '1' /f
	REG ADD 'HKLM\Software\Policies\Microsoft\Windows Defender\Signature Updates' /v 'AVSignatureDue' /t 'REG_DWORD' /d '1' /f
	REG ADD 'HKLM\Software\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\Network Protection' /v 'EnableNetworkProtection' /t 'REG_DWORD' /d '1' /f
	REG ADD 'HKLM\Software\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\Network Protection' /v 'EnableNetworkProtection' /t 'REG_DWORD' /d '1' /f
	REG ADD 'HKLM\Software\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\Network Protection' /v 'EnableNetworkProtection' /t 'REG_DWORD' /d '1' /f
	REG ADD 'HKLM\Software\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\Network Protection' /v 'EnableNetworkProtection' /t 'REG_DWORD' /d '1' /f
	REG ADD 'HKLM\Software\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\Network Protection' /v 'EnableNetworkProtection' /t 'REG_DWORD' /d '1' /f
	REG ADD 'HKLM\Software\Policies\Microsoft\Windows Defender\Real-Time Protection' /v 'LocalSettingOverrideDisableRealtimeMonitoring' /t 'REG_DWORD' /d '0' /f
	REG ADD 'HKLM\Software\Policies\Microsoft\Windows Defender\Real-Time Protection' /v 'LocalSettingOverrideDisableBehaviorMonitoring' /t 'REG_DWORD' /d '0' /f
	REG ADD 'HKLM\Software\Policies\Microsoft\Windows Defender\Real-Time Protection' /v 'LocalSettingOverrideDisableIOAVProtection' /t 'REG_DWORD' /d '0' /f
	REG ADD 'HKLM\Software\Policies\Microsoft\Windows Defender\Real-Time Protection' /v 'DisableScanOnRealtimeEnable' /t 'REG_DWORD' /d '0' /f
	REG ADD 'HKLM\Software\Policies\Microsoft\Windows Defender\Real-Time Protection' /v 'LocalSettingOverrideRealtimeScanDirection' /t 'REG_DWORD' /d '0' /f
	REG ADD 'HKLM\Software\Policies\Microsoft\Windows Defender\Real-Time Protection' /v 'LocalSettingOverrideDisableOnAccessProtection' /t 'REG_DWORD' /d '0' /f
	REG ADD 'HKLM\Software\Policies\Microsoft\Windows Defender\NIS' /v 'DisableProtocolRecognition' /t 'REG_DWORD' /d '0' /f
	REG ADD 'HKLM\Software\Policies\Microsoft\Windows Defender\Exclusions' /v 'DisableAutoExclusions' /t 'REG_DWORD' /d '0' /f
	REG ADD 'HKLM\Software\Policies\Microsoft\Windows Defender\Real-Time Protection' /v 'DisableRealtimeMonitoring' /t 'REG_DWORD' /d '0' /f
	REG ADD 'HKLM\Software\Policies\Microsoft\Windows Defender' /v 'DisableRoutinelyTakingAction' /t 'REG_DWORD' /d '0' /f

	
	# Set Defender Settings

	Write-Host "DEFENDER PREFS: " -ForegroundColor Green
	Set-MpPreference -AllowDatagramProcessingOnWinServer $true
	Set-MpPreference -AllowNetworkProtectionDownLevel $true
	Set-MpPreference -AllowNetworkProtectionOnWinServer $true
	Set-MpPreference -AllowSwitchToAsyncInspection $true
	Set-MpPreference -CheckForSignaturesBeforeRunningScan $true
	Set-MpPreference -CloudBlockLevel "zeroTolerance"
	Set-MpPreference -CloudExtendedTimeout 50
	Set-MpPreference -DisableArchiveScanning $false
	Set-MpPreference -DisableAutoExclusions $false
	Set-MpPreference -DisableBehaviorMonitoring $false
	Set-MpPreference -DisableBlockAtFirstSeen $false
	Set-MpPreference -DisableCacheMaintenance $false
	Set-MpPreference -DisableCatchupFullScan $false
	Set-MpPreference -DisableCatchupQuickScan $false
	Set-MpPreference -DisableCpuThrottleOnIdleScans $true
	Set-MpPreference -DisableDatagramProcessing $false
	Set-MpPreference -DisableDnsOverTcpParsing $false
	Set-MpPreference -DisableDnsParsing $false
	Set-MpPreference -DisableEmailScanning $false
	Set-MpPreference -DisableFtpParsing $false
	Set-MpPreference -DisableGradualRelease $false
	Set-MpPreference -DisableHttpParsing $false
	Set-MpPreference -DisableInboundConnectionFiltering $false
	Set-MpPreference -DisableIOAVProtection $false
	Set-MpPreference -DisableNetworkProtectionPerfTelemetry $true
	Set-MpPreference -DisablePrivacyMode $false
	Set-MpPreference -DisableRdpParsing $false
	Set-MpPreference -DisableRealtimeMonitoring $false
	Set-MpPreference -DisableRemovableDriveScanning $false
	Set-MpPreference -DisableRestorePoint $false
	Set-MpPreference -DisableScanningMappedNetworkDrivesForFullScan $false
	Set-MpPreference -DisableScanningNetworkFiles $false
	Set-MpPreference -DisableScriptScanning $false
	Set-MpPreference -DisableSmtpParsing $false
	Set-MpPreference -DisableSshParsing $false
	Set-MpPreference -DisableTlsParsing $false
	Set-MpPreference -EnableControlledFolderAccess "Enabled"
	Set-MpPreference -EnableDnsSinkhole $true
	Set-MpPreference -EnableFileHashComputation $true
	Set-MpPreference -EnableFullScanOnBatteryPower $true
	Set-MpPreference -EnableLowCpuPriority $false
	Set-MpPreference -EnableNetworkProtection "Enabled"
	Set-MpPreference -EngineUpdatesChannel "NotConfigured"
	Set-MpPreference -HighThreatDefaultAction "Remove"
	Set-MpPreference -IntelTDTEnabled 1
	Set-MpPreference -LowThreatDefaultAction "Remove"
	Set-MpPreference -MAPSReporting 0
	Set-MpPreference -MeteredConnectionUpdates $true
	Set-MpPreference -ModerateThreatDefaultAction "Remove"
	Set-MpPreference -OobeEnableRtpAndSigUpdate $true
	Set-MpPreference -PlatformUpdatesChannel "NotConfigured"
	Set-MpPreference -PUAProtection "Enabled"
	Set-MpPreference -QuarantinePurgeItemsAfterDelay 1
	Set-MpPreference -RandomizeScheduleTaskTimes $true
	Set-MpPreference -RealTimeScanDirection "Both"
	Set-MpPreference -RemediationScheduleDay "Everyday"
	Set-MpPreference -ScanOnlyIfIdleEnabled $false
	Set-MpPreference -ScanParameters "FullScan"
	Set-MpPreference -ScanScheduleDay "Everyday"
	Set-MpPreference -SchedulerRandomizationTime $true
	Set-MpPreference -ServiceHealthReportInterval 60
	Set-MpPreference -SevereThreatDefaultAction "Remove"
	Set-MpPreference -SignatureDisableUpdateOnStartupWithoutEngine $false
	Set-MpPreference -SignatureScheduleDay "Everyday"
	Set-MpPreference -SignatureUpdateCatchupInterval 0
	Set-MpPreference -SubmitSamplesConsent "NeverSend"
	Set-MpPreference -UILockdown $false
	Set-MpPreference -UnknownThreatDefaultAction "Remove"



	# Remove Defender Exclusions

	Write-Host "REMOVING PREFS: " -ForegroundColor Green
	Remove-MpPreference -AttackSurfaceReductionRules_Ids * -AttackSurfaceReductionRules_Actions * -AttackSurfaceReductionOnlyExclusions *
	Remove-MpPreference -ExclusionPath *
	Remove-MpPreference -ExclusionExtension *
	Remove-MpPreference -ExclusionProcess *
	Remove-MpPreference -ExclusionIpAddress *
	Remove-MpPreference -ThreatIDDefaultAction_Ids * -ThreatIDDefaultAction_Actions *
	Remove-MpPreference -ControlledFolderAccessAllowedApplications * -ControlledFolderAccessProtectedFolders *


	# Add ASR Rules (also does the CIS ones in gpedit)

	Write-Host "ADDING ASR RULES: " -ForegroundColor Green
	Add-MpPreference -AttackSurfaceReductionRules_Ids 56a863a9-875e-4185-98a7-b882c64b5ce5 -AttackSurfaceReductionRules_Actions 1 # In CIS
	Add-MpPreference -AttackSurfaceReductionRules_Ids 7674ba52-37eb-4a4f-a9a1-f0f9a1619a2c -AttackSurfaceReductionRules_Actions 1 # In CIS
	Add-MpPreference -AttackSurfaceReductionRules_Ids d4f940ab-401b-4efc-aadc-ad5f3c50688a -AttackSurfaceReductionRules_Actions 1 # In CIS
	Add-MpPreference -AttackSurfaceReductionRules_Ids 9e6c4e1f-7d60-472f-ba1a-a39ef669e4b2 -AttackSurfaceReductionRules_Actions 1 # In CIS
	Add-MpPreference -AttackSurfaceReductionRules_Ids be9ba2d9-53ea-4cdc-84e5-9b1eeee46550 -AttackSurfaceReductionRules_Actions 1 # In CIS
	Add-MpPreference -AttackSurfaceReductionRules_Ids 01443614-cd74-433a-b99e-2ecdc07bfc25 -AttackSurfaceReductionRules_Actions 1
	Add-MpPreference -AttackSurfaceReductionRules_Ids 5beb7efe-fd9a-4556-801d-275e5ffc04cc -AttackSurfaceReductionRules_Actions 1 # In CIS
	Add-MpPreference -AttackSurfaceReductionRules_Ids d3e037e1-3eb8-44c8-a917-57927947596d -AttackSurfaceReductionRules_Actions 1 # In CIS
	Add-MpPreference -AttackSurfaceReductionRules_Ids 3b576869-a4ec-4529-8536-b80a7769e899 -AttackSurfaceReductionRules_Actions 1 # In CIS
	Add-MpPreference -AttackSurfaceReductionRules_Ids 75668c1f-73b5-4cf0-bb93-3ecf5cb7cc84 -AttackSurfaceReductionRules_Actions 1 # In CIS
	Add-MpPreference -AttackSurfaceReductionRules_Ids 26190899-1602-49e8-8b27-eb1d0a1ce869 -AttackSurfaceReductionRules_Actions 1 # In CIS
	Add-MpPreference -AttackSurfaceReductionRules_Ids e6db77e5-3df2-4cf1-b95a-636979351e5b -AttackSurfaceReductionRules_Actions 1 # In CIS
	Add-MpPreference -AttackSurfaceReductionRules_Ids d1e49aac-8f56-4280-b9ba-993a6d77406c -AttackSurfaceReductionRules_Actions 1
	Add-MpPreference -AttackSurfaceReductionRules_Ids b2b3f03d-6a65-4f7b-a9c7-1c7ef74a9ba4 -AttackSurfaceReductionRules_Actions 1 # In CIS
	Add-MpPreference -AttackSurfaceReductionRules_Ids a8f5898e-1dc8-49a9-9878-85004b8a61e6 -AttackSurfaceReductionRules_Actions 1
	Add-MpPreference -AttackSurfaceReductionRules_Ids 92e97fa1-2edf-4476-bdd6-9dd0b4dddc7b -AttackSurfaceReductionRules_Actions 1 # In CIS
	Add-MpPreference -AttackSurfaceReductionRules_Ids c1db55ab-c21a-4637-bb3f-a12568109d35 -AttackSurfaceReductionRules_Actions 1


	REG ADD 'HKLM\Software\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR' /v 'ExploitGuard_ASR_Rules' /t 'REG_DWORD' /d '1' /f
	REG ADD 'HKLM\Software\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' /v '56a863a9-875e-4185-98a7-b882c64b5ce5' /t 'REG_SZ' /d '1' /f
	REG ADD 'HKLM\Software\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' /v '7674ba52-37eb-4a4f-a9a1-f0f9a1619a2c' /t 'REG_SZ' /d '1' /f
	REG ADD 'HKLM\Software\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' /v 'd4f940ab-401b-4efc-aadc-ad5f3c50688a' /t 'REG_SZ' /d '1' /f
	REG ADD 'HKLM\Software\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' /v '9e6c4e1f-7d60-472f-ba1a-a39ef669e4b2' /t 'REG_SZ' /d '1' /f
	REG ADD 'HKLM\Software\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' /v 'be9ba2d9-53ea-4cdc-84e5-9b1eeee46550' /t 'REG_SZ' /d '1' /f
	REG ADD 'HKLM\Software\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' /v '01443614-cd74-433a-b99e-2ecdc07bfc25' /t 'REG_SZ' /d '1' /f
	REG ADD 'HKLM\Software\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' /v '5beb7efe-fd9a-4556-801d-275e5ffc04cc' /t 'REG_SZ' /d '1' /f
	REG ADD 'HKLM\Software\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' /v 'd3e037e1-3eb8-44c8-a917-57927947596d' /t 'REG_SZ' /d '1' /f
	REG ADD 'HKLM\Software\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' /v '3b576869-a4ec-4529-8536-b80a7769e899' /t 'REG_SZ' /d '1' /f
	REG ADD 'HKLM\Software\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' /v '75668c1f-73b5-4cf0-bb93-3ecf5cb7cc84' /t 'REG_SZ' /d '1' /f
	REG ADD 'HKLM\Software\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' /v '26190899-1602-49e8-8b27-eb1d0a1ce869' /t 'REG_SZ' /d '1' /f
	REG ADD 'HKLM\Software\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' /v 'e6db77e5-3df2-4cf1-b95a-636979351e5b' /t 'REG_SZ' /d '1' /f
	REG ADD 'HKLM\Software\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' /v 'd1e49aac-8f56-4280-b9ba-993a6d77406c' /t 'REG_SZ' /d '1' /f
	REG ADD 'HKLM\Software\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' /v 'b2b3f03d-6a65-4f7b-a9c7-1c7ef74a9ba4' /t 'REG_SZ' /d '1' /f
	REG ADD 'HKLM\Software\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' /v 'a8f5898e-1dc8-49a9-9878-85004b8a61e6' /t 'REG_SZ' /d '1' /f
	REG ADD 'HKLM\Software\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' /v '92e97fa1-2edf-4476-bdd6-9dd0b4dddc7b' /t 'REG_SZ' /d '1' /f
	REG ADD 'HKLM\Software\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules' /v 'c1db55ab-c21a-4637-bb3f-a12568109d35' /t 'REG_SZ' /d '1' /f

	# Process Mitigation Stuff

	Write-Host "PROCESS MITIGATION: " -ForegroundColor Green
	set-processmitigation -system -enable DEP
	set-processmitigation -system -enable CFG
	

}
