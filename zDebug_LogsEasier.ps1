#----------------------------------------------------------
#
#     Author of the script: shyguyCreate
#                Github.com/shyguyCreate
#
#----------------------------------------------------------

#THIS SCRIPT IS JUST TO COUNT THE NUMBER OF MATCHES THAT THE MAIN SCRIPT WILL MAKE IN THE RUN.
#IT IS SUPPOSED TO JUST BE USED FOR DEBUGGUING THE MATCHES AND NO MORE.

#################### Fuctions ############################

function Get-LogContent-And-Clear-ExtraInfo ([string] $Path)
{
    #Get log lines only if it starts with a 4 digit number.
    [array] $logArray = Get-Content $logFile | Where-Object {$_ -match '^\d{4}'};

    #Gets the index of 'WinGet' to later delete all chars before that index.
    $extraInfoIndex = $logArray[0].IndexOf('WinGet');

    #Foreach line inside the array.
    for ($i = 0; $i -lt $logArray.Length; $i++) 
    {
        #Replaces every char before the 'WinGet' index with nothing.
        #Also, it tests if any words followed by a hashtag (#) symbol and numbers exists,
        #if it does, they are also erased.
        $logArray[$i] = $logArray[$i] -replace "^.{$extraInfoIndex}((\w+ )+#\d+: )?",'';
    }
    #Funtion return the array only with the lines that are not empty.
    return $logArray | Where-Object {$_ -ne ''};
}

function Get-IndexOfString ([array] $logArray, [string] $logString, $startIndex = 0)
{
    #Foreach line inside the array.
    for ($i = $startIndex; $i -lt $logArray.Length; $i++) {
        #Check for matches with parameter string.
        if ($logArray[$i] -match $logString) {
            #When it tests true, the index will be return and the for loop will be escaped.
            $indexReturn = $i;
            break;
        }
    } return $indexReturn;
}

function Get-FileListVerbose ([string] $logPathParam, [string] $logString, [string] $logMatch)
{
    [string] $logFileVerbose = $null;

    #Gets all the file names inside the logPathParam, files are sorted by LastWriteTime from bigger to smaller dates.
    [array] $logFiles = Get-Item $logPathParam | Sort-Object LastWriteTime -Descending | Select-Object -ExpandProperty FullName;
    
    #If there is no file, winget command is executted.
    if ($null -eq $logFiles) { 
        winget list -s winget --verbose-logs > $null; 
        #After execution the new file is stored for return.
        $logFileVerbose = Get-Item $logPath | Select-Object -ExpandProperty FullName;
    } else {            
        #Foreach file that exists.
        foreach ($file in $logFiles) {
            #Get the first 9 lines of each.
            $contentForEach = Get-Content $file -TotalCount 9;
            #Check for the indexLine that containd the string parameter.
            $indexForEach = Get-IndexOfString $contentForEach -logString $logString;
            #If nothing exists, it passes to the next item to avoid errors.
            if ($null -eq $indexForEach) { continue; }
            
            #Check if the indexLine contains another string parameter.
            [bool] $isListVerbose = $contentForEach[$indexForEach] -match $logMatch;

            #If match is true, the file is passed for return, and the for loop is escaped.
            if ($isListVerbose) { 
                $logFileVerbose = $file;
                break; 
            }
        }
        #After paasing through each file, if none of them matches then winget command is executed.
        if (-not $isListVerbose) {
            winget list -s winget --verbose-logs > $null;
            #The new file is created, and it is obtain by LastWriteTime with the biggest date.
            $logFileVerbose = Get-Item $logPathParam | Sort-Object LastWriteTime | Select-Object -ExpandProperty FullName -Last 1;
        }
    }
    return $logFileVerbose;
}

