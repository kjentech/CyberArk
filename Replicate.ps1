<#
.SYNOPSIS
    Uses PAReplicate to create a folder structure of full Vault backups.
.DESCRIPTION
    PAReplicate can point to a custom tsparm.ini, which can specify its own SafeDirectory.
    We copy tsparm.ini to a new folder on every script execution, edit its contents and run PAReplicate on that.
    The result is a full, timestamped Vault backup on every script execution in a nested folder structure.

    Example run 11/02/2022 16:04:
    C:\Safe\202202111604

    Prereqs:
    * create a Credfile for your backup user and put it in the root folder
    * copy Vault.ini from the PAReplicate installation path to the root folder and specify the main vault
    * copy tsparm.ini from the PAReplicate installation path to the root folder

    Note: PAReplicate has a maximum path length of 20 characters.
    The script is made specifically to have timestamps in the folder names - the root folder can have no more than 4 characters.
.EXAMPLE
    Create a folder structure under C:\Safe, remove backups older than 120 days
    .\Replicate.ps1

    Create a folder structure under C:\Safe, do not remove backups
    .\Replicate.ps1 -RemoveOlderThan 0

    Create a folder structure under C:\Temp, do not remove backups
    .\Replicate.ps1 -PathRoot C:\Temp -RemoveOlderThan 0

    Create a folder structure under C:\Temp, do not remove backups and use a credfile named Replicator.cred
    .\Replicate.ps1 -PathRoot C:\Temp -RemoveOlderThan 0 -CredFile "D:\Files\Replicator.cred"
.NOTES
    Author: kjentech
    GitHub: https://github.com/kjentech/CyberArk
#>

[CmdletBinding()]
param (
    [ValidateScript({
            if ($_.Length -le 7) { $true }
            else {
                throw "[-] The path can be a maximum of 7 characters in total including the drive letter.
                     You have a maximum of 4 characters to use in the folder name."
            } })][string]$PathRoot = "C:\Safe",
    [int]$RemoveOlderThan = 120,
    [System.IO.FileInfo]$VaultINI = "$PathRoot\Vault.ini",
    [System.IO.FileInfo]$CredFile = "$PathRoot\backup.cred",
    $RemoveOldPSMRecordings = $true
)


begin {
    function RecursivelyDelete {
        [CmdletBinding()]
        param (
            [Parameter()]
            [System.IO.DirectoryInfo[]]$FoldersToRemove
        )
    
        # enumerate every folder in the list
        foreach ($Directory in $FoldersToRemove) {
            $Result = "[+] Deletion of $($Directory.FullName) completed sucessfully"
    
            # enumerate subfolders
            $SubDirs = Get-ChildItem -Path $Directory -Directory
            foreach ($dir in $SubDirs) {
                try {
                    RecursivelyDelete -FoldersToRemove $dir.FullName -ErrorAction Stop
                }
                catch {
                    Write-Output "[-] $_"
                    $Result = "[!] Deletion of $($dir.FullName) completed with errors"
                }
                
            }
        
            foreach ($file in Get-ChildItem $Directory -File) {
                Remove-Item $file.FullName -Force -Verbose
            }
            Remove-Item $Directory -Force
            Write-Verbose $Result -Verbose
        }  
    }#RecursivelyDelete


    $Today = Get-Date
    $DateFormat = "yyyyMMddHHmm"
    $PathToday = [System.Io.FileInfo]"$PathRoot\$($Today.ToString($DateFormat))"          # ex: C:\Safe\202202141308 for 14/02-2022 13:08
    Start-Transcript -Path "$PathRoot\$($Today.ToString($DateFormat)).log" -Append


    "Vault.ini", "tsparm.ini" | ForEach-Object {
        if (!(Test-Path "$PathRoot\$_")) {
            throw "[-] $_ does not exist in $PathRoot. Please copy the file over and configure it before proceeding."
            Stop-Transcript -ErrorAction SilentlyContinue
        }
    }
}



