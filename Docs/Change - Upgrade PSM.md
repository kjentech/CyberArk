## Checklist
1. [ ] Pre: A VM snapshot has been taken for the server
2. [ ] Pre: Acquire the password for the Vault "administrator" user
3. [ ] Pre: PSM server has been drained of active users before the upgrade
4. [ ] Pre: PSM server is not included in Load Balancing during the upgrade
5. [ ] Pre: Back up the installation folder
6. [ ] Pre: "administrator" is not a safe owner of the "PSMUnmanagedSessionAccounts" safe
7. [ ] Pre: Take note of current settings
8. [ ] Upgrade: Prerequisites validated
9. [ ] Upgrade: Upgrade complete
10. [ ] Upgrade: Applied AppLocker and hardening
11. [ ] Post: Check System Health
12. [ ] Post: Test connection components defined in the description
13. [ ] Post: Checked all
14. [ ] Post: 2nd consultant checked all



Vault IP:  
Domain:  
Servers:  
Current component version: PSM xx.x  
Target component version: PSM xx.x 


The following are customizations that need to be made for CUSTOMER1:

CUSTOMER1 T2:
```
PSMHardening.ps1
$PSM_CONNECT_USER                  = "domain\srvpampsmconnect"
$PSM_ADMIN_CONNECT_USER            = "domain\srvpampsmadmconnect"
$SUPPORT_WEB_APPLICATIONS          = $true

PSMConfigureAppLocker.ps1
$PSM_CONNECT                        = "domain\srvpampsmconnect"
$PSM_ADMIN_CONNECT                  = "domain\srvpampsmadmconnect"

basic_psm.ini
PSMServerAdminId="srvpampsmadmconnect"
```



CUSTOMER1 T1:
```
PSMHardening.ps1
$PSM_CONNECT_USER                  = "domain\srvpampsmcon-t1"
$PSM_ADMIN_CONNECT_USER            = "domain\srvpampsmadmcon-t1"
$SUPPORT_WEB_APPLICATIONS          = $true

PSMConfigureAppLocker.ps1
$PSM_CONNECT                        = "domain\srvpampsmcon-t1"
$PSM_ADMIN_CONNECT                  = "domain\srvpampsmadmcon-t1"

basic_psm.ini
PSMServerAdminId="srvpampsmadmcon-t1"
```


  
The upgrade is split into these sections:  
- Pre-Upgrade steps  
- Upgrade  
- Post-Upgrade steps  
    - Customize the PSMConfigureAppLocker.xml file  
    - Prepare for hardening with a domain-based PSMConnect and PSMAdminConnect user  
    - Applying AppLocker and Hardening
    - Re-applying permissions on PSMSessionAlert.exe



## Impact Analysis
During the upgrade, connections through this PSM will fail, causing some users to be unable to launch PSM sessions. Accounts assigned to platforms that are configured to only use this PSM will fail until the upgrade is complete.
Should any errors occur during the upgrade, the PSM server will be out of operation until the errors have been resolved or the upgrade has been rolled back per the Roll Back Plan.

This PSM is part of a Load Balanced setup. During the upgrade, the performance of the other PSM servers in the Load Balanced setup will be degraded due to the higher load.



