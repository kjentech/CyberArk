## Sections
When following the PSM AutoIt Dispatcher Skeleton, the script is divided into sections.
As a reference, all variables and code with `; CHANGE_ME` appended should be changed.
This note uses the DHCP MMC snapin as an example.

### Consts
These variables define the initial command line being run.

```autoit
Global Const $DISPATCHER_NAME									= "Microsoft DHCP" ; CHANGE_ME
Global Const $CLIENT_EXECUTABLE									= 'mmc "C:\PSMApps\dhcpmgmt.msc"' ; CHANGE_ME
Global Const $ERROR_MESSAGE_TITLE  								= "PSM " & $DISPATCHER_NAME & " Dispatcher error message"
Global Const $LOG_MESSAGE_PREFIX 								= $DISPATCHER_NAME & " Dispatcher - "
```

### Globals
These variables represent the properties on the account being used, either as Optional, user-entered properties or statically defined on the object.

```autoit
Global $TargetUsername
Global $TargetPassword
Global $TargetAddress
Global $TargetLogonDomain
Global $TargetRemoteMachine
Global $ConnectionClientPID = 0
```


### Main
This section sets up the session itself.
This code does not need to be changed.

```autoit
Func Main()

	; Init PSM Dispatcher utils wrapper
	ToolTip ("Initializing...")
	if (PSMGenericClient_Init() <> $PSM_ERROR_SUCCESS) Then
		Error(PSMGenericClient_PSMGetLastErrorString())
	EndIf

	LogWrite("successfully initialized Dispatcher Utils Wrapper")

	; Get the dispatcher parameters
	FetchSessionProperties()

	LogWrite("mapping local drives")
	if (PSMGenericClient_MapTSDrives() <> $PSM_ERROR_SUCCESS) Then
		Error(PSMGenericClient_PSMGetLastErrorString())
	EndIf

	LogWrite("starting client application")
	ToolTip ("Starting " & $DISPATCHER_NAME & "...")
```


### Handle login here
This section runs the command line defined as a Type 2 logon (RunAs), sends process information to PSM and if needed, sends raw keypresses to complete the application launch.
The PSM assumes a broken session if an incorrect PID has been sent - this may be problematic if the dispatcher runs an executable, which spawns a temporary process, which then spawns the real client application.


```autoit
	; Execute RunAs command to run ssms under the PSM Shdaow User's profile, but pass the network credentials of
   	; the target (specified by the "2" logon type)
	$ConnectionClientPID = RunAs($TargetUsername,$TargetLogonDomain,$TargetPassword,2,$CLIENT_EXECUTABLE)
	if ($ConnectionClientPID == 0) Then
		Error(StringFormat("Failed to execute process [%s]", $CLIENT_EXECUTABLE, @error))
	EndIf

	; Send PID to PSM as early as possible so recording/monitoring can begin
 	LogWrite("sending PID to PSM")
 	if (PSMGenericClient_SendPID($ConnectionClientPID) <> $PSM_ERROR_SUCCESS) Then
 		Error(PSMGenericClient_PSMGetLastErrorString())
 	EndIf

    ; Start select server sequence

	;Wait for login form - PSO
    WinWait("DHCP")
	Sleep (1500)

    ; Send target servername
	WinActivate("DHCP")
	Sleep (500)
    Send("!a")
    Sleep (500)
	Send("{ENTER}")
	Sleep (500)
	Send($TargetRemoteMachine)
    Send("{TAB 2}")
    Sleep (500)
    Send("{ENTER}")

    ; Stop select server sequence


	; Terminate PSM Dispatcher utils wrapper
	LogWrite("Terminating Dispatcher Utils Wrapper")
	PSMGenericClient_Term()

	Return $PSM_ERROR_SUCCESS
```


### GetSessionProperty
This section defines what properties from the Globals section to use. If a property has been defined here, which is not present on the object, then a nondescriptive error may be thrown.

```autoit
Func FetchSessionProperties() ; CHANGE_ME
	if (PSMGenericClient_GetSessionProperty("Username", $TargetUsername) <> $PSM_ERROR_SUCCESS) Then
		Error(PSMGenericClient_PSMGetLastErrorString())
	EndIf

	if (PSMGenericClient_GetSessionProperty("Password", $TargetPassword) <> $PSM_ERROR_SUCCESS) Then
		Error(PSMGenericClient_PSMGetLastErrorString())
	EndIf

	;if (PSMGenericClient_GetSessionProperty("Address", $TargetAddress) <> $PSM_ERROR_SUCCESS) Then
	;	Error(PSMGenericClient_PSMGetLastErrorString())
	;EndIf

	if (PSMGenericClient_GetSessionProperty("LogonDomain", $TargetLogonDomain) <> $PSM_ERROR_SUCCESS) Then		;Added CWA
		Error(PSMGenericClient_PSMGetLastErrorString())
	EndIf

	 if (PSMGenericClient_GetSessionProperty("PSMRemoteMachine", $TargetRemoteMachine) <> $PSM_ERROR_SUCCESS) Then
		Error(PSMGenericClient_PSMGetLastErrorString())
	 EndIf

EndFunc
```



## Process for developing new connection components
1. Create folder `C:\PSMApps`
2. Create AutoIT script (copy from skeleton in `Components`)
3. Dump any referenced file into `C:\PSMApps`
4. Include any referenced file in PSMConfigureApplocker.xml
5. Run PSMConfigureApplocker.ps1 as admin
6. 

### MMC
1. Create MSC or use default
2. Copy to `C:\PSMApps`
3. Create AutoIT compiled exe
4. Copy to `Components`
5. Include `mmc` and the dispatcher in PSMConfigureApplocker.xml
6. Run PSMConfigureApplocker.ps1 as admin
7. Test and repeat if needed