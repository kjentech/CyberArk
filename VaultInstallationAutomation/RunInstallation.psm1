# @FUNCTION@ ======================================================================================================================
# Name...........: Execute
# Description....: Installing Vault application
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
		Add-CALogAll "Start Vault installation"
		Add-CALogAll "Args: $Args"
		$ScriptRoot = (Get-Location).Path		
		$setupPath = "$ScriptRoot\..\setup.exe"
		$silentLog = "$ScriptRoot\vault_silent.log"

		
		
		#define variables $Username, $Company, $VaultDestination, $SafesDestination, $LicensePath, $OperatorCDPath, $InstallRabbitMQ, $PerformHardening, $MasterPass, $AdminPass, $isUpgrade
		$Args | foreach {New-Variable -Name $_.Name -Value $_.Value}

		if ($isUpgrade -eq "true")
        {
            $issFilePath = "$ScriptRoot\vault12-0_upgrade.iss"
			Add-CALogAll "installation is running in upgrade mode"
        }
        else
        {	
			Copy-Item -Path "$ScriptRoot\vault12-0_template.iss" -Destination "$ScriptRoot\vault12-0.iss"
            $issFilePath = "$ScriptRoot\vault12-0.iss"
			Add-CALogAll "installation is running in install mode"
			Add-CALogAll "issfilepath = $issFilePath"
			Add-CALogAll "setuppath = $setupPath"
			Add-CALogAll "args = $Args"
			Add-CALogAll "silentlog = $silentLog"
			Add-CALogAll "additionalargs = $additionalArgs"
        }		
		
		try {
			
			
			# Replace placeholders with values from the configuration xml file
			#$additionalArgs = @( )	
			#$result = Invoke-CASetupFile $issFilePath $setupPath $Args $silentLog $additionalArgs
		}
		catch{
			Add-CALogErrorDetails $_.Exception
			Add-CALogAll "Failed installing Vault" "Error"
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