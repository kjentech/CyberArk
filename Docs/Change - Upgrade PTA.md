## Checklist
1. [ ] Pre: Ensure that a VM snapshot has been taken for the server
2. [ ] Pre: Acquire the password for the Vault "administrator" user
3. [ ] Copy the setup files to the server
4. [ ] Upgrade: Upgrade complete
5. [ ] Post: Checked all
6. [ ] Post: 2nd consultant checked all



Vault IP:  
Domain:  
Servers:  
Current component version: PTA 12.2
Target component version: PTA 12.6
  
NOTE: THIS CHANGE IS ONLY APPLICABLE UP TO PTA 12.6.
CONSULT THE CYBERARK DOCUMENTATION FOR INSTRUCTIONS ON UPGRADING TO LATER VERSIONS OF PTA.

## Impact Analysis
During the upgrade, PTA will not stream logs via syslog to any SIEM, PSM will not be able to take action on risky sessions and analysts will not be able to use the Security Events view in PVWA to analyze risky sessions.

As the upgrade process for PTA has known issues with authentication to PVWA that resolve automatically after a time period, 24 hours of downtime should be anticipated.


## Implementation Plan
#### Pre-upgrade
- Acquire the password for the vault "administrator" user
- Copy the setup files to the server (ie. `/tmp/`)
- Ensure that a recent VM snapshot has been taken for the server
- Ensure that the name of the network is correct
```
	nmcli connection show
	ls -l /etc/sysconfig/network-scripts/ifcfg*
```
- If the ifcfg file has an incorrect name, rename it to match the output of nmcli.
- Take note of permissions on mount point /dev/shm: `mount | grep "/dev/shm"`


#### Upgrade
- Use PuTTY to SSH to the server with the "root" user
- If `/dev/shm` is mounted with "noexec", run the following command to remount with execute permissions:
```
	mount -o remount,exec /dev/shm
```
- Run the following commands to start the upgrade:
```
	chmod 700 /tmp/pta_upgrade.sh
	/tmp/pta_upgrade.sh
```
- Press Enter, the script will upgrade PTA without further interaction
- The server will reboot automatically

#### Post-Upgrade
- Set up crontab job to update packages that are not updated by PTA any more

Set up the following iptables rules:

```
iptables -A INPUT -s 10.193.104.124/32 -p udp -m comment --comment "\\\'Allow SNMP - UDP 161\\\'" -j ACCEPT
iptables -A INPUT -s 10.199.88.150,10.199.88.201,10.199.88.202,10.199.88.101,10.199.88.102 -p tcp -m multiport --dports 10082,1556,13724,10102 -j ACCEPT -m comment --comment "Allow IN from backup server"
iptables -A OUTPUT -d 10.199.88.150,10.199.88.201,10.199.88.202,10.199.88.101,10.199.88.102 -p tcp -m multiport --dports 10082,1556,13724,10102 -j ACCEPT -m comment --comment "Allow OUT to backup server"
iptables -D INPUT -m comment --comment "Reject all traffic" -j REJECT --reject-with icmp-port-unreachable
iptables -A INPUT -m comment --comment "Reject all traffic" -j REJECT --reject-with icmp-port-unreachable
iptables -D OUTPUT -m comment --comment "Reject all traffic" -j REJECT --reject-with icmp-port-unreachable
iptables -A OUTPUT -m comment --comment "Reject all traffic" -j REJECT --reject-with icmp-port-unreachable
```



## Test and Verification Plan
##### Installation Logs
Review the following logs:
```
	/tmp/pta_upgrade.log
```


##### Service health and Validation
Test using the Security Events view in PVWA.

If errors 500 or 503 are observed, wait until the next morning.



## Fall Back Plan
- Revert the VM snapshot
- If more than 24 hours has passed since the snapshot was taken: `/opt/tomcat/utility/pasConfiguration.sh`
- `service appmgr restart`
- `reboot`



## Review Notes
##### Downtime estimation
If no errors occur, the server will be upgraded and operational within 24 hour(s).

##### Change schedule and time of day of execution
This change is scheduled for XX:XX inside regular business hours.

##### Estimated risk
Risk is medium.