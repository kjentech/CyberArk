param(
    $UserName = "",
    $ExportVaultDataPath = "D:\CyberArk\ExportVaultData-Rls-v12.2"
)

begin {
    $ScriptTimestamp = Get-Date -Format 'yyyyMMddHHmm'
    $Credential = Get-Credential -UserName $UserName -Message "EVD $ScriptTimestamp"
    $CredFile = "$ExportVaultDataPath\CreateCredFile\$($Credential.UserName)-$ScriptTimestamp.cred"

    Write-Output "[+] Script started at timestamp $ScriptTimestamp"
}


process {
    Push-Location $ExportVaultDataPath

    if (!(Test-Path $CredFile)) {
        try {
            Write-Output "[+] Creating Credfile .."
            &"CreateCredFile\CreateCredFile.exe" $CredFile Password /username $Credential.username /password $Credential.GetNetworkCredential().Password /IpAddress /OSUsername "$(whoami)" /AppType EVD /DpapiMachineProtection /DpapiUserProtection
            if (!(Test-Path $CredFile -ErrorAction Stop)) {Write-Error}
        } catch {
            throw "[-] FAILED TO CREATE CREDFILE !!"
        }
        Write-Output "[+] Successfully created Credfile at $CredFile"
    }
    
    .\ExportVaultData.exe \VaultFile=Vault.ini \CredFile=$CredFile \Target=File \italogfile=Exportitalog.txt
    
    if (Test-Path $CredFile) {
        try {
            Write-Output "[+] Deleting Credfile .."
            Remove-Item $CredFile -ErrorAction Stop
        } catch {
            throw "[-] FAILED TO DELETE CREDFILE !!"
        }
        Write-Output "[+] Successfully deleted Credfile at $CredFile"
    }
}

end {
    Pop-Location
    Write-Output "[+] Script ended at timestamp $(Get-Date -Format 'yyyyMMddHHmm')"
}