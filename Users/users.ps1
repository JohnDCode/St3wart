# Created By: JohnDavid Abe
# Created On: 6/13/23
# Last Modified: 11/12/23
# Title: users.ps1
# Description: Used to audit users, and user specific preferences on cyberpatriot competition images
# Version: 2.1



# Log the script running
$date = Get-Date
Add-Content .\log.txt "Script Ran: users.ps1"
Add-Content .\log.txt "Date: $date"
Add-Content .\log.txt ""

# Save the number of actions taken
$actionNumber = 0




# Retrieve the name of the main administrator (you)
$mainAdmin = (whoami).Split('\')[-1]


# Retrieve all users on the system
$sysUsers = Get-LocalUser | Select-Object -ExpandProperty Name


# Retrive all administrators on the system
$sysAdmins = @()
Get-LocalGroupMember Administrators | Select-Object -ExpandProperty Name | ForEach-Object {$sysAdmins += $_.Split('\')[-1]}



# Read which system policies to apply from input
Write-Host "Which OS baseline would you like to import?"
$osInput = Read-Host -Prompt "[1] Windows 10 [2] Windows 11 [3] Server 19 [4] Server 22"


# Import csv baselines based on the input
switch ($osInput) {
    "1" {
	# Defualt groups for Windows 10
	$defaultGroups = @("Access Control Assistance Operators", "Administrators", "Backup Operators", "Cryptographic Operators", "Device Owners", "Distributed COM Users", "Event Log Readers", "Guests", "Hyper-V Administrators", "IIS_IUSRS", "Network Configuration Operators", "Performance Log Users", "Performance Monitor Users", "Power Users", "Remote Desktop Users", "Remote Management Users", "Replicator", "System Managed Accounts Group", "Users")
	$defaultUsers = @("Administrator", "DefaultAccount", "Guest", "WDAGUtilityAccount")
 	}

    "2" {
	# Default groups for Windows 11
	$defaultGroups = @("Access Control Assistance Operators", "Administrators", "Backup Operators", "Cryptographic Operators", "Device Owners", "Distributed COM Users", "Event Log Readers", "Guests", "Hyper-V Administrators", "IIS_IUSRS", "Network Configuration Operators", "Performance Log Users", "Performance Monitor Users", "Power Users", "Remote Desktop Users", "Remote Management Users", "Replicator", "System Managed Accounts Group", "Users")
	$defaultUsers = @("Administrator", "DefaultAccount", "Guest", "WDAGUtilityAccount")
	}

	"3" {
	# Default groups for Server 19
	$defaultGroups = @("Access Control Assistance Operators", "Administrators", "Backup Operators", "Certificate Service DCOM Access", "Cryptographic Operators", "Device Owners", "Distributed COM Users", "Event Log Readers", "Guests", "Hyper-V Administrators", "IIS_IUSRS", "Network Configuration Operators", "Performance Log Users", "Performance Monitor Users", "Power Users", "Print Operators", "RDS Endpoint Servers", "RDS Management Servers", "RDS Remote Access Servers", "Remote Desktop Users", "Remote Management Users", "Replicator", "Storage Replica Administrators", "System Managed Accounts Group", "Users")
	$defaultUsers = @("Administrator", "DefaultAccount", "Guest", "WDAGUtilityAccount")
	}

	"4" {
	# Default groups for Server 22
    $defaultGroups = @("Access Control Assistance Operators", "Administrators", "Backup Operators", "Certificate Service DCOM Access", "Cryptographic Operators", "Device Owners", "Distributed COM Users", "Event Log Readers", "Guests", "Hyper-V Administrators", "IIS_IUSRS", "Network Configuration Operators", "Performance Log Users", "Performance Monitor Users", "Power Users", "Print Operators", "RDS Endpoint Servers", "RDS Management Servers", "RDS Remote Access Servers", "Remote Desktop Users", "Remote Management Users", "Replicator", "Storage Replica Administrators", "System Managed Accounts Group", "Users")
	$defaultUsers = @("Administrator", "DefaultAccount", "Guest", "WDAGUtilityAccount")
	}
}










Write-Host "Place the names of authorized users and admins into the respective text files. Confirm: "
$proceedConfirm = Read-Host -Prompt "Y/N"


# Import csv baselines based on the input
switch ($proceedConfirm) {
    "N" { 
	exit
 	}
}

# Holds all authorized users & admins from text files
$authAdmins = @()
$authUsers = @()

$authAdmins = Get-Content .\admins.txt
$authUsers = Get-Content .\users.txt








# Audit administrators

foreach($admin in $sysAdmins) {
	# There is no need to remove built in accounts, or the main admin (you)
	if(($defaultUsers.contains($admin)) -or ($admin -eq $mainAdmin)) {
		continue
	}
	# If the admin isn't on the list of authorized admins from the readMe, ask to remove them
	if (-not($authAdmins.contains($admin))) {
		$confirm = Read-Host -Prompt "The account named $admin, appears to have unauthorized administrator privlidges. Would you like to remove such privlidges?  (Y/N)"
		if ($confirm -eq "Y") {
			# Remove the account from the administrators group
			Remove-LocalGroupMember -Group Administrators -Member $admin
   			$confirmAdmin = @()

      		# Confirm that the administrator was removed

  			# Get all admins
			Get-LocalGroupMember Administrators | Select-Object -ExpandProperty Name | ForEach-Object {$confirmAdmin += $_.Split('\')[-1]}

      		# Check to see if the admin is still in the administrators group
   			if ($confirmAdmin.contains($admin)) {
      			Write-Host "Failed to remove the administrator"
      			Add-Content .\log.txt "`nAction $actionNumber. Removed $admin from administrators group. (Fail)"
      			$actionNumber += 1
			} else {
   				Write-Host "Successfully removed account $admin from the administrators group"
       			Add-Content .\log.txt "`nAction $actionNumber. Removed $admin from administrators group. (Success)"
	   			$actionNumber += 1
   			}
		}
	}
}








# Audit Users

foreach($user in $sysUsers) {
	# There will never be a situation where default accounts need to be removed (only disabled)
	# Every administrator has already been verified as well, so no need to audit them
	if(($defaultUsers.contains($user)) -or ($user -eq $mainAdmin) -or ($authAdmins.contains($user))) {
		continue
	}
	# If the user isn't on the list of authorized users from the readMe, ask to remove them
	if (-not($authUsers.contains($user))) {
		$confirm = Read-Host -Prompt "The account named, $user, appears to be an unauthorized user. Would you like to remove the account?  (Y/N)"
		if ($confirm -eq "Y") {
			# Remove the user from the system
			Remove-LocalUser -Name $user

      		# Confirm that the user was removed

  			# Get all users
			$confirmUser = Get-LocalUser | Select-Object -ExpandProperty Name

      		# Check to see if the user is still on the system
   			if ($confirmUser.contains($user)) {
      			Write-Host "Failed to remove the user"
      			Add-Content .\log.txt "`nAction $actionNumber. Removed $user from the system. (Fail)"
      			$actionNumber += 1
			} else {
   				Write-Host "Successfully removed account $user from the system"
       			Add-Content .\log.txt "`nAction $actionNumber. Removed $user from the system. (Success)"
	   			$actionNumber += 1
   			}
		}
	}
}








# Disable bulitin accounts

# Loop through each user
foreach ($account in $defaultUsers) {

	# Check to see if such is disabled
	if ((Get-LocalUser -Name $account).Enabled) {

		# Ask to see if you would like to disable the account
		$confirm = Read-Host -Prompt "The built in, $account, account is enabled. Would you like to disable? (Y/N)"
		if($confirm -eq "Y") {

			# Disable the account
			Disable-LocalUser -Name $account

   			# Confirm the account has been disabled
   			if ((Get-LocalUser -Name $account).Enabled) {
      			Write-Host "Failed to disable account $account"
      			Add-Content .\log.txt "`nAction $actionNumber. Disabled $account (Fail)"
	   			$actionNumber += 1
      		} else {
	 			Write-Host "Successfully disabled the account $account"
     			Add-Content .\log.txt "`nAction $actionNumber. Disabled $account (Success)"
	   			$actionNumber += 1
	 		}
		}
	}
}







# Set secure passwords for each account

# Define the password as a secure string
$pswd = ConvertTo-SecureString "Th1s1sS3cur34Sur3!" -AsPlainText -Force

# Get the users on the system (these have all been verified per earlier in the script)
$auditedSysUsers = Get-LocalUser | Select-Object -ExpandProperty Name

# Confirm that the main admin wants to set secure passwords for each account
$confirm = Read-Host -Prompt "Would you like to reset all passwords to a secure password? (Y/N)"


# If the user does wish to change passwords, cycle through each verified user
if ($confirm -eq "Y") {
	foreach($user in $auditedSysUsers) {
		# There will never be a situation where one should change the password of (your) the main admin account, or a builtin account
		if(($defaultUsers.contains($user)) -or ($user -eq $mainAdmin)) {
			continue
		}
		
		# Change the password
		Set-LocalUser -Name $user -Password $pswd -Verbose
  		if ($?) {
    		Add-Content .\log.txt "`nAction $actionNumber. Changed password for account $user to secure password (Success)"
	   		$actionNumber += 1
		} else {
			Add-Content .\log.txt "`nAction $actionNumber. Changed password for account $user to secure password (Fail)"
	   		$actionNumber += 1
		}
	}
}








# Remove unauthorized groups

# Get all local groups on the system
$localGroups = Get-LocalGroup | Select-Object -ExpandProperty Name


foreach($group in $localGroups) {
	if(-not($defaultGroups.contains($group))) {
		$confirm = Read-Host -Prompt "The group titled, $group, seems to be a non-builtin group. Would you like to remove such a group from the system? (Y/N)"
		if ($confirm -eq "Y") {
			Remove-LocalGroup -Name $group

   			# Confirm the group was removed

      		$confirmGroups = Get-LocalGroup | Select-Object -ExpandProperty Name
	 		if($confirmGroups.contains($group)) {
    			Write-Host "Failed to remove group $group from the system"
    			Add-Content .\log.txt "`nAction $actionNumber. Removed $group from the system (Fail)"
	   			$actionNumber += 1
			} else {
   				Write-Host "Successfully removed group $group from the system"
       			Add-Content .\log.txt "`nAction $actionNumber. Removed $group from the system (Success)"
	   			$actionNumber += 1
   			}
		}
	}
}







# Clear security groups (backup operators, device owners, etc.)

# The admin and user groups that have already been audited
$auditedGroups = "Administrators", "Users"

# Get all local groups on the system (again because some of them were just removed above)
$localGroups = Get-LocalGroup | Select-Object -ExpandProperty Name

foreach($group in $localGroups) {
	# There will never be a need to (re) audit the administrators and users on the system
	if ($auditedGroups.contains($group)) {
		continue
	}

	# Get all members of the particular group (remove the system name)
	$members = @()
	Get-LocalGroupMember $group | Select-Object -ExpandProperty Name | ForEach-Object {$members += $_.Split('\')[-1]}

	# Ask to remove each member from the particular group
	foreach($member in $members) {
		$confirm = Read-Host -Prompt "The user, $member, appears to be a member of the group, $group. Would you like to remove the user from this group? (Y/N)"
		if ($confirm -eq "Y") {
			# If yes, remove the user from the particular group
			Remove-LocalGroupMember -Group $group -Member $member

   			# Confirm the user was removed from the group

      		$confirmMembers = @()
	 		Get-LocalGroupMember $group | Select-Object -ExpandProperty Name | ForEach-Object {$confirmMembers += $_.Split('\')[-1]}
    		if ($confirmMembers.contains($member)) {
       			Write-Host "Failed to remove account $member from group $group"
       			Add-Content .\log.txt "`nAction $actionNumber. Removed account $member from group $group (Fail)"
	   			$actionNumber += 1
			} else {
   				Write-Host "Successfully removed account $member from group $group"
       			Add-Content .\log.txt "`nAction $actionNumber. Removed account $member from group $group (Success)"
	   			$actionNumber += 1
   			}
		}
	}

}








# Managing non-builtin accounts being disabled

foreach($user in $auditedSysUsers) {
	# The disabling of builtin accounts was audited earlier in the script
	if ($defaultUsers.contains($user)) {
		continue
	}
	# If the local account is disabled ask if the main admin would like to enable it
	if(-not((Get-LocalUser -Name $user).Enabled)) {
		$confirm = Read-Host -Prompt "The user account, $user, seems to be disabled. Would you like to re-enable the account? (Y/N)"
		if ($confirm -eq "Y") {
			# Enable the account
			Enable-LocalUser -Name $user

      		# Confirm that the account was enabled
	 		if(-not((Get-LocalUser -Name $user).Enabled)) {
    			Write-Host "Failed to enable account $user"
    			Add-Content .\log.txt "`nAction $actionNumber. Enabled account $user (Fail)"
	   			$actionNumber += 1
			} else {
   				Write-Host "Successfully enabled account $user"
       			Add-Content .\log.txt "`nAction $actionNumber. Enabled account $user (Success)"
	   			$actionNumber += 1
   			}
		}
	}
}








# Managing non-builtin accounts being locked out

foreach($user in $auditedSysUsers) {

	# If the local account is locked out, ask if the main admin would like to unlock the account
	if((Get-LocalUser -Name $user).LockedOut) {
		$confirm = Read-Host -Prompt "The user account, $user, seems to be locked out. Would you like to unlock the account? (Y/N)"
		if ($confirm -eq "Y") {
			# Get the user ($user only holds the userNAME)
			$userObj = Get-LocalUser $user

			# Clear the user's lockout flags by changing the UserFlags property
			$userObj.UserFlags = ($userObj.UserFlags -band (-bnot 0x10))
    		Set-LocalUser -InputObject $userObj

	  		# Confirm that the account was unlocked
	 		if((Get-LocalUser -Name $user).LockedOut) {
    			Write-Host "Failed to unlock account $user"
    			Add-Content .\log.txt "`nAction $actionNumber. Unlocked account $user (Fail)"
	   			$actionNumber += 1
			} else {
   				Write-Host "Successfully unlocked account $user"
       			Add-Content .\log.txt "`nAction $actionNumber. Unlocked account $user (Success)"
	   			$actionNumber += 1
   			}
		}
	}
}


# CP-17 Additions
# Managing user accounts password never expiring

$allUsers = Get-LocalUser | Select-Object -ExpandProperty Name

# Confirm that the main admin wants to set secure passwords for each account
$confirm = Read-Host -Prompt "Would you like to ensure each user account's password expires (in accordance to local policies)? (Y/N)"


# If the user does wish to change expiration policies, cycle through each user
if ($confirm -eq "Y") {
	foreach($user in $allUsers) {
		# There will never be a situation where the password should expire on the WDAGUtility Account
		if($user -eq "WDAGUtilityAccount") {
			continue
		}
		
		# Make the password expire
		Set-LocalUser -Name $user -PasswordNeverExpires $false
  		if ($?) {
    		Add-Content .\log.txt "`nAction $actionNumber. $user password expires (Success)"
	   		$actionNumber += 1
		} else {
			Add-Content .\log.txt "`nAction $actionNumber. $user password expires (Fail)"
	   		$actionNumber += 1
		}
	}
}





# Managing user accounts not being able to change their password

$allUsers = Get-LocalUser | Select-Object -ExpandProperty Name

# Confirm that the main admin wants to ensure all users can change their password
$confirm = Read-Host -Prompt "Would you like to ensure each user can change their password? (Y/N)"


# If the user does wish to change password change policies, cycle through each user
if ($confirm -eq "Y") {
	foreach($user in $allUsers) {
		# There will never be a situation where the password should expire on the WDAGUtility Account
		
		# Make the password to be able to be changed
		net user $user /PasswordChg:Yes
  		if ($?) {
    		Add-Content .\log.txt "`nAction $actionNumber. $user password can be changed (Success)"
	   		$actionNumber += 1
		} else {
			Add-Content .\log.txt "`nAction $actionNumber. $user password can be changed (Fail)"
	   		$actionNumber += 1
		}
	}
}






# Remind user to perform readMe tasks (usually some user task can be found in the readMe)
Write-Host ""
Write-Host "Remmber to perform specific user auditing tasks described in the readMe as well!"


# Script has finished, leave space before next script executes
Add-Content .\log.txt "`n"
Add-Content .\log.txt "`n"
Add-Content .\log.txt "`n"
Add-Content .\log.txt "`n"
Add-Content .\log.txt "`n"





# Notes:

# Should you set a password on some of the builtin accounts?
# Should the script manage UAC as well?
# Should we add fail safes for each step of the script (record changes and then ensure each was made at the end of script execution)?
# Update to handle changes through registry
