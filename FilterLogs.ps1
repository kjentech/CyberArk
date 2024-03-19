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

    if ($LogPath -match "pm") {

        

        $Regex = [regex]::match($_, "(?<date>\d{2}\/\d{2}\/\d{4})\s(?<time>\d{2}:\d{2}:\d{2}) \[(?<id>\w+)\]\s(?<code>\w+)\s(?<rawmessage>.*(?<shortmessage>Code: \d+.+))")
        $ht = @{
            Date       = $Regex.Groups["date"].Value
            Time       = $Regex.Groups["time"].Value
            ActionId   = $Regex.Groups["id"].Value
            ErrorCode  = $Regex.Groups["code"].Value
            RawMessage = $Regex.Groups["rawmessage"].Value
            Message    = $Regex.Groups["shortmessage"].Value
        }

    }

}
if ($LogPath -match "italog") {
    $Regex = [regex]::match($_, "^(?<date>\d{2}\/\d{2}\/\d{4})\s(?<time>\d{2}:\d{2}:\d{2})\s(?<code>\w+\d[IWE])\s(?<rawmessage>.*)")
}







$Log -notmatch $Filter | ForEach-Object { 
        











    # if ($LogPath -match "pm") { 
    #     $RawMessage = $_.Substring(37) 

    #     # We try to make a pretty message for the lines with an action code
    #     $null = $RawMessage -match "Code: (\d+)(.*)" 
    #     $Message = $Matches[0] 

    #     [PSCustomObject]@{ 
    #         Message    = $Message 
    #         Date       = $_.Substring(0, 10) 
    #         Time       = $_.Substring(11, 8) 
    #         ActionId   = $_.Substring(21, 4) 
    #         ErrorCode  = $_.Substring(27, 10) 
    #         RawMessage = $RawMessage 
    #     }
    # }

    # if ($LogPath -match "italog") { 
    #     $RawMessage = $_.Substring(30) 
    #     [PSCustomObject]@{ 
    #         Date       = $_.Substring(0, 10) 
    #         Time       = $_.Substring(11, 8) 
    #         ErrorCode  = $_.Substring(19, 11) 
    #         RawMessage = $RawMessage 
    #     }
    # }
}
}

$ITALog = "C:\Logs\italog.log"
$Filter = "ITATS528E|ITATS319W|ITATS532E|-77|ITATS966E" 
FilterLogs -LogPath $ITALog -Filter $Filter | Out-GridView -Wait -Title $env:COMPUTERNAME 
     