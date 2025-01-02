# Created By: JohnDavid Abe
# Created On: 12/31/24
# Last Modified: 12/31/24
# Title: dns.ps1
# Description: Hardens Windows Domain Controllers
# Version: 0.1


# Zerologon Vuln
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters" /v FullSecureChannelProtection /t REG_DWORD /d 1 /f

Write-Host "Attempting to delete zerologon vuln key (not finding key means no finding)" -ForegroundColor Green
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters" /v vulnerablechannelallowlist /f

nltest /DBFlag:2080FFFF


# User's Joining Computers to Domain
Set-ADDomain -Identity $env:USERDNSDOMAIN -Replace @{"ms-DS-MachineAccountQuota"="0"}


# LDAP Signing
reg add "HKLM\System\CurrentControlSet\Services\NTDS\Parameters" /v "LDAPServerIntegrity" /t REG_DWORD /d 2 /f


# LDAP Auth
reg add "HKLM\System\CurrentControlSet\Services\NTDS\Parameters" /v LdapEnforceChannelBinding /t REG_DWORD /d 2 /f


# DSRM Password Use
reg add "HKLM\System\CurrentControlSet\Control\Lsa" /v DsrmAdminLogonBehavior /t REG_DWORD /d 1 /f


# Unaunthenticated LDAP
$RootDSE = Get-ADRootDSE
$ObjectPath = 'CN=Directory Service,CN=Windows NT,CN=Services,{0}' -f $RootDSE.ConfigurationNamingContext
Set-ADObject -Identity $ObjectPath -Add @{ 'msDS-Other-Settings' = 'DenyUnauthenticatedBind=1'}


