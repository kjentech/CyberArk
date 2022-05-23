<#
.SYNOPSIS
    Small function to filter pm.log, pm_error.log and italog.log.
.DESCRIPTION
    This function is used to filter pm.log, pm_error.log and italog.log and output objects to the pipeline.
    Filter is a regular expression.
.EXAMPLE
    FilterLogs -LogPath "C:\Logs\italog.log" -Filter "ITATS528E|ITATS319W"
.EXAMPLE
    FilterLogs -LogPath "C:\Logs\pm_error.log" -Filter "CACPM708W"
.EXAMPLE
    $ITALog = "C:\Logs\italog.log"
    $Filter = "ITATS528E|ITATS319W" 
    FilterLogs -LogPath $ITALog -Filter $Filter
#>


function FilterLogs { 
    param ( 
        [string]$Filter, 
        $LogPath 
    )
    $Log = Get-Content $LogPath 
    $Log -notmatch $Filter | ForEach-Object { 
        if ($LogPath -match "pm") { 
            $RawMessage = $_.Substring(37) 

            # We try to make a pretty message for the lines with an action code
            $null = $RawMessage -match "Code: (\d+)(.*)" 
            $Message = $Matches[0] 

            [PSCustomObject]@{ 
                Message    = $Message 
                Date       = $_.Substring(0, 10) 
                Time       = $_.Substring(11, 8) 
                ActionId   = $_.Substring(21, 4) 
                ErrorCode  = $_.Substring(27, 10) 
                RawMessage = $RawMessage 
            }
        }

        if ($LogPath -match "italog") { 
            $RawMessage = $_.Substring(30) 
            [PSCustomObject]@{ 
                Date       = $_.Substring(0, 10) 
                Time       = $_.Substring(11, 8) 
                ErrorCode  = $_.Substring(19, 11) 
                RawMessage = $RawMessage 
            }
        }
    }
}

$ITALog = "C:\Logs\italog.log"
$Filter = "ITATS528E|ITATS319W|-77" 
FilterLogs -LogPath $ITALog -Filter $Filter | Out-GridView -Wait -Title $env:COMPUTERNAME 
     