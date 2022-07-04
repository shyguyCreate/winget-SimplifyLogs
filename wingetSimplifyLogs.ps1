#----------------------------------------------------------
#
#     Author of the script: shyguyCreate
#                Github.com/shyguyCreate
#
#----------------------------------------------------------


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

function Get-IndexOfString ([array] $logArray, [string] $logMatch, $startIndex = 0)
{
    #Foreach line inside the array.
    for ($i = $startIndex; $i -lt $logArray.Length; $i++) {
        #Check for matches with parameter string.
        if ($logArray[$i] -match $logMatch) {
            #When it tests true, the index will be return and the for loop will be escaped.
            $indexReturn = $i;
            break;
        }
    } return $indexReturn;
}

function Get-FileListVerbose ([string] $logPathParam, [string] $logMatch)
{
    [string] $logFileVerbose = $null;

    #Gets all the file names inside the logPathParam, files are sorted by CreationTime from bigger to smaller dates.
    [array] $logFiles = Get-Item $logPathParam | Where-Object CreationTime -ge (Get-Date).Date |
                        Sort-Object CreationTime -Descending | Select-Object -ExpandProperty FullName;
    
    if ($null -ne $logFiles) {
        #Foreach file that exists.
        foreach ($file in $logFiles)
        {
            #Get the first 9 lines of each.
            $contentForEach = Get-Content $file -TotalCount 5;

            #Check for the indexLine that containd the string parameter.
            $indexLineOfMatch = Get-IndexOfString $contentForEach -logMatch $logMatch;

            #If indexLine is not empty, the file is return and the loop is escaped.
            if ($null -ne $indexLineOfMatch) {
                $logFileVerbose = $file;
                break;
            }
        }
    }
    #If there is no file inside $logFiles or $logFileVerbose, winget command will be executted.
    if ([string]::IsNullOrEmpty($logFileVerbose)) 
    {
        winget list -s winget --verbose-logs > $null;
        #After execution, the new file is obtain by CreationTime with the biggest date and stored for return.
        $logFileVerbose = Get-Item $logPathParam | Sort-Object CreationTime | Select-Object -ExpandProperty FullName -Last 1;
    }
    return $logFileVerbose;
}

#ONLY for debug
function Debug-NumberOfMatches ([array] $logArray)
{
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

    #Here the matches will be count.
    for ($i = 0; $i -lt $logArray.Length; $i++) 
    {
        #First part
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
        
        #Second part
        if ($logArray[$i] -cmatch '^\d+ =>') {  $_arrow_++; continue; }        
        if ($logArray[$i] -cmatch '^SELECT \[.+WHERE (\[\w+\]) ') {  $SELECT_WHERE++; continue; }
        if ($logArray[$i] -match '^INSERT') {  $INSERT++; continue; }
        if ($logArray[$i].StartsWith('SELECT COUNT')) {  $SELECT_COUNT++; continue; }
        if ($logArray[$i] -cmatch '^SELECT \[.+WHERE (\[\w+\])\.') {  $SELECT_WHERE_++; continue; }        
        if ($logArray[$i].StartsWith('UPDATE')) {  $UPDATE++; continue; }
        if ($logArray[$i].StartsWith('DELETE')) {  $DELETE++; continue; }        
        if ($logArray[$i].EndsWith('ORDER BY [t].[sort]')) {  $ORDER_BY++; continue; }        
        if ($logArray[$i].StartsWith('select [value]')) {  $select_value++; continue; }
    }

    Write-Output "
    `r`$Stepping_statement: $Stepping_statement
    `r`$Statement_has_completed: $Statement_has_completed
    `r`$Statement_has_data: $Statement_has_data
    `r`$_savepoint: $_savepoint
    `r`$SAVEPOINT: $SAVEPOINT
    `r`$ROLLBACK: $ROLLBACK
    `r`$RELEASE: $RELEASE
    `r`$_TABLE: $_TABLE
    `r`$Reset_statement: $Reset_statement
    `r`$_INDEX: $_INDEX
    `r`$Setting_action: $Setting_action

    `r`$_arrow_: $_arrow_
    `r`$SELECT_WHERE: $SELECT_WHERE
    `r`$INSERT: $INSERT
    `r`$SELECT_COUNT: $SELECT_COUNT
    `r`$SELECT_WHERE_: $SELECT_WHERE_
    `r`$UPDATE: $UPDATE
    `r`$DELETE: $DELETE
    `r`$ORDER_BY: $ORDER_BY
    `r`$select_value: $select_value
    "
}


