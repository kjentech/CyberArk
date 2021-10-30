# CyberArk Digital Vault automated installation
CyberArk provide PowerShell modules for installing and upgrading PAS components "PVWA", "CPM" and "PSM" automatically, but provides no official examples for Vault, the centerpiece of CyberArk PAS.

All CyberArk PAS components (including Vault) are packaged by InstallShield, which provides its own answer file format, ISS([1](https://stackoverflow.com/questions/52092688/is-the-install-shield-silent-response-file-iss-file-login-user-rights-depende/52096995#52096995))([2](http://publib.boulder.ibm.com/tividd/td/framework/GC32-0804-00/en_US/HTML/instgu25.htm)).
The PowerShell modules are built to be as generic as possible, with only 2 files being distinct: `InstallationConfig.xml` (which is the one you edit for any other component) and `RunInstallation.psm1`.

To understand the modules better, we'll follow the flow.
- You, the admin installing Vault, will run `.\VaultInstallation.ps1`.
- VaultInstallation imports CommonUtil.psm1 (which imports Commands.psm1, which imports Common.psm1) and runs the command `Install-CAGenericSteps 'InstallationConfig.xml'`.
- Install-CAGenericSteps runs the command `Read-ConfigurationFile $configStepsPath`, which reads 'InstallationConfig.xml' and outputs objects
	- Where to find `RunInstallation.ps1` (`$scriptname`)
	- Parameters in a hashtable (`$params` or `$Args` or `$parameters`) (variable name changes but content is the same)
- Install-CAGenericSteps imports $scriptname.
- Install-CAGenericSteps looks for a function called `Execute` in $scriptname
- Install-CAGenericSteps runs the command `Execute $params` 
	- Execute defines `$issFilePath = "$ScriptRoot\vault12-0.iss"` (must be changed if later version)
	- Execute defines `$setupPath = "$ScriptRoot\..\setup.exe"`
	- Execute defines `$silentLog = "$ScriptRoot\vault_silent.log"`
- Execute runs the command `Invoke-CASetupFile $issFilePath $setupPath $Args $silentLog $additionalArgs` 
- Invoke-CASetupFile runs the command `Set-CAValuesInInstallationFile $issFilePath $parameters`, which will replace each "\{\{Parameter\}\}" in the ISS-file with equivalent value from $parameters.Value
- Invoke-CASetupFile runs the command `$setupPath /s /f1"$issFilePath" /f2"$silentLog"` which installs Vault.


## How to run
- Edit `InstallationConfig.xml` with desired values
- Put the license file in the path you've specified with the exact name `License.xml` (installer will fail with error -2147213312, which is InstallShield's error code for "User aborted the action" if not with the exact file name)
- Edit `RunInstallation.psm1` and make sure $issFilePath matches the filename of your ISS-file.
- Run `VaultInstallation.ps1` on your Vault server.


# # Disclaimer and important reminders
<u>**I AM NOT AFFILIATED WITH CYBERARK, I WILL TAKE NO RESPONSIBILITY FOR ANY LOSS OF DATA! CONSULT CYBERARK SUPPORT FOR GUIDANCE ON AUTOMATIC INSTALLATION AND UPGRADE OF THEIR PRODUCTS.**</u>

I made this repo because I felt curious knowing that CyberArk published automation together with some installers but not all.

I have only tested PAS 12.0, and I'm not going to test install/upgrade with every new version of PAS on-prem. Hence why the ISS-files are named with version numbers.
If you want an answer file for an older or later version of Vault, I highly suggest you generate one yourself with `setup.exe /r`.
