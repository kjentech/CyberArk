> [!IMPORTANT]
> Upgrading the Vault in this way is not supported. Follow the guide [[Change - Upgrade Vault]] instead.
> Proceed with caution.


## Checklist
1. [ ] Pre: Verify that a recent full backup has been taken
2. [ ] Pre: Verify that the customer can present the Operator key and Master Key
3. [ ] Pre: Copy the files (Vault installation files, Windows Update packages) to the server
4. [ ] Pre: Verify that System Locale is set correctly
5. [ ] Pre: Validated that prerequisites are installed
6. [ ] Pre: Verify that CPMs only connects to the Primary Vault
7. [ ] Pre: Verify that all other components point to both vaults
8. [ ] Upgrade: Exclude server from monitoring
9. [ ] Upgrade: Back up Vault installation folder
10. [ ] Upgrade: Acquire the password for the Vault "administrator" user
11. [ ] Failover: Failover complete
12. [ ] Failover: All components validated
13. [ ] Upgrade: Installed prerequisites (if any)
14. [ ] Upgrade: Primary Vault upgraded
15. [ ] Upgrade: DR Software upgraded
16. [ ] Failback: Started replication on Primary
17. [ ] Failback: Stopped Vault service on DR
18. [ ] Failback: Stopped DR service on Primary
19. [ ] Failback: Started Vault service on Primary
20. [ ] Upgrade: DR Vault - DR Software upgraded
21. [ ] Post: Validate the password for the Vault "administrator" user
22. [ ] Post: All components validated
23. [ ] Post: Started replication on DR
24. [ ] Post: Validated service status on Vault servers
25. [ ] Post: Checked all
26. [ ] Post: 2nd consultant checked all


Vault IP:
Domain: N/A  
Servers:
Failover: YES
Current component version: Vault xx.x  
Target component version: Vault xx.x  

The upgrade is split into these sections:  
- Pre-Upgrade steps  
- Upgrade: Primary Vault Server  
    - Manual Failover  
        - Validate  
    - Install Vault Software  
        - Validate  
    - Install DR Software  
        - Validate  
    - Manual Failback  
        - Validate  
- Post-Upgrade steps



## Impact Analysis
WRITE THIS SECTION IF YOU WILL NOT PERFORM FAILOVER/FAILBACK:
Throughout the whole upgrade process the vault servers will be rebooted and services taken offline, which will result in PVWA being inaccessible, PSM session already established will not close, but if the connection is lost it cannot be established again before the change is complete.

WRITE THIS SECTION IF YOU WILL PERFORM FAILOVER/FAILBACK:
During the upgrade process for the Primary Vault, the DR site will be active. Software (eg. PAReplicate) that point to the primary vault will fail to run. Under the failover and failback processes, components risk losing connection to the vault for short moments, disrupting user activity.

The CPM will be unable to perform password management tasks and if errors occur during the upgrade, the Vault will be offline until the errors are troubleshooted or the upgrade is rolled back.

## Implementation Plan
### Pre-Upgrade
- Ensure that a recent full backup of the Vault and metadata has been taken.
- Ensure that the customer can present the Operator and Master key in the case of an emergency.
- Acquire the password for the Prod Vault "administrator" user.
- Ensure that the prerequisites are met for the following software. If they aren't met, follow the "Installing prerequisites for Vault Software" section in the Implementation Plan.
	- Microsoft Visual C++ 2015-2022 (32-bit and 64-bit)
	- Microsoft .NET Framework 4.8

##### Prepare the setup files on the Vault servers
- Copy the setup files to a server that has PrivateArk Client installed
- Upload the software through PrivateArk Client to a Safe at your control, with a size quota above 5000MB.
- Use PrivateArk Client to download the software on all applicable servers

##### Ensure that CPM does not connect to the DR Vault during the upgrade.
- Log on to all CPMs
- Edit `C:\Program Files\CyberArk\Password Manager\Vault\Vault.ini`
- Ensure that the IP address of the Primary Vault is the ONLY IP address present in the ADDRESS section.

##### Ensure that all components (except for CPM) point to the DR Vault in addition to the Primary Vault
- On all component servers, open `vault.ini`
- Take note of the value in ADDRESS
- If any component does not include the DR Vault IP address, add it in the following format `ADDRESS=PRIMARYVAULTIP,DRVAULTIP`

##### Ensure that the non-Unicode System Locale is set to Danish
This section is only relevant if the system locale has previously been set to Danish (da-DK).

- Open a PowerShell prompt, run the following command
    (Get-WinSystemLocale).name -eq "da-DK"
- If "false", abort the change and arrange a change to set the system locale to Danish and reboot the server.

##### Back up the installation folders
- `C:\Program Files (x86)\PrivateArk\Server`
- `C:\Program Files (x86)\PrivateArk\Client`


### Upgrade
##### Manual Failover
- On the DR server, edit PADR.ini and set the following:
    EnableFailover=No
    EnableDbsync=Yes
    ActivateManualFailover=Yes
- On the DR server, restart the PADR service and validate in PADR.log that the failover process has started
- On the Primary Vault server, stop the "PrivateArk Server" service

Test using the "Validating component functionality" section of the Test and Verification Plan


##### Applying Windows Updates | Installing Prerequisites for Vault Software
This section must be followed if the customer has requested Windows Updates to be installed during the change, or if the prerequisites for the Vault Software aren't met.

- Run the following commands as administrator:
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
- Stop services "PrivateArk Database", "CyberArk Logic Container", "Cyber-Ark Event Notification Engine", "PrivateArk Remote Control Agent", "PrivateArk Server" and "CyberArk Vault Disaster Recovery"
- Set service "CyberArk Vault Disaster Recovery" to startup type Manual

Alternatively, with PowerShell:
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


