$dirPath = ""
$endDate = Get-Date -Date (Split-Path $dirPath -Leaf)
$last14Days = 0..14 | foreach { Get-Date ((get-date $enddate).AddDays(-$_)) -Format "dd-MM-yyyy"}
#$startDate = $endDate.AddDays(-7)
#$lastWeek = New-TimeSpan -Start ($endDate).AddDays(-7) -End $endDate

#dir $dirPath | foreach { copy-item -Path $dirpath\$_ -Destination "$dirpath\$($_.basename)-trimmed$($_.Extension)" }



$ItaLogPattern = @(
    '(?<Date>\d\d/\d\d/\d\d\d\d)'
    '(?<Time>(?:[0-1]?[0-9]|[2][0-3]):(?:[0-5][0-9])(?::[0-5][0-9])?)'
    '(?<Code>[\w\d]+)'
    '(?<Description>.+)'
) -join '\s+'





$trimmedFiles = dir "$dirPath\*"
foreach ($file in $trimmedFiles) {
    Write-Output "Processing file $file"
    $Content = Get-Content $file -Tail 10000
    #$Content = [system.io.file]::readalllines($file.FullName)




    if ($file.basename -like "*italog*") {
        $Content = $Content | where  {$_ -notmatch "ITATS319W|Authentication failure for user (extdub|kons)"}


        #make nice object
        $ContentObject = foreach ($line in $Content) {
            $null = $line -match $ItaLogPattern
            [PSCustomObject]$matches | select Date, Time, Code, Description
        }
        $ContentObject = $ContentObject | where { (get-date -date $_.Date) -gt (get-date).AddDays(-14) }
        $ContentObject | ogv

        #$ITALOG = $ContentObject | where {
            #$_.Code -ne "ITATS319W" -and
            #$_.Description -notmatch "Authentication failure for user (extdub|kons)"
        #}
        #$ITALOG | ogv
        #$ITALOG | Out-String | Set-Content $file
    }#if italog
    if ($file.basename -like "*PADR*") {
        [array]::reverse($Content)
        $Content |ogv

        #$PADR = $ContentObject | where {
        #$_.Code -notcontains "PAREP024I" -and
        #$_.Code -notcontains "PAREP013I"
        #}
        #$PADR
        #$PADR | Set-Content $file
    }#if PADR
    if ($file.basename -like "*PAReplicate*") {
        Write-Output "We have no checks for PAReplicate"
    }#if PAReplicate
    
}
