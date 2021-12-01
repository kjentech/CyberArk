########### PLATFORM VARIABLES
$tempPath = "C:\Users\Administrator\OneDrive - Dubex A S\CyberArk\Policies"

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
    PasswordLength                = "20"
    MinUpperCase                  = "2"
    MinLowerCase                  = "2"
    MinDigit                      = "1"
    MinSpecial                    = "1"
    PasswordForbiddenChars        = '''´`^~ilo0'            # single-quotes inside single-quote strings are escaped with single-quotes, so ' ''asd ' will output 'asd, rest are interpreted literally. https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_quoting_rules?view=powershell-7.2
    #PasswordEffectiveLength = "16"



    ###### Change Task
    AllowManualChange             = "Yes"
    #PerformPeriodicChange         = "No"
    #HeadStartInterval = "5"                                # In days (0 for none)
    #ChangeNotificationPeriod = "-1"                        # Minimum number of seconds the change is delayed to allow application password provider synchronization. Use -1 or comment the parameter for no notification
    #DaysNotifyPriorExpiration = "7"
    #FromHour = "-1"                                        # Expected values: 0-23 or -1 for none
    #ToHour = "-1"                                          # Expected values: 0-23 or -1 for none
    #ExecutionDays = "Mon,Tue,Wed,Thu,Fri,Sat,Sun"          # one string, separated by comma

    ###### Verification Task
    VFAllowManualVerification     = "Yes"
    #VFPerformPeriodicVerification = "No"
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

$UsePACLI = $false
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
    begin {
        function Get-Ini {
            [CmdletBinding()]
            param (
                [IO.FileInfo]$FilePath = "$tempPath\$file",
                [switch]$IgnoreComments,
                [string]$CommentChar = ";",
                [string]$NoSection = "_"
            )
    
    
            $ini = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
    
            $commentRegex = "^\s*([$($CommentChar -join '')].*)$"
            $sectionRegex = "^\s*\[(.+)\]\s*$"
            $keyRegex = "^\s*(.+?)\s*=\s*(['`"]?)(.*)\2\s*$"
    
    
            $commentCount = 0
            switch -regex -file $FilePath {
                $sectionRegex {
                    # Section
                    $section = $matches[1]
                    Write-Verbose "$($MyInvocation.MyCommand.Name):: Adding section : $section"
                    $ini[$section] = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
                    $CommentCount = 0
                    continue
                }
                $commentRegex {
                    # Comment
                    if (!$IgnoreComments) {
                        if (!($section)) {
                            $section = $NoSection
                            $ini[$section] = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
                        }
                        $value = $matches[1]
                        $CommentCount++
                        Write-Debug ("Incremented CommentCount is now {0}." -f $CommentCount)
                        $name = "Comment" + $CommentCount
                        Write-Verbose "$($MyInvocation.MyCommand.Name):: Adding $name with value: $value"
                        $ini[$section][$name] = $value
                    }
                    else {
                        Write-Debug ("Ignoring comment {0}." -f $matches[1])
                    }
    
                    continue
                }
                $keyRegex {
                    # Key
                    if (!($section)) {
                        $section = $NoSection
                        $ini[$section] = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
                    }
                    $name, $value = $matches[1, 3]
                    Write-Verbose "$($MyInvocation.MyCommand.Name):: Adding key $name with value: $value"
                    if (-not $ini[$section][$name]) {
                        $ini[$section][$name] = $value
                    }
                    else {
                        if ($ini[$section][$name] -is [string]) {
                            $ini[$section][$name] = [System.Collections.ArrayList]::new()
                            $null = $ini[$section][$name].Add($ini[$section][$name])
                            $null = $ini[$section][$name].Add($value)
                        }
                        else {
                            $null = $ini[$section][$name].Add($value)
                        }
                    }
                    continue
                }
            }
            Write-Output $ini
        }
    
    
    
        function Set-Ini {
            [CmdletBinding()]
            param (
                [Hashtable]$NameValuePairs,
                [string]$Sections = "_",
                #$FilePath

                [Parameter( Mandatory = $true, ValueFromPipeline = $true )]
                [System.Collections.IDictionary]
                $InputObject
            )
    
        
    
            begin {
                $content = Get-Ini -FilePath $FilePath
    
                Function Update-IniEntry {
                    param ($content, $section)
        
                    foreach ($pair in $NameValuePairs.GetEnumerator()) {
                        if (!($content[$section])) {
                            Write-Verbose ("$($MyInvocation.MyCommand.Name):: '{0}' section does not exist, creating it." -f $section)
                            $content[$section] = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
                        }
        
                        Write-Verbose ("$($MyInvocation.MyCommand.Name):: Setting '{0}' key in section {1} to '{2}'." -f $pair.key, $section, $pair.value)
                        $content[$section][$pair.key] = $pair.value
                    }
                }
            }
    
            process {
                if ($Sections) {
                    foreach ($section in $Sections) {
                        # Get rid of whitespace and section brackets.
                        $section = $section.Trim() -replace '[][]', ''
                        Update-IniEntry $content $section
                    }
                }
                else {
                    # No section supplied, go through the entire ini since changes apply to all sections.
                    foreach ($item in $content.GetEnumerator()) {
                        $section = $item.key
                        Update-IniEntry $content $section
                    }
                }
                Write-Output $content
            }
        }
    
    
    
        function Out-Ini {
            [CmdletBinding()]
            param (
                [ValidateNotNullOrEmpty()][ValidateScript( { Test-Path $_ -IsValid })]
                [Parameter( Mandatory, ValueFromPipelineByPropertyName )]
                [string]$FilePath,
    
                [Parameter( Mandatory = $true, ValueFromPipeline = $true )]
                [System.Collections.IDictionary]
                $InputObject,
    
                [ValidateSet("Unicode", "UTF7", "UTF8", "ASCII", "BigEndianUnicode", "Byte", "String")]
                [string]$Encoding = "UTF8",
    
                [string]$NoSection = "_"
            )
    
            begin {
                function Out-Keys {
                    param(
                        [ValidateNotNullOrEmpty()]
                        [Parameter( Mandatory, ValueFromPipeline )]
                        [System.Collections.IDictionary]$InputObject,
    
                        [ValidateNotNullOrEmpty()][ValidateScript( { Test-Path $_ -IsValid })]
                        [Parameter( Mandatory, ValueFromPipelineByPropertyName )]
                        [string]$FilePath,
    
                        [ValidateSet("Unicode", "UTF7", "UTF8", "ASCII", "BigEndianUnicode", "Byte", "String")]
                        [Parameter( Mandatory )]
                        [string]$Encoding = "UTF8",
    
                        $Delimiter = "=",
    
                        [Parameter( Mandatory )]
                        $MyInvocation
                    )
    
                    Process {
                        if (!($InputObject.get_keys())) {
                            Write-Warning ("No data found in '{0}'." -f $FilePath)
                        }
                        Foreach ($key in $InputObject.get_keys()) {
                            if ($key -match "^Comment\d+") {
                                Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing comment: $key"
                                "$($InputObject[$key])" | Out-File -Encoding $Encoding -FilePath $FilePath -Append
                            }
                            else {
                                Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing key: $key"
                                $InputObject[$key] |
                                ForEach-Object { "$key$delimiter$_" } |
                                Out-File -Encoding $Encoding -FilePath $FilePath -Append
                            }
                        }
                    }
                }
    
                $Delimiter = "="
    
                # Splatting Parameters
                $parameters = @{
                    Encoding = $Encoding;
                    FilePath = $FilePath
                }
            }
    
            process {
                $extraLF = ""
                $outFile = New-Item -ItemType file -Path $Filepath -Force
                if (!(Test-Path $outFile.FullName)) { Throw "Could not create File" }
    
                Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing to file: $Filepath"
                foreach ($i in $InputObject.get_keys()) {
                    if (!($InputObject[$i].GetType().GetInterface('IDictionary'))) {
                        #Key value pair
                        Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing key: $i"
                        "$i$delimiter$($InputObject[$i])" | Out-File -Append @parameters
    
                    }
                    elseif ($i -eq $NoSection) {
                        #Key value pair of NoSection
                        Out-Keys $InputObject[$i] `
                            @parameters `
                            -Delimiter $delimiter `
                            -MyInvocation $MyInvocation
                    }
                    else {
                        #Sections
                        Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing Section: [$i]"
    
                        # Only write section, if it is not a dummy ($script:NoSection)
                        if ($i -ne $NoSection) { "$extraLF[$i]"  | Out-File -Append @parameters }
    
                        if ( $InputObject[$i].Count) {
                            Out-Keys $InputObject[$i] `
                                @parameters `
                                -Delimiter $delimiter `
                                -MyInvocation $MyInvocation
                        }
    
                    }
                }
                Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Writing to file: $FilePath"
    
            }
    
    
    
        }
    }

    process {
        foreach ($file in (dir $tempPath)) {
            try {
                $stripped = Get-Ini -FilePath $file
                $props.keys | foreach { $stripped["_"].remove($_) }
                $c = $stripped["_"] + $props
                $d = Get-Ini -FilePath $file | Set-Ini -NameValuePairs $c
                $d | Out-Ini -FilePath "$($file.BaseName)-new.ini"

                Write-Verbose "[+] File $file has been SUCCESSFULLY modified" -Verbose

            }
            catch {
                Write-Warning "[-] File $file FAILED to be modified"
                continue
            } #trycatch
        }# foreach
    }# process
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