##### DR Software
- Stop service "PrivateArk Server"
- Right click Setup.exe and select "Run as Administrator"
- Click Yes to proceed with the Disaster Recovery application upgrade.
- Click Finish when the wizard is complete
- Set the CyberArk Vault Disaster Recovery service to startup type Manual


##### PrivateArk Client
- Right click Setup.exe and select "Run as Administrator"
- Click next on the Wizard until completion


##### Clean up after Windows Update or prerequisite installation
If you applied Windows Updates or installed prerequisites, follow this section.

- Run the following commands as administrator
```
	$vaultPackagePath = "C:\CA\Core PAS 13.0\Vault"            # change this as needed
	& $vaultPackagePath\WSUS\ClosingServices.ps1
```
- Restart the server


##### Manual Failback
- DR: Reset the password for the DR user to Cyberark1 (will be automatically changed later)
- Primary: Start the Primary server in DR mode
    1. Stop service "PrivateArk Server" if running
    2. Edit PADR.ini
    3. Set FailoverMode=No
    4. Set NextBinaryLogNumberToStartAt=-1
    5. Save and exit
    6. Create a new credfile for the DR user
	```
        cd "C:\Program Files (x86)\PrivateArk\PADR"
        del Conf\user.ini*
        createcredfile.exe user.ini /Password /username DR /password Cyberark1 /DPAPIMachineProtection /EntropyFile
	```
    7. Start (or restart) service "CyberArk Disaster Recovery"
    8. Wait for replication to end
- DR: Stop service "PrivateArk Server"

- Primary: Perform a manual failover on the Primary Vault server
    1. On the Primary server, edit PADR.ini
    2. Set EnableFailover=No
    3. Set EnableDbsync=Yes
    4. Set ActivateManualFailover=Yes
    5. Save and exit
    6. Start (or restart) service "CyberArk Disaster Recovery"
- Primary: Edit PADR.ini, set FailoverMode=No to ensure the Vault won't start in DR mode
- Primary: Reset the password for the DR user to Cyberark1 (will be automatically changed later)

- DR: Start the DR server in DR mode
    1. Stop service "PrivateArk Server" if running
    2. Edit PADR.ini
    3. Set FailoverMode=No
    4. Save and exit
    5. Create a new credfile for the DR user
	```
	cd "C:\Program Files (x86)\PrivateArk\PADR"
	del Conf\user.ini*
	createcredfile.exe user.ini /Password /username DR /password Cyberark1 /DPAPIMachineProtection /EntropyFile.
	```
    6. Start (or restart) service "CyberArk Disaster Recovery"
    7. Wait for replication to end

If replication was able to run, the password has changed as seen in the message "Leave replication user change password method" in PADR.log
Test using the "Validating component functionality" section of the Test and Verification Plan





##### Enable DR Replication on DR Vault
- Edit PADR.ini and set the following:
	EnableFailover=Yes
	NextBinaryLogNumberToStartAt=-1
	(delete LastDataReplicationTimestamp)
- Start service "CyberArk Vault Disaster Recovery"
- Set service "CyberArk Vault Disaster Recovery" to startup type Automatic

Validate using the "Validating the DR Service" section of the Test and Verification Plan


##### Final service validation
- Validate service status using the "Validate service status" section of the Test and Verification Plan



## Test and Verification Plan
### Validating the DR Vault installation
Review the following logs:
```
	C:\Program Files (x86)\PrivateArk\Server\Server\Logs\VaultConfiguration.log
```

If possible, start the PrivateArk Server service and review  `italog.log`. **Do not perform this without approval from the customer.**

### Validating the DR service
Review the following logs:
```
	C:\Program Files (x86)\PrivateArk\PADR\Logs\padr.log
```

Tail the log by running `Get-Content -Tail 10 -Wait "C:\Program Files (x86)\PrivateArk\PADR\Logs\padr.log"`


### Testing the Vault installation
Review the following logs:
```
	C:\Program Files (x86)\PrivateArk\Server\Server\Logs\VaultConfiguration.log
	C:\Program Files (x86)\PrivateArk\Server\Server\Logs\ITALog.log
```

- Log onto PrivateArk Client with a CyberArk Vault user
- Log onto PVWA with a CyberArk Vault user
- Log onto PVWA with an external directory user


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
- Test an account using the PSMP

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

### Replicate from DR Vault (Recommended)
- Stop service "CyberArk Vault Disaster Recovery" and "PrivateArk Server"
- Perform a full replication and manual failback as detailed in the Implementation Plan
- Validate using the "Testing the Primary Vault installation" section of the Test and Verification Plan

### Reinstall Vault (Emergencies)
> [!NOTE]
> A common case for Vault software reinstallation is when you upgrade a DR vault and you forgot to turn off the DR service. This will sync a database down from the Primary Vault that's a lower version than the Vault software installed. If there's no database version bump, there's a high chance that it will work fine, but if a particular Vault version happens to bump the schema version, you'll find that the Vault will not be able to start. To revert this, you need to uninstall the new Vault software and install the old one.

- Uninstall Vault
- Reinstall Vault in the same version and with the same Operator key as the currently active Vault
- Replicate from the currently active Vault or restore a full backup
- Validate using the "Testing the Vault installation" section of the Test and Verification Plan

### Restore a full backup (Last Resort)
> [!NOTE]
> Restoring a full backup is only necessary in absolute emergencies, where the data of both vaults have been corrupted.

- Copy a full backup of the Vault to `C:\PrivateArk\Restored Safes` on the Vault server
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
If no errors occur, the server will be upgraded and operational within 2 hour(s).


##### Change schedule and time of day of execution
This change is scheduled for XX:XX inside regular business hours.

##### Estimated risk
Risk is medium.