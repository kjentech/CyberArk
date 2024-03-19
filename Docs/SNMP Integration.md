The SNMP Agent on the Vault is called **PrivateArk Remote Control Agent** (PARAgent).

PARAgent can send any SNMP-based OS information as a trap, as well as Vault and DR status and logs.

CyberArk provides SNMPv1 and SNMPv2 MIBs on the Vault installation media. The MIBs may be considered invalid to some monitoring software - the solution is to delete this part at the end:
```
-- 1.3.6.1.4.1.11536.5 
cyberArkTrapGroup NOTIFICATION-GROUP 
    NOTIFICATIONS { osDiskFreeSpaceNotification, osCpuUsageNotification, osEventLogInfoNotification, 
					osMemoryUsageNotification, osServiceNameNotification, paVaultLogInfoNotification, 
					paVaultServiceNameNotification, paDRLogInfoNotification, osDRServiceNameNotification, 
					paCIFSLogInfoNotification, osCIFSServiceNameNotification, paFTPLogInfoNotification, 
					paSMTPLogInfoNotification } 
    STATUS  current 
    DESCRIPTION 
        "Group of notifications" 
    ::= { cyberArkMIB 5 } 

-- 1.3.6.1.4.1.11536.6 
cyberArkTrapGroup NOTIFICATION-GROUP 
    NOTIFICATIONS { osDiskFreeSpaceNotification, osCpuUsageNotification, osEventLogInfoNotification, 
					osMemoryUsageNotification, osServiceNameNotification, paVaultLogInfoNotification, 
					paVaultServiceNameNotification, paCVMLogInfoNotification, osCVMServiceNameNotification, 
					paCIFSLogInfoNotification, osCIFSServiceNameNotification, paFTPLogInfoNotification, 
					paSMTPLogInfoNotification } 
    STATUS  current 
    DESCRIPTION 
        "Group of notifications" 
    ::= { cyberArkMIB 6 } 
```


paragent.ini:
```
[MAIN]
RemoteStationIPAddress=172.20.26.20
UserCredentialsPath="C:\Program Files (x86)\PrivateArk\Server\Conf\ParAgent.pass"

SNMPVersion=v2
SNMPHostIP=172.20.26.11
SNMPTrapPort=162
SNMPCommunity="CyberArkDemo"
SNMPTrapInterval=30

*EnableTrace=Yes
*MonitoredEventLogNames=System,Application,Security
ExtensionComponentList="C:\Program Files (x86)\PrivateArk\Server\PARVaultAgent.dll,C:\Program Files (x86)\PrivateArk\Server\PARENEAgent.dll"
AllowedMonitoredServices="PrivateArk Database,CyberArk Logic Container, Cyber-Ark Event Notification Engine"
SNMPTrapsThresholdCPU=200,90,3,30,YES
SNMPTrapsThresholdPhysicalMemory=200,90,3,30,YES
SNMPTrapsThresholdSwapMemory=200,90,3,30,YES
SNMPTrapsThresholdDiskUsage=200,85,3,30,YES
SNMPTrapsThresholdServiceStatus=30,3,30,YES
LogMessagesFilterRegexp=.*
ExcludedLogMessagesFilterRegexp=(ITA|PARE|PADR|CAS).*I
```

AllowedMonitoredServices will throw a trap 4 (osServiceNameNotification) after SNMPTrapsThresholdServiceStatus has exceeded.
PrivateArk Server is monitored internally and will throw a trap 1001 (paVaultServiceNameNotification), so no need to add it to AllowedMonitoredServices.

Remote Control Agent is able to monitor Vault, DR and ENE, this is controlled using [ExtensionComponentList](https://cyberark-customers.force.com/s/article/00002452?t=1681638676673).
- Vault: `C:\Program Files (x86)\PrivateArk\Server\PARVaultAgent.dll`
- DR: `C:\Program Files (x86)\PrivateArk\Server\PARDRAgent.dll`
- ENE: `C:\Program Files (x86)\PrivateArk\Server\PARENEAgent.dll`


## PARClient
PARClient includes a command line tool for doing basic Vault commands.
- Retrieve Logs
- Set parameters
- Restart the Vault
- Restart Services
- Reboot Vault server
- Retrieve machine status (CPU/mem)