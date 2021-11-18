########### PLATFORM VARIABLES
$tempPath = "C:\Temp"
$PasswordLength = "27"
$MinUpperCase = "4"
$MinLowerCase = "3"
$MinDigit = "2"
$MinSpecial = "1"
###########



########### PACLI VARIABLES
# set $UsePACLI = $false to skip all PACLI functions.
# this script will then just edit the INI files placed in $tempPath, you can upload them to Vault yourself

$UsePACLI = $true
$PACLIPath = "C:\Install\Core Pas 12\PACLI-Rls-v12.0"
$Vault = "LabVault"
$VaultIP = "172.20.65.10"
$VaultPort = "1858"
$UserName = "administrator"
$Password = "Cyberark1"
$SafeName = "PasswordManagerShared"
$FolderName = "Root\Policies"
###########




function editFile {
    foreach ($file in (dir $tempPath)) {
        # edit
        try {
            cd $tempPath
            $content = Get-Content $file
            $content = $content -replace "PasswordLength=.*","PasswordLength=$PasswordLength"
            $content = $content -replace "MinUpperCase=.*","MinUpperCase=$MinUpperCase"
            $content = $content -replace "MinLowerCase=.*","MinLowerCase=$MinLowerCase"
            $content = $content -replace "MinDigit=.*","MinDigit=$MinDigit"
            $content = $content -replace "MinSpecial=.*","MinSpecial=$MinSpecial"
            Set-Content -Path $file -Value $content -Force -ErrorAction Stop

            Write-Verbose "[+] File $file has been SUCCESSFULLY modified" -Verbose
        } catch {
            Write-Warning "[-] File $file FAILED to be modified"
            continue
        } #trycatch
    }# foreach
}

function PACLIsetup {
    cd $PACLIPath

    try {
        $ErrorActionPreference = "Stop"
        .\Pacli.exe init
    } catch {}
    $ErrorActionPreference = "SilentlyContinue"
    .\Pacli.exe define vault=$vault address=$vaultIP port=$VaultPort
    .\Pacli.exe default vault=$Vault user=$UserName
    .\Pacli.exe logon password=$Password
    Write-Verbose "[+] PACLI session to Vault `'$vault`' on server $($vaultip):$VaultPort has been OPENED" -Verbose
    
}

function PACLIcleanup {
    cd $PACLIPath
    .\Pacli.exe logoff
    .\Pacli.exe term
    Write-Verbose "[+] PACLI session to Vault `'$vault`' on server $($vaultip):$VaultPort has been CLOSED" -Verbose
}

function PACLIdownload {
    cd $PACLIPath

    #open the safe PasswordManagerShared
    .\Pacli.exe opensafe safe=$SafeName
    Write-Verbose "[+] Safe $SafeName has been OPENED" -Verbose

    # get list of files
    #$pacliCsvHeaders = @("Name","InternalName","CreationDate","CreatedBy","DeletionDate","DeletionBy","LastUsedDate","LastUsedBy","Size","History","RetrieveLock","LockDate","LockedBy","FileId","Draft","Accessed","LockedByGW","ValidationStatus","LockedByUserId")
    #$policyFiles = .\Pacli.exe --% fileslist safe=PasswordManagerShared folder=Root\Policies output(all,enclose) | convertfrom-csv -Delimiter "," -Header $pacliCsvHeaders
    #$policyFilesPoshPACLI = Get-PVFileList -safe "PasswordManagerShared" -folder "Root\Policies" | select *
    $FileList = .\Pacli.exe fileslist safe=$SafeName folder=$FolderName 'output(name)'

    # select platforms to modify
    $selectedFiles = $FileList | Out-GridView -PassThru


    foreach ($file in $selectedFiles) {
        try {
            $null = New-Item -ItemType Directory -Path $tempPath -ErrorAction SilentlyContinue
        } catch {throw "Cannot create temp path"}

        # download
        try {
            .\Pacli.exe retrievefile safe=PasswordManagerShared folder=Root\Policies file=$file localfolder=$tempPath localfile=$file
            $fileObject = Get-Item $tempPath\$file -ErrorAction Stop
            Write-Verbose "[+] File $file was SUCCESSFULLY retrieved from Vault" -Verbose
        } catch {
            Write-Warning "[-] File $file FAILED to be retrieved from Vault"
            continue
        }# trycatch
    }# foreach
}# function

function PACLIupload {
    # upload the platforms
    foreach ($file in (dir $tempPath)) {
        try {
            cd $PACLIPath
            .\Pacli.exe storefile safe=$SafeName folder=$FolderName file=$file localfolder=$tempPath localfile=($file.name)
            #Add-PVFile -safe "PasswordManagerShared" -folder "Root\Policies" -file $policy -localFolder $tempPath -localFile $file.name -ErrorAction Stop
            Write-Output "[+] File $file was SUCCESSFULLY modified and stored in the Vault `'$Vault`'"
        } catch {
            Write-Warning "[-] File $file FAILED to be stored in the Vault"
        }
    }#foreach
}








if ($UsePACLI -eq $true) {
    PACLIsetup
    PACLIdownload
    editFile
    PACLIupload
} else {
    editFile
}
