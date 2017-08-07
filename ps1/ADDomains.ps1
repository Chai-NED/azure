clear

$dnsDomainName = (gwmi WIN32_ComputerSystem).Domain
$netbiosDomainName = (gwmi Win32_NTDomain).DomainName

Write-Host ('DNS Domain Name: ' + $dnsDomainName)
Write-Host ('NETBIOS Domain Name: ' + $netbiosDomainName)