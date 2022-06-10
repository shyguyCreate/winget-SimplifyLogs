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
        if ($logArray[$i] -cmatch '^SELECT \[.+WHERE (\[\w+\])\.') { 
            continue; }        
        if ($logArray[$i].StartsWith('SELECT COUNT')) { 
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
        #NOTE: some line where already passed when being replaced.
    }
    return $logArrayReturn;
}



# ============================================================================================

################################# Start Main Program #########################################	


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
$logContent = Format-Log $logContent;

#New file for the new log with less and more clear content.
$newLogFile = "$env:USERPROFILE\Desktop\winget log.txt";

#The file is created or overwritten with the new content from the logContent variable.
Set-Content $newLogFile -Value $logContent;

Write-Host "`nOpening new formatted log .txt file."
#Opens the file.
Invoke-Item $newLogFile;


#END of the script