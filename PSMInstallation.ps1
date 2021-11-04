cd "C:\Install\Core Pas 12\Privileged Session Manager-Rls-v12.0\InstallationAutomation"

# Prerequisites
# først: edit PrerequisitesConfig.xml
# RDSSecurityLayer: Yes
$Action = .\Execute-Stage.ps1 'Prerequisites\PrerequisitesConfig.xml' -silentMode "Silent" -displayJson -delayedrestart
$Action | Out-File -FilePath 'Prerequisites\psm_prerequisites_log.log'
$Result = Get-Content 'Prerequisites\psm_prerequisites_log.log' -Raw | ConvertFrom-Json
if ($Result.isSucceeded -ne 0) {
    echo "poo"
 } else {
    echo "yay"
}


# Installation
# først: edit InstallationConfig.xml
$Action = .\Execute-Stage.ps1 'Installation\InstallationConfig.xml' -silentMode "Silent" -displayJson -delayedrestart
$Action | Out-File -FilePath 'Installation\psm_Installation_log.log'
$Result = Get-Content 'Installation\psm_Installation_log.log' -Raw | ConvertFrom-Json
if ($Result.isSucceeded -ne 0) {
    echo "poo"
 } else {
    echo "yay"
}


# PostInstallation
# først: edit PostInstallationConfig.xml
$Action = .\Execute-Stage.ps1 'PostInstallation\PostInstallationConfig.xml' -silentMode "Silent" -displayJson -delayedrestart
$Action | Out-File -FilePath 'PostInstallation\psm_PostInstallation_log.log'
$Result = Get-Content 'PostInstallation\psm_PostInstallation_log.log' -Raw | ConvertFrom-Json
if ($Result.isSucceeded -ne 0) {
    echo "poo"
 } else {
    echo "yay"
}

$ErrorActionPreference = "Stop"
try {
    if ((Get-WmiObject -Class Win32_UserAccount -Filter {Name = "PSMConnect"}) -eq $null) { echo "poo" }
    if ((Get-WmiObject -Class Win32_UserAccount -Filter {Name = "PSMAdminConnect"}) -eq $null) { echo "poo" }
    echo "yay"
} catch {
    Write-Output "Error occured: $error"
    echo "poo"
}
$ErrorActionPreference = "Continue"


# Hardening
# først: edit PostInstallationConfig.xml
# sæt OutOfDomainHardening
$Action = .\Execute-Stage.ps1 'Hardening\HardeningConfig.xml' -silentMode "Silent" -displayJson -delayedrestart
$Action | Out-File -FilePath 'Hardening\psm_Hardening_log.log'
$Result = Get-Content 'Hardening\psm_Hardening_log.log' -Raw | ConvertFrom-Json
if ($Result.isSucceeded -ne 0) {
    echo "poo"
 } else {
    echo "yay"
}


# Registration
# først: edit RegistrationConfig.xml
$Action = .\Execute-Stage.ps1 'Registration\RegistrationConfig.xml' -silentMode "Silent" -displayJson -delayedrestart
$Action | Out-File -FilePath 'Registration\psm_Registration_log.log'
$Result = Get-Content 'Registration\psm_Registration_log.log' -Raw | ConvertFrom-Json
if ($Result.isSucceeded -ne 0) {
    echo "poo"
 } else {
    echo "yay"
}

