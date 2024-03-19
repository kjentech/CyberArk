$cpu = .\PARClient.exe 10.199.61.21 /usepassfile RCAgent.ini /c getcpu
$cpu -replace "%",""