## Implementation Plan
### Pre-upgrade
- Acquire the password for the Vault "administrator" user
- Copy the setup files to the server (ie. `C:\CA\Core PAS 12.6\Privileged Session Manager-Rls-v12.6\`)
- Ensure that .NET Framework 4.8 is installed. Reboot the server if necessary.
- Ensure that the PSM server has been drained of active users before the upgrade
- Ensure that the PSM server is not included in Load Balancing during the upgrade
- Back up the installation folder (`C:\Program Files (x86)\CyberArk\PSM`)
- Ensure that a recent VM snapshot has been taken for the server
- Ensure "administrator" is not a safe owner of the "PSMUnmanagedSessionAccounts" safe (<https://cyberark-customers.force.com/s/article/00003431)>
- Ensure PVWAAppUsers is a safe owner of PSMUnmanagedSessionAccounts with the following permissions (<https://docs.cyberark.com/Product-Doc/OnlineHelp/PAS/Latest/en/Content/PAS%20INST/Upgrading-PSM-in-an-Environment-with-Multiple-PVWAs.htm?tocpath=Installation%7CUpgrade%7CPrivileged%20Session%20Manager%7C_____3)>
- Ensure that PSRemoting is enabled, test using this command: `Get-RDServer`
- Take screenshots of the current settings for evidence keeping. Use this PowerShell script to open all relevant files:
```
	# take a screenshot of each AppLocker tab
	secpol.msc

	# take a screenshot of the file
	notepad "C:\Program Files (x86)\CyberArk\PSM\basic_psm.ini"

	# take a screenshot of $PSM_CONNECT_USER and $PSM_ADMIN_CONNECT_USER
	notepad "C:\Program Files (x86)\CyberArk\PSM\Hardening\PSMHardening.ps1"

	# take a screenshot of $PSM_CONNECT and $PSM_ADMIN_CONNECT
	notepad "C:\Program Files (x86)\CyberArk\PSM\Hardening\PSMConfigureAppLocker.ps1"

	# take a screenshot of the output and copy out the value for later use
	$psmsessionalertACL = (Get-Acl "C:\Program Files (x86)\CyberArk\PSM\Components\PSMSessionAlert.exe").Access | where {$_.FileSystemRights -match "ReadAndExecute" -and $_.AccessControlType -eq "Allow" -and $_.IsInherited -ne $true -and $_.IdentityReference -notmatch "NT AUTHORITY"} | Sort-Object -Property IdentityReference
	$psmsessionalertACL.IdentityReference
	
```



### Upgrade
- Open a PowerShell prompt as Administrator, navigate to the setup folder
```
	Set-ExecutionPolicy Bypass -Scope Process -Force
	cd "C:\CA\Core PAS 12.6\Privileged Session Manager-Rls-v12.6"
	Get-ChildItem -Recurse | Unblock-File
	.\setup.exe
	
```
- Click Install to install the prerequisites.
	- If Visual C++ Redistributable fails to install, verify that a newer version is already installed and continue.
	- If RemoteApp fails to install, verify that local PSRemoting is enabled and that `\\localhost\c$` is accessible. <https://cyberark-customers.force.com/s/question/0D52J00006aGhduSAC/upgrade-issue-with-the-psm>
	- To enable PSRemoting, run the following PowerShell script and rerun the installer:
```
		# if this registry value has been set by GPO, a "gpupdate /force" or a restart after installation is recommended
		Remove-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service" -Name AllowAutoConfig -Verbose
		Configure-SMRemoting.exe -disable
		Configure-SMRemoting.exe -enable
```

- Check Yes to shut down the PSM service
- On the introduction screen, click Next
- Confirm the Configuration Safe name as PVWAConfig and click Next
- Confirm the Vault Address and Port and click Next
- Type in the username and password for the "administrator" Vault user
- Accept the defaults on the API Gateway screen and click Next
- Click Next and do NOT check the box for "PKI authentication for PSM"
- On the Hardening screen, click Advanced and uncheck "Run the Hardening Script" and "Set up AppLocker Rules", click Next
- When the wizard is complete, click Finish to restart the server


### Post-Upgrade
- Wait for the PVWA RefreshPeriod interval (20 minutes by default) or run `iisreset` on all PVWA servers


#### Customize the PSMConfigureAppLocker.xml file
> [!NOTE]
> This step is performed because CyberArk may update the contents of PSMConfigureAppLocker.xml from version to version. The important thing is to check if there's any changes between the old default and the new default, and this can be done in a lab or test environment. If nothing important has changed, it's safe to let the old XML be carried into the new version.

- Diff PSMConfigureAppLocker.xml and PSMConfigureAppLocker.bak for changes between versions
- Edit PSMConfigureAppLocker.xml with your desired entries


#### Prepare for hardening with a domain-based PSMConnect and PSMAdminConnect user
- Edit `C:\Program Files (x86)\CyberArk\PSM\Hardening\PSMHardening.ps1`
	Change the variables `$PSM_CONNECT_USER` and `$PSM_ADMIN_CONNECT_USER` to the values noted in the description.
- Save and exit
- Edit `C:\Program Files (x86)\CyberArk\PSM\Hardening\PSMConfigureAppLocker.ps1`
	Change the variables `$PSM_CONNECT` and `$PSM_ADMIN_CONNECT` to the values noted in the description.
- Save and exit
- Edit `C:\Program Files (x86)\CyberArk\PSM\basic_psm.ini`
	Change the variable `PSMServerAdminId` to the value noted in the description.


#### Applying AppLocker and Hardening
- Open a PowerShell prompt as administrator, run the following commands:
```
	Set-ExecutionPolicy Bypass -Scope Process -Force
	cd 'C:\Program Files (x86)\CyberArk\PSM\Hardening'
	.\PSMHardening.ps1 -postInstall
	.\PSMConfigureAppLocker.ps1
	Restart-Service "Cyber-Ark Privileged Session Manager"
	
```


#### Re-applying permissions on PSMSessionAlert.exe
> [!NOTE]
> This is done only if you have accounts that log on directly to the PSM server. CUSTOMER1 has connection components that require this.

- Right click  `C:\Program Files (x86)\CyberArk\PSM\Components\PSMSessionAlert.exe`
- Properties, Security, Edit
- Add any needed users with the Read and Execute permissions. Look at the values noted before the upgrade for reference.

## Test and Verification Plan
##### Installation Logs
Review the following logs:
```
    C:\Windows\Temp\PSMInstall.log
```


##### Service health and Validation
Review the following logs:
```
	 C:\Program Files (x86)\CyberArk\PSM\Logs\PSMConsole.log
```

- Validate permissions on PSMSessionAlert.exe
- Check system health on PVWA.
- Test multiple Connection Components, use a platform that uses the upgraded PSM server.
	- PSM-RDP
	- In-box Windows applications (eg. mmc)
	- Web Dispatcher (eg. PVWA)
	- AutoIT-based dispatchers

##### Troubleshooting
- If AppLocker errors of any kind appear:
	- Run `PSMConfigureApplocker.ps1` again and verify
	- `secpol.msc`, AppLocker, right click, Clear Policy
	- Right click each subgroup, Add Default Policy
	- Run `PSMConfigureApplocker.ps1` again and verify
       - Last resort: Restart the server




## Fall Back Plan
##### Roll back with snapshot and new Credfile (recommended)
- Revert the VM snapshot
- Stop service "CyberArk Privileged Session Manager"
- In PrivateArk, create a new password for the PSM's "PSMApp" and "PSMGW" users
- Open a PowerShell prompt, run the following command to create new credfiles for the PSM's "PSMApp" and "PSMGW" users:
```
	cd "C:\Program Files (x86)\CyberArk\PSM\Vault"
	CreateCredFile.exe psmapp.ini Password /username PSMAppUser /password Cyberark1 /EntropyFile /DpapiMachineProtection
	CreateCredFile.exe psmgw.ini Password /username PSMGWUser /password Cyberark1 /EntropyFile /DpapiMachineProtection
	
```
- Start service "CyberArk Privileged Session Manager"
- Test using the "Service health and Validation" procedure in "Test and Verification Plan"


##### Manually reinstall PSM (only in emergencies)
- Open `appwiz.cpl`
- Uninstall "CyberArk Privileged Session Manager"
- Restart the server
- In PrivateArk, rename or delete the PSM's previous "PSMApp" and "PSMGW" users
- Install the previous version using the "Upgrade PSM" procedure in "Implementation Plan", select "Yes" or "OK" to any additional prompts.
- Restart the server
- Test using the procedure in "Test and Verification Plan"



## Review Notes
##### Downtime estimation
If no errors occur, the server will be upgraded and operational within 4 hour(s).
30 minutes are allocated for pre-upgrade checks
30 minutes is allocated for upgrading
2 hours is allocated for post-upgrade tasks
1 hour is allocated to test and verification

##### Change schedule and time of day of execution
This change is scheduled for outside regular office hours.

##### Estimated risk
Risk is high.


