# @FUNCTION@ ======================================================================================================================
# Name...........: Execute
# Description....: Installing CPM application
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
		Add-CALogAll "Start CPM installation"
		Add-CALogAll "Args: $Args"
		$ScriptRoot = (Get-Location).Path		
		$setupPath = "$ScriptRoot\..\..\setup.exe"
		$silentLog = "$ScriptRoot\cpm_silent.log"

		$username = ($Args | Where Name -eq "Username").Value
		$company = ($Args | Where Name -eq "Company").Value
		$CPMInstallDirectory = ($Args | Where Name -eq "CPMInstallDirectory").Value

		$isUpgradeVal =	($Args | Where Name -eq "isUpgrade").Value
		if ($isUpgradeVal -eq "true")
        {
            $issFilePath = "$ScriptRoot\silentUpdate.iss"
			Add-CALogAll "installation is running in upgrade mode"
        }
        else
        {		
            $issFilePath = "$ScriptRoot\CPM_template.iss"
			Add-CALogAll "installation is running in install mode"
        }		
		
		try {
			# Replace placeholders with values from the configuration xml file
			$additionalArgs = @( $username, $company, $CPMInstallDirectory, "", "", "", "deploy")
			$result = Invoke-CASetupFile $issFilePath $setupPath $Args $silentLog $additionalArgs
		}
		catch{
			Add-CALogErrorDetails $_.Exception
			Add-CALogAll "Failed installing CPM" "Error"
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