function Measure-Matches ([array] $logArray)
{
    for ($i = 0; $i -lt $logArray.Length; $i++) 
    {
        if ($logArray[$i] -match '^Stepping statement #\d+$') {  $Stepping_statement++;  continue; }
        if ($logArray[$i] -match '^Statement #\d+ has completed$') {  $Statement_has_completed++;  continue; }
        if ($logArray[$i] -match '^Statement #\d+ has data$') {  $Statement_has_data++;  continue; }
        if ($logArray[$i] -match '^(\w+ )+savepoint:') {  $_savepoint++;  continue; }
        if ($logArray[$i].StartsWith('SAVEPOINT')) {  $SAVEPOINT++;  continue; }
        if ($logArray[$i].StartsWith('ROLLBACK')) {  $ROLLBACK++;  continue; }
        if ($logArray[$i].StartsWith('RELEASE')) {  $RELEASE++;  continue; }
        if ($logArray[$i] -cmatch '^(\w+ )+TABLE') {  $_TABLE++;  continue; }
        if ($logArray[$i] -match '^Reset statement #\d+$') {  $Reset_statement++;  continue; }
        if ($logArray[$i] -cmatch '^(\w+ )+INDEX') {  $_INDEX++;  continue; }
        if ($logArray[$i].StartsWith('Setting action:')) {  $Setting_action++;  continue; }
        

        if ($logArray[$i] -cmatch '^\d+ =>') {  $_arrow_++; continue; }        
        if ($logArray[$i] -cmatch '^SELECT \[.+WHERE (\[\w+\]) ') {  $SELECT_WHERE++; continue; }
        if ($logArray[$i] -match '^INSERT') {  $INSERT++; continue; }
        if ($logArray[$i] -cmatch '^SELECT \[.+WHERE (\[\w+\])\.') {  $SELECT_WHERE_++; continue; }        
        if ($logArray[$i].StartsWith('SELECT COUNT')) {  $SELECT_COUNT++; continue; }
        if ($logArray[$i].StartsWith('UPDATE')) {  $UPDATE++; continue; }
        if ($logArray[$i].StartsWith('DELETE')) {  $DELETE++; continue; }        
        if ($logArray[$i].EndsWith('ORDER BY [t].[sort]')) {  $ORDER_BY++; continue; }        
        if ($logArray[$i].StartsWith('select [value]')) {  $select_value++; continue; }
    }
}



# ============================================================================================

################################# Start Main Program #########################################

#Debug variables
$Stepping_statement = 0;        $_arrow_ = 0
$Statement_has_completed = 0;   $SELECT_WHERE = 0
$Statement_has_data = 0;        $INSERT = 0
$_savepoint = 0;                $SELECT_WHERE_ = 0
$SAVEPOINT = 0;                 $SELECT_COUNT = 0
$ROLLBACK = 0;                  $UPDATE = 0
$RELEASE = 0;                   $DELETE = 0
$_TABLE = 0;                    $ORDER_BY = 0
$Reset_statement = 0;           $select_value = 0
$_INDEX = 0;
$Setting_action = 0;


#Winget logs are stored inside this folder.
$logPath = "$env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\DiagOutputDir\WinGet*";

#Use of do..while only for error security purposes.
do{
    #This will return the file full Name inside the 'winget Logs folder'
    #that matches the logMatch parameter inside the logString matched line.
    [string] $logFile = Get-FileListVerbose -logPathParam $logPath `
            -logString 'Command line Args:' -logMatch 'list\s+(-s\s+\w+\s+)?--verbose-logs$';

} while ($logFile -eq '')

#This will get all the log lines and will delete extra information established inside the function.
[array] $logContent = Get-LogContent-And-Clear-ExtraInfo -Path $logFile;

#Here many of the lines will be removed or change to make the log file more understandable.
Measure-Matches $logContent;

Write-Output"
`$Stepping_statement: $Stepping_statement
`$Statement_has_completed: $Statement_has_completed
`$Statement_has_data: $Statement_has_data
`$_savepoint: $_savepoint
`$SAVEPOINT: $SAVEPOINT
`$ROLLBACK: $ROLLBACK
`$RELEASE: $RELEASE
`$_TABLE: $_TABLE
`$Reset_statement: $Reset_statement
`$_INDEX: $_INDEX
`$Setting_action: $Setting_action

`$_arrow_: $_arrow_
`$SELECT_WHERE: $SELECT_WHERE
`$INSERT: $INSERT
`$SELECT_WHERE_: $SELECT_WHERE_
`$SELECT_COUNT: $SELECT_COUNT
`$UPDATE: $UPDATE
`$DELETE: $DELETE
`$ORDER_BY: $ORDER_BY
`$select_value: $select_value
"


#END of the script