## Checklist
1. [ ] Pre: Ensure that a VM snapshot has been taken for the server
2. [ ] Pre: Acquire the password for the Vault "administrator" user
3. [ ] Pre: Back up the installation folder
4. [ ] Upgrade: Upgrade complete
5. [ ] Upgrade: Performed hardening
6. [ ] Post: Check System Health
7. [ ] Post: Perform a CPM operation (Verify/Change/Reconcile)
8. [ ] Post: Checked all
9. [ ] Post: 2nd consultant checked all



Vault IP:  
Domain:  
Servers:  
Current component version: CPM xx.x  
Target component version: CPM xx.x  
  
  
The upgrade is split into these sections:  
- Pre-Upgrade steps  
- Upgrade  
- Hardening  
- Validate



## Impact Analysis
During the upgrade, password management will not function. This affects Password Change, Verify and Reconciliation actions.

If errors occur during the upgrade, password management will not function until the errors have been resolved or the upgrade has been rolled back as per the "Fall Back Plan".
There is no impact on PVWA, users will still be able to access and use their accounts to connect to servers via the PSM.


## Implementation Plan
#### Pre-upgrade
- Acquire the password for the Vault "administrator" user
- Copy the setup files to the server (ie. `C:\CA\Core PAS 12.6\Central Policy Manager-Rls-v12.6\`)
- Ensure that a recent VM snapshot has been taken for the server
- Back up the installation folder (`C:\Program Files (x86)\CyberArk\Password Manager\`)


#### Upgrade
- Open a PowerShell prompt as Administrator and run the preinstallation script:
```
	cd "C:\CA\Core PAS 12.6\Central Policy Manager-Rls-v12.6\InstallationAutomation"
	Set-ExecutionPolicy Bypass -Scope Process -Force
	.\CPM_Preinstallation.ps1
	Get-Service "CyberArk Password Manager","CyberArk Central Policy Manager Scanner" | Stop-Service -Verbose
```

- Right click Setup.exe and select "Run as Administrator"
- Click Yes to start the upgrade
- Confirm the Vault IP address and port 1858 and click Next
- Type in the username and password for the Prod Vault "administrator" user and click Next
- Click Finish when the wizard is complete

#### Hardening
Run the following PowerShell commands:
```
	Set-ExecutionPolicy Bypass -Scope Process -Force
	cd "C:\CA\Core PAS 12.6\Central Policy Manager-Rls-v12.6\InstallationAutomation"
	.\CPM_Hardening.ps1
```

- OPTIONAL: Restart the server



## Test and Verification Plan
##### Installation Logs
Review the following logs:
```
	C:\Windows\Temp\CPM\CPMInstall.log
```

##### Service health and Validation
Review the following logs:
```
    C:\Program Files (x86)\CyberArk\Password Manager\Logs\PMConsole.log
    C:\Program Files (x86)\CyberArk\Password Manager\Logs\pm.log
```

- Check system health in the PVWA
- Perform a CPM operation (Verify/Change/Reconcile)
- Perform a CPM Verify operation in the PVWA
- Perform a CPM Change operation in the PVWA
- Perform a CPM Reconcile operation in the PVWA




## Fall Back Plan
##### Roll back with snapshot and new Credfile (recommended)
- If a snapshot was taken before upgrading, revert to snapshot.
- Stop services "CyberArk Password Manager", "CyberArk Central Policy Manager Scanner"
- In PrivateArk, create a new password for the CPM user
- Run the following command:
```
	cd "C:\Program Files (x86)\CyberArk\Password Manager\Vault"
	CreateCredFile.exe user.ini Password /username PasswordManager /password Cyberark1 /EntropyFile /DpapiMachineProtection
```
- Start services "CyberArk Password Manager", "CyberArk Central Policy Manager Scanner"
- Test using the "Service health and Validation" procedure in "Test and Verification Plan"



##### Repair the installation
In the case of errors, a Repair operation can solve the issue.
Repairs can be done either after reverting to snapshot, or on the new version.

- open `appwiz.cpl`
- select "CyberArk Password Manager" and click Change/Remove
- select Repair and click Next
- Click Yes to recreate Vault environment
- click Next
- Type in the username and password for the Prod Vault "administrator" user and click Next
- click Finish when the wizard is complete
- Test using the "Service health and Validation" procedure in "Test and Verification Plan"



##### Manually reinstall CPM (only in emergencies)
- Open `appwiz.cpl`
- Select "CyberArk Password Manager" and click Remove
- Select Uninstall and click Next
- Restart the server
- In PrivateArk, rename or delete the CPM's previous app user.
- Install the previous version using the "Upgrade CPM" procedure in "Implementation Plan", select "Yes" or "OK" to any additional prompts.
- Restart the server
- Test using the procedure in "Test and Verification Plan"








## Review Notes
##### ##### Downtime estimation
If no errors occur, the server will be upgraded and operational within X hours.

##### Change schedule and time of day of execution
This change is scheduled for XX:XX inside regular business hours.

##### Estimated risk
Risk is medium.