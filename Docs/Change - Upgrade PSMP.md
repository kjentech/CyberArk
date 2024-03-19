## Checklist
1. [ ] Pre: Ensure that a VM snapshot has been taken for the server
2. [ ] Pre: Acquire the password for the Vault "administrator" user
3. [ ] Pre: Prepare the setup files on a Windows machine
4. [ ] Pre: Copy over the prepared setup files to the server
5. [ ] Upgrade: Upgraded PSMP
6. [ ] Post: Validated SSH Proxy functionality
7. [ ] Post: Checked all
8. [ ] Post: 2nd consultant checked all




## Impact Analysis
During the upgrade, users actively using SSH via the PSMP may experience disruptions. Connections through this PSMP will fail, causing some users to be unable to SSH to Linux targets.




## Implementation Plan
#### Pre-Upgrade
- Acquire the password for the Vault "administrator" user in the vault.
- Ensure that a recent VM snapshot has been taken for the server
- Extract the setup files on a Windows machine
- Edit vault.ini, set ADDRESS to the Vault IP
- Edit psmpparms.sample
- Set "InstallationFolder=/home/proxymng/PSMP13_0", "InstallCyberArkSSHD=Yes", "AcceptCyberArkEULA=Yes"
- Rename the folder to "PSMP13_0"
- Use WinSCP to copy over the setup files with the "proxymng" (or similar) user

#### Upgrade

##### Semi-Automated
- Use PuTTY to SSH to the server with a user that can run as root (proxymng or root). Adjust the first two lines of the following script and run it on the server:
```
	# EDIT THIS
	PSMPInstallDir="/home/proxymng/PSMP13_0"
	Password="VAULTADMINPASSWORD"

	# DO NOT TOUCH
	PSMPPackage="$(find $PSMPInstallDir -maxdepth 1 -name "CARKpsmp*.rpm")"
	cd $PSMPInstallDir
	/bin/cp psmpparms.sample /var/tmp/psmpparms
	chmod 755 CreateCredFile
	./CreateCredFile user.cred Password -username administrator -password $Password -entropyfile
	rpm -Uvh $PSMPPackage
	chmod 600 /home/PSMShadowUser/.ssh/config
	service sshd restart
	service psmpsrv restart
```



#### Post-Upgrade
- Delete the installation folder
- If the PSMP server will target older hosts, algorithms must be enabled as per [On PSMP version 12.6 and above - Error when connecting to an account using SSH keys (force.com)](https://cyberark-customers.force.com/s/article/PSMP-12-6-error-when-connecting-to-an-account-using-SSH-keys)
	- Run the following shell code as root:
```
	touch /home/PSMShadowUser/.ssh/config
	cat << EOF > /home/PSMShadowUser/.ssh/config
	Host *
	KexAlgorithms +diffie-hellman-group14-sha1,diffie-hellman-group-exchange-sha1,diffie-hellman-group1-sha1
	PubkeyAcceptedKeyTypes +ssh-rsa
	HostKeyAlgorithms +ssh-rsa
	EOF
	chmod 600 /home/PSMShadowUser/.ssh/config
	chown PSMShadowUser.PSMShadowUsers /home/PSMShadowUser/.ssh/config
```




## Test and Verification Plan
##### Installation Logs
Review the following log for errors related to the upgrade:
```
	/var/tmp/psmp_install.log
	/var/opt/CARKpsmp/temp/EnvManager.log
```


##### Service health and Validation
Review the following log to ensure the service is running: 
```
	/var/opt/CARKpsmp/logs/PSMPConsole.log
```

Check system health on PVWA.
Test an account, either yourself or the customer
Test new and older systems to ensure all Key Exchange algorithms, Public Key algorithms and Host Key algorithms are enabled after the upgrade.



## Fall Back Plan
Repair the installation by running "rpm -Uvh --force CARKpsmp...rpm"

Revert to snapshot if necessary. Test by following the Test and Verification Plan.


## Review Notes
##### Downtime estimation
If no errors occur, the server will be upgraded and operational within X hours.

##### Change schedule and time of day of execution
This change is scheduled for XX:XX inside regular business hours.

##### Estimated risk
Risk is medium.
