When connecting to a UNIX target, the [[🖥-CPM]] connects to the target over SSH. The SSH fingerprint is cached to ensure there's no tampering.
When the target server is reinstalled, or another is set up with the same hostname, the new SSH fingerprint doesn't match what's in the cache, and the CPM returns an error:

```
CACPM406E Reconciling Password
Error: Execution error.
EXT01::Fingerprint mismatch for 'ssh-ed25519@22:lnx-pora101'.
The CPM is trying to reconcile this password because its status matches the following search criteria: ResetImmediately
Safe: S-LX-R-LNX-PORA101
Folder: Root
Object: Operating System-PLTFRM-UNIX-ROOT-lnx-pora101-root failed (try #0)
Code: 9007
```

To fix the issue, remove the old fingerprint from the cache, so that the new fingerprint can be put into the cache.

The cache is located in the registry, where exactly is determined by which user is running the "CyberArk Password Manager" service.
- If SYSTEM runs the service: `HKEY_USERS\.DEFAULT\Software\CyberArk\Expect.NET\HostKeys`
- If another user runs the service: `HKEY_USERS\$SID\Software\CyberArk\Expect.NET\HostKeys`

To get the SID of the user running the service:

```powershell
$CPM = Get-CimInstance Win32_Service | Where-Object {$_.Name -eq "CyberArk Password Manager"}
$username = $CPM.StartName -replace "^.*\\",$null
$user = New-Object System.Security.Principal.NTAccount($username) 
$sid = $user.Translate([System.Security.Principal.SecurityIdentifier]).Value
```

Inside the HostKeys key, find the name of the key that matches the error and delete it. CPM actions will now successfully run.


# DeleteSSHFingerprint.ps1
This script can be run as an administrator on the CPM server to automate the finding and deletion of fingerprints in the cache.

```powershell
#requires -runasadministrator

$CPM = Get-CimInstance Win32_Service | Where-Object {$_.Name -eq "CyberArk Password Manager"}
$username = $CPM.StartName -replace "^.*\\",$null
$user = New-Object System.Security.Principal.NTAccount($username) 
$sid = $user.Translate([System.Security.Principal.SecurityIdentifier]).Value

New-PSDrive -Name "HKU" -PSProvider Registry -Root "HKEY_USERS"
$keysPath = "HKU:\$sid\Software\CyberArk\Expect.NET\HostKeys"
$SSHKeys = (Get-Item -Path $keysPath).Property | sort
$ogv = $SSHKeys | Out-GridView -PassThru
$ogv | foreach {
    Remove-ItemProperty -Path $keyspath -Name $_ -Verbose -Confirm
    if (!(Get-ItemProperty -Path $keysPath -Name $_ -ErrorAction SilentlyContinue)) {
        echo "[+] REMOVED $_ SUCECSSFULLY!"
    }
}

pause
```
