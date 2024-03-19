- Weekly: Check ITALog
- Quarterly: Check licenses
- Quarterly: Check disk space on all CyberArk servere
- Quarterly: Review LDAP directory mappings
- Annually: Test Master account and password login
- Annually: Test DR/BC failover
- Annually: Test password reset disk for local Windows administrator account on Vault servers


### Unsuspend users
Unsuspend users manually via PrivateArk Client OR allow automatic unsuspension in dbparm.ini `UserLockoutPeriodInMinutes=5`


### Create new credfile for component user
Do this if the component user's credfile is out of sync with the Vault, such as when the VM has been restored to a previous version.
> **ITADB487W** Component User PasswordManager has not accessed the Vault for x minutes
> **ITATS433E** IP Address x.x.x.x is suspended for User PasswordManager

1. Stop the component service
2. In PrivateArk, set a new password for the component user
3. In PrivateArk, unsuspend the component user in Trusted Network Areas
4. On the server, run [[CreateCredFile]] to create a credfile with the same password as in the Vault
5. Start the component service and verify Vault connectivity


### Clearing Safe history
PrivateArk Client, Tools, **Clear Expired History**.
Only deletes what's older in Safe Properties History.

### Vault Archive Log
Set Archive Log to a minimum of 24 hours for support reasons.

### Rotate CPM Logs
If the logs are uploaded to the Vault, `deletefiles.exe` can be used to delete old `pm.log` and `pm_error.log` files from disk. The tool can be run as a scheduled task.
Third party logs in `Logs\Old\ThirdParty`  are deleted automatically depending on the OldLogRetention parameter.

### Email notifications for Replicate and DR
- dbparm.ini `BackupNotificationThreshold=Yes,Yes,48,24,12`
	- First notification after 48 hours, after that after 24 hours, status checked every 12 hours
- dbparm.ini `DRNotificationThreshold=Yes,Yes,2,24,30m`


### Email notifications for disconnected component users
At the very least, set email notifications for the **Backup** and **DR** users. By default, the email is sent to all in Vault Admins, but can be customized.
An entry is also generated in ITALog.