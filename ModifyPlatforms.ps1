########### VARIABLES
$PACLIPath = "C:\Install\Core Pas 12\PACLI-Rls-v12.0"
$tempPath = "C:\Temp"
$Vault = "LabVault"
$VaultIP = "172.20.65.10"
$UserName = "administrator"
$Password = "Cyberark1"

$PasswordLength = "28"
$MinUpperCase = "4"
$MinLowerCase = "3"
$MinDigit = "2"
$MinSpecial = "1"
###########



########### PACLI SETUP
cd $PACLIPath
.\Pacli.exe init
.\Pacli.exe define vault=$vault address=$vaultIP port=1858
.\Pacli.exe default vault=$Vault user=$UserName
.\Pacli.exe logon password=$Password
.\Pacli.exe opensafe safe=PasswordManagerShared
###########



#$pacliCsvHeaders = @("Name","InternalName","CreationDate","CreatedBy","DeletionDate","DeletionBy","LastUsedDate","LastUsedBy","Size","History","RetrieveLock","LockDate","LockedBy","FileId","Draft","Accessed","LockedByGW","ValidationStatus","LockedByUserId")
#$policyFiles = .\Pacli.exe --% fileslist safe=PasswordManagerShared folder=Root\Policies output(all,enclose) | convertfrom-csv -Delimiter "," -Header $pacliCsvHeaders
#$policyFilesPoshPACLI = Get-PVFileList -safe "PasswordManagerShared" -folder "Root\Policies" | select *
$policyFiles = .\Pacli.exe --% fileslist safe=PasswordManagerShared folder=Root\Policies output(name)



# select platforms to modify
$selectedPolicies = $policyfiles | ogv -PassThru


# download, edit and upload the platforms
foreach ($policy in $selectedPolicies) {
    try {
        New-Item -ItemType Directory -Path "C:\temp" -ErrorAction SilentlyContinue
    } catch {throw "Cannot create temp path"}
    $path = "c:\temp"

    # download
    try {
        .\Pacli.exe retrievefile safe=PasswordManagerShared folder=Root\Policies file=$policy localfolder=$path localfile=$policy
        $file = Get-Item $path\$policy -ErrorAction Stop
        Write-Verbose "[+] File $policy was SUCCESSFULLY retrieved from Vault" -Verbose
    } catch {
        Write-Warning "[-] File $policy FAILED to be retrieved from Vault"
        continue
    }


    # edit
    try {
        $content = Get-Content $file
        $content = $content -replace "PasswordLength=.*","PasswordLength=$PasswordLength"
        $content = $content -replace "MinUpperCase=.*","MinUpperCase=$MinUpperCase"
        $content = $content -replace "MinLowerCase=.*","MinLowerCase=$MinLowerCase"
        $content = $content -replace "MinDigit=.*","MinDigit=$MinDigit"
        $content = $content -replace "MinSpecial=.*","MinSpecial=$MinSpecial"
        Set-Content -Path $file -Value $content -Force -ErrorAction Stop

        Write-Verbose "[+] File $policy has been SUCCESSFULLY modified" -Verbose
    } catch {
        Write-Warning "[-] File $policy FAILED to be modified"
        continue
    }


    # upload
    try {
        .\Pacli.exe storefile safe=PasswordManagerShared folder=Root\Policies file=$policy localfolder=$path localfile=($file.name)
        #Add-PVFile -safe "PasswordManagerShared" -folder "Root\Policies" -file $policy -localFolder $path -localFile $file.name -ErrorAction Stop
        Write-Output "[+] File $policy was SUCCESSFULLY modified and stored in the Vault"
    } catch {
        Write-Warning "[-] File $policy FAILED to be stored in the Vault"
    }
}


########### PACLI CLEANUP
.\Pacli.exe logoff
.\Pacli.exe term
###########
