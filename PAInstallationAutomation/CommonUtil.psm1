Import-Module .\Commands -PassThru | Out-Null

Set-Variable uninstallTimeout -option Constant -value 120

# @FUNCTION@ ======================================================================================================================
# Name...........: Write-CALogFile
# Description....: Writes log entries to the log file located in C:\Windows\Temp
#                  Usage: "Write-CALogFile -Message 'Message Text Here' -Level <Info/Warning/Error>"
# Parameters.....: $Message - String containing the message that is written to the log file
#                  $Level - Switches used to determine whether a log entry is Informational, Warning or and Error (Info by default)
# Return Values..: None
# =================================================================================================================================
function Write-CALogFile{
    [CmdletBinding()] 
    Param 
    ( 
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true)] 
        [ValidateNotNullOrEmpty()] 
        [string]$Message, 
 
        [Parameter(Mandatory=$false)] 
        [ValidateSet("Error","Warn","Info")] 
        [string]$Level="Info",

		  [Parameter(Mandatory=$false)] 
        [string]$Path='./Script.log'
    )

    Process{

        if(!(Test-Path $Path)){
				
				Write-Host "creating log file: $Path"
            #$VerbosePreference = 'Continue' 
            #Write-Verbose "Creating $Path." 
            $NewLogFile = New-Item $Path -Force -ItemType File 
        }

        $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
         
        switch ($Level) {
            'Error'{
                #Write-Error $Message
                $LevelText = 'ERROR: '
            } 'Warn' {
                #Write-Warning $Message
                $LevelText = 'WARNING: '
            } 'Info' {
                #Write-Verbose $Message
                $LevelText = 'INFO: '
            }
        }

    "$FormattedDate $LevelText $Message" | Out-File -FilePath $Path -Append -Encoding utf8 
    }
    End{
    }
}
export-modulemember -function Write-CALogFile


# @FUNCTION@ ======================================================================================================================
# Name...........: Set-CAStartService
# Description....: Start the required service
# Parameters.....: $serviceName 
# Return Values..: $true
#                  $false
# =================================================================================================================================
function Set-CAStartService{
    param
    (
        [Parameter(Mandatory=$true)] 
        [string]$serviceName

    )
   try
	{
	   Add-CALogAll "Start $serviceName service"
		$StartServiceSatus = Start-Service -Name $serviceName
		return $true

	}
	catch
	{
		Add-CALogAll "Failed to start $serviceName service, Please start it manually" "Error"
		Add-CALogErrorDetails $_.Exception
		return $false
	}
}
export-modulemember -function Set-CAStartService

# @FUNCTION@ ======================================================================================================================
# Name...........: Set-CAStopService
# Description....: Stop the required service
# Parameters.....: $serviceName 
# Return Values..: $true
#                  $false
# =================================================================================================================================
function Set-CAStopService{
    param
    (
        [Parameter(Mandatory=$true)] 
        [string]$serviceName

    )
   try
	   {
	    Add-CALogAll "Stop $serviceName service"
		Stop-Service -Name $serviceName

		return $true

	}
	catch
	{
		Add-CALogAll "Failed to stop $serviceName service, Please stop it manually and re-run the script" "Error"
		Add-CALogErrorDetails $_.Exception
		return $false
	}
}

export-modulemember -function Set-CAStopService


