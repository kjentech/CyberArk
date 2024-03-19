## Impact Analysis
Applying updates has a risk to introduce new bugs to the operating system, however, it also has a chance to fix existing bugs. The risk has been calculated to be acceptable.



## Implementation Plan
##### Pre-change actions
Copy the most recent Cumulative Update (KB5021655) and its prereqs (KB5005112) for Windows Server 2019 to the server.

##### Failover to DR Vault
- On the DR server, edit PADR.ini and set the following:
    EnableFailover=No
    EnableDbsync=Yes
    ActivateManualFailover=Yes
- Restart the PADR service and validate in PADR.log that the failover process has started
- Validate component functionality

##### Applying Windows Updates
- Run the following commands as administrator:
    reg add HKLM\SYSTEM\CurrentControlSet\Services\msiserver /v Start /d 3 /t REG_DWORD /f
    sc config wuauserv start=auto
    sc start wuauserv
    sc config trustedinstaller start=auto
    sc start trustedinstaller
    sc config "PrivateArk Server" start=disabled
- Restart the server
- Run the following in a PowerShell prompt as administrator to determine if the prerequisite has been installed:
    Get-Hotfix -Id KBxxxxxxxx
- Run the update package to install the update
- Restart the server

Test using the Test and Verification Plan before proceeding.

##### Cleanup
- Run the following commands as administrator
    reg add HKLM\SYSTEM\CurrentControlSet\Services\msiserver /v Start /d 4 /t REG_DWORD /f
    sc stop wuauserv
    sc config wuauserv start=disabled
    sc stop trustedinstaller
    sc config trustedinstaller start=disabled
- Restart the server

##### Failback to Primary Vault
- DR: Reset the password for the DR user to Cyberark1 (will be automatically changed later)
- Primary: Start the Primary server in DR mode
    1. Stop service "PrivateArk Server" if running
    2. Edit PADR.ini
    3. Set FailoverMode=No
    4. Set NextBinaryLogNumberToStartAt=-1
    5. Save and exit
    6. Create a new credfile for the DR user
        cd "C:\Program Files (x86)\PrivateArk\PADR"
        del Conf\user.ini*
        createcredfile.exe user.ini /Password /username DR /password Cyberark1 /DPAPIMachineProtection /EntropyFile
    7. Start (or restart) service "CyberArk Disaster Recovery"
    8. Wait for replication to end
- DR: Stop service "PrivateArk Server"
- Primary: Perform a manual failover
- Primary: Edit PADR.ini, set FailoverMode=No to make the Vault a Primary Vault again
- Primary: Reset the password for the DR user to Cyberark1 (will be automatically changed later)
- DR: Start the DR server in DR mode
    1. Stop service "PrivateArk Server" if running
    2. Edit PADR.ini
    3. Set FailoverMode=No
    4. Set NextBinaryLogNumberToStartAt=-1
    5. Save and exit
    6. Create a new credfile for the DR user
        cd "C:\Program Files (x86)\PrivateArk\PADR"
        del Conf\user.ini*
        createcredfile.exe user.ini /Password /username DR /password Cyberark1
/DPAPIMachineProtection /EntropyFile
    7. Start (or restart) service "CyberArk Disaster Recovery"
    8. Wait for replication to end



## Test and Verification Plan
- In a PowerShell prompt, run the following:
    Get-Hotfix

This should return the KB of the installed update. If it doesn't, install the update again, restart and test using the Test and Verification Plan.



## Fall Back Plan
To remove the latest update, run the following command as administrator:
    wusa.exe /uninstall /kb:XXXXXXXX /norestart
Restart the server and confirm using the Test and Verification Plan.




## Review Notes
##### Downtime estimation
If no errors occur, the server will be upgraded and operational within 2 hours.

##### Change schedule and time of day of execution
This change is scheduled for XX:XX inside regular business hours.

##### Estimated risk
Risk is medium.