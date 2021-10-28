Import-Module .\CommonUtil -PassThru | Out-Null

$scriptResult = Install-CAGenericSteps 'InstallationConfig.xml'
return $scriptResult | ConvertTo-Json