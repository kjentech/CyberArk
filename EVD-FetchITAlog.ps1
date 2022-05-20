param(
    $UserName = "",
    $ExportVaultDataPath = "D:\CyberArk\ExportVaultData-Rls-v12.2"
)

$ScriptTimestamp = Get-Date -Format 'yyyyMMddHHmm'
$Credential = Get-Credential -UserName $UserName -Message "EVD $ScriptTimestamp"
$CredFile = "$ExportVaultDataPath\CreateCredFile\$UserName-$ScriptTimestamp.cred"
$IPAddress = (Get-NetIPConfiguration | Where-Object IPv4DefaultGateway).IPv4Address.IPv4Address
$OSUserName = whoami

Write-Output "[+] Starting script at timestamp $ScriptTimestamp"
Push-Location $ExportVaultDataPath

if (!(Test-Path $CredFile)) {
    try {
        Write-Output "[+] Creating Credfile .."
        &"$ExportVaultDataPath\CreateCredFile\CreateCredFile.exe" $CredFile Password /username $UserName /password $Credential.GetNetworkCredential().Password /IpAddress $IPAddress /OSUsername $OSUserName /AppType EVD /DpapiMachineProtection /DpapiUserProtection
        if ((!Test-Path $CredFile -ErrorAction Stop)) {Write-Error}
    } catch {
        throw "[-] FAILED TO CREATE CREDFILE !!"
    }
    Write-Output "[+] Successfully created Credfile at $CredFile"
}

&"$ExportVaultDataPath\ExportVaultData.exe" `\VaultFile=Vault.ini `\CredFile=$CredFile `\Target=File `\italogfile=Exportitalog.txt

if (Test-Path $CredFile) {
    try {
        Write-Output "[+] Deleting Credfile .."
        Remove-Item $CredFile -ErrorAction Stop
    } catch {
        throw "[-] FAILED TO DELETE CREDFILE !!"
    }
    Write-Output "[+] Successfully deleted Credfile at $CredFile"
}

Pop-Location