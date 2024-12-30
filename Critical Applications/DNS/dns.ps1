# Created By: JohnDavid Abe
# Created On: 12/29/24
# Last Modified: 12/30/24
# Title: dns.ps1
# Description: Hardens the Windows DNS Server (to be used for servers hosting ad-integrated zones)
# Version: 0.2



# Made from STIGViewer and Microsoft Docs + Practice Image Checks







# Remediate remote code execution 0 day
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\DNS\Parameters" /v "TcpReceivePacketSize" /t REG_DWORD /d 0xFF00 /f



# Restart DNS
net stop DNS
net start DNS



# Configure reg keys
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Kerberos\Parameters" /v SupportedEncryptionTypes /t REG_DWORD /d 2147483640 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" /v EnableMulticast /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" /v DisableSmartNameResolution /t REG_DWORD /d 1 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v DisableParallelAandAAAA /t REG_DWORD /d 1 /f
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\DNS\Parameters" -Name MaximumUdpPacketSize -Type DWord -Value 0x4C5 -Force
reg add "HKLM\SYSTEM\CurrentControlSet\Services\DNS\Parameters" /v MaximumUdpPacketSize /t REG_DWORD /d 0x4C5 /f



# Configure logging
Set-DnsServerRRL -Mode Enable -Force
Set-DnsServerResponseRateLimiting -ResetToDefault -Force
Set-DnsServerResponseRateLimiting -WindowInSec 7 -LeakRate 4 -TruncateRate 3 -ErrorsPerSec 8 -ResponsesPerSec 8 -Force



# Configure Defender DNS policies
Set-mppreference -DisableDnsOverTcpParsing $False
Set-mppreference -DisableDnsParsing $False
Set-mppreference -EnableDnsSinkhole $True
Set-DnsServerRecursion -Enable $false
Set-DnsServerRecursion -SecureResponse $true



# Configure DNS Server Diagnostics
Set-DnsServerDiagnostics EnableLoggingForLocalLookupEvent $true
Set-DnsServerDiagnostics EnableLoggingForPluginDllEvent $true
Set-DnsServerDiagnostics EnableLoggingForRecursiveLookupEvent $true
Set-DnsServerDiagnostics EnableLoggingForRemoteServerEvent $true
Set-DnsServerDiagnostics EnableLoggingForServerStartStopEvent $true
Set-DnsServerDiagnostics EnableLoggingForTombstoneEvent $true
Set-DnsServerDiagnostics EnableLoggingForZoneDataWriteEvent $true
Set-DnsServerDiagnostics EnableLoggingForZoneLoadingEvent $true



# Restart DNS
net stop DNS
net start DNS



# DNS config spam
dnscmd /config /EnableVersionQuery 0
dnscmd /config /enablednssec 1
dnscmd /config /retrieveroottrustanchors
dnscmd /config /addressanswerlimit 5
dnscmd /config /bindsecondaries 0
dnscmd /config /bootmethod 3
dnscmd /config /defaultagingstate 1
dnscmd /config /defaultnorefreshinterval 0xA8
dnscmd /config /defaultrefreshinterval  0xA8
dnscmd /config /disableautoreversezones  1
dnscmd /config /disablensrecordsautocreation 1
dnscmd /config /dspollinginterval 30
dnscmd /config /dstombstoneinterval 30
dnscmd /config /ednscachetimeout  604,800
dnscmd /config /enableglobalnamessupport 0
dnscmd /config /enableglobalqueryblocklist 1
dnscmd /config /globalqueryblocklist isatap wpad
dnscmd /config /eventloglevel 4
dnscmd /config /forwarddelegations 1
dnscmd /config /forwardingtimeout 0x5
dnscmd /config /globalneamesqueryorder 1
dnscmd /config /isslave 0
dnscmd /config /localnetpriority 0
dnscmd /config /logfilemaxsize 0xFFFFFFFF
dnscmd /config /logipfilterlist 
dnscmd /config /loglevel 0xFFFF
dnscmd /config /maxcachesize 10000
dnscmd /config /maxcachettl 0x15180
dnscmd /config /maxnegativecachettl 0x384
dnscmd /config /namecheckflag 2
dnscmd /config /norecursion 0
dnscmd /config /recursionretry  0x3
dnscmd /config /AllowUpdate 2
dnscmd /config /recursionretry  0xF
dnscmd /config /roundrobin  1  
dnscmd /config /scavenginginterval 0x0
dnscmd /config /secureresponses 0
dnscmd /config /sendport 0x0
dnscmd /config /strictfileparsing  1
dnscmd /config /updateoptions 0x30F  
dnscmd /config /writeauthorityns  0
dnscmd /config /xfrconnecttimeout    0x1E
dnscmd /config /allowupdate 2
dnscmd /config /enableednsprobes 0
dnscmd /config /localnetprioritynetmask 0x0000ffff
dnscmd /config /openaclonproxyupdates 0
dnscmd /config /DisableNSRecordsAutoCreation 1
dnscmd /config /enableglobalqueryblocklist 1



# Restart DNS 
net stop DNS
net start DNS
