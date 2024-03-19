## Manual failover
Official documentation: https://docs.cyberark.com/Product-Doc/OnlineHelp/PAS/Latest/en/Content/PASIMP/Initiating%20a%20Predefined%20DR%20Failover.htm?TocPath=Administrator%7CComponents%7CDigital%20Vault%7COperate%20the%20CyberArk%20Vault%7CCyberArk%20Disaster%20Recovery%20Vault%7C_____7

1.  In the Disaster Recovery installation folder, open PADR.ini.
	- EnableFailover=No
	- ActivateManualFailover=Yes
	- EnableDBSync=Yes
1.  Save PADR.ini and close it.
2.  Restart the CyberArk Vault Disaster Recovery service.


## Manual failback to Primary
Official documentation: https://docs.cyberark.com/Product-Doc/OnlineHelp/PAS/Latest/en/Content/PASIMP/Initiating-DR-Failback-to-Production-Vault.htm
NOTE: The documentation lacks guidance to reset the DR user's password and create a new credfile. When a credfile is used, the password is changed and a new credfile has to be created.

Service status:
- Primary Vault:
	- PrivateArk Server: ❓
	- CyberArk Disaster Recovery: ❓
- DR Vault
	- PrivateArk Server: ✅
	- CyberArk Disaster Recovery: ⬇

### 1. DR: Reset the password for the DR user to **Cyberark1** (will be automatically changed later)
No change in service status.

### 2. Primary: Start the Primary server in DR mode
1. Stop service "PrivateArk Server" if running
2. Edit PADR.ini
	- FailoverMode=No
	- NextBinaryLogNumberToStartAt=-1
1. Save and exit
2. Create a new credfile for the DR user
	- `cd "C:\Program Files (x86)\PrivateArk\PADR"`
	- `del Conf\user.ini*` (deletes user.ini and user.ini.entropy)
	- `createcredfile.exe user.ini /Password /username DR /password Cyberark1 /DPAPIMachineProtection /EntropyFile`
3. Start (or restart) service "CyberArk Disaster Recovery"
4. Wait for replication to end

Service status:
- Primary Vault:
	- PrivateArk Server: ⬇
	- CyberArk Disaster Recovery: ✅
- DR Vault
	- PrivateArk Server: ✅
	- CyberArk Disaster Recovery: ⬇

### 3. DR: Stop service "PrivateArk Server"
On the DR server, stop the "PrivateArk Server" service.

- Service status:
	- Primary Vault:
		- PrivateArk Server: ⬇
		- CyberArk Disaster Recovery: ✅
	- DR Vault
		- PrivateArk Server: ⬇
		- CyberArk Disaster Recovery: ⬇


### 4. Primary: Perform a manual failover
Follow the guidance in the section "Manual failover". You will perform the steps on the Primary Vault, to make it active again.

- Service status:
	- Primary Vault:
		- PrivateArk Server: ✅
		- CyberArk Disaster Recovery: ⬇
	- DR Vault
		- PrivateArk Server: ⬇
		- CyberArk Disaster Recovery: ⬇

### 5. Primary: Edit PADR.ini, set FailoverMode=No to "promote" the server to Primary Vault.
No change in service status.

### 6. Primary: Reset the password for the DR user to **Cyberark1** (will be automatically changed later)
No change in service status.

### 7. DR: Start the DR server in DR mode
1. Stop service "PrivateArk Server" if running
2. Edit PADR.ini
3. Set FailoverMode=No
4. Set NextBinaryLogNumberToStartAt=-1
5. Save and exit
6. Create a new credfile for the DR user
	- `cd "C:\Program Files (x86)\PrivateArk\PADR"`
	- `del Conf\user.ini*`
	- `createcredfile.exe user.ini /Password /username DR /password Cyberark1 /DPAPIMachineProtection /EntropyFile`
7. Start (or restart) service "CyberArk Disaster Recovery"
8. Wait for replication to end

You have now performed a full Vault failback. Now proceed to validate component functionality.

Service status:
- Primary Vault:
	- PrivateArk Server: ✅
	- CyberArk Disaster Recovery: ⬇
- DR Vault
	- PrivateArk Server: ⬇
	- CyberArk Disaster Recovery: ✅