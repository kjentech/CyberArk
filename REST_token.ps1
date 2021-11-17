 $domainName = "lab.local"
 $BaseURI = "https://pvwa1.lab.local"
 
 
 
 # Acquire a token through PsPAS
 $cred = Get-Credential -Message "$(Get-Date) CyberArk Lab"
 New-PASSession -Credential $cred -BaseURI $BaseURI
 
 
 
 
 # Acquire a token through REST
 $tokenBody = @{
 "username" = "administrator"
 "password" = "Cyberark1"
 }
 $token = Invoke-RestMethod -Uri "$BaseURI/PasswordVault/API/auth/Cyberark/Logon" -Method POST -Body ($tokenBody | ConvertTo-Json) -ContentType "application/json"