# @FUNCTION@ ======================================================================================================================
# Name...........: RunProcess
# Description....: Run deployment process 
# Parameters.....: 
# Return Values..: if operation succeeded 
# =================================================================================================================================
function RunProcess{
	Param(
		[Parameter(Mandatory=$true)] 
		[string]$ProcessFullPath,
		[Parameter(Mandatory=$false)] 
		[string[]]$Args,
        [Parameter(Mandatory=$false)] 
		[string]$PasswordEnvVarKey,
        [Parameter(Mandatory=$false)] 
		[Security.SecureString]$SecurePassword
	)
    Begin{
		$processName = Split-Path -Leaf $ProcessFullPath
        $processPath = Split-Path -Parent $ProcessFullPath
	}
	Process{
        $processArgs = ""
        foreach($item in $Args)
        {
            $processArgs += "`"$item`" "
        }
		Add-CALogAll "Running process [$processName] from path [$processPath] with arguments [$processArgs]."
        if ($SecurePassword -and $PasswordEnvVarKey)
        { 
           $password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword))
            [System.Environment]::SetEnvironmentVariable($PasswordEnvVarKey,$password)    
        }
        $process = (Start-Process $ProcessName "$processArgs" -WorkingDirectory $processPath -Wait -WindowStyle Hidden -PassThru)
		$processExitCode = $process.ExitCode.ToString()
		[bool]$isSuccess = $false
        if ($process.ExitCode -eq 0)
        {
            Add-CALogAll "Process $ProcessName finished successfully"
            $isSuccess = $true
        }
        else
        {
            Add-CALogAll "Process $ProcessName failed with exit code $processExitCode" "Error"
            $isSuccess = $false
        }
		return $isSuccess
	}
}
export-modulemember -function RunProcess


# @FUNCTION@ ======================================================================================================================
# Name...........: Add-CAAuditRulesToPath
# Description....: Adds audit access rules to the required path
# Parameters.....: $path - Path - Registry or File
#                  $accessRules - Access Control Rules
# Return Values..: $true
#                  $false
# =================================================================================================================================
function Add-CAAuditRulesToPath{
    param
    (
        [Parameter(Mandatory=$true)] 
        [string]$path,
		
		[Parameter(Mandatory=$true)]  
        $accessRules
    )

	Try {
		Add-CALogAll "Configuring audit rules for: $path"

		$Audit = Get-Acl $path -Audit | Format-List Path,AuditToString
		$Audit =  ($Audit| Format-List | Out-String)
		Add-CALogAll "Audit before updating: $Audit"	 
	

		if ((Get-Item -Path $path) -is [Microsoft.Win32.RegistryKey])
		{
			$Path_ACL = Get-Acl $path
		}
		else 
		{
			$Path_ACL = (Get-Item $path).GetAccessControl('Access')
		}

		ForEach ($accessRule in $accessRules)
		{
			$Path_ACL.AddAuditRule($accessRule)
		}
	
		$Path_ACL | Set-Acl $path

		$Audit = Get-Acl $path -Audit | Format-List Path,AuditToString
		$Audit =  ($Audit| Format-List | Out-String)
		Add-CALogAll "Audit after updating: $Audit"	
		return $true
	}
	catch
	{
		Add-CALogAll "Failed to configure audit access rules for: $key. Please set the audit rules according to the documentation" "Error"
		return $false

	}
}
export-modulemember -function Add-CAAuditRulesToPath


# @FUNCTION@ ======================================================================================================================
# Name...........: Add-CALogAll
# Description....: log to host and to log file. 
# Parameters.....: $Message - String containing the message that is written to the log file
#                  $Level - Switches used to determine whether a log entry is Informational, Warning or and Error (Info by default)
# Return Values..: None
# =================================================================================================================================
function Add-CALogAll{
	[CmdletBinding()] 
   Param 
   ( 
		[Parameter(Mandatory=$true, 
			ValueFromPipelineByPropertyName=$true)] 
      [Alias("LogContent")] 
      [string]$Message, 

      [Parameter(Mandatory=$false)]
      [string]$Level="Info",

		[Parameter(Mandatory=$false)] 
      [Alias('LogPath')] 
      [string]$Path
	)

	Process{
		Write-Host $Message
		if($Path -eq ""){
			Write-CALogFile $Message $Level
		} else {
			Write-CALogFile $Message $Level $Path
		}
	}
	End{
   }
}
export-modulemember -function Add-CALogAll

# @FUNCTION@ ======================================================================================================================
# Name...........: Add-CALogErrorDetails
# Description....: Handles errors, gathers error message and items into parameters and serves these to the console and log file. 
# Parameters.....: None
# Return Values..: None
# =================================================================================================================================
function Add-CALogErrorDetails{
	[CmdletBinding()] 
	param(
		$Exception
	)

	Process {
		if ($Exception -ne $null){			
			Add-CALogAll "The following error occurred: $Exception" "Error"
		} else {
			Add-CALogAll "An uncaught error occurred" "Error"
		}
	}
	End{
   }
}
export-modulemember -function Add-CALogErrorDetails

# @FUNCTION@ ======================================================================================================================
function LoadPolFileEditor{
	try{
		Add-CALogAll "Add PolFileEditor.dll"
		Add-Type -Path ".\PolFileEditor.dll" -ErrorAction Stop
	} catch {
		Add-CALogErrorDetails $_.Exception
	}
}
export-modulemember -function LoadPolFileEditor

# =================================================================================================================================

# @FUNCTION@ ======================================================================================================================
# Name...........: Get-CARegistryEntryValue
# Description....: Return registry value from path and key provided. Also print the value for the log
# Parameters.....: $regPath - Registry path
#                  $regKey - Registry key name
# Return Values..: return registry key value if exist, or $null if not found.
#
# =================================================================================================================================
function Get-CARegistryEntryValue{
	[CmdletBinding()] 
   param (
   [parameter(Mandatory=$true)]
   [ValidateNotNullOrEmpty()]$regPath,
   [parameter(Mandatory=$true)]
   [ValidateNotNullOrEmpty()]$regKey
   )

	Process {
		try {
         $returnRegValue = $null
			$returnRegValue = (Get-ItemProperty -Path $regPath -Name $regKey).$regKey
			Add-CALogAll "Current registry value at path $regPath for key $regKey is: $returnRegValue"
		}Catch{
         $returnRegValue = $null
			Add-CALogErrorDetails $_.Exception
		}

      return $returnRegValue
	}
	End{
   }
}
export-modulemember -function Get-CARegistryEntryValue

# @FUNCTION@ ======================================================================================================================
# Name...........: Test-CARegistryEntryExist
# Description....: Checks if a registry value exists from submitted path and value parameters and returns a boolean value 
# Parameters.....: $regPath - Registry path
#                  $regKey - Registry key name
# Return Values..: $true
#                  $false
# =================================================================================================================================
function Test-CARegistryEntryExist{
	[CmdletBinding()] 
   param (
   [parameter(Mandatory=$true)]
   [ValidateNotNullOrEmpty()]$regPath,
   [parameter(Mandatory=$true)]
   [ValidateNotNullOrEmpty()]$regKey
   )

	Process {
		Add-CALogAll "Checking if a registry on path: $regPath and key: $regKey is exists"
		If (Get-ItemProperty -Path $regPath -Name $regKey -ErrorAction SilentlyContinue) {
			Get-CARegistryEntryValue -regPath $regPath -regKey $regKey
			return $true
		}
		Add-CALogAll "Registry on path: $regPath and key: $regKey is not exists"
		return $false
	}
	End{
		Add-CALogAll "Finish checking if a registry entry exists"
   }
}
export-modulemember -function Test-CARegistryEntryExist

# @FUNCTION@ ======================================================================================================================
# Name...........: Add-CARegistryEntry
# Description....: Creates a new registry entry using the registry path, property name, property value and property type submitted 
# Parameters.....: $regPath - The full path of the registry key that is being created
#                  $regKey - The name of the registry item be created
#                  $regValue - The value that the registry item will be set as
#                  $regProperty - The type of the registry property that will be created
# Return Values..: None
# =================================================================================================================================
function Add-CARegistryEntry{
	[CmdletBinding()] 
   param(
   [parameter(Mandatory=$true)]
   [ValidateNotNullOrEmpty()]$regPath,
   [parameter(Mandatory=$true)]
   [ValidateNotNullOrEmpty()]$regKey,
   [parameter(Mandatory=$true)]
   [ValidateNotNullOrEmpty()]$regValue,
   [parameter(Mandatory=$false)]
   [ValidateNotNullOrEmpty()]$regProperty
   )

	Process {
		Try{
			If(-not(Test-Path -Path $regPath)){
				Add-CALogAll "Attempting to create new registry path: $regPath"
				New-Item -Path $regPath -Force
			}

			Add-CALogAll "Attempting to create new registry key: $regKey on path: $regPath"

			New-ItemProperty -Path $regPath -Name $regKey -Value $regValue -PropertyType $regProperty
        
			Get-CARegistryEntryValue -regPath $regPath -regKey $regKey

			Add-CALogAll "The registry value has been successfully created"
		}Catch{
			Add-CALogErrorDetails $_.Exception
		}
	}
	End{
   }
}
export-modulemember -function Add-CARegistryEntry

# @FUNCTION@ ======================================================================================================================
# Name...........: Set-CARegistryEntry
# Description....: Changes a registry entry value using the registry path, property name and property value submitted. 
# Parameters.....: $regPath - The full path of the registry key
#                  $regKey - The name of the registry item to be changed
#                  $regValue - The value that the registry item will be changed to
# Return Values..: None
# =================================================================================================================================
function Set-CARegistryEntry{
   [CmdletBinding()] 
   param(
   [parameter(Mandatory=$true)]
   [ValidateNotNullOrEmpty()]$regPath,
   [parameter(Mandatory=$true)]
   [ValidateNotNullOrEmpty()]$regKey,
   [parameter(Mandatory=$true)]
   [ValidateNotNullOrEmpty()]$regValue
   )
   
	Process {
		Try{
			Add-CALogAll "Attempting to change the registry item to the desired value"
    
			Set-ItemProperty -Path $regPath -Name $regKey -Value $regValue
        
			Get-CARegistryEntryValue -regPath $regPath -regKey $regKey
  
			Add-CALogAll "The registry value has been successfully changed"
		}Catch{  
			Add-CALogErrorDetails $_.Exception
		}
	}
	End{
   }
}
export-modulemember -function Set-CARegistryEntry

# @FUNCTION@ ======================================================================================================================
# Name...........: Test-CAInstalledRole
# Description....: gets a server role and test if it is installed on the machine 
# Parameters.....: $roleName - the role to check
# Return Values..: true if exists, otherwise false
# =================================================================================================================================
Function Test-CAInstalledRole
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false)]
		$roleName
	)

	Process{
		
		if ((Get-WindowsFeature $roleName).Installed -eq 1){
			$true
		} else {
			$flase
		}
	}
}
export-modulemember -function Test-CAInstalledRole

# @FUNCTION@ ======================================================================================================================
# Name...........: Add-CALocalUser
# Description....: Creates a new local user using the username, password and description submitted 
# Parameters.....: $userName - The username of user to create
#                  $userPassword - The user password
#                  $userDescription - The user description of user to create
# Return Values..: $true or $false
# =================================================================================================================================
function Add-CALocalUser{
	[CmdletBinding()] 
   param(
   [parameter(Mandatory=$true)]
   [ValidateNotNullOrEmpty()]$userName,
   [parameter(Mandatory=$true)]
   [ValidateNotNullOrEmpty()]$userPassword,
   [parameter(Mandatory=$true)]
   [ValidateNotNullOrEmpty()]$userDescription
   )

	Process {
		Try{
            $result = $false
			   Add-CALogAll "Attempting to create new local user $userName"

            $localComputer = [ADSI]"WinNT://$env:COMPUTERNAME"
            $existingUser = $localComputer.Children | where {$_.SchemaClassName -eq 'user' -and $_.Name -eq $userName }

            if ($existingUser -eq $null) {
      
				$user = $localComputer.Create("User", $userName)
				
				$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($userPassword)
	            $user.SetPassword([System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR))
	            $user.SetInfo()
				[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
	       
	            $user.Put("Description", $userDescription)
	            $user.SetInfo()

               $result = $true
               Add-CALogAll "The local user $userName has been successfully created"
            }
            else {
                Add-CALogAll "Local user $userName is already exist. Please do this step manually." "Warn"
            }

		}Catch{
         Add-CALogAll "Failed to create new local user $userName." "Error"
			Add-CALogErrorDetails $_.Exception
		}

      return $result
	}
	End{
   }
}
export-modulemember -function Add-CALocalUser


# @FUNCTION@ ======================================================================================================================
# Name...........: Get-CAGeneratedPassword
# Description....: Generate random password according to length submitted
# Parameters.....: $length - The password length to generate, not mandatory, default is 10 characters.
# Return Values..: generated password
# =================================================================================================================================
function Get-CAGeneratedPassword{
    [CmdletBinding()] 
	param(
    [parameter(Mandatory=$false)] 
    [int]$length = 10
    )
    	Process {
		Try{
            $secureStringPass = ConvertTo-SecureString (([char[]]([char]35..[char]126) | sort {Get-Random})[0..($length-1)] -join '') -AsPlainText -Force
			return $secureStringPass
		}Catch{
			Add-CALogErrorDetails $_.Exception
		}
	}
	End{
   }
}
export-modulemember -function Get-CAGeneratedPassword


# @FUNCTION@ ======================================================================================================================
# Name...........: Add-CAUserRight
# Description....: Add user right to a local user in Local security policy
# Parameters.....: $userName - The user name to add right to.
#                  $userRight - The user right to add
# Return Values..: None
# =================================================================================================================================
function Add-CAUserRight{
    [CmdletBinding()] 
	param(
   [parameter(Mandatory=$true)]
   [ValidateNotNullOrEmpty()]$userName,
   [parameter(Mandatory=$true)]
   [ValidateNotNullOrEmpty()]$userRight
    )
    	Process {
		Try{
                Add-CALogAll "Start adding ""$userRight"" user rights to user $userName"
                Try {
		                $ntprincipal = new-object System.Security.Principal.NTAccount "$userName"
		                $userSid = $ntprincipal.Translate([System.Security.Principal.SecurityIdentifier])
		                $userSidstr = $userSid.Value.ToString()
	                } Catch {
		                $userSidstr = $null
	                }

	                if( [string]::IsNullOrEmpty($userSidstr) ) {
		                Add-CALogAll "User $userName not found!" "Error"
		                return $false
	                }

                    Add-CALogAll "User SID: $($userSidstr)"

                    $tempPath = [System.IO.Path]::GetTempPath()
                    $importPath = Join-Path -Path $tempPath -ChildPath "import.inf"
                    if(Test-Path $importPath) { Remove-Item -Path $importPath -Force }
                    $exportPath = Join-Path -Path $tempPath -ChildPath "export.inf"
                    if(Test-Path $exportPath) { Remove-Item -Path $exportPath -Force }
                    $secedtPath = Join-Path -Path $tempPath -ChildPath "secedt.sdb"
                    if(Test-Path $secedtPath) { Remove-Item -Path $secedtPath -Force }
  
                    Add-CALogAll "Export current Local Security Policy to file $exportPath"
	                 secedit.exe /export /cfg "$exportPath"

                    $currentRightKeyValue = (Select-String $exportPath -Pattern "$userRight").Line

                    $splitedKeyValue = $currentRightKeyValue.split("=",[System.StringSplitOptions]::RemoveEmptyEntries)
			           $currentSidsValue  = $splitedKeyValue[1].Trim()

                    $newSidsValue = ""
                    
	                if( $currentSidsValue -notlike "*$($userSidstr)*" ) {
		                Add-CALogAll "Modify ""$userRight"" settings"
		
		                if( [string]::IsNullOrEmpty($currentSidsValue) ) {
			                $newSidsValue = "*$($userSidstr)"
		                } else {
			                $newSidsValue = "*$($userSidstr),$($currentSidsValue)"
		                }
		
                      $importFileContentTemplate = @"
[Unicode]
Unicode=yes
[Version]
signature="`$CHICAGO`$"
Revision=1
[Privilege Rights]
$userRight = $newSidsValue
"@

		                Add-CALogAll "Import new settings to Local Security Policy from file $importPath"
		                $importFileContentTemplate | Set-Content -Path $importPath -Encoding Unicode -Force

			             secedit.exe /configure /db "$secedtPath" /cfg "$importPath" /areas USER_RIGHTS 

	                } else {
		                Add-CALogAll "NO ACTIONS REQUIRED! User $userName already in ""$userRight"""
	                }
                      
                    Remove-Item -Path $importPath -Force
                    Remove-Item -Path $exportPath -Force
                    Remove-Item -Path $secedtPath -Force

	                Add-CALogAll "Finished adding ""$userRight"" user rights to user $userName"
	                return $true
			
		}Catch{
         Add-CALogAll "Failed to add  ""$userRight"" user right for user $userName." "Error"
			Add-CALogErrorDetails $_.Exception
		}

      return $false
	}
	End{
   }
}
export-modulemember -function Add-CAUserRight

# @FUNCTION@ ======================================================================================================================
# Name...........: Set-CAPolicyEntry
# Description....: Set local Group Policy object using the PowerShell module "PolicyFileEditor"
# Parameters.....: $EntryTitle - The descriptive name of the local group policy entry.
#                  $UserDir - Path to the .pol (policy) file 
#						 $RegPath - path to the local GPO entry
#						 $RegName - local GPO entry name
#						 $RegData - local GPO entry value
#						 $RegType - local GPO entry type
# Return Values..: True in case of success, false otherwise
# =================================================================================================================================
function Set-CAPolicyEntry{
	[CmdletBinding()] 
	param(
		$EntryTitle,
		$UserDir,
		$RegPath,
		$RegName,
		$RegData,
		$RegType
	)

	begin{
		try{
			$data = Get-PolicyFileEntry -Path $UserDir -Key $RegPath -ValueName $RegName 
			Add-CALogAll "$EntryTitle status before change: $data"
		}Catch{
			Add-CALogErrorDetails "Error checking local group policy:  $_.Exception"
		}
	}

	process{
		try{
			Add-CALogAll "Set $EntryTitle"

			Set-PolicyFileEntry -Path $UserDir -Key $RegPath -ValueName $RegName -Data $RegData -Type $RegType

		}Catch{
			Add-CALogErrorDetails "Error setting local group policy:  $_.Exception. Please set it manually ($EntryTitle) "
			return $false 
		}
	}

	End{
		try{
			$data = Get-PolicyFileEntry -Path $UserDir -Key $RegPath -ValueName $RegName 
			Add-CALogAll "$EntryTitle status after change: $data"
		}Catch{
			Add-CALogErrorDetails "Error checking local group policy after change:  $_.Exception. Please check ($EntryTitle) manually."
		}

		return $true
	}
}
export-modulemember -function Set-CAPolicyEntry



function Get-CAPolicyEntryAll{
	[CmdletBinding()] 
	param(
		$RegPath
	)

	process{
		$res = Get-PolicyFileEntry -Path $RegPath -All
		Write-Host $res
		Add-CALogAll $res
	}
}
export-modulemember -function Get-CAPolicyEntryAll

# @FUNCTION@ ======================================================================================================================
# Name...........: Get-PolicyFileEntry
# Description....: Get Local Group Policy settings
# Parameters.....:	$Path
#							$Key
#							$ValueName
#							$All
# Return Values..: None
# Function Group.: Main Hardening Functionality
# =================================================================================================================================
function Get-CAPolicyFileEntry
{
    [CmdletBinding(DefaultParameterSetName = 'ByKeyAndValue')]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Path,

        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'ByKeyAndValue')]
        [string] $Key,

        [Parameter(Mandatory = $true, Position = 2, ParameterSetName = 'ByKeyAndValue')]
        [string] $ValueName,

        [Parameter(Mandatory = $true, ParameterSetName = 'All')]
        [switch] $All
    )

    if (Get-Command [G]et-CallerPreference -CommandType Function -Module PreferenceVariables)
    {
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    try
    {
        $policyFile = OpenPolicyFile -Path $Path -ErrorAction Stop
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }

    if ($PSCmdlet.ParameterSetName -eq 'ByKeyAndValue')
    {
        $entry = $policyFile.GetValue($Key, $ValueName)

        if ($null -ne $entry)
        {
            PolEntryToPsObject -PolEntry $entry
        }
    }
    else
    {
        foreach ($entry in $policyFile.Entries)
        {
            PolEntryToPsObject -PolEntry $entry
        }
    }
}
export-modulemember -function Get-CAPolicyFileEntry



# @FUNCTION@ ======================================================================================================================
# Name...........: Set-CAServiceRunWithLocalUser
# Description....: Set service to run with a local user, also set user right to run as service
# Parameters.....: $serviceName - The service name to configure.
#                  $username - The local user name that will run the service
#                  $userPassword - The local user password
# Return Values..: if succeed $true or $false
# =================================================================================================================================
function Set-CAServiceRunWithLocalUser{
    [CmdletBinding()] 
	param(
   [parameter(Mandatory=$true)]
   [ValidateNotNullOrEmpty()]$serviceName,
   [parameter(Mandatory=$true)]
   [ValidateNotNullOrEmpty()]$username,
    [parameter(Mandatory=$true)]
   [ValidateNotNullOrEmpty()]$userPassword
    )
    	Process {
		Try{
            $result = $false

            Add-CALogAll "Start setting '$serviceName' Service to login with '$username' local user"

            Add-CALogAll "Setting service $serviceName to use local user $username for login"
			
			$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($userPassword)
            sc.exe config "$serviceName" obj= ".\$username" password= "$([System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR))"
			
			[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
             
			Add-CALogAll "Giving $username Logon as Service rights"
            Add-CAUserRight $username "SeServiceLogonRight"

            $result = $true

            Add-CALogAll "Finished to set '$serviceName' to login with '$username' local user"

		}Catch{
			Add-CALogErrorDetails $_.Exception
		}

      return $result
	}
	End{
   }
}
export-modulemember -function Set-CAServiceRunWithLocalUser

# @FUNCTION@ ======================================================================================================================
# Name...........: Get-CAPVWAInstallationFolder
# Description....: Get the PVWA installation folder
# Return Values..: If found it return the installation folder otherwise $NULL
# =================================================================================================================================
function Get-CAPVWAInstallationFolder{
	[CmdletBinding()]
	Param()

	Process{
		Add-CALogAll "Searching for PVWA installation"
		$m_PVWAInstallPath = Get-CAServiceNameInstallPath "CyberArk Scheduled Tasks"

		if($m_PVWAInstallPath -ne $NULL)
		{
			# Get the PVWA Installation Path
			$pvwaPath = $m_PVWAInstallPath.Replace("\Services\CyberArkScheduledTasks.exe","").Replace('"',"").Trim()
			Add-CALogAll "Verify if the path '$pvwaPath' exist"
			if (Test-Path -Path $pvwaPath) {
				Add-CALogAll "Found PVWA installation folder at: '$pvwaPath'"
				return $pvwaPath
			} else {
				Add-CALogAll "PVWA installation folder is not exist" "Error"
			}
		}

		Add-CALogAll "PVWA installation folder was not found" "Error"
		return $NULL
	}
	End{
	}
}
export-modulemember -function Get-CAPVWAInstallationFolder

# @FUNCTION@ ======================================================================================================================
# Name...........: Get-CACPMInstallationFolder
# Description....: Get the CPM installation folder
# Return Values..: If found it return the installation folder otherwise $NULL
# =================================================================================================================================
function Get-CACPMInstallationFolder{
       [CmdletBinding()]
       Param()

       Process{
              Add-CALogAll "Searching for CPM installation"
              $m_CPMInstallPath = Get-CAServiceNameInstallPath "CyberArk Password Manager"

              if($m_CPMInstallPath -ne $NULL)
              {
                  # Get the CPM Installation Path
                  $cpmPath = $m_CPMInstallPath.Replace("\PMEngine.exe","").Replace('"',"").Trim()
                  Add-CALogAll "Verify if the path '$cpmPath' exist"
                  if (Test-Path -Path $cpmPath) {
                        Add-CALogAll "Found CPM installation folder at: '$cpmPath'"
                        return $cpmPath
                  } else {
                        Add-CALogAll "CPM installation folder is not exist" "Error"
                  }
              }
              
				  Add-CALogAll "CPM installation folder was not found" "Error"
              return $NULL
       }
       End{
       }
}
export-modulemember -function Get-CACPMInstallationFolder


# @FUNCTION@ ======================================================================================================================
# Name...........: Get-CAServiceNameInstallPath
# Description....: Get path of service executable file according to service name
# Parameters.....: $ServiceName - The service name to extract is execute file.
# Return Values..: If found we get service name path, otherwise $null
# =================================================================================================================================
function Get-CAServiceNameInstallPath{
	param (
	[parameter(Mandatory=$true)]
	[ValidateNotNullOrEmpty()]$ServiceName
	)
	Process {
		try {
			$m_ServiceList = Get-ChildItem "HKLM:\System\CurrentControlSet\Services" | ForEach-Object { Get-ItemProperty $_.pspath }
	
			$regPath =  $m_ServiceList | Where-Object {$_.PSChildName -eq $ServiceName}
			If ($regPath -ne $Null)
			{
				return $regPath.ImagePath.Substring($regPath.ImagePath.IndexOf('"'),$regPath.ImagePath.LastIndexOf('"') + 1)
			}
		} Catch {
			Add-CALogAll "Couldn't extract service execute file path: $ServiceName" "Error"
			Add-CALogErrorDetails $_.Exception
		}

		return $NULL
	}
	End{
   }
}

# @FUNCTION@ ======================================================================================================================
# Name...........: Set-CAPermissions
# Description....: Set new permissions on the relevant path.
# Parameters.....: $path - The location path we want to set permissions.
#				   $identity - The location path we want to set permissions.
#				   $rights - The rights we want to set to the identity on this path.
#							 Please Notice this needs to be string indicate enum name from System.Security.AccessControl.RegistryRights or System.Security.AccessControl.FileSystemRights enums.
#				   $removePreviousPermisions - Boolean indicate if we want to remove all of permissions.
# Return Values..: True or false if succeeded or not.
# =================================================================================================================================
function Set-CAPermissions{
   [CmdletBinding()] 
   param(
   [parameter(Mandatory=$true)]
   [ValidateNotNullOrEmpty()]$path,
   [parameter(Mandatory=$true)]
   [ValidateNotNullOrEmpty()]$identity,
   [parameter(Mandatory=$true)]
   [ValidateNotNullOrEmpty()]$rights,
   [ValidateNotNullOrEmpty()]
   [bool]$removePreviousPermisions = $false

   )
	Process {
		$returnVal = $false
		try {
			Add-CALogAll "Set new permissions: '$rights' on path: '$path' to user\group: '$identity'"
			$acl =( Get-Item $path).GetAccessControl('Access')
			$aclLog = $acl | Format-List | Out-String
         Add-CALogAll "The permissions on path: '$path' before changing are: $aclLog"
			
			# Clean all permissions
			if($removePreviousPermisions -eq $true) {
				$acl.SetSecurityDescriptorSddlForm("D:PAI")
			}
			$aclPermision = New-CANewAccessControlObject -path $path -identity $identity -rights $rights
			$acl.AddAccessRule($aclPermision)

			$acl = Set-Acl -Path $path -AclObject $acl -Passthru
			$aclLog = $acl | Format-List | Out-String
			Add-CALogAll "The permissions on path: '$path' after changing are: $aclLog"

			$returnVal = $true
			
		} Catch {
			Add-CALogErrorDetails $_.Exception
			Add-CALogAll "Failed to set new permissions: '$rights' on path: '$path' to user\group: '$identity'" "Error"
		}
		return $returnVal
	}
	End{
   }
}
export-modulemember -function Set-CAPermissions

# @FUNCTION@ ======================================================================================================================
# Name...........: Get-SIDNameValue
# Description....: Get the name value of SID identity
# Parameters.....: $sidID - A string indicate the SID id.
# Return Values..: If found we the value name, otherwise $NULL
# =================================================================================================================================
function Get-SIDNameValue{
   [CmdletBinding()] 
   param(
   [parameter(Mandatory=$true)]
   [ValidateNotNullOrEmpty()]$sidID
   )
	Process {
		$returnVal = $NULL
		try {
			# Use this SID to take the name of built-in operating system identifiers.
			$objSID = New-Object System.Security.Principal.SecurityIdentifier ($sidID)
			$objGroup = $objSID.Translate([System.Security.Principal.NTAccount])
			$returnVal = $objGroup.value
			Add-CALogAll "Sid name is: $returnVal"
		} Catch {
			Add-CALogErrorDetails $_.Exception
		}
		return $returnVal
	}
	End{
   }
}
export-modulemember -function Get-SIDNameValue

# @FUNCTION@ ======================================================================================================================
# Name...........: New-CANewAccessControlObject
# Description....: Get the relevant access control object for this path.
# Parameters.....: $path - The location path we want to set permissions.
#				   $identity - The identity we want to set the relevant permissions.
#				   $rights - The rights we want to set to the identity on this path.
#							 Please Notice this needs to be string indicate enum name from System.Security.AccessControl.RegistryRights or System.Security.AccessControl.FileSystemRights enums.
# Return Values..: $NUll is couldn't create object, otherwise it return the relevant object.
# =================================================================================================================================
function New-CANewAccessControlObject{
   [CmdletBinding()] 
   param(
   [parameter(Mandatory=$true)]
   [ValidateNotNullOrEmpty()]$path,
   [parameter(Mandatory=$true)]
   [ValidateNotNullOrEmpty()]$identity,
   [ValidateNotNullOrEmpty()]$rights
   )
	Process {
		$returnVal = $NULL
		try {
			$item = Get-Item -Path $path
			
			If ($item -is [System.IO.DirectoryInfo]) {
				$returnVal = New-Object System.Security.AccessControl.FileSystemAccessRule ($identity,$rights,"ContainerInherit,ObjectInherit","None","Allow")
			} ElseIf ($item -is [Microsoft.Win32.RegistryKey]) {
				$returnVal = New-Object System.Security.AccessControl.RegistryAccessRule ($identity,$rights,"ContainerInherit,ObjectInherit","None","Allow")
			} ElseIf ($item -is [System.IO.FileInfo]){
				$returnVal = New-Object System.Security.AccessControl.FileSystemAccessRule ($identity,$rights,"Allow")
			}
		} Catch {
			Add-CALogErrorDetails $_.Exception
		}
		return $returnVal
	}
	End{
   }
}
export-modulemember -function New-CANewAccessControlObject

# @FUNCTION@ ======================================================================================================================
# Name...........: Set-CAPathPermisionsOnlyToAdministratorsGroup
# Description....: Set on the relevant path permissions only for administrators.
# Parameters.....: $path - The location path we want to set permissions.
# Return Values..: True or false if succeeded or not.
# =================================================================================================================================
function Set-CAPathPermisionsOnlyToAdministratorsGroup{
   [CmdletBinding()] 
   param(
   [parameter(Mandatory=$true)]
   [ValidateNotNullOrEmpty()]$path
   )
	Process {
		$returnVal = $false
		$administratorAccess = $null
		try {
			# "S-1-5-32-544" is constant value representing Administrators group
			# Use this SID to take Administrators group built-in name from operating system.
			$administratorsGroupName = Get-SIDNameValue "S-1-5-32-544"
			$returnVal = Set-CAPermissions $path $administratorsGroupName "FullControl" $true
		} Catch {
			Add-CALogErrorDetails $_.Exception
		}
		return $returnVal
	}
	End{
   }
}
export-modulemember -function Set-CAPathPermisionsOnlyToAdministratorsGroup


# @FUNCTION@ ======================================================================================================================
# Name...........: Set-AdvancedAuditPolicySubCategory
# Description....: Set Advanced Audit Policy security settings
# Parameters.....: $subcategory - String containing the entry to set
#                  $success - success enabled/disabled
#                  $failure - failure enabled/disabled
# Return Values..: None
# =================================================================================================================================
function Set-AdvancedAuditPolicySubCategory{
   [CmdletBinding()] 
   param(
   [parameter(Mandatory=$true)]
   [ValidateNotNullOrEmpty()]$subcategory,
	[ValidateSet("enable","disable")] 
   [ValidateNotNullOrEmpty()]$success="enable",
	[ValidateSet("enable","disable")] 
   [ValidateNotNullOrEmpty()]$failure="enable"
   )
	Process {
		$returnVal = $true
		try {			
			Add-CALogAll "Subcategory $subcategory current state:"
			auditpol /get /subcategory:$subcategory |  ForEach-Object { if($_ -ne "") { Add-CALogAll $_ } }
			
			auditpol /set /subcategory:$subcategory /success:$success /failure:$failure

			Add-CALogAll "Subcategory $subcategory state after change:"
			auditpol /get /subcategory:$subcategory |  ForEach-Object { if($_ -ne "") { Add-CALogAll $_ } }
		} Catch {
			Add-CALogErrorDetails $_.Exception
			$returnVal = $false
		}
		return $returnVal
	}
	End{
   }
}
export-modulemember -function Set-AdvancedAuditPolicySubCategory


# @FUNCTION@ ======================================================================================================================
# Name...........: Set-CARemoveExcessPermissions
# Description....: Set new permissions on the relevant path. Remove inheritance and permissions of users not in 'identitiesToIgnore' parameter
# Parameters.....: $path - The location folder we want to set permissions.
#				       $identitiesToIgnore - Array of identities (users) we want to save permissions on the folder. Giving them full permissions
# Return Values..: Exit code - 0 if succeeded or last error code if not.
# =================================================================================================================================
function Set-CARemoveExcessPermissions {
    [CmdletBinding()] 
    param(
	    [Parameter(Mandatory=$true)]
       [ValidateNotNullOrEmpty()]$path,
       [Parameter(Mandatory=$true)] 
       [string[]]$identitiesToIgnore
	)

   Process {

      $exitCode = 0

		try {
            
            if( -Not (Test-Path -path $path) ) {
               Add-CALogAll "Failed to set new permissions on path: '$path', path not found." "Error"
               $exitCode = 2
            }else {
               $aclLog = Get-ACL -Path $path | Format-List | Out-String
               Add-CALogAll "The permissions on path: '$path' before changing are: $aclLog"

			    $thisUser = $env:UserDomain + "\" + $env:UserName				
				
			   Add-CALogAll "Current user: '$thisUser'"                       
	
               Add-CALogAll "Removing inheritance access permissions on '$path'"

	            $output = icacls.exe `"$path`" /inheritance:d
	            if (-not $?) {
                  Add-CALogAll "Failed to remove inheritance access permissions on folder '$path'. Error code: $lastexitcode" "Error"
                  $exitCode = $lastexitcode
	            }

               ForEach ($identity in $identitiesToIgnore)
	            {
                  Add-CALogAll "Grant full access control permissions to '$identity' on folder '$path'"

                  $item = Get-Item -Path $path
			
                  # ContainerInherit (CI),ObjectInherit (OI) can be set only on folders not files
			         If ($item -is [System.IO.DirectoryInfo]) {
				         $output = icacls.exe `"$path`" /grant `"$identity`":`(OI`)`(CI`)F
			         } ElseIf ($item -is [System.IO.FileInfo]){
				         $output = icacls.exe `"$path`" /grant `"$identity`":F
			         }

		            if (-not $?) { 
                     Add-CALogAll "Failed to grant full access control permissions to '$identity' on folder '$path'. Error code: $lastexitcode" "Error"
                     $exitCode = $lastexitcode
		            }
	            }
	
	            $acl = Get-Acl -Path $path
		
	            $identitiesToIgnore += $thisUser

	            ForEach ($accessRule in $acl.Access)
	            {
		            if ($identitiesToIgnore -notcontains $accessRule.IdentityReference)
		            {
			            $identityRefernce = Get-IdentityReference -identityRefernce $accessRule.IdentityReference
			            Add-CALogAll "Trying to remove access rule for '$identityRefernce' on folder '$path'"
			         
			            $output = icacls.exe `"$path`" /remove:g $identityRefernce
			            if (-not $?) { 
                        $exitCode = $lastexitcode
                        Add-CALogAll "Failed to remove access permissions of '$identityRefernce' on folder '$path'. Error code: $lastexitcode" "Error"
			            } 
		            }
	            }

               Add-CALogAll "Removing access permissions for '$thisUser' on folder '$path'"
	
	            $output = icacls.exe `"$path`" /remove:g $thisUser
	            if (-not $?) { 
                  $exitCode = $lastexitcode
                  Add-CALogAll "Failed to remove access permissions of '$thisUser' on folder '$path'. Error code: $lastexitcode" "Error"
	            }

               $aclLog = Get-ACL -Path $path | Format-List | Out-String
               Add-CALogAll "The permissions on path: '$path' after changing are: $aclLog"
            }

      } Catch {
         $exitCode = -1
         Add-CALogAll "Failed to set new permissions on path: '$path'" "Error"
			Add-CALogErrorDetails $_.Exception
		}

		return $exitCode 
   }
	End{
   }
}
export-modulemember -function Set-CARemoveExcessPermissions

# @FUNCTION@ ======================================================================================================================
# Name...........: Get-IdentityReference
# Description....: Get Identity Reference
# Parameters.....: $identityRefernce
# Return Values..: IdentityReference
# =================================================================================================================================
function Get-IdentityReference
{
	[CmdletBinding()] 
	param(
		$identityRefernce
	)

	Process {
		if ($identityRefernce -eq 'APPLICATION PACKAGE AUTHORITY\ALL APPLICATION PACKAGES')
		{
			$identityRefernce = "ALL APPLICATION PACKAGES"
		}
		if ($identityRefernce -eq 'APPLICATION PACKAGE AUTHORITY\ALL RESTRICTED APPLICATION PACKAGES')
		{
			$identityRefernce = "ALL RESTRICTED APPLICATION PACKAGES"
		}
    
		return $identityRefernce
	}
}
export-modulemember -function Get-IdentityReference


# @FUNCTION@ ======================================================================================================================
# Name...........: Read-ConfigurationFile
# Description....: Parse Configuration File and get all the steps to execute
# Parameters.....: $identityRefernce
# Return Values..: IdentityReference
# =================================================================================================================================
function Read-ConfigurationFile
{
	[CmdletBinding()] 
	param(
		[Parameter(Mandatory=$true)]
		[string]$ConfigurationFilePath
	)

	Process {
		try
		{
			[xml]$ConfigurationObject = Get-Content $ConfigurationFilePath
			$StepsToRun=@()
			$StepsNodes = $ConfigurationObject.SelectNodes("//Step")
	
			foreach ($node in $StepsNodes) 
			{
				$enable = $node.attributes['Enable'].value
		
				if ($enable -eq "Yes")
				{
		
					$name = $node.attributes['Name'].value
					$displayName = $node.attributes['DisplayName'].value
					$scriptName = $node.attributes['ScriptName'].value
					$scriptEnable = $node.attributes['Enable'].value
					$parametersNode = $node.FirstChild 
			
					$ParamsList=@()  # Will be empty if the step does not contain parameters
			
					if ($parametersNode -ne $null)
					{
						$ParametersNodeContent = $parametersNode.SelectNodes("//Parameter")
						foreach ($param in $ParametersNodeContent) 
						{
							$paramName = $param.attributes['Name'].value
							$paramValue = $param.attributes['Value'].value
					
							$paramObject = new-object psobject -prop @{Name=$paramName;Value=$paramValue}
					
							$ParamsList += $paramObject				
						}
					}
			
					$StepObject = new-object psobject -prop @{Name=$name;DisplayName=$displayName;ScriptName=$scriptName;Parameters=$ParamsList;Enable=$scriptEnable}
					
					$StepsToRun += $StepObject
				}			
			}

			return $StepsToRun
		}
		Catch
		{
			Add-CALogAll "Failed to parse configuration file: $ConfigurationFilePath" "Error"
			Add-CALogErrorDetails $_.Exception
			return $null
		}
	}
}
export-modulemember -function Read-ConfigurationFile


# @FUNCTION@ =============================================================================================================================
# Name...........: IsPSMInstalled
# Description....: This function checks is PSM is already installed on this machine.
# Parameters.....: None
# Return Values..: Exists (Boolean)
# Function Group.: Main Hardening Functionality
# ========================================================================================================================================
function Test-IsPSMInstalled(){
	Process{
		$installedPSMRegistryPath = "hklm:software\wow6432node\cyberark\cyberark privileged session manager\"
		if(Test-Path -Path $installedPSMRegistryPath)
		{
			# PSM already exists on this machine
			$versionPath = Get-ChildItem -Path $installedPSMRegistryPath
			if($versionPath) {
				$lastVersionPath = $versionPath[$versionPath.Length - 1].Name
				$version = $lastVersionPath.Substring($lastVersionPath.LastIndexOf("\") + 1)

				if($version) {
					Add-CALogAll "PSM version $version was installed on this machine."
					return $true
				}
			}
		}
		return $false
	}
	End{
	}
}
export-modulemember -function Test-IsPSMInstalled 


# @FUNCTION@ ======================================================================================================================
# Name...........: Get-CAUserSID
# Description....: Get user sid value
# Parameters.....: $userName - The user name we want his SID value.
# Return Values..: SID str value
# =================================================================================================================================
function Get-CAUserSID {
    [CmdletBinding()] 
	param(
   [parameter(Mandatory=$true)]
   [ValidateNotNullOrEmpty()]$userName
    )
    	Process {
			Add-CALogAll "Get SID value for user: $userName"
			$userSidstr = $null
            Try {
				$ntprincipal = new-object System.Security.Principal.NTAccount "$userName"
		        $userSid = $ntprincipal.Translate([System.Security.Principal.SecurityIdentifier])
		        $userSidstr = $userSid.Value.ToString()
				Add-CALogAll "User SID: $($userSidstr)"
	        } Catch {
				$userSidstr = $null
				Add-CALogAll "Failed to get SID for user: $userName" "Error"
				Add-CALogErrorDetails $_.Exception

	        }
			            
			return $userSidstr
		}
	End{
   }
}
export-modulemember -function Get-CAUserSID

# @FUNCTION@ ======================================================================================================================
# Name...........: Add-CARegistryKey
# Description....: Creates a new registry key (folder)
# Parameters.....: $regPath - The full path of the registry key that is being created
# Return Values..: None
# =================================================================================================================================
function Add-CARegistryKey{
	[CmdletBinding()] 
   param(
   [parameter(Mandatory=$true)]
   [ValidateNotNullOrEmpty()]$regPath
   )

	Process {
		Try{
			If(-not(Test-Path -Path $regPath)){
				Add-CALogAll "Attempting to create new registry path: $regPath"
				New-Item -Path $regPath -Force
                Add-CALogAll "The registry key has been successfully created. Registry path $regPath"
			}
            else
            {
                Add-CALogAll "The registry key already exist. Registry path: $regPath"
            }

			
		}Catch{
			Add-CALogErrorDetails $_.Exception
		}
	}
	End{
   }
}
export-modulemember -function Add-CARegistryKey

# @FUNCTION@ ======================================================================================================================
# Name...........: Add-EditCARegistryEntry
# Description....: Creates or update registry entry using the registry path, property name, property value and property type submitted 
# Parameters.....: $regPath - The full path of the registry key that is being created
#                  $regKey - The name of the registry item be created
#                  $regValue - The value that the registry item will be set as
#                  $regProperty - The type of the registry property that will be created
# Return Values..: None
# =================================================================================================================================
function Add-EditCARegistryEntry{
[CmdletBinding()] 
   param(
   [parameter(Mandatory=$true)]
   [ValidateNotNullOrEmpty()]$regPath,
   [parameter(Mandatory=$true)]
   [ValidateNotNullOrEmpty()]$regName,
   [parameter(Mandatory=$true)]
   [ValidateNotNullOrEmpty()]$regValue,
   [parameter(Mandatory=$false)]
   [ValidateNotNullOrEmpty()]$regType = "DWord"
   )
	Process {
	
		if(Test-CARegistryEntryExist $regPath $regName){
            Add-CALogAll ("Edit reg path: {0}, name: {1}, value: {2}" -f $regPath, $regName, $regValue)
			Set-CARegistryEntry $regPath $regName $regValue
		} else {
            Add-CALogAll ("Add reg path: {0}, name: {1}, value: {2}, type: {3}" -f $regPath, $regName, $regValue, $regType)
			Add-CARegistryEntry $regPath $regName $regValue $regType
		}
	}
	End{
   }
}
export-modulemember -function Add-EditCARegistryEntry

# @FUNCTION@ ======================================================================================================================
# Name...........: Get-SecurePassword
# Description....: this method gets password as securePassword or plain text
#						 and returns the password as securePassword
# Parameters.....: $spassword - password as securePassword
# password AsPlainText
# Return Values..: execution summary
# =================================================================================================================================
function Get-SecurePassword
{
	[CmdletBinding()]
	param(
   [string]$password,
   [Security.SecureString]$spassword
	)
	Process {
		
		if(!$spassword)
		{
			if ([string]::IsNullOrEmpty($password)) 
			{
				#read secure password from intercative user
				Add-CALogAll "Vault user password is missing, reading password from interactive user" "Info"
				$spassword = Read-Host "Enter Vault User Password" -AsSecureString;
			}
			else
			{
				$spassword = (ConvertTo-SecureString $password -AsPlainText -Force)
			}
		}
		
		return $spassword;
	 }
	 End {
	 }
}
export-modulemember -function Get-SecurePassword

# @FUNCTION@ ======================================================================================================================
# Name...........: Install-CAGenericSteps
# Description....: this method gets a path to a steps config file, parse the file, run the steps, 
#						 and return a summary of the execution
# Parameters.....: $configStepsPath - The full path of the steps config file
# Return Values..: execution summary
# =================================================================================================================================
function Install-CAGenericSteps{
[CmdletBinding()] 
   param(
   [parameter(Mandatory=$true)]
   [ValidateNotNullOrEmpty()]
   $configStepsPath,
   [string]$password,
   [Security.SecureString]$spassword
	)

	Process {
      if($spassword)
       {
            $global:spassword = $spassword;
       }
       if(![String]::IsNullOrEmpty($password))
       {
            $global:password = $password;
       }

		$AllStepsArray = @()
		$ModulesToRun = Read-ConfigurationFile $configStepsPath
		if($ModulesToRun -eq $null)
		{
			Add-CALogAll "*******************************************************************"
			Add-CALogAll "        Operation Failure. Error parsing configuration file"
			Add-CALogAll "*******************************************************************"

			$parseFailResult = "" | Select-Object -Property isSucceeded, errorData, logPath
			$parseFailResult.isSucceeded = 1
			$parseFailResult.errorData = "Error parsing configuration file"
			$parseFailResult.logPath = ".\Script.log"
			return $parseFailResult
		}

		$report = $null
		ForEach ($module in $ModulesToRun) 
		{
			$displayName = $module.DisplayName
			Add-CALogAll "==================================================================="
			Add-CALogAll "Start Step $displayName"

			$CurrModule = Import-Module ".\$($module.ScriptName)" -PassThru

			if ($module.Enable -ne 'Yes' -and $module.Enable -ne 'True')
			{
				Add-CALogAll "Step is disabled"
				$runScript = $false
				$report += "Step $displayName is disabled.`n"
			}
			elseif ($true -eq $performPreCheck)
			{
				Add-CALogAll "Starting prerequisites check"

				try
				{
					$runScript = & $CurrModule {PreCheck}
				}
				catch
				{
					Add-CALogErrorDetails $_.Exception
					$runScript = $false
					$report += "Step $displayName PreCheck failed. See error in log.`n"
				}
			}
			else 
			{
				# no preCheck, run step
				$runScript = $true
				Add-CALogAll "Skipping prerequisites check"
				$report += "Step $displayName Skipping prerequisites check.`n"
			}

			if ($runScript)
			{	
				Add-CALogAll "start execute step $displayName"

				try
				{
					$params = $module.Parameters
					$executeCommand = Get-Command -Module $CurrModule -Name "Execute" -PassThru
					$isSuccess = . $executeCommand $params

					if (!$isSuccess)
					{
							$failedSteps += $CurrModule
							Add-CALogAll "The following step had failed: $CurrModule. Please see documentation in the log" "Error"
					}
					else
					{
							[array]$successSteps += $CurrModule
							Add-CALogAll "The following step had been completed successfully: $CurrModule"
					}
				}
				catch
				{
					Add-CALogErrorDetails $_.Exception
					if ($failedSteps -notcontains $CurrModule)
					{
						Add-CALogAll "The following step had failed: $CurrModule. Please see documentation in the log" "Error"
	    				$failedSteps += $CurrModule
					}
				}

				Add-CALogAll "finish execute step $displayName"
			}
			else
			{
				$failedSteps += $CurrModule
			}
		}

		Add-CALogAll "==================================================================="
    
		$result = 0
		$resultMessage = ''
		if ($failedSteps.Length -ge 1)
		{
			Add-CALogAll "*******************************************************************"
			$resultMessage = "        The following Step failed : $failedSteps"
			Add-CALogAll $resultMessage "Error"
			Add-CALogAll "*******************************************************************"
			$result = 1
		} 
		else
		{
			Add-CALogAll "*******************************************************************"
			$resultMessage = "                  Operation Succeeded"
			Add-CALogAll $resultMessage
			Add-CALogAll "*******************************************************************"
		}

		$report += $resultMessage

		$scriptResult = "" | Select-Object -Property isSucceeded, errorData, logPath
		$scriptResult.isSucceeded = $result
		$scriptResult.errorData = $report
		$scriptResult.logPath = "$pwd\Script.log"

		return $scriptResult  # | ConvertTo-Json
	}
	End{
   }
}
export-modulemember -function Install-CAGenericSteps


# @FUNCTION@ ======================================================================================================================
# Name...........: Remove-WindowsFeaturesOrRoles
# Description....: this method gets a list of windows features or roles to uninstall, check and if installed than
#						 uninstall them
# Parameters.....: $entitiesToCheck - List of windows features or roles to uninstall
#						 $entityType - feature or role
# Return Values..: execution summary
# =================================================================================================================================
function Remove-WindowsFeaturesOrRoles{
	[CmdletBinding()]
	Param(
		$entitiesToCheck,
		$entityType
	)

	Process{
		
		$result = $true
		$entitiesToRemove = @()
		ForEach ($entity in $entitiesToCheck)
		{
			try{
				Add-CALogAll "Checking $entityType : $entity"
				If(Test-CAInstalledRole $entity)
				{
					Add-CALogAll "$entity $entityType is installed and added to list of entities to uninstall"
					$entitiesToRemove += $entity
				} else {
					Add-CALogAll "$entity $entityType is not installed"
				}
			}
			catch{
				Add-CALogErrorDetails $_.Exception
				Add-CALogAll "Could not determine $entityType $entity existence. Please check and uninstall it manually." "Error"
			}
		}

		if ($entitiesToRemove.Count -ge 1) {
			try {
				Add-CALogAll "Attempting to uninstall $entityType : $entitiesToRemove"				
				$entitiesToRemove = $entitiesToRemove -join ","
				$script = "Uninstall-WindowsFeature $entitiesToRemove"
				Wait-Script $script $uninstallTimeout
			}
			catch {
				Add-CALogAll "The following entities were not removed. Please uninstall them manually." "Error"
				Add-CALogErrorDetails $_.Exception
			}


			Add-CALogAll "validating entities removal"
			ForEach ($entity in $entitiesToRemove)
			{
				try {
					If(Test-CAInstalledRole $entity) {
						Add-CALogAll "Server $entityType $entity was not removed. Please uninstall it manually." "Error"
						$result = $false
					} else {
						Add-CALogAll "Server $entityType $entity and its child entities (if existed) were uninstalled successfully."
					}
				} catch{
					Add-CALogAll "Could not determine $entityType $entity removal. Please check and uninstall it manually if needed." "Error"
					$result = $false
				}
			}
		}

		return $result
	}
	End{

	}
}
export-modulemember -function Remove-WindowsFeaturesOrRoles


# @FUNCTION@ ======================================================================================================================
# Name...........: Add-WindowsFeaturesOrRoles
# Description....: this method gets a list of windows features or roles to install, check and if not already installed than
#						 install them
# Parameters.....: $entitiesToCheck - List of windows features or roles to uninstall
#						 $entityType - feature or role
# Return Values..: execution summary
# =================================================================================================================================
function Add-WindowsFeaturesOrRoles{
	[CmdletBinding()]
	Param(
		$entitiesToCheck,
		$entityType
	)

	Process{
		
		$result = $true
		$entitiesToAdd = @()
		$AlternativeSource = "C:\Windows\Temp\sxs"
		ForEach ($entity in $entitiesToCheck)
		{
			try{
				Add-CALogAll "Checking $entityType : $entity"
				If(Test-CAInstalledRole $entity)
				{
					Add-CALogAll "$entity $entityType is installed"
				} else {
					Add-CALogAll "$entity $entityType is not installed and added to list of entities to install"
					$entitiesToAdd += $entity
				}
			}
			catch{
				Add-CALogErrorDetails $_.Exception
				Add-CALogAll "Could not determine $entityType $entity existence. Please check and install it manually." "Error"
			}
		}

		if ($entitiesToAdd.Count -ge 1) {
			try {
				Add-CALogAll "Attempting to install $entityType : $entitiesToAdd"
				if (Test-Path -Path $AlternativeSource) {
				Install-WindowsFeature $entitiesToAdd -Source $AlternativeSource
				}
				else {
				Install-WindowsFeature $entitiesToAdd
				}
			}
			catch {
				Add-CALogAll "The following entities were not added. Please install them manually." "Error"
				Add-CALogErrorDetails $_.Exception
			}


			Add-CALogAll "validating entities installed"
			ForEach ($entity in $entitiesToAdd)
			{
				try {
					If(Test-CAInstalledRole $entity) {
						Add-CALogAll "Server $entityType $entity installed successfully."
					} else {
						Add-CALogAll "Server $entityType $entity was not installed. Please install it manually." "Error"
						$result = $false
					}
				} catch{
					Add-CALogAll "Could not determine $entityType $entity removal. Please check and install it manually if needed." "Error"
					$result = $false
				}
			}
		} else {
			Add-CALogAll "All entities already installed"
		}

		return $result
	}
	End{

	}
}
export-modulemember -function Add-WindowsFeaturesOrRoles

Function Get-DnsHost()
{
	[CmdletBinding()]
	Param(
	)

	Process{
		return [system.net.dns]::GetHostByName($env:COMPUTERNAME) | fl hostname | Out-String | %{ "{0}" -f $_.Split(':')[1].Trim()};
	}
}
export-modulemember -function  Get-DnsHost

# @FUNCTION@ ======================================================================================================================
# Name...........: Remove-Certificate
# Description....: purge DNS certificates
# Parameters.....: $store - data store
# Return Values..: execution summary
# =================================================================================================================================
Function Remove-Certificate()
{
	[CmdletBinding()]
	Param(
		$store
	)
	Process{
		#purge DNS certificates
		[string]$DnsHost = Get-DnsHost

		$store.Open('ReadWrite')
		## Find all certs that have an Issuer of my old CA
		$container = "CN=$DnsHost"
		$certs = $store.Certificates | ? {$_.Subject -eq $container}
		## Remove all the certs it finds
		$certs | % {$store.Remove($_)}
		
		return $true
	 }
	End{
	}
}
export-modulemember -function Remove-Certificate


# @FUNCTION@ ======================================================================================================================
# Name...........: Set-CAValuesInInstallationFile
# Description....: this method set values in iss file
# Parameters.....: $issFilePath - The full path of iss file
#				   $parameters - Values to set in the iss file
# Return Values..: execution summary
# =================================================================================================================================
function Set-CAValuesInInstallationFile()
{
	[CmdletBinding()]
	param(
		[parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]$issFile,
		[parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]$parameters
	)
	process{
		$result = $true
		try {

			Add-CALogAll "Attempting to set ISS parameters, on file: ""$issFilePath"""
			if (-not (Test-Path -Path $issFilePath))
			{
				Add-CALogAll "Failed to set ISS parameters, reason: file on path: ""$issFilePath"" does not exist" "Error"
				return $false
			}
			$issFileContent = Get-Content($issFile)
     
			foreach($param in $parameters) {
				# Replace keys in format of {{key}} with values
				$keyFormat = "{{" + $param.psobject.properties["Name"].value + "}}"
				$issFileContent = $issFileContent.replace($keyFormat,$param.psobject.properties["Value"].value)
			}

			Set-Content -Path $issFile -Value $issFileContent -Force
		}
		catch {
			Add-CALogErrorDetails $_.Exception
			Add-CALogAll "Failed to set ISS parameters, unexpected error" "Error"
			$result = $false
		}
		Add-CALogAll "End setting ISS parameters, on file: ""$issFilePath"""
		return $result
	}
	End{
	}
}
export-modulemember -function Set-CAValuesInInstallationFile

# @FUNCTION@ ======================================================================================================================
# Name...........: Invoke-CASetupFile
# Description....: this method running setup file in silent mode.
# Parameters.....: $issFilePath - The full path of iss file
#				   $setupPath - The full path of setup file path
#				   $parameters - Values to set in the iss file
#				   $silentLog - The full path of to the silent log file
#				   $additionalInputParams - additional parameters for the installation
# Return Values..: execution summary
# =================================================================================================================================
function Invoke-CASetupFile(){
	[CmdletBinding()]
	param(
		[parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$issFilePath,
		[parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$setupPath,
		[parameter(Mandatory=$true)]
		$parameters,
		[parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$silentLog,
		[parameter(Mandatory=$false)]
		[array]$additionalInputParams=$null
	)
	process{
		Add-CALogAll "start execute setup file"
		
		if (-not($parameters -eq $null) -and $parameters.Count -gt 0){
			$result = Set-CAValuesInInstallationFile $issFilePath $parameters
			
			if(-not($result)) {
				Add-CALogAll "Failed to run setup file. There was a problem in setting ISS values." "Error"
				return $false
			}
		}
		
		if(-not(Test-Path -Path $setupPath)) {
			Add-CALogAll "Failed to run setup file. The installation file not found in the path: $setupPath" "Error"
			return $false
		}
		try{
			Add-CALogAll "Running setup file: $setupPath"
			#Run setup
			$arglist = "/s /f1`"$issFilePath`""
			if($additionalInputParams -is [system.array] -and $additionalInputParams.Count -ge 0) {
				$params = ""
				ForEach ($param in $additionalInputParams) {
					$params = "$params;$param"
				}
				$params = $params.Substring(1)
				$arglist = $arglist + " /z`"$params`""
			}

			$arglist = $arglist + " /f2`"$silentLog`""
			$process = (Start-Process -FilePath $setupPath -ArgumentList $arglist -Wait -NoNewWindow -PassThru)
		}
		catch{
			Add-CALogErrorDetails $_.Exception
			Add-CALogAll "Failed to running setup" "Error"
			$result = $false
		}
		Add-CALogAll "Finish to execute setup file"
		return $process.ExitCode -eq 0
	}
	End{
	}
}
export-modulemember -function Invoke-CASetupFile

# @FUNCTION@ ======================================================================================================================
# Name...........: Wait-Script
# Description....: This method runs a script block with timeout limitation.
# Parameters.....: $scriptBlock - The script block which will run with timeout limitation
#				   $timeout - timeout for ending the script running in seconds
# Return Values..: None
# =================================================================================================================================

function Wait-Script(){
[CmdletBinding()] 
   param(
	   [parameter(Mandatory=$true)]
	   [ValidateNotNullOrEmpty()]
	   [string]$script, 

	   [Parameter(Mandatory=$true)]
       [ValidateNotNullOrEmpty()]
	   [int]$timeout ## seconds
	)

	process {
				Set-Variable RetriesCount -option Constant -value 3

				$scriptBlock = [scriptblock]::Create("
									$script 
							   ")

				$jobCompleted = $false

                For ($i=1; ($i -le $RetriesCount) -and ($jobCompleted -eq $false); $i++) {

						try {
							$Job = Start-Job -ScriptBlock $scriptBlock

							if (Wait-Job $Job -Timeout $timeout) { 
								Receive-Job $Job 
							}			
						
							$state = $Job.State.ToString()
							Add-CALogAll "Operation state: $state"
						
							if($state -ne "Completed") 
							{
								Add-CALogAll "Timeout expired in attempt number $i"
							}
							else
							{
								$jobCompleted = $true
							}				             
							Remove-Job -force $Job
							$timeout+=30
						}
						catch {
							Add-CALogAll "An Error Occured during waiting for the script: $scriptBlock." "Error" 
							Add-CALogErrorDetails $_.Exception
						}
					}	
								
			 }             
	End{
   }
}
export-modulemember -function Wait-Script


function Restart-CAAppPool(){
 [CmdletBinding()] 
    param(
	   [parameter(Mandatory=$true)]
	   [ValidateNotNullOrEmpty()]
	   [string]$appPoolName
	)
	try
	{
	    Add-CALogAll "Checking the status of application pool $appPoolName"
		$appPoolState = Get-WebAppPoolState $appPoolName
		if ($appPoolState.Value -eq "Stopped")
		{
			Add-CALogAll "Application pool $appPoolName is stopped - starting the application pool"
			Start-WebAppPool $appPoolName
		}
		else {
			Add-CALogAll "Application pool $appPoolName is running - restarting the application pool"
			Restart-WebAppPool $appPoolName
		}
		
		$maxTries = 5
		$getStateTry = 1
		$appPoolState = Get-WebAppPoolState $appPoolName		
		while (($appPoolState.Value -eq "Starting" -or $appPoolState.Value -eq "Unknown") -and $getStateTry -lt $maxTries)
		{
			Add-CALogAll "Application pool $appPoolName is not started yet, current status is $appPoolState.Value. Waiting 1 second and checking again"			
			Start-Sleep -Seconds 1
			$appPoolState = Get-WebAppPoolState $appPoolName
			$getStateTry = $getStateTry + 1
		}
		
		if (-not($appPoolState.Value -eq "Started"))
		{
			Add-CALogAll "Failed to restart application pool $appPoolName, please start it manually" "Error"
			return $false
		}
		
		Add-CALogAll "Application pool $appPoolName restarted successfully"
		return $true
	}
	catch
	{
		Add-CALogAll "Failed to restart application pool $appPoolName, please start it manually" "Error"
		Add-CALogErrorDetails $_.Exception
		return $false
	}
}
export-modulemember -function Restart-CAAppPool