 # REST Token test

 $domainName = "lab.local"
 $BaseURI = "https://pvwa1.lab.local"
 $UserName = "administrator"
 $Password = "Cyberark1"
 
 
 
 # Acquire a token through PsPAS
 #$cred = Get-Credential -Message "$(Get-Date) CyberArk Lab"
 $cred = [PSCredential]::new($UserName, ($Password | ConvertTo-SecureString -AsPlainText -Force))
 New-PASSession -Credential $cred -BaseURI $BaseURI
 
 
 
 
 # Acquire a token through REST
 $tokenBody = @{
 "username" = $UserName
 "password" = $Password
 }
 $token = Invoke-RestMethod -Uri "$BaseURI/PasswordVault/API/auth/Cyberark/Logon" -Method POST -Body ($tokenBody | ConvertTo-Json) -ContentType "application/json"
