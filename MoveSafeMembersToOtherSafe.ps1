param (
    [string]$DomainName = "kaj.local"
)


$cred = Get-Credential -Message "$(get-date) CyberArk PowerShell"
New-PASSession -Credential $cred -BaseURI "https://pvwa1.kaj.local"



#REGION provision environment
Add-PASSafe -SafeName "FT-Pending accounts" -ManagingCPM "PasswordManager" -NumberOfVersionsRetention 5 -UseGen1API

1..10 | foreach {
    $splat = @{
        "SecretType"                 = "Password"
        "secret"                     = ("Cyberark1" | ConvertTo-SecureString -AsPlainText -Force)
        "platformAccountProperties"  = @{"LOGONDOMAIN" = $DomainName }
        "automaticManagementEnabled" = $true
        "SafeName"                   = "FT-Pending accounts"
        "PlatformId"                 = "WIN-ADM-LCL-30"
        "Address"                    = "KAJ-Server$(Get-Random -Maximum 999).$DomainName"
        "Username"                   = "sysman"
    }
    Add-PASAccount @splat
}

#ENDREGION

#REGION add safes
$sysmanAccounts = Get-PASAccount -search "sysman"
$sysmanAccounts | convertto-csv -Delimiter "," -NoTypeInformation | out-file c:\temp\sysmanAccounts.csv


foreach ($sysman in $sysmanAccounts) {
    #create safe
    $null = $sysman.address -match "(.*)\.$DomainName"; $hostname = $matches[1]
    $safename = "FT-S-SRV-$hostname"
    Add-PASSafe -SafeName $safename -ManagingCPM "PasswordManager" -NumberOfVersionsRetention 5 -UseGen1API

    #add safe members
    $safeMemberSplat1 = @{
        "SafeName"                               = $SafeName
        "MemberName"                             = "CyberArk Vault Admins"
        "SearchIn"                               = "Vault"
        "UseAccounts"                            = $true
        "RetrieveAccounts"                       = $true
        "ListAccounts"                           = $true
        "AddAccounts"                            = $true
        "UpdateAccountContent"                   = $true
        "UpdateAccountProperties"                = $true
        "InitiateCPMAccountManagementOperations" = $true
        "SpecifyNextAccountContent"              = $true
        "RenameAccounts"                         = $true
        "DeleteAccounts"                         = $true
        "UnlockAccounts"                         = $true
        "ManageSafe"                             = $true
        "ManageSafeMembers"                      = $true
        "BackupSafe"                             = $true
        "ViewAuditLog"                           = $true
        "ViewSafeMembers"                        = $true
        "AccessWithoutConfirmation"              = $true
        "CreateFolders"                          = $true
        "DeleteFolders"                          = $true
        "MoveAccountsAndFolders"                 = $true
    }
    Add-PASSafeMember @safeMemberSplat1 -UseGen1API
}
#ENDREGION

$sysmanSafes = foreach ($sysman in $sysmanAccounts) {
    $null = $sysman.address -match "(.*)\.$DomainName"; $hostname = $matches[1]
    $safename = "FT-S-SRV-$hostname"
    Get-PASSafe -SafeName $SafeName -UseGen1API
}
$sysmanSafes | convertto-csv -Delimiter "," -NoTypeInformation | out-file c:\temp\sysmanSafes.csv

#REGION swap membership
foreach ($sysman in $sysmanAccounts) {
    Remove-PASAccount -AccountID $sysman.id -UseGen1API -Verbose
}



foreach ($sysman in $sysmanAccounts) {
    $null = $sysman.address -match "(.*)\.$DomainName"; $hostname = $matches[1]
    $safename = "FT-S-SRV-$hostname"

    $splat = @{
        "SecretType"                = $sysman.secretType
        "secret"                    = ("Cyberark1" | ConvertTo-SecureString -AsPlainText -Force)
        "platformAccountProperties" = @{"LOGONDOMAIN" = $hostname }
        "SafeName"                  = $safename
        "PlatformId"                = $sysman.platformId
        "Address"                   = $sysman | select -ExpandProperty Address          #fejler ved $sysman.address
        "Username"                  = $sysman.userName
    }
    Add-PASAccount @splat
}

#remove safes
foreach ($safe in $sysmanSafes) {
    Remove-PASSafe -SafeName $safe.SafeName -UseGen1API
}


