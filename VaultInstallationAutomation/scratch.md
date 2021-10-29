$configStepsPath = "C:\Users\kaj\Documents\CyberArk\VaultInstallationAutomation\InstallationConfig.xml"
$ModulesToRun = Read-ConfigurationFile $configStepsPath
$module = $ModulesToRun[0]
$params = $module.Parameters
$Args = $params


$username = ($Args | Where Name -eq "Username").Value
$company = ($Args | Where Name -eq "Company").Value
$VaultDestination = ($Args | Where Name -eq "VaultDestination").Value
$SafesDestination = ($Args | Where Name -eq "SafesDestination").Value
$LicensePath = ($Args | Where Name -eq "LicensePath").Value
$OperatorCDPath = ($Args | Where Name -eq "OperatorCDPath").Value
$InstallRabbitMQ = ($Args | Where Name -eq "InstallRabbitMQ").Value
$PerformHardening = ($Args | Where Name -eq "PerformHardening").Value
$MasterPass = ($Args | Where Name -eq "MasterPass").Value
$AdminPass = ($Args | Where Name -eq "AdminPass").Value

$setupPath = "..\..\setup.exe"
$silentLog = "..\vault_silent.log"
$issFilePath = "C:\Users\kaj\Documents\CyberArk\VaultInstallationAutomation\vault12-0_template.iss"

