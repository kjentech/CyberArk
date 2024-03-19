# @FUNCTION@ ======================================================================================================================
# Name...........: Execute
# Description....: Installing Replicate application
# Parameters.....: None
# Return Values..: None
# =================================================================================================================================
function Execute{
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$false)] 
		[array]$Args = $null
	)

	Process{
		Add-CALogAll "Start Replicate installation"
		Add-CALogAll "Args: $Args"
		$ScriptRoot = (Get-Location).Path		
		$setupPath = "$ScriptRoot\setup.exe"
		$silentLog = "$ScriptRoot\Replicate_silent.log"

		
		
		#define variables from XML
		$Args | foreach {New-Variable -Name $_.Name -Value $_.Value}

		if ($isUpgrade -eq "true")
        {
            $issFilePath = "$ScriptRoot\setup_upgrade.iss"
			Add-CALogAll "installation is running in upgrade mode"
        }
        else
        {	
			Copy-Item -Path "$ScriptRoot\setup_template.iss" -Destination "$ScriptRoot\setup.iss"
            $issFilePath = "$ScriptRoot\setup.iss"
			Add-CALogAll "installation is running in install mode"
        }		
		
		try {
			# Replace placeholders with values from the configuration xml file
			#$additionalArgs = @( )	
			$result = Invoke-CASetupFile $issFilePath $setupPath $Args $silentLog
		}
		catch{
			Add-CALogErrorDetails $_.Exception
			Add-CALogAll "Failed installing Replicate" "Error"
			$result = $false
		}
		return $result
	}
	End{
	}
}
export-modulemember -function Execute


function PreCheck{
	[CmdletBinding()] 
	 Param()

	 Process{
		$true
	 }
	End{
	}
}
export-modulemember -function PreCheck