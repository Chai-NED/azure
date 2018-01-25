# ##############################
# Purpose: Output a VM's DNS and NetBIOS domain names
#
# Author: Patrick El-Azem
# ##############################

$dnsDomainName = (gwmi WIN32_ComputerSystem).Domain
$netbiosDomainName = (gwmi Win32_NTDomain).DomainName

Write-Host ('DNS Domain Name: ' + $dnsDomainName)
Write-Host ('NETBIOS Domain Name: ' + $netbiosDomainName)