## Checklist
1. [ ] Pre: Verify that a recent full backup has been taken
2. [ ] Pre: Verify that the customer can present the Operator key and Master Key (only applicable if upgrading Primary Vault)
3. [ ] Pre: Copy the files (Vault installation files, Windows Update packages) to the server
4. [ ] Pre: Verify that System Locale is set correctly
5. [ ] Pre: Validated that prerequisites are installed
6. [ ] Pre: Verify that CPMs only connects to the Primary Vault
7. [ ] Pre: Verify that all other components point to both vaults (only applicable if upgrading Primary Vault)
8. [ ] Upgrade: Exclude server from monitoring
9. [ ] Upgrade: Back up Vault installation folder
10. [ ] Upgrade: Acquire the password for the Vault "administrator" user (only applicable if upgrading Primary Vault)
11. [ ] Upgrade: Applied Windows patches (if requested)
12. [ ] Upgrade: Installed prerequisites (if any)
13. [ ] Upgrade: Vault upgraded
14. [ ] Upgrade: DR Software upgraded (if applicable)
15. [ ] Post: If DR Server: Started replication
16. [ ] Post: Include server in monitoring
17. [ ] Post: All components validated (only applicable if upgrading Primary Vault)
18. [ ] Post: Validate the password for the Vault "administrator" user (only applicable if upgrading Primary Vault)
19. [ ] Post: Validated service status on Vault servers
20. [ ] Post: Checked all
21. [ ] Post: 2nd consultant checked all




Vault IP:
Domain: N/A  
Servers:
Failover: NO  
Current component version: Vault xx.x  
Target component version: Vault xx.x  

The upgrade is split into these sections:  
- Pre-Upgrade steps  
- Upgrade  
    - Install Vault Software  
        - Validate  
    - Install DR Software  
        - Validate  
- Post-Upgrade steps


## Impact Analysis
If Primary: Throughout the whole upgrade process the vault servers will be rebooted and services taken offline, which will result in PVWA being inaccessible, PSM session already established will not close, but if the connection is lost it cannot be established again before the change is complete.
The CPM will be unable to perform password management tasks and if errors occur during the upgrade, the Vault will be offline until the errors are troubleshooted or the upgrade is rolled back.

If DR: Should errors occur during the upgrade, there will be no DR service to fail over to if the Primary Vault experiences problems.


## Implementation Plan
### Pre-Upgrade
- Ensure that a recent full backup of the Vault and metadata has been taken.
- Ensure that the customer can present the Operator and Master key in the case of an emergency.

##### Prepare the setup files on the Vault server
- Option 1: Copy the files over RDP to the Vault server
- Option 2: Copy the files over PrivateArk Client
	- Copy the setup files to a server that has PrivateArk Client installed
	- Upload the software through PrivateArk Client to a Safe at your control, with a size quota above 5000MB.
	- Use PrivateArk Client to download the software

##### Ensure that the non-Unicode System Locale is set to Danish
This section is only relevant if the system locale has previously been set to Danish (da-DK).

- Open a PowerShell prompt, run the following command
    (Get-WinSystemLocale).name -eq "da-DK"
- If "false", abort the change and arrange a change to set the system locale and reboot the server.

##### Validate Prerequisites
- Open appwiz.cpl
- If "Microsoft Visual C++ 2015-2022 Redistributable" is installed in x64 and x86 versions, prerequisites are OK
- If not installed, perform the step "Applying Windows Updates | Installing Prerequisites for Vault Software" when performing the change.

##### Ensure that CPM does not connect to the DR Vault during the upgrade.
- Log on to all CPMs
- Edit `C:\Program Files\CyberArk\Password Manager\Vault\Vault.ini`
- Ensure that the IP address of the Primary Vault is the ONLY IP address present in the ADDRESS section.

##### Ensure that all components (except for CPM) point to the DR Vault in addition to the Primary Vault
- On all component servers, open `vault.ini`
- Take note of the value in ADDRESS
- If any component does not include the DR Vault IP address, add it in the following format `ADDRESS=PRIMARYVAULTIP,DRVAULTIP`



