Write-Host "Downloading & Installing NSCLIENT++"
$root = Get-Location
Invoke-WebRequest 'https://github.com/mickem/nscp/releases/download/0.5.2.41/NSCP-0.5.2.41-x64.msi' -OutFile NSCP-0.5.2.41-x64.msi
msiexec.exe /I $root\NSCP-0.5.2.41-x64.msi /QB /L*V "$root\nscp.log"

#create cert
#create cert default does not works.https://github.com/NagiosEnterprises/nrpe/issues/173
Write-Host "Downloading & Installing OPENSSL with winget"
try {&winget install ShiningLight.OpenSSL.Light}
catch{"Error: Winget not found"}
Write-Host "Creating 2048 cert"
&"C:\Program Files\OpenSSL-Win64\bin\openssl.exe" dhparam  2048 > "C:\Program Files\NSClient++\security\nrpe_dh_2048.pem"
Write-host "Uninstalling OpenSSL"
try {&winget uninstall ShiningLight.OpenSSL.Light}
catch{"Error: Winget not found"}

#config adding cert to config
Add-content "C:\Program Files\NSClient++\nsclient.ini" "`n; DH KEY - "
Add-content "C:\Program Files\NSClient++\nsclient.ini" "`ndh = ${certificate-path}/nrpe_dh_2048.pem"

sc.exe stop nscp
sc.exe start nscp

