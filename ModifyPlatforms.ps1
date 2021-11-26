########### PLATFORM VARIABLES
$tempPath = "C:\Users\Administrator\Downloads\CyberArk\Policies"

# uncomment the ones you want to edit/add
$props = [ordered]@{
    ###### Comman Tasks Parameters
    #AllowedSafes = ".*"
    #MaxConcurrentConnections = "3"

    #MinValidityPeriod = "60"                               # In minutes (-1 for none)
    #ResetOveridesMinValidity = "Yes"
    #ResetOveridesTimeFrame = "Yes"
    #ImmediateInterval = "5"                                # In minutes
    #Interval = "1440"                                      # In minutes
    #UnrecoverableErrors = "2103,2105,2121"                 # one string, seperated by comma
    
    #MaximumRetries = "5"
    #MinDelayBetweenRetries = "90"                          # In minutes

    ###### Password Properties
    PasswordLength                = "27"
    MinUpperCase                  = "4"
    MinLowerCase                  = "3"
    MinDigit                      = "2"
    MinSpecial                    = "1"
    PasswordForbiddenChars        = @("'", '´', '`', '^', '~', 'i', 'l', 'o', '0')            # rule of thumb: use single-quotes, only double-quote when enclosing a single-quote
    #PasswordEffectiveLength = "16"

    ###### Change Task
    AllowManualChange             = "Yes"
    PerformPeriodicChange         = "No"
    #HeadStartInterval = "5"                                # In days (0 for none)
    #ChangeNotificationPeriod = "-1"                        # Minimum number of seconds the change is delayed to allow application password provider synchronization. Use -1 or comment the parameter for no notification
    #DaysNotifyPriorExpiration = "7"
    #FromHour = "-1"                                        # Expected values: 0-23 or -1 for none
    #ToHour = "-1"                                          # Expected values: 0-23 or -1 for none
    #ExecutionDays = "Mon,Tue,Wed,Thu,Fri,Sat,Sun"          # one string, separated by comma

    ###### Verification Task
    VFAllowManualVerification     = "Yes"
    VFPerformPeriodicVerification = "No"
    #VFFromHour = "-1"                                        # Expected values: 0-23 or -1 for none
    #VFToHour = "-1"                                          # Expected values: 0-23 or -1 for none
    #VFExecutionDays = "Mon,Tue,Wed,Thu,Fri,Sat,Sun"          # one string, seperated by comma

    ###### Reconciliation Task
    RCAllowManualReconciliation   = "Yes"
    #RCAutomaticReconcileWhenUnsynched = "No"
    #RCReconcileReasons = "2114,2115,2106,2101"               # one string, Plug-in return codes separated by comma
    #ReconcileAccountSafe = ""
    #ReconcileAccountFolder = ""
    #ReconcileAccountName = ""
    #RCFromHour = "-1"                                        # Expected values: 0-23 or -1 for none
    #RCToHour = "-1"                                          # Expected values: 0-23 or -1 for none
    #RCExecutionDays = "Mon,Tue,Wed,Thu,Fri,Sat,Sun"          # one string, seperated by comma

    ###### Notification settings
    #NFNotifyPriorExpiration = "No"
    #NFPriorExpirationRecipients = ""                        # One or more email addresses, separated by comma. Replaces default ENE recipient list.
    #NFPriorExpirationFromHour = "0"                         # Expected values: 0-23 or -1 for none
    #NFPriorExpirationToHour = "7"                           # Expected values: 0-23 or -1 for none
    #NFPriorExpirationInterval = "60"                        # In minutes
    
    #NFNotifyOnPasswordDisable = "Yes"
    #NFOnPasswordDisableRecipients = ""                      # One or more email addresses, separated by comma. Replaces default ENE recipient list.

    #NFNotifyOnVerificationErrors = "Yes"
    #NFOnVerificationErrorsRecipients = ""                   # One or more email addresses, separated by comma. Replaces default ENE recipient list.
}
###########



########### PACLI VARIABLES
# set $UsePACLI = $false to skip all PACLI functions.
# this script will then just edit the INI files placed in $tempPath, you can upload them to Vault yourself using PrivateArk Client

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
            

            # first filter - only get key-value pairs before a Section marker ( [...] )
            
            $stop = $false
            foreach ($line in $content) {
                if ($line -match "\[") { $stop = $true }
                if ($stop -ne $true) {
                    $m = $line.Split("=")[0]

                    foreach ($key in $props.Keys) {
                        if ($m -match $key) {
                            $line -replace "$key=.*","$key=$($props[$key])"
                        }
                    }


                    # enumerate igennem $props
                    # foreach $key
                    #   $line -replace "$key=.*", "$key=$value"
                    # måske lav en spacer med flowerbox "New values from script"?
                    # ;**************************************
                    # ;New values automatically added from script
                    # ;**************************************
                }
            }
            


            $content = $content -replace "PasswordLength=.*", "PasswordLength=$PasswordLength"
            $content = $content -replace "MinUpperCase=.*", "MinUpperCase=$MinUpperCase"
            $content = $content -replace "MinLowerCase=.*", "MinLowerCase=$MinLowerCase"
            $content = $content -replace "MinDigit=.*", "MinDigit=$MinDigit"
            $content = $content -replace "MinSpecial=.*", "MinSpecial=$MinSpecial"
            $content = $content -replace "PasswordForbiddenChars=.*", "PasswordForbiddenChars=$($PasswordForbiddenChars -join ',')"
            if (!($content -match "PasswordForbiddenChars")) { $content = $content -replace "MinSpecial=.*", "MinSpecial=$MinSpecial`r`nPasswordForbiddenChars=$($PasswordForbiddenChars -join ',')" }
            Set-Content -Path $file -Value $content -Force -ErrorAction Stop

            Write-Verbose "[+] File $file has been SUCCESSFULLY modified" -Verbose
        }
        catch {
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
    }
    catch {}
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
        }
        catch { throw "Cannot create temp path" }

        # download
        try {
            .\Pacli.exe retrievefile safe=PasswordManagerShared folder=Root\Policies file=$file localfolder=$tempPath localfile=$file
            $fileObject = Get-Item $tempPath\$file -ErrorAction Stop
            Write-Verbose "[+] File $file was SUCCESSFULLY retrieved from Vault" -Verbose
        }
        catch {
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
        }
        catch {
            Write-Warning "[-] File $file FAILED to be stored in the Vault"
        }
    }#foreach
}








if ($UsePACLI -eq $true) {
    PACLIsetup
    PACLIdownload
    editFile
    PACLIupload
}
else {
    editFile
}