### Upgrade
##### Exclude server from monitoring
- Exclude the server from monitoring solutions
- Instructions vary by product

##### Back up the installation folders
- `C:\Program Files (x86)\PrivateArk\Server`
- `C:\Program Files (x86)\PrivateArk\Client`

##### Applying Windows Updates | Installing Prerequisites for Vault Software
This section must be followed if the customer has requested Windows Updates to be installed during the change, or if the prerequisites for the Vault Software aren't met.
Skip this section if prerequisites are met, and the customer doesn't need Windows Updates applied.

- Run the following PowerShell commands as administrator:
```
	$vaultPackagePath = "C:\CA\Core PAS 13.0\Vault"         # change this as needed
	& $vaultPackagePath\WSUS\OpeningServices.ps1
	Set-Service "PrivateArk Server" -StartupType Disabled
```

- Ensure that service "PrivateArk Server" has been set to startup mode Disabled to prevent the Vault from starting automatically after restart
- Restart the server
- Run the wanted update package to install the update
- Install any missing prerequisites
- Restart the server

Test using the Test and Verification Plan before proceeding.


##### Vault Software upgrade
- Acquire the password for the Prod Vault "administrator" user.
- Run the following PowerShell commands as administrator to stop all CyberArk related services and set the DR service to not start automatically
```
	Get-Service "Cyber-Ark Event Notification Engine", "PrivateArk Remote Control Agent", "PrivateArk Server", "PrivateArk Database", "CyberArk Logic Container" | Stop-Service -Verbose
	Get-Service "CyberArk Vault Disaster Recovery" -ErrorAction SilentlyContinue | Stop-Service -Verbose
	Get-Service "CyberArk Vault Disaster Recovery" -ErrorAction SilentlyContinue | Set-Service -StartupType Manual
```

- Right click Setup.exe and select "Run as Administrator"
- Click Yes to converting data during the upgrade
- Click No to installing RabbitMQ
- Click Finish when the wizard is complete

Test using the "Testing the Primary Vault installation via the PVWA" section of the Test and Verification Plan


##### PrivateArk Client
- Right click Setup.exe and select "Run as Administrator"
- Click next on the Wizard until completion


##### DR Software
- Stop service "PrivateArk Server" if running
- Right click Setup.exe and select "Run as Administrator"
- Click Yes to proceed with the Disaster Recovery application upgrade.
- Click Finish when the wizard is complete
- If the server is a DR Vault, set service "CyberArk Vault Disaster Recovery" to startup type Automatic
- If the server is a DR Vault, start service "CyberArk Vault Disaster Recovery"


##### Clean up after Windows Update or prerequisite installation
If you applied Windows Updates or installed prerequisites, follow this section.

- Run the following PowerShell commands as administrator:
```
	$vaultPackagePath = "C:\CA\Core PAS 13.0\Vault"            # change this as needed
	& $vaultPackagePath\WSUS\ClosingServices.ps1
```
- Restart the server


##### Include server in monitoring
- Include the server in your monitoring solutions
- Instructions vary by product


##### Final service validation
- Test using the "Validating component functionality" section of the Test and Verification Plan
- Validate service status using the "Validate service status" section of the Test and Verification Plan



## Test and Verification Plan
### Validating the DR service
Review the following logs:
```
	C:\Program Files (x86)\PrivateArk\PADR\Logs\padr.log
```

Tail the log by running `Get-Content -Tail 10 -Wait "C:\Program Files (x86)\PrivateArk\PADR\Logs\padr.log"`


### Validate component functionality
#### Vault/PVWA
- Log onto PVWA with an external directory user using LDAP and RADIUS
- Search for an account
- Log off
- Log onto PVWA with a CyberArk Vault user
- Check System Health, take note of any disconnected components

The PVWA is now validated. If any components are shown as disconnected, review those.

Troubleshooting:
- Run `iisreset` on the PVWA server

