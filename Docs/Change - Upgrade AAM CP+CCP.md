## Impact Analysis
During the upgrade, any application that has been integrated with AAM to avoid hardcoded passwords may fail to authenticate.


## Implementation Plan
#### Pre-Upgrade
- Acquire the password for the Vault "administrator" user
- Copy the setup files to the server  (ie. `C:\Install\Core PAS 12.6\AAM-Windows64-Rls-v12.6\`)
- Ensure that a recent VM snapshot has been taken for the server


#### Upgrade CP
- Open a PowerShell prompt as Administrator, run the following:
```powershell
# Define variables
$InstallRoot = "C:\CA"
$InstallFolder = "$InstallRoot\Core PAS 12.6"
$BackupFolder = "$InstallRoot\Backup_before_12.6"
$CP = "AAM-Windows64-Rls-v12.6"
$CCP = "Central Credential Provider-Rld-v12.6.1"

# NO TOUCH SECTION

# Create folders if they don't exist
New-Item -ItemType Directory $InstallFolder
New-Item -ItemType Directory $BackupFolder

# Back up current config
Copy-Item 'C:\Program Files (x86)\CyberArk\ApplicationPasswordProvider' -Recurse -Destination $BackupFolder
Copy-Item 'C:\Program Files (x86)\CyberArk\ApplicationPasswordSdk' -Recurse -Destination $BackupFolder
Copy-Item 'C:\inetpub\wwwroot' -Recurse -Destination $BackupFolder

# Get the current Vault IP address
Get-Content 'C:\Program Files (x86)\CyberArk\ApplicationPasswordProvider\Vault\Vault.ini' | Select-String -Pattern "^Address"

# Start the installation
Get-Service "CyberArk Application Password Provider" | Stop-Service -Force -Verbose
cd $InstallFolder\$CP
.\setup.exe
```

- Click Yes to confirm and start the upgrade
- Click Next without changing any configurations
- Verify the Vault connection details and click Next (only one Vault address can be written here, if more Vault addresses are needed, do so under the Post-Upgrade section)
- Type the username and password of the Vault "administrator" user
- Click Next to perform the upgrade
- Click Finish to close the wizard

#### Upgrade CCP
- Open `appwiz.cpl`
- Uninstall "CyberArk AIMWebService"
- Right click the CCP installation setup.exe and select "Run as Administrator"
- Click Next
- Click Finish to close the wizard

#### Post-Upgrade
- If needed, edit Vault.ini  (`C:\Program Files (x86)\CyberArk\ApplicationPasswordProvider\Vault\Vault.ini`) to add all necessary Vault addresses
- Restart the server


## Test and Verification Plan
##### Installation Logs
Review the following log:
```
	C:\Program Files (x86)\CyberArk\ApplicationPasswordProvider\Env\Log\CreateEnv.log
```


##### Service health and Validation
Review the following log:
```
	C:\Program Files (x86)\CyberArk\ApplicationPasswordProvider\Logs\APPConsole.log
```

- Check system health in the PVWA


### Troubleshooting
- CheckConnection fails: Password contains `"`, which makes the command line utility that the installer runs in the background fail.


## Fall Back Plan
- Restore the VM snapshot taken for the server
- Run a Repair of CP to register the application with Vault
- Uninstall CP and reinstall CP as per the Implementation Plan
- Restart the server
- Verify using the Test and Verification Plan


## Review Notes
##### Downtime estimation
If no errors occur, the server will be upgraded and operational within 1 hour(s).

##### Change schedule and time of day of execution
This change is scheduled for DATE, TIME

##### Estimated risk
Risk is medium.