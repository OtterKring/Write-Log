#region Write-Log

<#
.SYNOPSIS
Makes writing beautiful readable logs easy

.PARAMETER FileName
Full path (!) and name of the Logfile.
MANDATORY

.PARAMETER Message
The information to log. Can be omitted for Process STATUS and LINE.

.PARAMETER Process
A tag to describe the nature of the logged event. Allowed values are:
'START','EXECUTE','FINISH','INFO','ERROR','WARNING','STATUS','LINE'

STATUS displays a status bar showing the percentage of progress if parameters StatusNow and StatusFull are set.
Ignores parameter Message.
LINE displays a vertical line to separate distinctive parts in the log.
Ignores parameter Message.

MANDATORY

.PARAMETER StatusNow
int32 value to show the current percentage on the status bar (Process STATUS).
Does not have any effect if Process -ne STATUS.

.PARAMETER StutusFull
int32 value depicting the maximum value the status bar may count to (Process STATUS).
Does not have any effect if Process -ne STATUS

.NOTES
by Maximilian Otter, Oct 2019
#>
function Write-Log {
    param (
        [Parameter(Mandatory)]
        [ValidatePattern('^[a-zA-Z]\:\\|^\\\\\w+')]
        [string]$FileName,
        [Parameter(ValueFromPipeline)]
        [string]$Message,
        [Parameter(Mandatory)]
        [ValidateSet('START','EXECUTE','FINISH','INFO','ERROR','WARNING','STATUS','LINE')]
        [string]$Process,
        [int32]$StatusNow,
        [int32]$StatusFull,
        [ValidateSet('BASIC','FULL','DEBUG')]
        [string]$LogLevel                               # not yet impemented
    )

    if ($Message -or $Process -in @('STATUS','LINE')) {

        #$LogPrefix = "$(Get-Date -Format 'yyyyMMddHHmmssfff')"
        $LogPrefix = [datetime]::Now.ToString('yyyyMMddHHmmssfff')
        $LogProcess = $Process + ' ' * (7-$Process.Length)   

        if (-not($Message)) {

            if ($Process -eq 'STATUS' -and $StatusNow -and $StatusFull -and $StatusNow -le $StatusFull) {
                $Percent = [int32][math]::Round(($StatusNow * 100) / $StatusFull, 0, 1)
                $Output = $LogPrefix + ' | ' + $LogProcess + ' | ' + ('O' * $Percent) + ('-' * (100 - $Percent)) + ' | ' + $Percent + '%'
            } elseif ($Process -eq 'LINE') {
                $Output = '-' * 140
            } else {
                $Output = $LogPrefix + ' | ' + $LogProcess + ' | ' + ('-' * 40) + ' NO STATUS AVAILABLE ' + ('-' * 39) + ' |'
            }

        } else {
            $Output = $LogPrefix + ' | ' + $LogProcess + ' | ' + $Message
        }

        [System.IO.File]::AppendAllLines([string]$FileName,[string[]]$Output)
        
    } else {
        Write-Error "LINE $($MyInvocation.ScriptLineNumber) : Parameter -Message is required if -Process -ne `"STATUS`" -or `"LINE`""
    }

}

#endregion Write-Log

#region Clear-LogHistory

<#
.SYNOPSIS
    Clears the give log to keep only the specified timespan (from now backwards)
.PARAMETER FileName
    The FULL path and filename (local or UNC) of the log file to clear
    MANDATORY
.PARAMETER KeepTimespan
    The timespan which should not be deleted. Must be of type [timespan].
    DEFAULT = 30 days
.EXAMPLE
    Clear-LogHistory -FileName 'C:\temp\mylog.txt' -KeepTimespan ([timespan]::FromDays(10))

    Deletes everything older than 10 days from the log.
.INPUTS
    Text file use for logging. Must have been created with Write-Log from this module
    or use the same date format (yyyyMMddHHmmss) at the beginning of the lines,
    otherwise Clear-LogHistory will not work correctly
.OUTPUTS
    Overwrites the input file in UTF8 encoding
.NOTES
    by Maximilian Otter, Oct 2019
#>
function Clear-LogHistory {
    param (
        [Parameter(Mandatory)]
        [ValidatePattern('^[a-zA-Z]\:\\|^\\\\\w+')]
        [string]$FileName,
        [timespan]$KeepTimespan = [timespan]::FromDays(30)
    )

    $KeepFrom = (([datetime]::Now) - $KeepTimespan).ToString('yyyyMMddHHmmssfff')

    $buffer = [System.IO.File]::ReadAllLines($FileName)
    $buffer = $buffer.Where({$_.substring(0,1) -match '^\d' -and $_.substring(0,17) -ge $KeepFrom},'SkipUntil')
    [System.IO.File]::WriteAllLines($FileName,$buffer)

}

#endregion Clear-LogHistory