#### CPM
- Check `pmconsole.log` and `pm_error.log` on the CPM server
- Perform a Validate operation in the PVWA

Troubleshooting:
- Restart service `CyberArk Password Manager`

#### PSM
- Check `psmconsole.log` on the PSM server
- Change a platform to connect to the PSM server and test a Connection Component

Troubleshooting:
- Restart service `CyberArk Privileged Session Manager`

#### PTA
- Check services on the PTA server as root: `MONIT_STATUS`
- Browse to the Security Events page in the PVWA

Troubleshooting:
- Restart all PTA services: Run `UTILITYDIR`, `./run.sh`, 3, 5, 4, 6

#### PSMP
- Check service `psmpsrv` on the PSMP server: `systemctl status psmpserv`
- The customer must verify PSMP functionality

Troubleshooting: Restart PSMP service: `systemctl restart psmpsrv`


### Validate service status
- DR Vault server:
	- Stopped: CyberArk Event Notification Service
	- Started: CyberArk Logic Container
	- Started: CyberArk Vault Disaster Recovery
	- Started: PrivateArk Database
	- Started: PrivateArk Remote Control Agent
	- Stopped: PrivateArk Server
- Primary Vault server:
	- Stopped: CyberArk Event Notification Service
	- Started: CyberArk Logic Container
	- Stopped: CyberArk Vault Disaster Recovery
	- Started: PrivateArk Database
	- Started: PrivateArk Remote Control Agent
	- Started: PrivateArk Server




## Fall Back Plan
NOTE: Vault reinstallation is only necessary in absolute emergencies, where either both vaults have been corrupted, or the Vault installation itself has been corrupted in the upgrade process.

### Replicate from DR Vault (Recommended)
- Stop service "CyberArk Vault Disaster Recovery" and "PrivateArk Server"
- Perform a full replication and manual failback as detailed in the Implementation Plan
- Validate using the "Testing the Primary Vault installation" section of the Test and Verification Plan

### Reinstall Vault (Emergencies)
> [!NOTE]
> A common case for Vault software reinstallation is when you upgrade a DR vault and you forgot to turn off the DR service. This will sync a database down from the Primary Vault that's a lower version than the Vault software installed. If there's no database version bump, there's a high chance that it will work fine, but if a particular Vault version happens to bump the schema version, you'll find that the Vault will not be able to start. To revert this, you need to uninstall the new Vault software and install the old one.

- Uninstall Vault
- Reinstall Vault in the same version and with the same Operator key as the currently active currently active Vault
- Replicate from the currently active Vault or restore a full backup
- Validate using the "Testing the Vault installation" section of the Test and Verification Plan

### Restore a full backup (Last Resort)
> [!NOTE]
> Restoring a full backup is only necessary in absolute emergencies, where the data of both vaults have been corrupted.

- Copy a full backup to `C:\PrivateArk\Restored Safes` on the Vault server
- Stop service "CyberArk Vault Disaster Recovery" and "PrivateArk Server"
- Edit `C:\Program Files (x86)\PrivateArk\Server\Conf\dbparm.ini`
	- Note the current value of BackupFilesDeletion and RecoveryPrvKey
	- Set the following parameters: `BackupFilesDeletion=No` and `RecoveryPrvKey=C:\PathToMasterCD\RecPrv.key`
- From an elevated command prompt, run `cd C:\Program Files (x86)\PrivateArk\Server; CAVaultManager RecoverBackupFiles`
- Run `CAVaultManager RestoreDB`, which will synchronize the Vault Metadata
- Edit `C:\Program Files (x86)\PrivateArk\Server\Conf\dbparm.ini`, restore to previously noted values
- Start service "PrivateArk Server"
- Validate using the "Testing the Primary Vault installation" section of the Test and Verification Plan


## Review Notes
##### Downtime estimation
If no errors occur, the server will be upgraded and operational within 2 hours.

##### Change schedule and time of day of execution
This change is scheduled for XX:XX inside regular business hours.

##### Estimated risk
Risk is medium.