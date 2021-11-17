# Fusible Plug - Version 2.0.1r - 3/20/2013 
# Created by: ChuckstaBurnt
#
# You use this at your own risk. I provide this with
# absolutely no warranty neither expressed nor implied.
# You are free to re-distribute and modify, so long as
# this license and created by header is intact. Thanks.
#
#
# This script handles checking to see if srcds.exe
# is running, starts it if not, and checks to see if 
# game files are out of date by reading the log file
# for a request to update from Valve. After updating,
# srcds.exe is restarted. Use task scheduler to run
# This script at an interval you define. 
#
# Recommended: 10 minutes.
#
# ------------------------------------------------
# Begin user-defined directories and variables
# This directory is where HldsUpdateTool.exe & .\orangebox are located.
$BaseDirectory = 'C:\GameBox'
# This is the directory where FusiblePlug will dump logs. If you do not wish to use logging, replace this value with '0'
$FusiblePlugLogDirectory = 'C:\fplog'
$GameName = 'tf'
$HostPort = 27015
$MaxPlayers = 24
$MapName = 'cp_dustbowl'
# Options here are: 0 or 1. 0 = Always start with map defined above. 1 = Random map on start. See PickMapStartServer below.
$FlagOnStartRandomMap = 1
$FlagEnableRunLogging = 1
# End user-defined directories and variables
# ------------------------------------------------
# Begin hardcoded variables
$RunTime = get-date
# End hardcoded variables
#
#
# Begin directory preassembly.
$LogDirectory = $BaseDirectory+'\orangebox\'+$GameName+'\console.log'
$UpdateDirectory = $BaseDirectory+'\HldsUpdateTool.exe'
$GameDirectory = $BaseDirectory+'\orangebox\srcds.exe'
# End directory preassembly.
#
#
# Start FusiblePlug logging function
Function FusibleLog {
if ($FusiblePlugLogDirectory -eq 0) {
    write-host 'Logging disabled.'
} 
elseif ($FlagEnableRunlogging -eq 0) {
    write-host 'Logging disabled.'
}
else {
    $DoesLogPathExist = test-path $FusiblePlugLogDirectory
    if ($DoesLogPathExist -eq $False) {
        write-host 'Log path does not exist!'
        sleep(10)
        exit
    } elseif ($DoesLogPathExist -eq $True) {
        $FullFusiblePlugDirectory = $FusiblePlugLogDirectory+'\fplog.log'
        $DoesLogFileExist = test-path $FullFusiblePlugDirectory
    }
        if ($DoesLogFileExist -eq $True) {
            write-host 'Log file found. Logging to' $FullFusiblePlugDirectory
        } else {
            new-item $FullFusiblePlugDirectory -type file
            add-content $FullFusiblePlugDirectory 'FusiblePlug Run/Debug Log'
        }
    Switch ($RunStatus) {
        10 {$RunLog = [string]$RunTime + ' srcds.exe running, no updates required.'}
        20 {$RunLog = [string]$RunTime + ' Server content updated.'}
        21 {$RunLog = [string]$RunTime + ' No console log file found.'}
        30 {$RunLog = [string]$RunTime + ' srcds.exe was not running, starting with map ' + $MapName + '.'}
        default {$RunLog = [string]$RunTime + ' Something happened, but I am not sure what.'}
    }
    add-content $FullFusiblePlugDirectory $RunLog
    }
if ($RunStatus -eq 20) {
    PickMapStartServer
} else {
sleep(10)
exit
}
}
# Stop FusiblePlug logger function
#
#
# Start map randomizer (if flagged) and server starter function.
Function PickMapStartServer {
if ($FlagOnStartRandomMap -eq 1) {
    write-host 'Randomizing start map.'
    $RandomNumber = get-random -minimum 1 -maximum 7
    # These maps can be changed as can the number of options. Make sure that the maximum flag is equal to the number of maps you want on random + 1.
    Switch ($RandomNumber) {
        1 {$MapName = 'cp_dustbowl'}
        2 {$MapName = 'cp_fastlane'}
        3 {$MapName = 'pl_goldrush'}
        4 {$MapName = 'koth_harvest_final'}
        5 {$MapName = 'ctf_turbine'}
        6 {$MapName = 'ctf_2fort'}
}
}
write-host 'Starting server with' $MapName
$StartServer = $GameDirectory + " -console -condebug -game " + $GameName + " -port " + $HostPort + " +maxplayers " + $MaxPlayers + " +map " + $MapName
Invoke-Expression $StartServer
$RunStatus = 30
FusibleLog
}
# End map randomizer (if flagged) and server starter function.
#
#
# Begin up/down check.
write-host '1. Ensure game server is running.'
write-host 'Getting status of srcds.exe...'
$AppStatus = (get-process -processname 'srcds') | Write-Output
if ($AppStatus -eq $Null) {
    write-host 'srcds.exe does not appear to be running. Attempting start.'
    PickMapStartServer
} else {
    write-host 'srcds.exe appears to be running.'
}
# End up/down check.
#
#
# Begin log file check.
write-host ' '
write-host '2. Looking for console log files.'
$PathPresent = test-path $LogDirectory
if ($PathPresent -eq $False) {
    write-host 'Unable to find a log file! Ensure that logging is enabled in server.cfg and log directory is correct.'
    $RunStatus = 21
    FusibleLog
} else {
    $LogDirectory
    write-host 'Log file found: '$LogDirectory
}
# End log file check.
#
#
# Begin update check.
write-host ' '
write-host '3. Checking log file for an update command.'
$UpdateTrigger = (get-content $LogDirectory | select-string "Please update" -Quiet)
if ($UpdateTrigger -ne $True) {
    write-host 'No updates needed.'
    $RunStatus = 10
    FusibleLog
} else {
    write-host 'Starting update...'
    stop-process -processname 'srcds'
    sleep(2)
    $UpdateServer = $UpdateDirectory + " -command update -game " + $GameName + " -dir " + $BaseDirectory
    Invoke-Expression $UpdateServer
    sleep(2)
    write-host 'Deleting console.log'
    remove-item $LogDirectory
    sleep(2)
    write-host 'Updating complete. Restarting server.'
    write-host ' '
    $RunStatus = 20
    FusibleLog
}
# End update check.