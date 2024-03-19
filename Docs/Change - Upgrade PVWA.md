## Checklist
1. [ ] Pre: Ensure that a VM snapshot has been taken for the server
2. [ ] Pre: Acquire the password for the Vault "administrator" user
3. [ ] Pre: Back up the installation folder and the IIS web site
4. [ ] Pre: Note the value of HTTP Redirect in IIS/Default Web Site
5. [ ] Pre: Note the value of "Access this computer from the network" in secpol.msc > Local Policies > User Rights Assignment
6. [ ] Upgrade: Upgrade complete
7. [ ] Upgrade: Performed hardening
8. [ ] Post: Test LDAP and RADIUS authentication
9. [ ] Post: Check System Health
10. [ ] Post: Check the redirect URL in IIS/Default Web Site
11. [ ] Post: Check custom MIME types
12. [ ] Post: Check the value of "Access this computer from the network" in secpol.msc > Local Policies > User Rights Assignment
13. [ ] Post: Checked all
14. [ ] Post: 2nd consultant checked all



Vault IP:  
Domain:  
Servers:  
Current component version: PVWA 12.x  
Target component version: PVWA 13.0
  
  
The upgrade is split into these sections:  
- Pre-Upgrade steps  
- Upgrade  
- Hardening  
- Validate





## Impact Analysis
During the upgrade, the PVWA service will be down and users connecting to the web portal through this server will experience errors until the upgrade is complete or has been rolled back.


## Implementation Plan
##### Pre-upgrade
- Acquire the password for the Prod Vault "administrator" user
- Copy the setup files to the server (ie. `C:\Install\Core PAS 12.6\Password Vault Web Access-Rls-v12.6`)
- Ensure that a VM snapshot has been taken for the server
- Back up the installation folder (`C:\CyberArk\Password Vault Web Access\`) and the IIS web site (`C:\inetpub\wwwroot\`)
- Note the value of HTTP Redirect in IIS/Default Web Site
- Note the value of "Access this computer from the network" in secpol.msc > Local Policies > User Rights Assignment
- Ensure that the server has been excluded from load balancing: `(Get-Counter "\web service(default web site)\current connections").CounterSamples.CookedValue`

##### Upgrade
- Open a PowerShell prompt as Administrator, navigate to the InstallationAutomation directory under the installation folder
```
	cd "C:\CA\Core PAS 12.6\Password Vault Web Access-Rls-v12.6\InstallationAutomation"
	Set-ExecutionPolicy Bypass -Scope Process -Force
	.\PVWA_Prerequisites.ps1
	cd ..
	.\setup.exe
	
```
- Click install to the prerequisites. If they fail, they may already be installed in a later version
- Click Next and select Yes to accept the EULA
- Type in the username and password for the Prod Vault "administrator" user.
- Click Finish when the wizard is complete


##### Adjust the PVWA connection component to work PVWA 13.0
If you have upgraded from PVWA 12.x to PVWA 13.0 or later, follow this section.
Attempt to launch the PVWA Connection Component. If this fails, edit the WebFormFields property on the PVWA Connection Component:

- Copy the value of the WebFormFields property of the Connection Component
- Paste in the following and save:

user_pass_form_username_field>{username}(searchby=id)
user_pass_form_password_field>{password}(searchby=id)
span.p-button-label>(Button)(SearchBy=css)

Test the PVWA Connection Component again.


##### Hardening
- Run the following PowerShell script: `cd "C:\CA\Core PAS 12.6\Password Vault Web Access-Rls-v12.6\InstallationAutomation"; .\PVWA_Hardening.ps1`
- The hardening script resets the local policy "Access this computer from the network", which may be required for monitoring by an NMS.
	- `secpol.msc`
	- Local Policies, User Rights Assignment
	- Allow this computer from the network: Add `domain\MonitoringAccount`
- The hardening script clears custom MIME types, if those had previously been set
	- `inetmgr`
	- PasswordVault, MIME Types
	- Add
		- File name extension: `.mp4`
		- MIME type: `video/mp4`



## Test and Verification Plan
#### Installation Logs
Review the following logs for errors:
```
	C:\Windows\Temp\PVWAInstall.log
	C:\Windows\Temp\PVWAInstallEnv.log
	C:\Windows\Temp\PVWAInstallError.log
	C:\Windows\Temp\PVWAInstallErrorEnv.log
	C:\CyberArk\Password Vault Web Access\Env\Log\CheckConnection.log
	C:\CyberArk\Password Vault Web Access\Env\Log\ConfigureInstance.log
	C:\CyberArk\Password Vault Web Access\Env\Log\ConfigureVault.log
	C:\CyberArk\Password Vault Web Access\Env\Log\RegisterInstance.log
```

#### Service health and Validation
- Test Authentication methods using PVWA.
- Check system health on https://SERVERNAME.DOMAIN/PasswordVault
- Check the redirect URL in IIS/Default Web Site
- Check the value of "Access this computer from the network" in secpol.msc > Local Policies > User Rights Assignment

## Fall Back Plan
##### Roll back with snapshot and new Credfile (recommended)
If a snapshot was taken before upgrading, revert to snapshot.
Create a new credfile for the PVWA component user and run `iisreset`.
Test connectivity as noted in the Test and Verification Plan.

##### Repair the installation
If no snapshot was taken, attempt a repair of the installation.
- Open `appwiz.cpl`
- Select "CyberArk Password Vault Web Access" and click Change/Remove
- Select Repair and click Next

The PVWA server will register itself with the Vault again.
Test connectivity as noted in the Test and Verification Plan.

## Review Notes
#### Downtime estimation
If no errors occur, the server will be upgraded and operational within 1 hour.

#### Change schedule and time of day of execution
This change is scheduled for outside regular office hours dd-mm.

#### Estimated risk
Risk is medium.