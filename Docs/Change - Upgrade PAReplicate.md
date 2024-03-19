## Checklist
1. [ ] Pre: Verify that the latest backup has no errors in the logs
2. [ ] Upgrade: Installed prerequisites (MSVCR 2015-2022 32-bit, 64-bit)
3. [ ] Upgrade: Upgraded PAReplicate
4. [ ] Upgrade: Restarted the server
5. [ ] Post: Run a manual backup
6. [ ] Post: Verify that the latest backup has no errors in the logs
7. [ ] Post: Checked all
8. [ ] Post: 2nd consultant checked all


## Impact Analysis
The tool will be upgraded outside of its scheduled run time, so there will be no operational impact.

If errors occur during the upgrade, no backup will be taken for the Vault until the error has been resolved.


## Implementation Plan
#### Pre-upgrade
- Copy the setup files to the server

#### Upgrade
- Install the prerequisites
	- Microsoft Visual C++ Runtime 2015-2022 32-bit
	- Microsoft Visual C++ Runtime 2015-2022 64-bit
- Right click Setup.exe and select "Run as Administrator"
- Click Yes to start the upgrade
- Click Finish when the wizard is complete

#### Post-Upgrade
- Restart the server
- Open Task Scheduler (taskschd.msc)
- Run the backup task manually



## Test and Verification Plan
##### Installation Logs
Review the following logs:
```
	PAReplicate.log
```





## Fall Back Plan
- Perform local troubleshooting
- Uninstall PAReplicate
- Reinstall PAReplicate in the old version, following the Implementation Plan




## Review Notes
##### Downtime estimation
If no errors occur, the server will be upgraded and operational within X hours.

##### Change schedule and time of day of execution
This change is scheduled for XX:XX inside regular business hours.

##### Estimated risk
Risk is low.