function Format-Log ([array] $logArray)
{
    [array] $logArrayReturn = @();

    #Foreach line inside the array.
    for ($i = 0; $i -lt $logArray.Length; $i++) 
    {
        #Here a lot of extra stuff that doesn't help to understand what is happening (in my consideration)
        #will be left outside of the final file.
        if ($logArray[$i] -match '^Stepping statement #\d+$') { continue; }
        if ($logArray[$i] -match '^Statement #\d+ has completed$') { continue; }
        if ($logArray[$i] -match '^Statement #\d+ has data$') { continue; }
        if ($logArray[$i] -match '^(\w+ )+savepoint:') { continue; }
        if ($logArray[$i].StartsWith('SAVEPOINT')) { continue; }
        if ($logArray[$i].StartsWith('ROLLBACK')) { continue; }
        if ($logArray[$i].StartsWith('RELEASE')) { continue; }
        if ($logArray[$i] -cmatch '^(\w+ )+TABLE') { continue; }
        if ($logArray[$i] -match '^Reset statement #\d+$') { continue; }
        if ($logArray[$i] -cmatch '^(\w+ )+INDEX') { continue; }
        if ($logArray[$i].StartsWith('Setting action:')) { continue; }
        
        #Here is the fun part where a lot of data will not get to the final file, some will be joined with another line
        #to generate less lines overall and some will be replaced by shorted version from their original lines.
        #Comment lines at your consideration.
        if ($logArray[$i] -cmatch '^\d+ =>') { 
            continue; }        
        if ($logArray[$i] -cmatch '^SELECT \[.+WHERE (\[\w+\]) ') {
            $logArrayReturn += $logArray[$i] -replace '^SELECT.+WHERE (\[\w+\]).+',"`$1 $($logArray[($i+1)] -replace '^\d+ =>','=')";
            continue; }
        if ($logArray[$i] -match '^INSERT') { 
            continue; }
        if ($logArray[$i].StartsWith('SELECT COUNT')) { 
            continue; }
        if ($logArray[$i] -cmatch '^SELECT \[.+WHERE (\[\w+\])\.') { 
            continue; }        
        if ($logArray[$i].StartsWith('UPDATE')) {
            $logArrayReturn += $logArray[$i] -replace '^UPDATE.+SET (\[\w+\]).+',"`$1 $($logArray[($i+1)]-replace '^\d+ =>','=')" ;
            continue; }
        if ($logArray[$i].StartsWith('DELETE')) { 
            continue; }        
        if ($logArray[$i].EndsWith('ORDER BY [t].[sort]')) { 
            continue; }        
        if ($logArray[$i].StartsWith('select [value]')) { 
            continue; }

        #Every line that does not match any string will be passed as the semi-original line.
        $logArrayReturn += $logArray[$i];
        #NOTE: some lines where already passed when being replaced.
    }
    return $logArrayReturn;
}



# ============================================================================================

################################# Start Main Program #########################################


#Winget logs are stored inside this folder.
$logPath = "$env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\DiagOutputDir\WinGet*";

#Use of do..while only for error security purposes.
do{
    #This will return the file full Name inside the 'winget Logs folder' that matches the logMatch parameter.
    [string] $logFile = Get-FileListVerbose -logPathParam $logPath `
            -logMatch 'Command line Args:.+list\s+((-s|--source)\s+\w+\s+)?--verbose-logs$';

} while ($logFile -eq '')

#This will get all the log lines and will delete extra information established inside the function.
[array] $logContent = Get-LogContent-And-Clear-ExtraInfo -Path $logFile;

#Uncomment this line for counting the number of matches produced.
# Debug-NumberOfMatches -logArray $logContent

#Here many of the lines will be removed or change to make the log file more understandable.
$logContent = Format-Log $logContent;

#New file for the new log with less and more clear content.
$newLogFile = "$env:USERPROFILE\Desktop\winget log.txt";

#The file is created or overwritten with the new content from the logContent variable.
Set-Content $newLogFile -Value $logContent;

Write-Host "`nOpening new formatted log .txt file."
#Opens the file.
Invoke-Item $newLogFile;


#END of the script