process {
    # remove old backups if specified
    if ($RemoveOlderThan -gt 0) {
        $DateToRemove = Get-Date ($Today.AddDays(-$RemoveOlderThan)) -Format $DateFormat
        $FoldersToRemove = Get-ChildItem $PathRoot -Directory | Where-Object { $_.Name -le $DateToRemove }
        RecursivelyDelete $FoldersToRemove.FullName
    }

    # create folder structure, copy tsparm.ini
    try {
        $null = New-Item -ItemType Directory -Path "$PathToday\MetaData" -Force -ErrorAction Stop             # creates the entire folder structure
        Copy-Item "$PathRoot\tsparm.ini" -Destination $PathToday -ErrorAction Stop                            # we use this tsparm.ini in the command line
        Write-Verbose "[+] Created folder $PathToday" -Verbose
    }
    catch {
        throw "[-] Could not create folder $PathToday"
    }

    # replace contents of tsparm.ini
    try {
        $tsparmINIold = Get-Content -Path "$PathToday\tsparm.ini"
        $tsparmINInew = $tsparmINIold -replace "SafesDirectory=.*", "SafesDirectory=$PathToday"
        Set-Content -Path "$PathToday\tsparm.ini" -Value $tsparmINInew -Force -ErrorAction Stop
        Write-Verbose "[+] Updated tsparm.ini" -Verbose
    }
    catch {
        throw "[-] Could not update contents of tsparm.ini"
    }

    # run PAReplicate
    $PAReplicateFilePath = "C:\Program Files (x86)\PrivateArk\Replicate\PAReplicate.exe"
    $PAReplicateArgs = '"{0}" /LOGONFROMFILE "{1}" /tsparmfile "{2}" /FullBackup' -f $VaultINI, $CredFile, "$PathToday\tsparm.ini"
    Write-Verbose "[+] $(Get-Date -Format "yyyyMMdd-HHmmss") Running command line `"$PAReplicateFilePath`" $PAReplicateArgs" -Verbose
    Push-Location "C:\Program Files (x86)\PrivateArk\Replicate"    # PAReplicate has a tendency to crash if we're not in its directory

    # example command line
    # C:\Program Files (x86)\PrivateArk\Replicate\PAReplicate.exe" "C:\Safe\Vault.ini" /LOGONFROMFILE "C:\Safe\backup.cred" /tsparmfile "C:\Safe\202202151213\tsparm.ini" /FullBackup
    Start-Process -FilePath $PAReplicateFilePath -ArgumentList $PAReplicateArgs -Wait -RedirectStandardOutput "$PathToday\PAReplicate.log"
    Pop-Location

    # check log
    $PAReplicateLog = Get-Content "$PathToday\PAReplicate.log"

    # if the replication process started and ended
    if ($PAReplicateLog[0..10] -match "PAREP013I" -and $PAReplicateLog[-10..-1] -match "PAREP022I") {
        $Result = "[+] $(Get-Date -Format "yyyyMMdd-HHmmss") Replication completed successfully"
        if ($PAReplicateLog[-10..-1] -cmatch ".+(E|W) ") { $Result = "[!] $(Get-Date -Format "yyyyMMdd-HHmmss") Replication completed with errors" }
        Write-Verbose $Result -Verbose
    }
    else {
        Write-Warning "[-] $(Get-Date -Format "yyyyMMdd-HHmmss") Replication failed, check $PathToday\PAReplicate.log for errors !!!" -Verbose
    }


    if ($RemoveOldPSMRecordings) {
        $FoldersToRemove = Get-ChildItem -Path $PathRoot -Recurse -Directory | Where-Object { $_.Name -eq "PSMRecordings" -and $_.FullName -notmatch $PathToday.Name }
        if (Test-Path -Path "$PathToday\Data\PSMRecordings\root\*.avi" -PathType Leaf) {
            Write-Verbose "[+] Starting removal of old PSMRecordings safes" -Verbose
            RecursivelyDelete $FoldersToRemove.FullName
        }
    }

}
end {
    Stop-Transcript
}
