#!/bin/zsh --no-rcs
label="" # if no label is sent to the script, this will be used

# Installomator
#
# Downloads and installs Applications
# 2020-2026 Installomator
#
# inspired by the download scripts from William Smith and Sander Schram
#
# Dev Team:
#    Armin Briegel - @scriptingosx
#    Isaac Ordonez - @issacatmann
#    Søren Theilgaard - @Theile
#    Adam Codega - @acodega
#    Trevor Sysock - @BigMacAdmin
#
# Maintainers:
#    Gil Burns - @gilburns
#    Richard Glaser - @uurazzle
#
# with contributions from many others

export PATH=/usr/bin:/bin:/usr/sbin:/sbin

# NOTE: adjust these variables:

# set to 0 for production, 1 or 2 for debugging
# while debugging, items will be downloaded to the parent directory of this script
# also no actual installation will be performed
# debug mode 1 will download to the directory the script is run in, but will not check the version
# debug mode 2 will download to the temp directory, check for blocking processes, check the version, but will not install anything or remove the current version
DEBUG=1

# notify behavior
NOTIFY=success
# options:
#   - success      notify the user on success
#   - silent       no notifications
#   - all          all notifications (great for Self Service installation)

# time in seconds to wait for a prompt to be answered before exiting the script
PROMPT_TIMEOUT=86400
# Common times translated into seconds
# 60    =  1 minute
# 300   =  5 minutes
# 600   = 10 minutes
# 3600  =  1 hour
# 86400 = 24 hours (default)

# behavior when blocking processes are found
# BLOCKING_PROCESS_ACTION is ignored if app label uses updateTool
BLOCKING_PROCESS_ACTION=tell_user
# options:
#   - ignore       continue even when blocking processes are found
#   - quit         app will be told to quit nicely if running
#   - quit_kill    told to quit twice, then it will be killed
#                  Could be great for service apps if they do not respawn
#   - silent_fail  exit script without prompt or installation
#   - prompt_user  show a user dialog for each blocking process found,
#                  user can choose "Quit and Update" or "Not Now".
#                  When "Quit and Update" is chosen, blocking process
#                  will be told to quit. Installomator will wait 30 seconds
#                  before checking again in case Save dialogs etc are being responded to.
#                  Installomator will abort if quitting after three tries does not succeed.
#                  "Not Now" will exit Installomator.
#   - prompt_user_then_kill
#                  show a user dialog for each blocking process found,
#                  user can choose "Quit and Update" or "Not Now".
#                  When "Quit and Update" is chosen, blocking process
#                  will be terminated. Installomator will abort if terminating
#                  after two tries does not succeed. "Not Now" will exit Installomator.
#   - prompt_user_loop
#                  Like prompt-user, but clicking "Not Now", will just wait an hour,
#                  and then it will ask again.
#                  WARNING! It might block the MDM agent on the machine, as
#                  the script will not exit, it will pause until the hour has passed,
#                  possibly blocking for other management actions in this time.
#   - tell_user    User will be showed a notification about the important update,
#                  but user is only allowed to Quit and Continue, and then we
#                  ask the app to quit. This is default.
#   - tell_user_then_kill
#                  User will be showed a notification about the important update,
#                  but user is only allowed to Quit and Continue. If the quitting fails,
#                  the blocking processes will be terminated.
#   - kill         kill process without prompting or giving the user a chance to save


# logo-icon used in dialog boxes if app is blocking
LOGO=appstore
# options:
#   - appstore      Icon is Apple App Store (default)
#   - jamf          JAMF Pro
#   - mosyleb       Mosyle Business
#   - mosylem       Mosyle Manager (Education)
#   - addigy        Addigy
#   - microsoft     Microsoft Endpoint Manager (Intune)
#   - ws1           Workspace ONE (AirWatch)
#   - filewave      FileWave
#   - kandji        Kandji
# path can also be set in the command call, and if file exists, it will be used.
# Like 'LOGO="/System/Applications/App\ Store.app/Contents/Resources/AppIcon.icns"'
# (spaces have to be escaped).


# App Store apps handling
IGNORE_APP_STORE_APPS=no
# options:
#  - no            If the installed app is from App Store (which include VPP installed apps)
#                  it will not be touched, no matter its version (default)
#  - yes           Replace App Store (and VPP) version of the app and handle future
#                  updates using Installomator, even if latest version.
#                  Shouldn’t give any problems for the user in most cases.
#                  Known bad example: Slack will lose all settings.

# Owner of copied apps
SYSTEMOWNER=0
# options:
#  - 0             Current user will be owner of copied apps, just like if they
#                  installed it themselves (default).
#  - 1             root:wheel will be set on the copied app.
#                  Useful for shared machines.

# install behavior
INSTALL=""
# options:
#  -               When not set, the software will only be installed
#                  if it is newer/different in version
#  - force         Install even if it’s the same version


# Re-opening of closed app
REOPEN="yes"
# options:
#  - yes           App will be reopened if it was closed
#  - no            App not reopened

# Only let Installomator return the name of the label
# RETURN_LABEL_NAME=0
# options:
#   - 1      Installomator will return the name of the label and exit, so last line of
#            output will be that name. When Installomator is locally installed and we
#            use DEPNotify, then DEPNotify can present a more nice name to the user,
#            instead of just the label name.


# Interrupt Do Not Disturb (DND) full screen apps
INTERRUPT_DND="yes"
# options:
#  - yes           Script will run without checking for DND full screen apps.
#  - no            Script will exit when an active DND full screen app is detected.

# Comma separated list of app names to ignore when evaluating DND
IGNORE_DND_APPS=""
# example that will ignore browsers when evaluating DND:
# IGNORE_DND_APPS="firefox,Google Chrome,Safari,Microsoft Edge,Opera,Amphetamine,caffeinate"


# Use proxy for network access
PROXY=""
# Use this format for proxy: server.network.dns:port
# Configure proxy settings so that curl can work through that if needed.
# Port number is important for the check of access.
# Please note that some proxy configurations allow text download, but block binary downloads.
# So could be a situation where curl works for version, but not for download.
# This error line is then shown: “curl output was: curl: (22) The requested URL returned error: 403”


# Swift Dialog integration

# These variables will allow Installomator to communicate progress with Swift Dialog
# https://github.com/swiftDialog/swiftDialog

# This requires Swift Dialog 2.11.2 or higher.

DIALOG_CMD_FILE=""
# When this variable is set, Installomator will write Swift Dialog commands to this path.
# Installomator will not launch Swift Dialog. The process calling Installomator will have
# launch and configure Swift Dialog to listen to this file.
# See `MDM/swiftdialog_example.sh` for an example.

DIALOG_LIST_ITEM_NAME=""
# When this variable is set, progress for downloads and installs will be sent to this
# listitem.
# When the variable is unset, progress will be sent to Swift Dialog's main progress bar.

NOTIFY_DIALOG=0
# If this variable is set to 1, then we will check for installed Swift Dialog v. 2 or later, and use that for notification


# NOTE: How labels work

# Each workflow label needs to be listed in the case statement below.
# for each label these variables can be set:
#
# - name: (required)
#   Name of the installed app.
#   This is used to derive many of the other variables.
#
# - type: (required)
#   The type of the installation. Possible values:
#     - dmg
#     - pkg
#     - zip
#     - tbz
#     - pkgInDmg
#     - pkgInZip
#     - appInDmgInZip
#     - pkgInDmgInZip
#     - updateronly     This last one is for labels that should only run an updateTool (see below)
#
# - packageID: (optional)
#   The package ID of a pkg
#   If given, will be used to find the version of installed software, instead of searching for an app.
#   Usefull if a pkg does not install an app.
#   See label installomator_st
#
# - downloadURL: (required)
#   URL to download the dmg.
#   Can be generated with a series of commands (see BBEdit for an example).
#
# - curlOptions: (array, optional)
#   Options to the curl command, needed for curl to be able to download the software.
#   Usually used for adding extra headers that some servers need in order to serve the file.
#   curlOptions=( -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.1 Safari/605.1.15" )
#   (See “mocha”-labels, for examples on labels, and buildLabel.sh for header-examples.)
#
# - appNewVersion: (optional)
#   Version of the downloaded software.
#   If given, it will be compared to the installed version, to see if the download is different.
#   It does not check for newer or not, only different.
#
# - versionKey: (optional)
#   How we get version number from app. Possible values:
#     - CFBundleShortVersionString
#     - CFBundleVersion
#   Not all software titles uses fields the same.
#   See Opera label.
#
# - appCustomVersion(){}: (optional function)
#   This function can be added to your label, if a specific custom
#   mechanism hs to be used for getting the installed version.
#   See labels zulujdk11, zulujdk13, zulujdk15
#
# - expectedTeamID: (required)
#   10-digit developer team ID.
#   Obtain the team ID by running:
#
#   - Applications (in dmgs or zips)
#     spctl -a -vv /Applications/BBEdit.app
#
#   - Pkgs
#     spctl -a -vv -t install ~/Downloads/desktoppr-0.2.pkg
#
#   The team ID is the ten-digit ID at the end of the line starting with 'origin='
#
# - archiveName: (optional)
#   The name of the downloaded file.
#   When not given the archiveName is derived from the $name.
#   Note: This has to be defined BEFORE calling downloadURLFromGit or
#   versionFromGit functions in the label.
#
# - appName: (optional)
#   File name of the app bundle in the dmg to verify and copy (include .app).
#   When not given, the appName is derived from the $name.
#
# - targetDir: (optional)
#   dmg or zip:
#     Applications will be copied to this directory.
#     Default value is '/Applications' for dmg and zip installations.
#   pkg:
#     targetDir is used as the install-location. Default is '/'.
#
# - blockingProcesses: (optional)
#   Array of process names that will block the installation or update.
#   If no blockingProcesses array is given the default will be:
#     blockingProcesses=( $name )
#   When a package contains multiple applications, _all_ should be listed, e.g:
#     blockingProcesses=( "Keynote" "Pages" "Numbers" )
#   When a workflow has no blocking processes, use
#     blockingProcesses=( NONE )
#
# - pkgName: (optional, only used for pkgInDmg, dmgInZip, and appInDmgInZip)
#   File name or path to the pkg/dmg file _inside_ the dmg or zip.
#   When not given the pkgName is derived from the $name
#
# - updateTool:
# - updateToolArguments:
#   When Installomator detects an existing installation of the application,
#   and the updateTool variable is set
#       $updateTool $updateArguments
#   Will be run instead of of downloading and installing a complete new version.
#   Use this when the updateTool does differential and optimized downloads.
#   e.g. msupdate on various Microsoft labels
#
# - updateToolRunAsCurrentUser:
#   When this variable is set (any value), $updateTool will be run as the current user.
#
# - CLIInstaller:
# - CLIArguments:
#   If the downloaded dmg is an installer that we can call using CLI, we can
#   use these two variables for what to call.
#   We need to define `name` for the installed app (to be version checked), as well as
#   `installerTool` for the installer app (if named differently than `name`. Installomator
#   will add the path to the folder/disk image with the binary, and it will be called like this:
#       $CLIInstaller $CLIArguments
#   For most installations `CLIInstaller` should contain the `installerTool` for the CLI call
#   (if it’s the same).
#   We can support a whole range of other software titles by implementing this.
#   See label adobecreativeclouddesktop
#
# - installerTool:
#   Introduced as part of `CLIInstaller`. If the installer in the DMG or ZIP is named
#   differently than the installed app, then this variable can be used to name the
#   installer that should be located after mounting/expanding the downloaded archive.
#   See label adobecreativeclouddesktop
#
### Logging
# Logging behavior
LOGGING="INFO"
# options:
#   - DEBUG     Everything is logged
#   - INFO      (default) normal logging level
#   - WARN      only warning
#   - ERROR     only errors
#   - REQ       ????

# MDM profile name
MDMProfileName=""
# options:
#   - MDM Profile               Addigy has this name on the profile
#   - Mosyle Corporation MDM    Mosyle uses this name on the profile
# From the LOGO variable we can know if Addigy og Mosyle is used, so if that variable
# is either of these, and this variable is empty, then we will auto detect this.

# Datadog logging used
datadogAPI=""
# Simply add your own API key for this in order to have logs sent to Datadog
# See more here: https://www.datadoghq.com/product/log-management/

# Advanced version comparison
ADVANCED_VERSION_COMPARISON=""
# options:
#   - yes   Use more advanced version comparison.
# By default Installomator will allways attempt to update an application if the installed
# version is different from the version found online, even if the installed version is 
# higher. This option will not perform an update if the installed version is higher.
# Note: Version comparison only works for version formats containing numbers and dots.
# If any other character is found, it will use the default version comparison.

# Log Date format used when parsing logs for debugging, this is the default used by
# install.log, override this in the case statements if you need something custom per
# application (See adobeillustrator).  Using stadard GNU Date formatting.
LogDateFormat="%Y-%m-%d %H:%M:%S"

# Get the start time for parsing install.log if we fail.
starttime=$(date "+$LogDateFormat")

# Check if we have rosetta installed
if [[ $(/usr/bin/arch) == "arm64" ]]; then
    if ! arch -x86_64 /usr/bin/true >/dev/null 2>&1; then # pgrep oahd >/dev/null 2>&1
        rosetta2=no
    fi
fi
VERSION="10.10.4"
VERSIONDATE="2026-11-26"

# MARK: Functions

cleanupAndExit() { # $1 = exit code, $2 message, $3 level
    if [ -n "$dmgmount" ]; then
        # unmount disk image
        printlog "Unmounting $dmgmount" DEBUG
        unmountingOut=$(hdiutil detach "$dmgmount" 2>&1)
        printlog "Debugging enabled, Unmounting output was:\n$unmountingOut" DEBUG
    fi
    if [ "$DEBUG" -ne 1 ]; then
        # remove the temporary working directory when done (only if DEBUG is not used)
        printlog "Deleting $tmpDir" DEBUG
        deleteTmpOut=$(rm -Rfv "$tmpDir")
        printlog "Debugging enabled, Deleting tmpDir output was:\n$deleteTmpOut" DEBUG
    fi

    # If we closed any processes, reopen the app again
    reopenClosedProcess
    if [[ -n $2 && $1 -ne 0 ]]; then
        printlog "ERROR: $2" $3
        updateDialog "fail" "Error ($1; $2)"
    else
        printlog "$2" $3
        updateDialog "success" ""
    fi
    printlog "################## End Installomator, exit code $1 \n" REQ

    # if label is wrong and we wanted name of the label, then return ##################
    if [[ $RETURN_LABEL_NAME -eq 1 ]]; then
        1=0 # If only label name should be returned we exit without any errors
        echo "#"
    fi
    exit "$1"
}

runAsUser() {
    if [[ $currentUser != "loginwindow" ]]; then
        uid=$(id -u "$currentUser")
        launchctl asuser $uid sudo -u $currentUser "$@"
    fi
}

reloadAsUser() {
    if [[ $currentUser != "loginwindow" ]]; then
        uid=$(id -u "$currentUser")
        su - $currentUser -c "${@}"
    fi
}

displaydialog() { # $1: message $2: title
    message=${1:-"Message"}
    title=${2:-"Installomator"}
    runAsUser osascript -e "button returned of (display dialog \"$message\" with  title \"$title\" buttons {\"Not Now\", \"Quit and Update\"} default button \"Quit and Update\" with icon POSIX file \"$LOGO\" giving up after $PROMPT_TIMEOUT)"
}

displaydialogContinue() { # $1: message $2: title
    message=${1:-"Message"}
    title=${2:-"Installomator"}
    runAsUser osascript -e "button returned of (display dialog \"$message\" with  title \"$title\" buttons {\"Quit and Update\"} default button \"Quit and Update\" with icon POSIX file \"$LOGO\")"
}

displaynotification() { # $1: message $2: title
    message=${1:-"Message"}

    if [[ -n "$logcode" && "${message#$logcode}" != "$message" ]]; then
        message="${message#$logcode}"
        message="${message# }"
    fi

    title=${2:-"Notification"}
    manageaction="/Library/Application Support/JAMF/bin/Management Action.app/Contents/MacOS/Management Action"
    hubcli="/usr/local/bin/hubcli"
    swiftdialog="/usr/local/bin/dialog"

    if [[ "$NOTIFY_DIALOG" -eq 1 && -x "$swiftdialog" && "$("$swiftdialog" --version | cut -d "." -f1)" -ge 2 ]]; then
        "$swiftdialog" --notification --title "$title" --message "$message"
    elif [[ -x "$manageaction" ]]; then
         "$manageaction" -message "$message" -title "$title" &
    elif [[ -x "$hubcli" ]]; then
         "$hubcli" notify -t "$title" -i "$message" -c "Dismiss"
    else
        runAsUser osascript -e "display notification \"$message\" with title \"$title\""
    fi
}

printlog(){
    [ -z "$2" ] && 2=INFO
    log_message=$1
    log_priority=$2
    timestamp=$(date +%F\ %T)

    # Check to make sure that the log isn't the same as the last, if it is then don't log and increment a timer.
    if [[ ${log_message} == ${previous_log_message} ]]; then
        let logrepeat=$logrepeat+1
        return
    fi
    previous_log_message=$log_message

    # Extra spaces for log_priority alignment
    space_char=""
    if [[ ${#log_priority} -eq 3 ]]; then
        space_char="  "
    elif [[ ${#log_priority} -eq 4 ]]; then
        space_char=" "
    fi

    # Once we finally stop getting duplicate logs output the number of times we got a duplicate.
    if [[ $logrepeat -gt 1 ]];then
        echo "$timestamp" : "${log_priority}${space_char} : $label : Last Log repeated ${logrepeat} times" | tee -a $log_location

        if [[ ! -z $datadogAPI ]]; then
            curl -s -X POST https://http-intake.logs.datadoghq.com/v1/input -H "Content-Type: text/plain" -H "DD-API-KEY: $datadogAPI" -d "${log_priority} : $mdmURL : $APPLICATION : $VERSION : $SESSION : Last Log repeated ${logrepeat} times" > /dev/null
        fi
        logrepeat=0
    fi

    # If the datadogAPI key value is set and our logging level is greater than or equal to our set level
    # then post to Datadog's HTTPs endpoint.
    if [[ -n $datadogAPI && ${levels[$log_priority]} -ge ${levels[$datadogLoggingLevel]} ]]; then
        while IFS= read -r logmessage; do
            curl -s -X POST https://http-intake.logs.datadoghq.com/v1/input -H "Content-Type: text/plain" -H "DD-API-KEY: $datadogAPI" -d "${log_priority} : $mdmURL : Installomator-${label} : ${VERSIONDATE//-/} : $SESSION : ${logmessage}" > /dev/null
        done <<< "$log_message"
    fi

    # If our logging level is greaterthan or equal to our set level then output locally.
    if [[ ${levels[$log_priority]} -ge ${levels[$LOGGING]} ]]; then
        while IFS= read -r logmessage; do
            if [[ "$(whoami)" == "root" ]]; then
                echo "$timestamp" : "${log_priority}${space_char} : $label : ${logmessage}" | tee -a $log_location
            else
                echo "$timestamp" : "${log_priority}${space_char} : $label : ${logmessage}"
            fi
        done <<< "$log_message"
    fi
}

# Used to remove dupplicate lines in large log output,
# for example from msupdate command after it finishes running.
deduplicatelogs() {
    loginput=${1:-"Log"}
    logoutput=""
    # Read each line of the incoming log individually, match it with the previous.
    # If it matches increment logrepeate then skip to the next line.
    while read log; do
        if [[ $log == $previous_log ]];then
            let logrepeat=$logrepeat+1
            continue
        fi

        previous_log="$log"
        if [[ $logrepeat -gt 1 ]];then
            logoutput+="Last Log repeated ${logrepeat} times\n"
            logrepeat=0
        fi

        logoutput+="$log\n"
    done <<< "$loginput"
}

# will get the latest release download from a github repo
downloadURLFromGit() { # $1 git user name, $2 git repo name
    gitusername=${1?:"no git user name"}
    gitreponame=${2?:"no git repo name"}

    if [[ $type == "pkgInDmg" ]]; then
        filetype="dmg"
    elif [[ $type == "pkgInZip" ]]; then
        filetype="zip"
    else
        filetype=$type
    fi

    if [ -n "$archiveName" ]; then
        downloadURL=$(curl -sfL "https://api.github.com/repos/$gitusername/$gitreponame/releases/latest" | awk -F '"' "/browser_download_url/ && /$archiveName\"/ { print \$4; exit }")
        if [[ "$(echo $downloadURL | grep -ioE "https.*$archiveName")" == "" ]]; then
            #downloadURL=https://github.com$(curl -sfL "https://github.com/$gitusername/$gitreponame/releases/latest" | tr '"' "\n" | grep -i "^/.*\/releases\/download\/.*$archiveName" | head -1)
            downloadURL="https://github.com$(curl -sfL "$(curl -sfL "https://github.com/$gitusername/$gitreponame/releases/latest" | tr '"' "\n" | grep -i "expanded_assets" | head -1)" | tr '"' "\n" | grep -i "^/.*\/releases\/download\/.*$archiveName" | head -1)"
        fi
    else
        downloadURL=$(curl -sfL "https://api.github.com/repos/$gitusername/$gitreponame/releases/latest" | awk -F '"' "/browser_download_url/ && /$filetype\"/ { print \$4; exit }")
        if [[ "$(echo $downloadURL | grep -ioE "https.*.$filetype")" == "" ]]; then
            #downloadURL=https://github.com$(curl -sfL "https://github.com/$gitusername/$gitreponame/releases/latest" | tr '"' "\n" | grep -i "^/.*\/releases\/download\/.*\.$filetype" | head -1)
            downloadURL="https://github.com$(curl -sfL "$(curl -sfL "https://github.com/$gitusername/$gitreponame/releases/latest" | tr '"' "\n" | grep -i "expanded_assets" | head -1)" | tr '"' "\n" | grep -i "^/.*\/releases\/download\/.*\.$filetype" | head -1)"
        fi
    fi
    if [ -z "$downloadURL" ]; then
        cleanupAndExit 14 "could not retrieve download URL for $gitusername/$gitreponame" ERROR
    else
        echo "$downloadURL"
        return 0
    fi
}

versionFromGit() {
    # credit: Søren Theilgaard (@theilgaard)
    # $1 git user name, $2 git repo name
    gitusername=${1?:"no git user name"}
    gitreponame=${2?:"no git repo name"}

    #appNewVersion=$(curl -L --silent --fail "https://api.github.com/repos/$gitusername/$gitreponame/releases/latest" | grep tag_name | cut -d '"' -f 4 | sed 's/[^0-9\.]//g')
    appNewVersion=$(curl -sLI "https://github.com/$gitusername/$gitreponame/releases/latest" | grep -i "^location" | tr "/" "\n" | tail -1 | sed 's/[^0-9\.]//g')
    if [ -z "$appNewVersion" ]; then
        printlog "could not retrieve version number for $gitusername/$gitreponame" WARN
        appNewVersion=""
    else
        echo "$appNewVersion"
        return 0
    fi
}


# Handling of differences in xpath between Catalina and Big Sur
xpath() {
	# the xpath tool changes in Big Sur and now requires the `-e` option
	if [[ $(sw_vers -buildVersion) > "20A" ]]; then
		/usr/bin/xpath -q -e $@
		# alternative: switch to xmllint (which is not perl)
		#xmllint --xpath $@ -
	else
		/usr/bin/xpath -q $@
	fi
}

# from @Pico: https://macadmins.slack.com/archives/CGXNNJXJ9/p1652222365989229?thread_ts=1651786411.413349&cid=CGXNNJXJ9
getJSONValue() {
	# $1: JSON string OR file path to parse (tested to work with up to 1GB string and 2GB file).
	# $2: JSON key path to look up (using dot or bracket notation).
	printf '%s' "$1" | /usr/bin/osascript -l 'JavaScript' \
		-e "let json = $.NSString.alloc.initWithDataEncoding($.NSFileHandle.fileHandleWithStandardInput.readDataToEndOfFile$(/usr/bin/uname -r | /usr/bin/awk -F '.' '($1 > 18) { print "AndReturnError(ObjC.wrap())" }'), $.NSUTF8StringEncoding)" \
		-e 'if ($.NSFileManager.defaultManager.fileExistsAtPath(json)) json = $.NSString.stringWithContentsOfFileEncodingError(json, $.NSUTF8StringEncoding, ObjC.wrap())' \
		-e "const value = JSON.parse(json.js)$([ -n "${2%%[.[]*}" ] && echo '.')$2" \
		-e 'if (typeof value === "object") { JSON.stringify(value, null, 4) } else { value }'
}

getAppVersion() {
    # modified by: Søren Theilgaard (@theilgaard) and Isaac Ordonez

    # If label contain function appCustomVersion, we use that and return
    if type 'appCustomVersion' 2>/dev/null | grep -q 'function'; then
        appversion=$(appCustomVersion)
        printlog "Custom App Version detection is used, found $appversion"
        return
    fi

    # pkgs contains a version number, then we don't have to search for an app
    if [[ $packageID != "" ]]; then
        appversion="$(pkgutil --pkg-info-plist "${packageID}" 2>/dev/null | plutil -extract pkg-version raw -o - -)"
        if [[ $appversion != "" ]]; then
            printlog "found packageID $packageID installed, version $appversion"
            updateDetected="YES"
            return
        else
            printlog "No version found using packageID $packageID"
        fi
    fi

    # get app in targetDir, /Applications, or /Applications/Utilities
    if [[ -d "$targetDir/$appName" ]]; then
        applist="$targetDir/$appName"
    elif [[ -d "/Applications/$appName" ]]; then
        applist="/Applications/$appName"
#        if [[ $type =~ '^(dmg|zip|tbz|app.*)$' ]]; then
#            targetDir="/Applications"
#        fi
    elif [[ -d "/Applications/Utilities/$appName" ]]; then
        applist="/Applications/Utilities/$appName"
#        if [[ $type =~ '^(dmg|zip|tbz|app.*)$' ]]; then
#            targetDir="/Applications/Utilities"
#        fi
    else
        printlog "name: $name, appName: $appName"
        # mdfind now handling if kind is either Application or App
        applist=$(mdfind "kMDItemContentType:com.apple.application AND kMDItemFSName:\"$name\"" -0 2>/dev/null)
#        applist=$(mdfind "kMDItemContentType:com.apple.application AND kMDItemFSName:\"$appName\"" -0 2>/dev/null)
#        printlog "App(s) found: ${applist}" DEBUG
    fi
    if [[ -z $applist ]]; then
        printlog "No previous app found" WARN
    else
        printlog "App(s) found: ${applist}" INFO
    fi
#    if [[ $type =~ '^(dmg|zip|tbz|app.*)$' ]]; then
#        printlog "targetDir for installation: $targetDir" INFO
#    fi

    appPathArray=( ${(0)applist} )

    if [[ ${#appPathArray} -gt 0 ]]; then
        filteredAppPaths=( ${(M)appPathArray:#${targetDir}*} )
        if [[ ${#filteredAppPaths} -eq 1 ]]; then
            installedAppPath=$filteredAppPaths[1]
            #appversion=$(mdls -name kMDItemVersion -raw $installedAppPath )
            appversion=$(defaults read $installedAppPath/Contents/Info.plist $versionKey) #Not dependant on Spotlight indexing
            printlog "found app at $installedAppPath, version $appversion, on versionKey $versionKey"
            updateDetected="YES"
            # Is current app from App Store
            if [[ -d "$installedAppPath"/Contents/_MASReceipt ]];then
                printlog "Installed $appName is from App Store, use “IGNORE_APP_STORE_APPS=yes” to replace."
                if [[ $IGNORE_APP_STORE_APPS == "yes" ]]; then
                    printlog "Replacing App Store apps, no matter the version" WARN
                    appversion=0
                else
                    if [[ $DIALOG_CMD_FILE != "" ]]; then
                        updateDialog "wait" "Already installed from App Store. Not replaced."
                        sleep 4
                    fi
                    cleanupAndExit 23 "App previously installed from App Store, and we respect that" ERROR
                fi
            fi
        else
            printlog "could not determine location of $appName" WARN
        fi
    else
        printlog "could not find $appName" WARN
    fi
}

checkRunningProcesses() {
    # don't check in DEBUG mode 1
    if [[ $DEBUG -eq 1 ]]; then
        printlog "DEBUG mode 1, not checking for blocking processes" DEBUG
        return
    fi

    # try at most 3 times
    for i in {1..4}; do
        countedProcesses=0
        for x in ${blockingProcesses}; do
            if pgrep -xq "$x"; then
                printlog "found blocking process $x"
                appClosed=1

                case $BLOCKING_PROCESS_ACTION in
                    quit|quit_kill)
                        printlog "telling app $x to quit"
                        runAsUser osascript -e "tell app \"$x\" to quit"
                        if [[ $i > 2 && $BLOCKING_PROCESS_ACTION = "quit_kill" ]]; then
                          printlog "Changing BLOCKING_PROCESS_ACTION to kill"
                          BLOCKING_PROCESS_ACTION=kill
                        else
                            # give the user a bit of time to quit apps
                            printlog "waiting 30 seconds for processes to quit"
                            sleep 30
                        fi
                        ;;
                    kill)
                      printlog "killing process $x"
                      pkill $x
                      sleep 5
                      ;;
                    prompt_user|prompt_user_then_kill)
                      button=$(displaydialog "Quit “$x” to continue updating? $([[ -n $appNewVersion ]] && echo "Version $appversion is installed, but version $appNewVersion is available.") (Leave this dialogue if you want to activate this update later)." "The application “$x” needs to be updated.")
                      if [[ $button = "Not Now" ]]; then
                        appClosed=0
                        cleanupAndExit 10 "user aborted update" ERROR
                      elif [[ $button = "" ]]; then
                        appClosed=0
                        cleanupAndExit 25 "timed out waiting for user response" ERROR
                      else
                        if [[ $BLOCKING_PROCESS_ACTION = "prompt_user_then_kill" ]]; then
                          # try to quit, then set to kill
                          printlog "telling app $x to quit"
                          runAsUser osascript -e "tell app \"$x\" to quit"
                          # give the user a bit of time to quit apps
                          printlog "waiting 30 seconds for processes to quit"
                          sleep 30
                          printlog "Changing BLOCKING_PROCESS_ACTION to kill"
                          BLOCKING_PROCESS_ACTION=kill
                        else
                          printlog "telling app $x to quit"
                          runAsUser osascript -e "tell app \"$x\" to quit"
                          # give the user a bit of time to quit apps
                          printlog "waiting 30 seconds for processes to quit"
                          sleep 30
                        fi
                      fi
                      ;;
                    prompt_user_loop)
                      button=$(displaydialog "Quit “$x” to continue updating? $([[ -n $appNewVersion ]] && echo "Version $appversion is installed, but version $appNewVersion is available.") (Click “Not Now” to be asked in 1 hour, or leave this open until you are ready)." "The application “$x” needs to be updated.")
                      if [[ $button = "Not Now" ]]; then
                        if [[ $i < 2 ]]; then
                          printlog "user wants to wait an hour"
                          sleep 3600 # 3600 seconds is an hour
                        else
                          printlog "change of BLOCKING_PROCESS_ACTION to tell_user"
                          BLOCKING_PROCESS_ACTION=tell_user
                        fi
                      else
                        printlog "telling app $x to quit"
                        runAsUser osascript -e "tell app \"$x\" to quit"
                        # give the user a bit of time to quit apps
                        printlog "waiting 30 seconds for processes to quit"
                        sleep 30
                      fi
                      ;;
                    tell_user|tell_user_then_kill)
                      button=$(displaydialogContinue "Quit “$x” to continue updating? (This is an important update). Wait for notification of update before launching app again." "The application “$x” needs to be updated.")
                      printlog "telling app $x to quit"
                      runAsUser osascript -e "tell app \"$x\" to quit"
                      # give the user a bit of time to quit apps
                      printlog "waiting 30 seconds for processes to quit"
                      sleep 30
                      if [[ $i > 1 && $BLOCKING_PROCESS_ACTION = tell_user_then_kill ]]; then
                          printlog "Changing BLOCKING_PROCESS_ACTION to kill"
                          BLOCKING_PROCESS_ACTION=kill
                      fi
                      ;;
                    silent_fail)
                      appClosed=0
                      cleanupAndExit 12 "blocking process '$x' found, aborting" ERROR
                      ;;
                esac

                countedProcesses=$((countedProcesses + 1))
            fi
        done

    done

    if [[ $countedProcesses -ne 0 ]]; then
        cleanupAndExit 11 "could not quit all processes, aborting..." ERROR
    fi

    printlog "no more blocking processes, continue with update" REQ
}

reopenClosedProcess() {
    # If Installomator closed any processes, let's get the app opened again
    # credit: Søren Theilgaard (@theilgaard)

    # don't reopen if REOPEN is not "yes"
    if [[ $REOPEN != yes ]]; then
        printlog "REOPEN=no, not reopening anything"
        return
    fi

    # don't reopen in DEBUG mode 1
    if [[ $DEBUG -eq 1 ]]; then
        printlog "DEBUG mode 1, not reopening anything" DEBUG
        return
    fi

    if [[ $appClosed == 1 ]]; then
        printlog "Telling app $appName to open"
        #runAsUser osascript -e "tell app \"$appName\" to open"
        #runAsUser open -a "${appName}"
        reloadAsUser "open -a \"${appName}\""
        #reloadAsUser "open \"${(0)applist}\""
        processuser=$(ps aux | grep -i "${appName}" | grep -vi "grep" | awk '{print $1}')
        printlog "Reopened ${appName} as $processuser"
    else
        printlog "Installomator did not close any apps, so no need to reopen any apps." INFO
    fi
}

installAppWithPath() { # $1: path to app to install in $targetDir $2: path to folder (with app inside) to copy to $targetDir
    # modified by: Søren Theilgaard (@theilgaard)
    appPath=${1?:"no path to app"}
    # If $2 ends in "/" then a folderName has not been specified so don't set it.
    if [[ ! "${2}" == */ ]]; then
        folderPath="${2}"
    fi

    # check if app exists
    if [ ! -e "$appPath" ]; then
        cleanupAndExit 8 "could not find: $appPath" ERROR
    fi

    # check if folder path exists if it is set
    if [[ -n "$folderPath" ]] && [[ ! -e "$folderPath" ]]; then
        cleanupAndExit 8 "could not find folder: $folderPath" ERROR
    fi

    # verify with spctl
    printlog "Verifying: $appPath" INFO
    updateDialog "wait" "Verifying..."
    printlog "App size: $(du -sh "$appPath")" DEBUG
    appVerify=$(spctl -a -vv "$appPath" 2>&1 )
    appVerifyStatus=$(echo $?)
    teamID=$(echo $appVerify | awk '/origin=/ {print $NF }' | tr -d '()' )
    deduplicatelogs "$appVerify"

    if [[ $appVerifyStatus -ne 0 ]] ; then
    #if ! teamID=$(spctl -a -vv "$appPath" 2>&1 | awk '/origin=/ {print $NF }' | tr -d '()' ); then
        cleanupAndExit 4 "Error verifying $appPath error:\n$logoutput" ERROR
    fi
    printlog "Debugging enabled, App Verification output was:\n$logoutput" DEBUG
    printlog "Team ID matching: $teamID (expected: $expectedTeamID )" INFO

    if [ "$expectedTeamID" != "$teamID" ]; then
        cleanupAndExit 5 "Team IDs do not match" ERROR
    fi

    # app versioncheck
    appNewVersion=$(defaults read $appPath/Contents/Info.plist $versionKey)
    if [[ -n $appNewVersion ]] && [[ -n $appversion ]] && is-at-least $appNewVersion $appversion; then
        printlog "Downloaded version of $name is $appNewVersion on versionKey $versionKey, same or older as installed version $appversion."
        if [[ $INSTALL != "force" ]]; then
            message="$name, version $appNewVersion, is the latest version."
            if [[ $currentUser != "loginwindow" && $NOTIFY == "all" ]]; then
                printlog "notifying"
                displaynotification "$message" "No update for $name!"
            fi
            if [[ $DIALOG_CMD_FILE != "" ]]; then
                updateDialog "wait" "Latest version already installed..."
                sleep 2
            fi
            cleanupAndExit 0 "No new version to install" REG
        else
            printlog "Using force to install anyway."
        fi
    elif [[ -z $appversion ]]; then
        printlog "Installing $name version $appNewVersion on versionKey $versionKey."
    else
        printlog "Downloaded version of $name is $appNewVersion on versionKey $versionKey (replacing version $appversion)."
    fi

    # macOS versioncheck
    minimumOSversion=$(defaults read $appPath/Contents/Info.plist LSMinimumSystemVersion 2>/dev/null )
    if [[ -n $minimumOSversion && $minimumOSversion =~ '[0-9.]*' ]]; then
        printlog "App has LSMinimumSystemVersion: $minimumOSversion"
        if ! is-at-least $minimumOSversion $installedOSversion; then
            printlog "App requires higher System Version than installed: $installedOSversion"
            message="Cannot install $name, version $appNewVersion, as it is not compatible with the running system version."
            if [[ $currentUser != "loginwindow" && $NOTIFY == "all" ]]; then
                printlog "notifying"
                displaynotification "$message" "Error updating $name!"
            fi
            cleanupAndExit 15 "Installed macOS is too old for this app." ERROR
        fi
    fi

    # skip install for DEBUG 1
    if [ "$DEBUG" -eq 1 ]; then
        printlog "DEBUG mode 1 enabled, skipping remove, copy and chown steps" DEBUG
        return 0
    fi

    # skip install for DEBUG 2
    if [ "$DEBUG" -eq 2 ]; then
        printlog "DEBUG mode 2 enabled, not installing anything, exiting" DEBUG
        cleanupAndExit 0
    fi

    # Test if variable CLIInstaller is set
    if [[ -z $CLIInstaller ]]; then

        # remove existing application
        if [ -e "$targetDir/$appName" ]; then
            printlog "Removing existing $targetDir/$appName" WARN
            deleteAppOut=$(rm -Rfv "$targetDir/$appName" 2>&1)
            tempName="$targetDir/$appName"
            tempNameLength=$((${#tempName} + 10))
            deleteAppOut=$(echo $deleteAppOut | cut -c 1-$tempNameLength)
            deduplicatelogs "$deleteAppOut"
            printlog "Debugging enabled, App removing output was:\n$logoutput" DEBUG
        fi

        # copy app to /Applications
        printlog "Copy $appPath to $targetDir"
        if [[ -n $folderPath ]]; then
            copyAppOut=$(ditto -v "$folderPath" "$targetDir/$folderName" 2>&1)
        else
            copyAppOut=$(ditto -v "$appPath" "$targetDir/$appName" 2>&1)
        fi
        copyAppStatus=$(echo $?)
        deduplicatelogs "$copyAppOut"
        printlog "Debugging enabled, App copy output was:\n$logoutput" DEBUG
        if [[ $copyAppStatus -ne 0 ]] ; then
        #if ! ditto "$appPath" "$targetDir/$appName"; then
            cleanupAndExit 7 "Error while copying:\n$logoutput" ERROR
        fi

        # set ownership to current user
        if [[ "$currentUser" != "loginwindow" && $SYSTEMOWNER -ne 1 ]]; then
            printlog "Changing owner to $currentUser" WARN
            chown -R "$currentUser" "$targetDir/$appName"
        else
            printlog "No user logged in or SYSTEMOWNER=1, setting owner to root:wheel" WARN
            chown -R root:wheel "$targetDir/$appName"
        fi

    elif [[ ! -z $CLIInstaller ]]; then
        mountname=$(dirname $appPath)
        printlog "CLIInstaller exists, running installer command $mountname/$CLIInstaller $CLIArguments" INFO

        CLIoutput=$("$mountname/$CLIInstaller" "${CLIArguments[@]}" 2>&1)
        CLIstatus=$(echo $?)
        deduplicatelogs "$CLIoutput"

        if [ $CLIstatus -ne 0 ] ; then
            cleanupAndExit 16 "Error installing $mountname/$CLIInstaller $CLIArguments error:\n$logoutput" ERROR
        else
            printlog "Succesfully ran $mountname/$CLIInstaller $CLIArguments" INFO
        fi
        printlog "Debugging enabled, update tool output was:\n$logoutput" DEBUG
    fi

}

mountDMG() {
    # mount the dmg
    printlog "Mounting $tmpDir/$archiveName"
    # always pipe 'Y\n' in case the dmg requires an agreement
    dmgmountOut=$(echo 'Y'$'\n' | hdiutil attach "$tmpDir/$archiveName" -nobrowse -readonly )
    dmgmountStatus=$(echo $?)
    dmgmount=$(echo $dmgmountOut | tail -n 1 | cut -c 54- )
    deduplicatelogs "$dmgmountOut"

    if [[ $dmgmountStatus -ne 0 ]] ; then
    #if ! dmgmount=$(echo 'Y'$'\n' | hdiutil attach "$tmpDir/$archiveName" -nobrowse -readonly | tail -n 1 | cut -c 54- ); then
        cleanupAndExit 3 "Error mounting $tmpDir/$archiveName error:\n$logoutput" ERROR
    fi
    if [[ ! -e $dmgmount ]]; then
        cleanupAndExit 3 "Error accessing mountpoint for $tmpDir/$archiveName error:\n$logoutput" ERROR
    fi
    printlog "Debugging enabled, dmgmount output was:\n$logoutput" DEBUG

    printlog "Mounted: $dmgmount" INFO
}

installFromDMG() {
    mountDMG
    installAppWithPath "$dmgmount/$appName" "$dmgmount/$folderName"
}

installFromPKG() {
    # verify with spctl
    printlog "Verifying: $archiveName"
    updateDialog "wait" "Verifying..."
    printlog "File list: $(ls -lh "$archiveName")" DEBUG
    printlog "File type: $(file "$archiveName")" DEBUG
    spctlOut=$(spctl -a -vv -t install "$archiveName" 2>&1 )
    spctlStatus=$(echo $?)
    printlog "spctlOut is $spctlOut" DEBUG

    teamID=$(echo $spctlOut | awk -F '(' '/origin=/ {print $NF }' | tr -d '()' )
    # Apple signed software has no teamID, grab entire text after origin= instead
    if [[ -z $teamID ]] || [[ $teamID == "origin="* ]]; then
        teamID=$(echo $spctlOut | awk -F '=' '/origin=/ {print $NF }')
    fi

    deduplicatelogs "$spctlOut"

    if [[ $spctlStatus -ne 0 ]] ; then
    #if ! spctlout=$(spctl -a -vv -t install "$archiveName" 2>&1 ); then
        cleanupAndExit 4 "Error verifying $archiveName error:\n$logoutput" ERROR
    fi

    # Apple signed software has no teamID, grab entire origin instead
    if [[ -z $teamID ]]; then
        teamID=$(echo $spctlout | awk -F '=' '/origin=/ {print $NF }')
    fi

    printlog "Team ID: $teamID (expected: $expectedTeamID )"

    if [ "$expectedTeamID" != "$teamID" ]; then
        cleanupAndExit 5 "Team IDs do not match!" ERROR
    fi

    # Check version of pkg to be installed if packageID is set
    if [[ $packageID != "" && $appversion != "" ]]; then
        printlog "Checking package version."
        baseArchiveName=$(basename $archiveName)
        expandedPkg="$tmpDir/${baseArchiveName}_pkg"
        pkgutil --expand "$archiveName" "$expandedPkg"
        appNewVersion=$(cat "$expandedPkg"/Distribution | xpath "string(//installer-gui-script/pkg-ref[@id='$packageID'][@version]/@version)" 2>/dev/null )
        rm -r "$expandedPkg"
        printlog "Downloaded package $packageID version $appNewVersion"
        if [[ $appversion == $appNewVersion ]]; then
            printlog "Downloaded version of $name is the same as installed."
            if [[ $INSTALL != "force" ]]; then
                message="$name, version $appNewVersion, is the latest version."
                if [[ $currentUser != "loginwindow" && $NOTIFY == "all" ]]; then
                    printlog "notifying"
                    displaynotification "$message" "No update for $name!"
                fi
                if [[ $DIALOG_CMD_FILE != "" ]]; then
                    updateDialog "wait" "Latest version already installed..."
                    sleep 2
                fi
                cleanupAndExit 0 "No new version to install" REQ
            else
                printlog "Using force to install anyway."
            fi
        fi
    fi

    # skip install for DEBUG 1
    if [ "$DEBUG" -eq 1 ]; then
        printlog "DEBUG enabled, skipping installation" DEBUG
        return 0
    fi

    # skip install for DEBUG 2
    if [ "$DEBUG" -eq 2 ]; then
        cleanupAndExit 0 "DEBUG mode 2 enabled, exiting" DEBUG
    fi

    # install pkg
    printlog "Installing $archiveName to $targetDir"

    if [[ $DIALOG_CMD_FILE != "" ]]; then
        # pipe
        pipe="$tmpDir/installpipe"
        # initialise named pipe for installer output
        initNamedPipe create $pipe

        # run the pipe read in the background
        readPKGInstallPipe $pipe "$DIALOG_CMD_FILE" & installPipePID=$!
        printlog "listening to output of installer with pipe $pipe and command file $DIALOG_CMD_FILE on PID $installPipePID" DEBUG

        pkgInstall=$(installer -verboseR -pkg "$archiveName" -tgt "$targetDir" 2>&1 | tee $pipe)
        pkgInstallStatus=$pipestatus[1]
            # because we are tee-ing the output, we want the pipe status of the first command in the chain, not the most recent one
        killProcess $installPipePID

    else
        pkgInstall=$(installer -verbose -dumplog -pkg "$archiveName" -tgt "$targetDir" 2>&1)
        pkgInstallStatus=$(echo $?)
    fi



    sleep 1
    pkgEndTime=$(date "+$LogDateFormat")
    pkgInstall+=$(echo "\nOutput of /var/log/install.log below this line.\n")
    pkgInstall+=$(echo "----------------------------------------------------------\n")
    pkgInstall+=$(awk -v "b=$starttime" -v "e=$pkgEndTime" -F ',' '$1 >= b && $1 <= e' /var/log/install.log)
    deduplicatelogs "$pkgInstall"

    if [[ $pkgInstallStatus -ne 0 ]] && [[ $logoutput == *"requires Rosetta 2"* ]] && [[ $rosetta2 == no ]]; then
        printlog "Package requires Rosetta 2, Installing Rosetta 2 and Installing Package" INFO
        /usr/sbin/softwareupdate --install-rosetta --agree-to-license
        rosetta2=yes
        installFromPKG
    fi

    if [[ $pkgInstallStatus -ne 0 ]] ; then
    #if ! installer -pkg "$archiveName" -tgt "$targetDir" ; then
        cleanupAndExit 9 "Error installing $archiveName error:\n$logoutput" ERROR
    fi
    printlog "Debugging enabled, installer output was:\n$logoutput" DEBUG
}

installFromZIP() {
    # unzip the archive
    printlog "Unzipping $archiveName"

    # tar -xf "$archiveName"

    # note: when you expand a zip using tar in Mojave the expanded
    # app will never pass the spctl check

    # unzip -o -qq "$archiveName"

    # note: githubdesktop fails spctl verification when expanded
    # with unzip

    ditto -x -k "$archiveName" "$tmpDir"
    installAppWithPath "$tmpDir/$appName"
}

installFromTBZ() {
    # unzip the archive
    printlog "Unzipping $archiveName"
    tar -xf "$archiveName"
    installAppWithPath "$tmpDir/$appName"
}

installPkgInDmg() {
    mountDMG
    # locate pkg in dmg
    if [[ -z $pkgName ]]; then
        # find first file ending with 'pkg'
        findfiles=$(find "$dmgmount" -iname "*.pkg" -type f -maxdepth 1  )
        printlog "Found pkg(s):\n$findfiles" DEBUG
        filearray=( ${(f)findfiles} )
        if [[ ${#filearray} -eq 0 ]]; then
            cleanupAndExit 20 "couldn't find pkg in dmg $archiveName" ERROR
        fi
        archiveName="${filearray[1]}"
    else
        if [[ -s "$dmgmount/$pkgName" ]] ; then # was: $tmpDir
            archiveName="$dmgmount/$pkgName"
        else
            # try searching for pkg
            findfiles=$(find "$dmgmount" -iname "$pkgName") # was: $tmpDir
            printlog "Found pkg(s):\n$findfiles" DEBUG
            filearray=( ${(f)findfiles} )
            if [[ ${#filearray} -eq 0 ]]; then
                cleanupAndExit 20 "couldn't find pkg “$pkgName” in dmg $archiveName" ERROR
            fi
            # it is now safe to overwrite archiveName for installFromPKG
            archiveName="${filearray[1]}"
        fi
    fi
    printlog "found pkg: $archiveName"

    # installFromPkgs
    installFromPKG
}

installPkgInZip() {
    # unzip the archive
    printlog "Unzipping $archiveName"
    tar -xf "$archiveName"

    # locate pkg in zip
    if [[ -z $pkgName ]]; then
        # find first file ending with 'pkg'
        findfiles=$(find "$tmpDir" -iname "*.pkg" -type f -maxdepth 2  )
        printlog "Found pkg(s):\n$findfiles" DEBUG
        filearray=( ${(f)findfiles} )
        if [[ ${#filearray} -eq 0 ]]; then
            cleanupAndExit 21 "couldn't find pkg in zip $archiveName" ERROR
        fi
        # it is now safe to overwrite archiveName for installFromPKG
        archiveName="${filearray[1]}"
        printlog "found pkg: $archiveName"
    else
        if [[ -s "$tmpDir/$pkgName" ]]; then
            archiveName="$tmpDir/$pkgName"
        else
            # try searching for pkg
            findfiles=$(find "$tmpDir" -iname "$pkgName")
            filearray=( ${(f)findfiles} )
            if [[ ${#filearray} -eq 0 ]]; then
                cleanupAndExit 21 "couldn't find pkg “$pkgName” in zip $archiveName" ERROR
            fi
            # it is now safe to overwrite archiveName for installFromPKG
            archiveName="${filearray[1]}"
            printlog "found pkg: $archiveName"
        fi
    fi

    # installFromPkgs
    installFromPKG
}

installItemInDmgInZip() {
    # unzip the archive
    printlog "Unzipping $archiveName"
    tar -xf "$archiveName"

    # locate dmg in zip
    if [[ -z $pkgName ]]; then
        # find first file ending with 'dmg'
        findfiles=$(find "$tmpDir" -iname "*.dmg" -maxdepth 2  )
        filearray=( ${(f)findfiles} )
        if [[ ${#filearray} -eq 0 ]]; then
            cleanupAndExit 22 "couldn't find dmg in zip $archiveName" ERROR
        fi
        archiveName="$(basename ${filearray[1]})"
        # it is now safe to overwrite archiveName for installFromDMG
        printlog "found dmg: $tmpDir/$archiveName"
    else
        # it is now safe to overwrite archiveName for installFromDMG
        archiveName="$pkgName"
    fi

    case $type in
        appInDmgInZip)
            # installFromDMG, DMG expected to include an app (will not work with pkg)
            installFromDMG
            ;;
        pkgInDmgInZip)
            # installPkgInDmg, DMG expected to include an pkg (will not work with app)
            installPkgInDmg
            ;;
        *)
            cleanupAndExit 99 "Cannot handle type $type" ERROR
            ;;
    esac
}


runUpdateTool() {
    printlog "Function called: runUpdateTool"
    if [[ -x $updateTool ]]; then
        printlog "running $updateTool $updateToolArguments"
        if [[ -n $updateToolRunAsCurrentUser ]]; then
            updateOutput=$(runAsUser $updateTool ${updateToolArguments} 2>&1)
            updateStatus=$(echo $?)
        else
            updateOutput=$($updateTool ${updateToolArguments} 2>&1)
            updateStatus=$(echo $?)
        fi
        sleep 1
        updateEndTime=$(date "+$updateToolLogDateFormat")
        deduplicatelogs $updateOutput
        if [[ -n $updateToolLog ]]; then
            updateOutput+=$(echo "Output of Installer log of $updateToolLog below this line.\n")
            updateOutput+=$(echo "----------------------------------------------------------\n")
            updateOutput+=$(awk -v "b=$updatestarttime" -v "e=$updateEndTime" -F ',' '$1 >= b && $1 <= e' $updateToolLog)
        fi

        if [[ $updateStatus -ne 0 ]]; then
            printlog "Error running $updateTool, Procceding with normal installation. Exit Status: $updateStatus Error:\n$logoutput" WARN
            return 1
            if [[ $type == updateronly ]]; then
                cleanupAndExit 77 "No Download URL Set, this is an update only application and the updater failed" ERROR
            fi
        elif [[ $updateStatus -eq 0 ]]; then
            printlog "Debugging enabled, update tool output was:\n$logoutput" DEBUG
        fi
    else
        printlog "couldn't find $updateTool, continuing normally" WARN
        return 1
    fi
    return 0
}

finishing() {
    printlog "Finishing..."

    sleep 3 # wait a moment to let spotlight catch up

    if [[ $appversion ]]; then
        oldversion=$appversion
    fi

    getAppVersion

    if [[ -z $appNewVersion ]]; then
        message="$logcode Installed $name"
    elif [[ -z $oldversion ]]; then
        message="$logcode Installed $name (version $appNewVersion)"
    else
        message="$logcode Updated $name (old: $oldversion, new: $appNewVersion)"
    fi

    printlog "$message" REQ

    if [[ $currentUser != "loginwindow" && ( $NOTIFY == "success" || $NOTIFY == "all" ) ]]; then
        printlog "notifying"
        if [[ $updateDetected == "YES" ]]; then
            displaynotification "$message" "$name update complete!"
        else
            displaynotification "$message" "$name installation complete!"
        fi
    fi
}

# Detect if there is an app actively making a display sleep assertion, e.g.
# KeyNote, PowerPoint, Zoom, or Webex.
# See: https://developer.apple.com/documentation/iokit/iopmlib_h/iopmassertiontypes
hasDisplaySleepAssertion() {
    # Get the names of all apps with active display sleep assertions (removing non-ASCII characters before awk)
    local apps="$(/usr/bin/pmset -g assertions | iconv -f UTF-8 -t ASCII//TRANSLIT//IGNORE | /usr/bin/awk '/NoDisplaySleepAssertion | PreventUserIdleDisplaySleep/ && match($0,/\(.+\)/) && ! /coreaudiod/ {gsub(/^.*\(/,"",$0); gsub(/\).*$/,"",$0); print};')"

    if [[ ! "${apps}" ]]; then
        # No display sleep assertions detected
        return 1
    fi

    # Create an array of apps that need to be ignored
    local ignore_array=("${(@s/,/)IGNORE_DND_APPS}")

    for app in ${(f)apps}; do
        if (( ! ${ignore_array[(Ie)${app}]} )); then
            # Relevant app with display sleep assertion detected
            printlog "Display sleep assertion detected by ${app}."
            return 0
        fi
    done

    # No relevant display sleep assertion detected
    return 1
}


initNamedPipe() {
    # create or delete a named pipe
    # commands are "create" or "delete"

    local cmd=$1
    local pipe=$2
    case $cmd in
        "create")
            if [[ -e $pipe ]]; then
                rm $pipe
            fi
            # make named pipe
            mkfifo -m 644 $pipe
            ;;
        "delete")
            # clean up
            rm $pipe
            ;;
        *)
            ;;
    esac
}

readDownloadPipe() {
    # reads from a previously created named pipe
    # output from curl with --progress-bar. % downloaded is read in and then sent to the specified log file
    local pipe=$1
    local log=${2:-$DIALOG_CMD_FILE}
    # set up read from pipe
    while IFS= read -k 1 -u 0 char; do
        if [[ $char =~ [0-9] ]]; then
            keep=1
        fi

        if [[ $char == % ]]; then
            updateDialog $progress "Downloading..."
            progress=""
            keep=0
        fi

        if [[ $keep == 1 ]]; then
            progress="$progress$char"
        fi
    done < $pipe
}

readPKGInstallPipe() {
    # reads from a previously created named pipe
    # output from installer with -verboseR. % install status is read in and then sent to the specified log file
    local pipe=$1
    local log=${2:-$DIALOG_CMD_FILE}
    local appname=${3:-$name}

    while read -k 1 -u 0 char; do
        if [[ $char == % ]]; then
            keep=1
        fi
        if [[ $char =~ [0-9] && $keep == 1 ]]; then
            progress="$progress$char"
        fi
        if [[ $char == . && $keep == 1 ]]; then
            updateDialog $progress "Installing..."
            progress=""
            keep=0
        fi
    done < $pipe
}

killProcess() {
    # will silently kill the specified PID
    builtin kill $1 2>/dev/null
}

updateDialog() {
    local state=$1
    local message=$2
    local listitem=${3:-$DIALOG_LIST_ITEM_NAME}
    local cmd_file=${4:-$DIALOG_CMD_FILE}
    local progress=""

    if [[ $state =~ '^[0-9]' \
       || $state == "reset" \
       || $state == "increment" \
       || $state == "complete" \
       || $state == "indeterminate" ]]; then
        progress=$state
    fi

    # when to cmdfile is set, do nothing
    if [[ $cmd_file == "" ]]; then
        return
    fi

    if [[ $listitem == "" ]]; then
        # no listitem set, update main progress bar and progress text
        if [[ $progress != "" ]]; then
            echo "progress: $progress" >> $cmd_file
        fi
        if [[ $message != "" ]]; then
            if [[ $appNewVersion != "" ]]; then
                appVersionProgressText=${appNewVersion// /}
                echo "progresstext: v$appVersionProgressText $message" >> $cmd_file
            else
                echo "progresstext: $message" >> $cmd_file
            fi
        fi
    else
        # list item has a value, so we update the progress and text in the list
        if [[ $progress != "" ]]; then
            echo "listitem: title: $listitem, statustext: $message, progress: $progress" >> $cmd_file
        else
            echo "listitem: title: $listitem, statustext: $message, status: $state" >> $cmd_file
        fi
    fi
}
# NOTE: check minimal macOS requirement
autoload is-at-least

installedOSversion=$(sw_vers -productVersion)
if ! is-at-least 10.14 $installedOSversion; then
    printlog "Installomator requires at least macOS 10.14 Mojave." ERROR
    exit 98
fi


# MARK: argument parsing
if [[ $# -eq 0 ]]; then
    if [[ -z $label ]]; then # check if label is set inside script
        printlog "no label provided, printing labels" REQ
        grep -E '^[a-z0-9\_-]*(\)|\|\\)$' "$0" | tr -d ')|\' | grep -v -E '^(broken.*|longversion|version|valuesfromarguments)$' | sort
        #grep -E '^[a-z0-9\_-]*(\)|\|\\)$' "${labelFile}" | tr -d ')|\' | grep -v -E '^(broken.*|longversion|version|valuesfromarguments)$' | sort
        exit 0
    fi
elif [[ $1 == "/" ]]; then
    # jamf uses sends '/' as the first argument
    printlog "shifting arguments for Jamf" REQ
    shift 3
fi

# first argument is the label
label=$1

# lowercase the label
label=${label:l}

# separate check for 'version' in order to print plain version number without any other information
if [[ $label == "version" ]]; then
    echo "$VERSION"
    exit 0
fi

# MARK: reading rest of the arguments
argumentsArray=()
while [[ -n $1 ]]; do
    if [[ $1 =~ ".*\=.*" ]]; then
        # if an argument contains an = character, send it to eval
        printlog "setting variable from argument $1" INFO
        argumentsArray+=( $1 )
        eval $1
    fi
    # shift to next argument
    shift 1
done
printlog "Total items in argumentsArray: ${#argumentsArray[@]}" INFO
printlog "argumentsArray: ${argumentsArray[*]}" INFO

# NOTE: Use proxy for network access if defined
if [[ -n $PROXY ]]; then
    printlog "Proxy defined: $PROXY, testing access to it" REQ
    proxyAddress=$(echo $PROXY | cut -d ":" -f1)
    portNumber=$(echo $PROXY | cut -d ":" -f2)
    printlog "Proxy: $proxyAddress, Port: $portNumber"
    if cmdOutput=$(! nc -z -v -G 10 ${proxyAddress} ${portNumber} 2>&1) ; then
        printlog "$cmdOutput" REQ
        printlog "ERROR : No proxy connection, skipping this." REQ
    else
        printlog "Proxy access detected, so using that." REQ
        export ALL_PROXY="$PROXY"
    fi
fi

# MARK: Logging
log_location="/private/var/log/Installomator.log"

# Check if we're in debug mode, if so then set logging to DEBUG, otherwise default to INFO
# if no log level is specified.
if [[ $DEBUG -ne 0 ]]; then
    LOGGING=DEBUG
elif [[ -z $LOGGING ]]; then
    LOGGING=INFO
    datadogLoggingLevel=INFO
fi

# Associate logging levels with a numerical value so that we are able to identify what
# should be removed. For example if the LOGGING=ERROR only printlog statements with the
# level REQ and ERROR will be displayed. LOGGING=DEBUG will show all printlog statements.
# If a printlog statement has no level set it's automatically assigned INFO.

declare -A levels=(DEBUG 0 INFO 1 WARN 2 ERROR 3 REQ 4)

# If we are able to detect an MDM URL (Jamf Pro) or another identifier for a customer/instance we grab it here, this is useful if we're centrally logging multiple MDM instances.
if [[ -f /Library/Preferences/com.jamfsoftware.jamf.plist ]]; then
    mdmURL=$(defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url)
elif [[ -n "$MDMProfileName" ]]; then
    mdmURL=$(sudo profiles show | grep -A3 "$MDMProfileName" | sed -n -e 's/^.*organization: //p')
else
    mdmURL="Unknown"
fi

# Generate a session key for this run, this is useful to idenify streams when we're centrally logging.
SESSION=$RANDOM

# MARK: START
printlog "################## Start Installomator v. $VERSION, date $VERSIONDATE" REQ
printlog "################## Version: $VERSION" INFO
printlog "################## Date: $VERSIONDATE" INFO
printlog "################## $label" INFO

# Check for DEBUG mode
if [[ $DEBUG -gt 0 ]]; then
    printlog "DEBUG mode $DEBUG enabled." DEBUG
fi

# How we get version number from app
if [[ -z $versionKey ]]; then
    versionKey="CFBundleShortVersionString"
fi

# get current user
currentUser=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ { print $3 }')

# NOTE: check for root
if [[ "$(whoami)" != "root" && "$DEBUG" -eq 0 ]]; then
    # not running as root
    cleanupAndExit 6 "not running as root, exiting" ERROR
fi

# check Swift Dialog presence and version
DIALOG_CMD="/usr/local/bin/dialog"

if [[ ! -x $DIALOG_CMD ]]; then
    # Swift Dialog is not installed, clear cmd file variable to ignore
    printlog "SwiftDialog is not installed, clear cmd file var"
    DIALOG_CMD_FILE=""
fi

# MARK: labels in case statement
case $label in
longversion)
    # print the script version
    printlog "Installomater: version $VERSION ($VERSIONDATE)" REQ
    exit 0
    ;;
valuesfromarguments)
    # no action necessary, all values should be provided in arguments
    ;;

# label descriptions start here
adobecreativeclouddesktop)
    name="Adobe Creative Cloud"
    appName="Creative Cloud.app"
    type="dmg"
    if pgrep -q "Adobe Installer"; then
        cleanupAndExit 75 "Adobe Installer is running; Adobe Creative Cloud cannot be updated." WARN
    fi
    if [[ $(arch) == "arm64" ]]; then
        adobeArch="macarm64"
    else
        adobeArch="osx10"
    fi
    adobeConfig=$(curl -fsSL "https://ffc-static-cdn.oobesaas.adobe.com/init/v1/$adobeArch/ccdConfig.json") || cleanupAndExit 14 "Could not retrieve Adobe Creative Cloud update configuration." ERROR
    appNewVersion=$(getJSONValue "$(getJSONValue "$adobeConfig" ".features['feature-response']['feature-entry'].find(item => item.id == 'ccd.fw.update.greenline.latest').data")" "version")
    [[ -n "$appNewVersion" ]] || cleanupAndExit 14 "Could not determine Adobe Creative Cloud version." ERROR
    IFS='.' read -r major minor patch build <<< "$appNewVersion"
    downloadURL="https://ccmdls.adobe.com/AdobeProducts/StandaloneBuilds/ACCC/ESD/$major.$minor.$patch/$build/$adobeArch/ACCCx${appNewVersion//./_}.dmg"
    appCustomVersion() { sqlite3 "/Library/Application Support/Adobe/Adobe Desktop Common/pim.db" "SELECT value FROM pim_meta WHERE key='application_version';" 2>/dev/null; }
    targetDir="/Applications/Utilities/Adobe Creative Cloud/ACC/"
    installerTool="Install.app"
    CLIInstaller="Install.app/Contents/MacOS/Install"
    CLIArguments=(--mode=silent)
    expectedTeamID="JQ525L2MZD"
    blockingProcesses=( "Creative Cloud" )
    ;;
adobereaderdc|\
adobereaderdc-install|\
adobereaderdc-update)
    name="Adobe Acrobat Reader"
    type="pkgInDmg"
    if [[ -d "/Applications/Adobe Acrobat Reader DC.app" ]]; then
      printlog "Found /Applications/Adobe Acrobat Reader DC.app - Setting readerPath" INFO
      readerPath="/Applications/Adobe Acrobat Reader DC.app"
      name="Adobe Acrobat Reader DC"
    elif [[ -d "/Applications/Adobe Acrobat Reader.app" ]]; then
      printlog "Found /Applications/Adobe Acrobat Reader.app - Setting readerPath" INFO
      readerPath="/Applications/Adobe Acrobat Reader.app"
    fi
    if ! [[ `defaults read "$readerPath/Contents/Resources/AcroLocale.plist"` ]]; then
      printlog "Missing locale data, this will cause the updater to fail.  Deleting Adobe Acrobat Reader DC.app and installing fresh." INFO
      rm -Rf "$readerPath"
      unset $readerPath
    fi
    if [[ -n $readerPath ]]; then
      mkdir -p "/Library/Application Support/Adobe/Acrobat/11.0"
      defaults write "/Library/Application Support/Adobe/Acrobat/11.0/com.adobe.Acrobat.InstallerOverrides.plist" ReaderAppPath "$readerPath"
      defaults write "/Library/Application Support/Adobe/Acrobat/11.0/com.adobe.Acrobat.InstallerOverrides.plist" BreakIfAppPathInvalid -bool false
      printlog "Adobe Reader Installed, running updater." INFO
      adobecurrent=$(curl -sL https://armmf.adobe.com/arm-manifests/mac/AcrobatDC/reader/current_version.txt)
      adobecurrentmod="${adobecurrent//.}"
      if [[ "${adobecurrentmod}" != <-> ]]; then
        printlog "Got an invalid response for the Adobe Reader Current Version: ${adobecurrent}" ERROR
        printlog "################## End $APPLICATION \n\n" INFO
        exit 50
      fi
      if pgrep -q "Acrobat Updater"; then
        printlog "Adobe Acrobat Updater Running, killing it to avoid any conflicts" INFO
        killall "Acrobat Updater"
      fi
      downloadURL=$(echo https://ardownload2.adobe.com/pub/adobe/reader/mac/AcrobatDC/"$adobecurrentmod"/AcroRdrDCUpd"$adobecurrentmod"_MUI.dmg)
      appNewVersion="${adobecurrent}"
    else
      printlog "Changing IFS for Adobe Reader" INFO
      SAVEIFS=$IFS
      IFS=$'\n'
      versions=( $( curl -s https://www.adobe.com/devnet-docs/acrobatetk/tools/ReleaseNotesDC/index.html | grep -Eo "[0-9]+\.[0-9]+\.[0-9]+"| head -n 30) )
      local version
      for version in $versions; do
        version="${version//.}"
        printlog "trying version: $version" INFO
        local httpstatus=$(curl -X HEAD -s "https://ardownload2.adobe.com/pub/adobe/reader/mac/AcrobatDC/${version}/AcroRdrDC_${version}_MUI.dmg" --write-out "%{http_code}")
        printlog "HTTP status for Adobe Reader full installer URL https://ardownload2.adobe.com/pub/adobe/reader/mac/AcrobatDC/${version}/AcroRdrDC_${version}_MUI.dmg is $httpstatus" DEBUG
        if [[ "${httpstatus}" == "200" ]]; then
          downloadURL="https://ardownload2.adobe.com/pub/adobe/reader/mac/AcrobatDC/${version}/AcroRdrDC_${version}_MUI.dmg"
          unset httpstatus
          break
        fi
      done
      unset version
      IFS=$SAVEIFS
    fi
    updateTool="/usr/local/bin/RemoteUpdateManager"
    updateToolArguments=( --productVersions=RDR )
    updateToolLog="/Users/$currentUser/Library/Logs/RemoteUpdateManager.log"
    updateToolLogDateFormat="%m/%d/%y %H:%M:%S"
    expectedTeamID="JQ525L2MZD"
    blockingProcesses=( "Acrobat Pro DC" "AdobeAcrobat" "AdobeReader" "Distiller" )
    Company="Adobe"
    ;;
anydesk)
    name="AnyDesk"
    type="dmg"
    downloadURL="https://download.anydesk.com/anydesk.dmg"
    appNewVersion=$(curl -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.1 Safari/605.1.15" -fs "https://download.anydesk.com/changelog.txt" | grep -m1 "(macOS)" | sed -E 's/.*- ([0-9.]+) \(macOS\).*/\1/')
    expectedTeamID="KHRWM533LU"
    ;;
audacity|\
audacity3)
    name="Audacity"
    type="dmg"
    releaseData=$(curl -fsL "https://api.github.com/repos/audacity/audacity/releases?per_page=100")
    downloadURL=$(printf '%s\n' "$releaseData" | awk -F '"' '/"browser_download_url":/ && /audacity-macOS-3\.[0-9]+\.[0-9]+-universal\.dmg/ && url == "" { url=$4 } END { print url }')
    appNewVersion=$(printf '%s\n' "$downloadURL" | sed -E 's|.*/audacity-macOS-([0-9]+(\.[0-9]+)+)-universal\.dmg$|\1.0|')
    expectedTeamID="6EPAF2X3PR"
    ;;
bbedit)
    name="BBEdit"
    type="dmg"
    downloadURL=$(curl -s https://versioncheck.barebones.com/BBEdit.xml | grep dmg | sort | tail -n1 | cut -d">" -f2 | cut -d"<" -f1)
    appNewVersion=$(curl -s https://versioncheck.barebones.com/BBEdit.xml | grep dmg | sort  | tail -n1 | sed -E 's/.*BBEdit_([0-9 .]*)\.dmg.*/\1/')
    expectedTeamID="W52GZAXT98"
    ;;
beidtoken)
    name="BEIDToken"
    type="pkgInDmg"
    downloadURL="$(curl -fsL https://eid.belgium.be/en/download/16/license | grep -o 'https:\/\/eid\.belgium\.be\/sites\/default\/files\/software\/eID-Quickinstaller-[0-9/.]*dmg')"
    appNewVersion="$(echo $downloadURL | grep -o '[0-9/.]*dmg' | sed 's/....$//')"
    expectedTeamID="EU27N85PBZ"
    ;;
bitwarden)
    name="Bitwarden"
    type="dmg"
    downloadURL="https://vault.bitwarden.com/download/?app=desktop&platform=macos"
    appNewVersion=$(curl -fsIL "$downloadURL" -o /dev/null -D - | awk 'BEGIN{IGNORECASE=1}/^location:/{gsub("\r",""); print $2}' | grep '/bitwarden/clients/releases/download/desktop-v' | head -n 1 | sed -E 's|.*/desktop-v([0-9]+(\.[0-9]+)+)/.*|\1|')
    expectedTeamID="LTZ2PFU5D6"
    ;;
blender)
    name="Blender"
    type="dmg"
    versionKey="CFBundleShortVersionString"
    baseVersion=$(curl -sf https://ftp.nluug.nl/pub/graphics/blender/release/ | grep -o 'Blender[0-9]\+\.[0-9]\+' | cut -d 'r' -f 2 | sort -V | tail -1)
    if [[ $(arch) == "arm64" ]]; then
        appNewVersion=$(curl -sf https://ftp.nluug.nl/pub/graphics/blender/release/Blender$baseVersion/ | grep -o 'blender-[0-9]\+\.[0-9]\+\.[0-9]\+-macos-arm64\.dmg' | sort -V | tail -1 | sed -E 's/[^0-9]*([0-9]+\.[0-9]+\.[0-9]+).*/\1/' )
        archiveName=$(curl -sf "https://ftp.nluug.nl/pub/graphics/blender/release/Blender$baseVersion/"| grep -o 'blender-[0-9]\+\.[0-9]\+\.[0-9]\+-macos-arm64\.dmg' | sort -V | tail -1)
        downloadURL="https://ftp.nluug.nl/pub/graphics/blender/release/Blender$baseVersion/$archiveName"
    elif [[ $(arch) == "i386" ]]; then
        archiveName=$(curl -sf "https://ftp.nluug.nl/pub/graphics/blender/release/Blender4.5/" | grep -o 'blender-[0-9]\+\.[0-9]\+\.[0-9]\+-macos-x64\.dmg' | sort -V | tail -1)
        downloadURL="https://ftp.nluug.nl/pub/graphics/blender/release/Blender4.5//$archiveName"
    fi
    expectedTeamID="68UA947AUU"
    ;;
brave)
    name="Brave Browser"
    type="dmg"
    if [[ $(arch) == "arm64" ]]; then
        sparkleData=$(curl -fsL "https://updates.bravesoftware.com/sparkle/Brave-Browser/stable-arm64/appcast.xml")
    else
        sparkleData=$(curl -fsL "https://updates.bravesoftware.com/sparkle/Brave-Browser/stable/appcast.xml")
    fi
    appNewVersion=$(echo "$sparkleData" | xpath 'string((//*[local-name()="item"])[1]/enclosure/@*[local-name()="shortVersionString"])' | cut -d. -f1-3)
    downloadURL=$(echo "$sparkleData" | xpath 'string((//*[local-name()="item"])[1]/enclosure/@url)')
    appCustomVersion() { defaults read "/Applications/Brave Browser.app/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null | cut -d. -f2- }
    expectedTeamID="KL8N8XSYF4"
    ;;
caffeine)
    name="Caffeine"
    type="dmg"
    downloadURL=$(downloadURLFromGit IntelliScape caffeine)
    appNewVersion=$(versionFromGit IntelliScape caffeine)
    expectedTeamID="YD6LEYT6WZ"
    ;;
calibriteprofiler)
    name="calibrite PROFILER"
    type="dmg"
    downloadURL="$(downloadURLFromGit LUMESCA calibrite-profiler-releases)"
    appNewVersion="$(versionFromGit LUMESCA calibrite-profiler-releases)"
    expectedTeamID="5C392763F5"
    ;;
canva)
    name="Canva"
    type="dmg"
    downloadURL="https://desktop-release.canva.com/Canva-latest.dmg"
    appNewVersion=$(curl -fsL "https://desktop-release.canva.com/latest-mac.yml" | awk '/^version:/ { print $2; exit }')
    expectedTeamID="5HD2ARTBFS"
    ;;
chatgpt|\
codex)
    name="ChatGPT"
    type="zip"
    if [[ $(arch) == "arm64" ]]; then
        sparkleData=$(curl -fsL "https://persistent.oaistatic.com/codex-app-prod/appcast.xml")
        appNewVersion=$(echo "$sparkleData" | xpath 'string(//rss/channel/item[1]/sparkle:shortVersionString)')
        downloadURL=$(echo "$sparkleData" | xpath 'string(//rss/channel/item[1]/enclosure/@url)')
    else
        printlog "ChatGPT is only compatible with Apple Silicon (arm64) Macs." ERROR
        cleanupAndExit 95 "ChatGPT requires Apple Silicon" ERROR
    fi
    blockingProcesses=( "ChatGPT" )
    expectedTeamID="2DC432GLL2"
    ;;
cinema4d)
    name="Cinema 4D"
    type="dmg"
    productDownloadsPage=$(curl -fsL https://www.maxon.net/en/downloads | grep -oE '[^"]*downloads/cinema-4d[^"]*' | head -1)
    downloadURL=$(curl -fsL $productDownloadsPage | grep -oE 'https://[^"]*\.dmg' | head -1)
    appNewVersion=$(sed -E 's/.*_([0-9.]*)_Mac\.dmg/\1/g' <<< $downloadURL)
    targetDir="/Applications/Maxon Cinema 4D ${appNewVersion:0:4}"
    appCustomVersion(){
      defaults read "$targetDir/Cinema 4D.app/Contents/Info.plist" CFBundleGetInfoString | grep -Eo "202[0-9]+\.[0-9]+\.[0-9]+"
    }
    installerTool="Maxon Cinema 4D Installer.app"
    CLIInstaller="Maxon Cinema 4D Installer.app/Contents/MacOS/installbuilder.sh"
    CLIArguments=( --mode unattended --unattendedmodeui none )
    expectedTeamID="4ZY22YGXQG"
    ;;

citrixworkspace)
    name="Citrix Workspace"
    type="pkgInDmg"
    curlOptions=( --user-agent "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36" )
    parseURL() {
        urlToParse='https://www.citrix.com/downloads/workspace-app/mac/workspace-app-for-mac-latest.html'
        htmlDocument=$(curl -s -L "$urlToParse" $curlOptions)
        xmllint --html --xpath \
            "string(//a[contains(@class, 'ctx-dl-link')]/@rel)" \
            2>/dev/null <(print "$htmlDocument")
    }
    downloadURL="https:$(parseURL)"
    newVersionString() {
        urlToParse='https://www.citrix.com/downloads/workspace-app/mac/workspace-app-for-mac-latest.html'
        htmlDocument=$(curl -fs "$urlToParse" $curlOptions)
        xmllint --html --xpath \
            "string(//div[@class='ctx-dl-content']/p[starts-with(., 'Version')])" \
            2>/dev/null <(print "$htmlDocument")
    }
    appNewVersion=$(newVersionString | sed -nE 's/.*Version[[:space:]]+([0-9.]+).*/\1/p')
    versionKey="CitrixVersionString"
    expectedTeamID="S272Y5R93J"
    ;;
claudedesktop)
    name="Claude"
    type="zip"
    releaseFeed=$(curl -fsL "https://downloads.claude.ai/releases/darwin/universal/RELEASES.json")
    appNewVersion=$(getJSONValue "${releaseFeed}" "currentRelease")
    downloadURL=$(getJSONValue "${releaseFeed}" "releases[0].updateTo.url")
    expectedTeamID="Q6L2SF6YDW"
    blockingProcesses=( "Claude" "Claude Helper" )
    ;;
clickshare)
    name="ClickShare"
    type="zip"
    json_feed=$(curl -fsL "https://assets.cloud.barco.com/clickshare/release/release.mac")
    appNewVersion=$(getJSONValue "${json_feed}" 'version' | tr -d 'b' | tr "-" ".")
    file_name=$(getJSONValue "${json_feed}" 'name')
    downloadURL="https://assets.cloud.barco.com/clickshare/release/${file_name}"
    expectedTeamID="P6CDJZR997"
    ;;
connectfonts)
    name="Connect Fonts"
    type="dmg"
    downloadURL="https://links.extensis.com/connect_fonts/cf_latest?language=en&platform=mac"
    appNewVersion=$( curl -is "$downloadURL" | grep "location:" | grep -o "[[:digit:]]\+-[[:digit:]]\+-[[:digit:]]\+" | sed -e 's/-/./g' )
    expectedTeamID="J6MMHGD9D6"
    ;;
cyberduck)
    name="Cyberduck"
    type="zip"
    changeLOG="$( curl -fs https://version.cyberduck.io/changelog.rss )"
    downloadURL=$( echo "$changeLOG" | sed 's/sparkle://g' | xmllint --xpath 'string(//item/enclosure/@url)' - 2>/dev/null)
    appNewVersion=$( echo "$changeLOG" | sed 's/sparkle://g' | xmllint --xpath 'string(//item/enclosure/@shortVersionString)' - 2>/dev/null)
    expectedTeamID="G69SCX94XU"
    ;;
deepl)
    name="DeepL"
    type="dmg"
    downloadURL="https://appdownload.deepl.com/macos/$(curl -fs https://appdownload.deepl.com/macos/ | grep -o "[0-9]\+\.[0-9]\+/[0-9]\+/DeepL\.dmg" | sort -t'/' -k1,1V -k2,2n | tail -n 1)"
    appNewVersion="$(curl -fs https://appdownload.deepl.com/macos/ | grep -o "[0-9]\+\.[0-9]\+/[0-9]\+/DeepL\.dmg" | sort -t'/' -k1,1V -k2,2n | tail -n 1 | awk -F'/' '{print $1 "." $2}')"
    expectedTeamID="4N8BGCG336"
    ;;
dialog|\
swiftdialog)
    name="Dialog"
    type="pkg"
    packageID="au.csiro.dialogcli"
    downloadURL="$(downloadURLFromGit swiftDialog swiftDialog)"
    appNewVersion="$(versionFromGit swiftDialog swiftDialog)"
    expectedTeamID="PWA5E9TQ59"
    ;;
discord)
    name="Discord"
    type="dmg"
    downloadURL="https://discordapp.com/api/download?platform=osx"
    appNewVersion="$(curl -fsL -o /dev/null -w %{url_effective} "${downloadURL}" | awk -F'/' '{print $(NF-1)}')"
    expectedTeamID="53Q6R32WPB"
    ;;
drawio)
    name="draw.io"
    type="dmg"
    archiveName="draw.io-universal-[0-9.]*.dmg"
    downloadURL="$(downloadURLFromGit jgraph drawio-desktop)"
    appNewVersion="$(versionFromGit jgraph drawio-desktop)"
    expectedTeamID="UZEUFB4N53"
    blockingProcesses=( draw.io )
    ;;
dropbox)
    name="Dropbox"
    type="dmg"
    # Handling differens on Apple Silicon and Intel arch
    if [[ $(arch) = "arm64" ]]; then
        printlog "Architecture: arm64"
        downloadURL="https://www.dropbox.com/download?plat=mac&full=1&arch=arm64"
    else
        printlog "Architecture: i386 (not arm64)"
        downloadURL="https://www.dropbox.com/download?plat=mac&full=1"
    fi
    appNewVersion=$(curl -fsIL "$downloadURL" | grep -i "^location" | sed -E 's/.*%20([0-9.]*)\.[arm64.]*dmg/\1/g' | tr -d '[:cntrl:]' )
    expectedTeamID="G7HH3F8CAK"
    ;;
easyfind)
    name="EasyFind"
    type="zip"
    downloadURL="$(curl -fs "https://www.devontechnologies.com/apps/freeware" | grep -o "http.*download.*.zip" | grep -i easyfind)"
    appNewVersion="$(echo $downloadURL | sed -E 's/.*\/([0-9.]*)\/.*/\1/g')"
    expectedTeamID="679S2QUWR8"
    ;;
eidviewer)
    name="eID Viewer"
    type="dmg"
    downloadURL="$(curl -fsL https://eid.belgium.be/en/download/22/license | grep -o 'https:\/\/eid\.belgium\.be\/sites\/default\/files\/software\/eID%20Viewer-[0-9/.]*dmg')"
    appNewVersion="$(echo $downloadURL | grep -o '[0-9/.]*dmg' | sed 's/....$//')"
    expectedTeamID="EU27N85PBZ"
    ;;elgatostreamdeck)
    name="Elgato Stream Deck"
    type="pkg"
    # packageID="com.elgato.StreamDeck"
	downloadURL="https://gc-updates.elgato.com/mac/sd-update/final/download-website.php"
    appNewVersion=$(curl -fsI "https://gc-updates.elgato.com/mac/sd-update/final/download-website.php" | grep -i ^location | sed -E 's/.*Stream_Deck_([0-9.]*).pkg/\1/g' | sed 's/\.[^.]*//3')
    expectedTeamID="Y93VXCB8Q5"
    blockingProcesses=( "Stream Deck" )
    ;;
figma)
    name="Figma"
    type="zip"
    if [[ $(arch) == "arm64" ]]; then
        downloadURL="https://desktop.figma.com/mac-arm/Figma.zip"
    elif [[ $(arch) == "i386" ]]; then
        downloadURL="https://desktop.figma.com/mac/Figma.zip"
    fi
    appNewVersion="$(getJSONValue "$(curl -fs https://desktop.figma.com/mac/RELEASE.json)" "version")"
    expectedTeamID="T8RA8NE3B7"
    ;;
filemakerpro)
    name="FileMaker Pro"
    type="dmg"
    versionKey="BuildVersion"
    downloadURL=$(curl -fs https://www.filemaker.com/redirects/ss.txt | grep '\"PRO..MAC\"' | tail -1 | sed "s|.*url\":\"\(.*\)\".*|\\1|")
    appNewVersion=$(curl -fs https://www.filemaker.com/redirects/ss.txt | grep '\"PRO..MAC\"' | tail -1 | sed "s|.*fmp_\(.*\).dmg.*|\\1|")
    expectedTeamID="J6K4T76U7W"
    ;;
firefoxpkg)
    name="Firefox"
    type="pkg"
    downloadURL="https://download.mozilla.org/?product=firefox-pkg-latest-ssl&os=osx&lang=en-US"
    firefoxVersions=$(curl -fs "https://product-details.mozilla.org/1.0/firefox_versions.json")
    appNewVersion=$(getJSONValue "$firefoxVersions" "LATEST_FIREFOX_VERSION")
    expectedTeamID="43AQ936H96"
    blockingProcesses=( firefox )
    ;;
gimp)
    name="GIMP"
    type="dmg"
    if [[ $(arch) == "arm64" ]]; then
        downloadURL=https://$(curl -fs https://www.gimp.org/downloads/ | grep -m 1 -o "download.*gimp-.*-arm64.dmg")
    elif [[ $(arch) == "i386" ]]; then
        downloadURL=https://$(curl -fs https://www.gimp.org/downloads/ | grep -m 1 -o "download.*gimp-.*-x86_64.dmg")
    fi
    appNewVersion=$(echo $downloadURL | cut -d "-" -f 2)
    expectedTeamID="T25BQ8HSJF"
    ;;
githubdesktop)
    name="GitHub Desktop"
    type="zip"
    if [[ $(arch) == "arm64" ]]; then
        downloadURL="https://central.github.com/deployments/desktop/desktop/latest/darwin-arm64"
    elif [[ $(arch) == "i386" ]]; then
        downloadURL="https://central.github.com/deployments/desktop/desktop/latest/darwin"
    fi
    appNewVersion=$(curl -fsL https://central.github.com/deployments/desktop/desktop/changelog.json | awk -F '{' '/"version"/ { print $2 }' | sed -E 's/.*,\"version\":\"([0-9.]*)\".*/\1/g')
    expectedTeamID="VEKTX9H2N7"
    ;;
gitkraken)
    name="GitKraken"
    type="zip"
    if [[ $(arch) == "arm64" ]]; then
        gitkrakenFeed="https://release.gitkraken.com/darwin-arm64/RELEASES?v=12.0.0&darwin=27.0.0"
    else
        gitkrakenFeed="https://release.gitkraken.com/darwin/RELEASES?v=12.0.0&darwin=27.0.0"
    fi
    gitkrakenJSON=$(curl -fsL "$gitkrakenFeed")
    appNewVersion=$(getJSONValue "$gitkrakenJSON" "name")
    downloadURL=$(getJSONValue "$gitkrakenJSON" "url")
    expectedTeamID="T7QVVUTZQ8"
    ;;
googlechromepkg)
    name="Google Chrome"
    type="pkg"
    #
    # Note: this url acknowledges that you accept the terms of service
    # https://support.google.com/chrome/a/answer/9915669
    #
    downloadURL="https://dl.google.com/chrome/mac/stable/accept_tos%3Dhttps%253A%252F%252Fwww.google.com%252Fintl%252Fen_ph%252Fchrome%252Fterms%252F%26_and_accept_tos%3Dhttps%253A%252F%252Fpolicies.google.com%252Fterms/googlechrome.pkg"
    appNewVersion=$(getJSONValue "$(curl -fsL "https://versionhistory.googleapis.com/v1/chrome/platforms/mac/channels/stable/versions/all/releases?filter=fraction%3E0.01,endtime=none&order_by=version%20desc" )" "releases[0].version" )
    expectedTeamID="EQHXZ8M8AV"
    updateTool="/Library/Google/GoogleSoftwareUpdate/GoogleSoftwareUpdate.bundle/Contents/Resources/GoogleSoftwareUpdateAgent.app/Contents/MacOS/GoogleSoftwareUpdateAgent"
    updateToolArguments=( -runMode oneshot -userInitiated YES )
    updateToolRunAsCurrentUser=1
    ;;
googledrive|\
googledrivefilestream)
    name="Google Drive"
    type="pkgInDmg"
    appNewVersion=$(curl -fsL "https://community.chocolatey.org/api/v2/Packages()?%24filter=Id%20eq%20%27googledrive%27%20and%20IsLatestVersion" | xmllint --xpath 'string(//*[local-name()="Version"])' - 2>/dev/null)
    downloadURL="https://dl.google.com/drive-file-stream/GoogleDrive.dmg"
    blockingProcesses=( "Google Docs" "Google Drive" "Google Sheets" "Google Slides" )
    versionKey="CFBundleVersion"
    expectedTeamID="EQHXZ8M8AV"
    ;;
googleearth)
    name="Google Earth Pro"
    type="pkgInDmg"
    appNewVersion=$(curl -fsL "https://www.google.com/earth/about/versions/\#download-pro" | grep -oi "<strong>version [0-9\.]*" | grep -o "[0-9\.]*")
    downloadURL="https://dl.google.com/earth/client/advanced/current/GoogleEarthProMac-Intel.dmg"
    expectedTeamID="EQHXZ8M8AV"
    ;;
gotomeeting)
    # credit: @matins
    name="GoToMeeting"
    type="dmg"
    downloadURL="https://link.gotomeeting.com/latest-dmg"
    expectedTeamID="GFNFVT632V"
    ;;
gpgsuite)
    name="GPG Suite"
    type="pkgInDmg"
    pkgName="Install.pkg"
    downloadURL=$(curl -fsL "https://gpgtools.org/" | grep -oE 'https://releases\.gpgtools\.com/[^"]*GPG_Suite-[^"]*\.dmg' | head -n 1)
    appNewVersion=$(sed -E 's#^.*/GPG_Suite-([^/]+)\.dmg$#\1#' <<< "$downloadURL")
    appCustomVersion(){ /usr/bin/defaults read "/Library/Application Support/GPGTools/version.plist" CFBundleVersion; }
    blockingProcesses=( NONE )
    expectedTeamID="PKV8ZPD836"
    ;;handbrake)
    name="HandBrake"
    type="dmg"
    downloadURL=$(downloadURLFromGit HandBrake HandBrake )
    appNewVersion=$(versionFromGit HandBrake HandBrake )
    expectedTeamID="5X9DE89KYV"
    ;;
imazingprofileeditor)
    # Credit: Bilal Habib @Pro4TLZZ
    name="iMazing Profile Editor"
    type="dmg"
    downloadURL="https://downloads.imazing.com/mac/iMazing-Profile-Editor/iMazingProfileEditorMac.dmg"
    appNewVersion=$(curl -s https://imazing.com/profile-editor/download | grep -2 'Version' | head -4 | sed -nE 's/.*<b>([0-9\.]+)<\/b>.*/\1/p' )
    expectedTeamID="J5PR93692Y"
    ;;
inkscape)
    name="Inkscape"
    type="dmg"
    appCustomVersion() { /Applications/Inkscape.app/Contents/MacOS/inkscape --version | cut -d " " -f2 }
    appNewVersion=$(curl -fsL https://inkscape.org/release/  | grep "<title>" | grep -o -e "[0-9.]*")
    if [[ $(arch) == arm64 ]]; then
        downloadURL="https://media.inkscape.org/dl/resources/file/$(curl -fsL https://inkscape.org/release/inkscape-{$appNewVersion}/mac-os-x/dmg-arm64/dl/ | grep -o -m1 "Inkscape-.*.dmg")"
    elif [[ $(arch) == i386 ]]; then
        downloadURL="https://media.inkscape.org/dl/resources/file/$(curl -fsL https://inkscape.org/release/inkscape-{$appNewVersion}/mac-os-x/dmg/dl/ | grep -o -m1 "Inkscape-.*.dmg")"
    fi
    expectedTeamID="SW3D6BB6A6"
    ;;
iterm2)
    name="iTerm"
    type="zip"
    downloadURL="https://iterm2.com/downloads/stable/latest"
    appNewVersion=$(curl -is https://iterm2.com/downloads/stable/latest | grep location: | grep -o "iTerm2.*zip" | cut -d "-" -f 2 | cut -d '.' -f1 | sed 's/_/./g')
    expectedTeamID="H7V7XYVQ7D"
    blockingProcesses=( "iTerm" "iTerm2" )
    ;;
jetbrainsintellijidea|\
jetbrainsintellijideace|\
intellijideace)
    name="IntelliJ IDEA"
    type="dmg"
    jetbrainscode="II"
    if [[ $(arch) == i386 ]]; then
        jetbrainsdistribution="mac"
    elif [[ $(arch) == arm64 ]]; then
        jetbrainsdistribution="macM1"
    fi
    blockingProcesses=( "idea" )
    downloadURL="https://download.jetbrains.com/product?code=${jetbrainscode}&latest&distribution=${jetbrainsdistribution}"
    appNewVersion=$( curl -fsIL "${downloadURL}" | grep -i "location" | tail -1 | sed -E 's/.*-([0-9.]+)[-.].*/\1/g' )
    expectedTeamID="2ZEFAR8TH3"
    ;;
jetbrainspycharm|\
jetbrainspycharmce|\
pycharmce)
    name="PyCharm"
    type="dmg"
    jetbrainscode="PCP"
    if [[ $(arch) == arm64 ]]; then
        jetbrainsdistribution="macM1"
    else
        jetbrainsdistribution="mac"
    fi
    downloadURL="https://download.jetbrains.com/product?code=${jetbrainscode}&latest&distribution=${jetbrainsdistribution}"
    appNewVersion=$( curl -fsIL "${downloadURL}" | grep -i "^location" | tail -1 | sed -E 's/\?.*//;s/.*-([0-9.]+)[-.].*/\1/' )
    expectedTeamID="2ZEFAR8TH3"
    ;;
jre8)
    name="Java Runtime Environment 8"
    type="pkgInDmg"
    versionKey="CFBundleVersion"
    sparkleData=$(curl -fs "$(curl -fs "https://javadl-esd-secure.oracle.com/update/mac/map-mac-1.8.0.xml" | xmllint --xpath 'string((//java-update-map/mapping/url[not(contains(., "-cb.xml"))])[last()])' -)")
    appNewVersion=$(echo "$sparkleData" | xmllint --xpath 'string((//*[local-name()="enclosure"]/@*[local-name()="version"])[last()])' -)
    appBuildVersion=$(echo "$appNewVersion" | cut -d. -f3)
    downloadURL=$(echo "$sparkleData" | xmllint --xpath 'string((//*[local-name()="enclosure"]/@url)[last()])' -)
    pkgName="Java 8 Update ${appBuildVersion}.app/Contents/Resources/JavaAppletPlugin.pkg"
    appCustomVersion(){ defaults read "/Library/Internet Plug-Ins/JavaAppletPlugin.plugin/Contents/Info.plist" "${versionKey}" 2>/dev/null }
    expectedTeamID="VB5E2TV963"
    blockingProcesses=( NONE )
    ;;
keka)
    name="Keka"
    type="dmg"
    downloadURL=$(downloadURLFromGit aonez Keka)
    appNewVersion=$(versionFromGit aonez Keka)
    expectedTeamID="4FG648TM2A"
    ;;
lastpass)
    name="LastPass"
    type="dmg"
    downloadURL="https://download.cloud.lastpass.com/mac/LastPass.dmg"
    appNewVersion="$(curl -fs "https://download.cloud.lastpass.com/mac/AppCast.xml" | xpath 'string(//rss/channel/item/title)' 2>/dev/null)"
    expectedTeamID="N24REP3BMN"
    ;;
logitechoptionsplus)
    name="Logi Options+"
    appName="logioptionsplus_installer.app"
    type="zip"
    osMajorVersion=$(sw_vers -productVersion | awk -F "." '{print $1}')
    osVersion=$(sw_vers -productVersion | awk -F "." '{if ($1 == "10") print $1"."$2; else print $1".0"}')
    if [[ "$osMajorVersion" -lt 11 ]]; then
        printlog "Logi Options+ download could not be safely verified for this macOS version." ERROR
        cleanupAndExit 95 "Logi Options+ requires a verified macOS 11 or later download" ERROR
    fi
    appNewVersion="$(curl -fs "https://support.logi.com/api/v2/help_center/en-us/articles.json?label_names=webcontent=productdownload,webos=mac-macos-x-${osVersion}" | sed $'s/},{"id"/}\\\n{"id"/g' | awk -F '"body":"' 'index($0, "\"title\":\"Logi Options+\"") {print $2; exit}' | sed 's/\\n/ /g;s/<[^>]*>//g;s/\\"/"/g' | grep -oE 'Software Version: *[0-9]+([.][0-9]+)+' | head -1 | grep -oE '[0-9]+([.][0-9]+)+')"
    if [[ "$osMajorVersion" -ge 14 ]]; then
        downloadURL="https://download01.logi.com/web/ftp/pub/techsupport/optionsplus/logioptionsplus_installer.zip"
    else
        downloadURL="https://download01.logi.com/web/ftp/pub/techsupport/optionsplus/logioptionsplus_installer_${appNewVersion}.zip"
    fi
    CLIInstaller="logioptionsplus_installer.app/Contents/MacOS/logioptionsplus_installer"
    CLIArguments=(--quiet)
    appCustomVersion(){ if [[ -f "/Applications/logioptionsplus.app/Contents/Info.plist" ]]; then /usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "/Applications/logioptionsplus.app/Contents/Info.plist" 2>/dev/null; fi; }
    versionKey="CFBundleVersion"
    expectedTeamID="QED4VVPZWA"
    ;;
lucidlink)
    name="LucidLink"
    type="pkg"
    downloadURL="https://www.lucidlink.com/download/new-ll-latest/macos/stable"
    appNewVersion=$(curl -fsIL -H "Referer: https://www.lucidlink.com/download/new-ll-latest/macos/stable" "$downloadURL" | awk 'BEGIN{IGNORECASE=1}/^location:/{gsub("\r",""); print $2}' | tail -n 1 | sed -E 's|.*/lucidlink-([0-9]+(\.[0-9]+)+)\.pkg$|\1|')
    expectedTeamID="Y4KMJPU2B4"
    ;;
maxonapp)
    name="Maxon"
    type="zip"
    versionKey="CFBundleShortVersionString"
    appNewVersion="$(curl -s "https://packages.maxon.net/manifests?platform=macos&org=maxon&type=products&family=fuse" | tr '{' '\n' | tr ',' '\n' | tr '}' '\n' | grep "version" | awk -F'"' '{print $4}' | sort -Vr | head -n 1)"
    downloadURL="https://mx-app-blob-prod.maxon.net/mx-package-production/installer/macos/maxon/maxonapp/releases/${appNewVersion}/Maxon_App_${appNewVersion}_Mac.zip"
    installerTool="Maxon_App_${appNewVersion}_Mac.app"
    CLIInstaller="Maxon_App_${appNewVersion}_Mac.app/Contents/MacOS/installbuilder.sh"
    CLIArguments=(--mode unattended --unattendedmodeui none)
    expectedTeamID="4ZY22YGXQG"
    ;;
microsoft365copilot)
    name="Microsoft 365 Copilot"
    type="pkg"
    downloadURL="https://go.microsoft.com/fwlink/?linkid=2325438"
    versionKey="CFBundleVersion"
    appNewVersion=$(curl -fsIL "$downloadURL" | grep -i location: | grep -o "/Microsoft_365_Copilot.*pkg" | sed -E 's/.*_([0-9]+\.[0-9]+\.[0-9]+)_.*\.pkg/\1/')
    expectedTeamID="UBF8T346G9"
    if [[ -x "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" && $INSTALL != "force" ]]; then
        printlog "Running msupdate --list"
        "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" --list
    fi
    updateTool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
    updateToolArguments=( --install --apps MSCP10 )
    ;;
microsoftautoupdate)
    name="Microsoft AutoUpdate"
    type="pkg"
    downloadURL="https://go.microsoft.com/fwlink/?linkid=830196"
    versionKey="CFBundleVersion"
    appNewVersion=$(curl -fsIL "$downloadURL" | grep -i location: | grep -o "Microsoft_AutoUpdate.*pkg" | sed -E 's/[a-zA-Z_]*_([0-9.]*)_.*/\1/g')
    expectedTeamID="UBF8T346G9"
    # commented the updatetool for MSAutoupdate, because when Autoupdate is really
    # old or broken, you want to force a new install
    #updateTool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
    #updateToolArguments=( --install --apps MSau04 )
    ;;
microsoftcompanyportal)
    name="Company Portal"
    type="pkg"
    MAUSource="https://res.public.onecdn.static.microsoft/mro1cdnstorage/C1297A47-86C4-4C1F-97FA-950631F94777/MacAutoupdate/0409IMCP01.xml"
    downloadURL=$(curl -fsL $MAUSource | xmllint --xpath '//array/dict[1]/key[text()="Location"]/following-sibling::string[1]/text()' - | sed 's/-Upgrade/-Installer/' 2>/dev/null)
    appNewVersion=$(curl -fsL $MAUSource | xmllint --xpath '//array/dict[1]/key[text()="Update Version"]/following-sibling::string[1]/text()' - 2>/dev/null)
    expectedTeamID="UBF8T346G9"
    versionKey="CFBundleVersion"
    if [[ -x "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" && $INSTALL != "force" && $DEBUG -eq 0 ]]; then
        printlog "Running msupdate --list"
        "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" --list
    fi
    updateTool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
    updateToolArguments=( --install --apps IMCP01 )
    ;;
microsoftdefender|\
microsoftdefenderatp)
    name="Microsoft Defender"
    type="pkg"
    MAUSource="https://res.public.onecdn.static.microsoft/mro1cdnstorage/C1297A47-86C4-4C1F-97FA-950631F94777/MacAutoupdate/0409WDAV00.xml"
    downloadURL=$(curl -fsL $MAUSource | xmllint --xpath '//array/dict[1]/key[text()="Location"]/following-sibling::string[1]/text()' - | sed 's/-upgrade//' 2>/dev/null)
    appNewVersion=$(curl -fsL $MAUSource | xmllint --xpath '//array/dict[1]/key[text()="Update Version"]/following-sibling::string[1]/text()' - 2>/dev/null)
    expectedTeamID="UBF8T346G9"
    if [[ -x "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" && $INSTALL != "force" && $DEBUG -eq 0 ]]; then
        printlog "Running msupdate --list"
        "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" --list
    fi
    updateTool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
    updateToolArguments=( --install --apps WDAV00 )
    ;;
microsoftedge|\
microsoftedgeconsumerstable|\
microsoftedgeenterprisestable)
    name="Microsoft Edge"
    type="pkg"
    downloadURL="https://go.microsoft.com/fwlink/?linkid=2093504"
    appNewVersion=$(curl -fsIL "$downloadURL" | grep -i location: | grep -o "/MicrosoftEdge.*pkg" | sed -E 's/.*\/[a-zA-Z]*-([0-9.]*)\..*/\1/g')
    expectedTeamID="UBF8T346G9"
    ;;
    
microsoftexcel)
    name="Microsoft Excel"
    type="pkg"
    MAUSource="https://res.public.onecdn.static.microsoft/mro1cdnstorage/C1297A47-86C4-4C1F-97FA-950631F94777/MacAutoupdate/0409XCEL2019.xml"
    downloadURL=$(curl -fsL $MAUSource | xmllint --xpath '//array/dict[1]/key[text()="FullUpdaterLocation"]/following-sibling::string[1]/text()' - | sed 's/_Updater/_Installer/' 2>/dev/null)
    appNewVersion=$(curl -fsL $MAUSource | xmllint --xpath '//array/dict[1]/key[text()="Update Version"]/following-sibling::string[1]/text()' - 2>/dev/null)
    expectedTeamID="UBF8T346G9"
    versionKey="CFBundleVersion"
    if [[ -x "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" && $INSTALL != "force" && $DEBUG -eq 0 ]]; then
        printlog "Running msupdate --list"
        "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" --list
    fi
    blockingProcesses=( "Microsoft Excel" )
    updateTool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
    updateToolArguments=( --install --apps XCEL2019 )
    ;;
microsoftonedrive)
    name="OneDrive"
    type="pkg"
    downloadURL=$(curl -fsL https://raw.githubusercontent.com/cocopuff2u/MOFA/refs/heads/main/latest_raw_files/macos_standalone_onedrive_all.xml | grep full_update_download | head -1 | grep -o https://oneclient.sfx.ms/Mac/Installers/\[0-9.]\*/universal/OneDrive.pkg)
    appNewVersion=$(print $downloadURL | grep -o '[0-9.]\{5,\}' | cut -d "." -f 1-3)
    expectedTeamID="UBF8T346G9"
    ;;
microsoftonenote)
    name="Microsoft OneNote"
    type="pkg"
    MAUSource="https://res.public.onecdn.static.microsoft/mro1cdnstorage/C1297A47-86C4-4C1F-97FA-950631F94777/MacAutoupdate/0409ONMC2019.xml"
    downloadURL=$(curl -fsL $MAUSource | xmllint --xpath '//array/dict[1]/key[text()="FullUpdaterLocation"]/following-sibling::string[1]/text()' - 2>/dev/null)
    appNewVersion=$(curl -fsL $MAUSource | xmllint --xpath '//array/dict[1]/key[text()="Update Version"]/following-sibling::string[1]/text()' - 2>/dev/null)
    expectedTeamID="UBF8T346G9"
    versionKey="CFBundleVersion"
    if [[ -x "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" && $INSTALL != "force" && $DEBUG -eq 0 ]]; then
        printlog "Running msupdate --list"
        "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" --list
    fi
    blockingProcesses=( "Microsoft OneNote" )
    updateTool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
    updateToolArguments=( --install --apps ONMC2019 )
    ;;
microsoftoutlook)
    name="Microsoft Outlook"
    type="pkg"
    MAUSource="https://res.public.onecdn.static.microsoft/mro1cdnstorage/C1297A47-86C4-4C1F-97FA-950631F94777/MacAutoupdate/0409OPIM2019.xml"
    downloadURL=$(curl -fsL $MAUSource | xmllint --xpath '//array/dict[1]/key[text()="FullUpdaterLocation"]/following-sibling::string[1]/text()' - | sed 's/_Updater/_Installer/' 2>/dev/null)
    appNewVersion=$(curl -fsL $MAUSource | xmllint --xpath '//array/dict[1]/key[text()="Update Version"]/following-sibling::string[1]/text()' - 2>/dev/null)
    expectedTeamID="UBF8T346G9"
    versionKey="CFBundleVersion"
    if [[ -x "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" && $INSTALL != "force" && $DEBUG -eq 0 ]]; then
        printlog "Running msupdate --list"
        "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" --list
    fi
    blockingProcesses=( "Microsoft Outlook" )
    updateTool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
    updateToolArguments=( --install --apps OPIM2019 )
    ;;
microsoftpowerpoint)
    name="Microsoft PowerPoint"
    type="pkg"
    MAUSource="https://res.public.onecdn.static.microsoft/mro1cdnstorage/C1297A47-86C4-4C1F-97FA-950631F94777/MacAutoupdate/0409PPT32019.xml"
    downloadURL=$(curl -fsL $MAUSource | xmllint --xpath '//array/dict[1]/key[text()="FullUpdaterLocation"]/following-sibling::string[1]/text()' - | sed 's/_Updater/_Installer/' 2>/dev/null)
    appNewVersion=$(curl -fsL $MAUSource | xmllint --xpath '//array/dict[1]/key[text()="Update Version"]/following-sibling::string[1]/text()' - 2>/dev/null)
    expectedTeamID="UBF8T346G9"
    versionKey="CFBundleVersion"
    if [[ -x "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" && $INSTALL != "force" && $DEBUG -eq 0 ]]; then
        printlog "Running msupdate --list"
        "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" --list
    fi
    blockingProcesses=( "Microsoft PowerPoint" )
    updateTool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
    updateToolArguments=( --install --apps PPT32019 )
    ;;
microsoftteams|\
microsoftteamsnew)
    name="Microsoft Teams"
    type="pkg"
    MAUSource="https://res.public.onecdn.static.microsoft/mro1cdnstorage/C1297A47-86C4-4C1F-97FA-950631F94777/MacAutoupdate/0409TEAMS21.xml"
    mauXML=$(curl -fsL "$MAUSource")
    appNewVersion=$(printf '%s' "$mauXML" | xmllint --xpath 'string((//dict[key[text()="Application ID"]/following-sibling::string[1]="TEAMS21" and key[text()="Location"]/following-sibling::string[1][contains(.,"/MicrosoftTeams.pkg")]]/key[text()="Update Version"]/following-sibling::string[1])[1])' - 2>/dev/null)
    downloadURL=$(printf '%s' "$mauXML" | xmllint --xpath 'string((//dict[key[text()="Application ID"]/following-sibling::string[1]="TEAMS21" and key[text()="Location"]/following-sibling::string[1][contains(.,"/MicrosoftTeams.pkg")]]/key[text()="Location"]/following-sibling::string[1])[1])' - 2>/dev/null)
    expectedTeamID="UBF8T346G9"
    blockingProcesses=( MSTeams "Microsoft Teams" "Microsoft Teams WebView" "Microsoft Teams Launcher" "Microsoft Teams (work preview)")
    if [[ -x "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" && $INSTALL != "force" && $DEBUG -eq 0 ]]; then
        printlog "Running msupdate --list"
        "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" --list
    fi
    updateTool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
    updateToolArguments=( --install --apps TEAMS21 )
    ;;
microsoftvisualstudiocode|\
visualstudiocode)
    name="Visual Studio Code"
    type="zip"
    appNewVersion=$(curl -fsL "https://update.code.visualstudio.com/api/releases/stable" | plutil -extract 0 raw -o - -)
    downloadURL="https://update.code.visualstudio.com/latest/darwin-universal/stable"
    expectedTeamID="UBF8T346G9"
    blockingProcesses=( Code )
    ;;
microsoftwindowsapp|\
microsoftremotedesktop)
    name="Windows App"
    type="pkg"
    MAUSource="https://res.public.onecdn.static.microsoft/mro1cdnstorage/C1297A47-86C4-4C1F-97FA-950631F94777/MacAutoupdate/0409MSRD10.xml"
    downloadURL=$(curl -fsL $MAUSource | xmllint --xpath '//array/dict[1]/key[text()="Location"]/following-sibling::string[1]/text()' - | sed 's/_updater/_installer/' 2>/dev/null)
    appNewVersion=$(curl -fsL $MAUSource | xmllint --xpath '//array/dict[1]/key[text()="Title"]/following-sibling::string[1]/text()' - | grep -oE '[\.0-9]*' 2>/dev/null)
    expectedTeamID="UBF8T346G9"
    if [[ -x "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" && $INSTALL != "force" && $DEBUG -eq 0 ]]; then
        printlog "Running msupdate --list"
        "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" --list
    fi
    updateTool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
    updateToolArguments=( --install --apps MSRD10 )
    ;;
microsoftword)
    name="Microsoft Word"
    type="pkg"
    MAUSource="https://res.public.onecdn.static.microsoft/mro1cdnstorage/C1297A47-86C4-4C1F-97FA-950631F94777/MacAutoupdate/0409MSWD2019.xml"
    downloadURL=$(curl -fsL $MAUSource | xmllint --xpath '//array/dict[1]/key[text()="FullUpdaterLocation"]/following-sibling::string[1]/text()' - | sed 's/_Updater/_Installer/' 2>/dev/null)
    appNewVersion=$(curl -fsL $MAUSource | xmllint --xpath '//array/dict[1]/key[text()="Update Version"]/following-sibling::string[1]/text()' - 2>/dev/null)
    expectedTeamID="UBF8T346G9"
    versionKey="CFBundleVersion"
    if [[ -x "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" && $INSTALL != "force" ]]; then
        printlog "Running msupdate --list"
        "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" --list
    fi
    blockingProcesses=( "Microsoft Word" )
    updateTool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
    updateToolArguments=( --install --apps MSWD2019 )
    ;;
miro)
    # credit: @matins
    name="Miro"
    type="dmg"
    if [[ $(arch) == arm64 ]]; then
        downloadURL="https://desktop.miro.com/platforms/darwin-arm64/Install-Miro.dmg"
    elif [[ $(arch) == i386 ]]; then
        downloadURL="https://desktop.miro.com/platforms/darwin/Install-Miro.dmg"
    fi
    expectedTeamID="M3GM7MFY7U"
    ;;
nextcloud)
    name="Nextcloud"
    type="pkg"
    archiveName="Nextcloud-[0-9.]+\.pkg"
    downloadURL=$(downloadURLFromGit nextcloud-releases desktop)
    appNewVersion=$(versionFromGit nextcloud-releases desktop)
    expectedTeamID="NKUJUXUJ3B"
    ;;
nodejs)
    name="nodejs"
    type="pkg"
    packageID="org.nodejs.node.pkg"
    appNewVersion=$(getJSONValue "$(curl -fsL https://nodejs.org/dist/index.json)" "[0].version")
    downloadURL="https://nodejs.org/dist/${appNewVersion}/node-${appNewVersion}.pkg"
    expectedTeamID="HX7739G8FX"
    blockingProcesses=( NONE )
    ;;
nudge)
    name="Nudge App"
    type="pkg"
    archiveName="Nudge-[0-9.]*.pkg"
    packageID="com.github.macadmins.Nudge"
    downloadURL=$(downloadURLFromGit macadmins Nudge )
    appNewVersion=$(versionFromGit macadmins Nudge )
    expectedTeamID="T4SK8ZXCXG"
    ;;
obs)
    name="OBS"
    appName="OBS.app"
    type="dmg"
    if [[ $(arch) == "arm64" ]]; then
        archiveName="OBS-Studio-[0-9.]*-macOS-Apple.dmg"
    elif [[ $(arch) == "i386" ]]; then
        archiveName="OBS-Studio-[0-9.]*-macOS-Intel.dmg"
    fi
    downloadURL=$(downloadURLFromGit obsproject obs-studio )
    appNewVersion=$(versionFromGit obsproject obs-studio )
    expectedTeamID="2MMRE5MTB8"
    ;;
onyx)
    name="OnyX"
    type="dmg"
    osVersion="${installedOSversion%%.*}"
    if [[ "$(arch)" == "i386" && "$osVersion" -ge 27 ]]; then
        printlog "OnyX for macOS ${osVersion} requires Apple Silicon (arm64)." ERROR
        cleanupAndExit 95 "OnyX requires Apple Silicon on macOS ${osVersion}" ERROR
    else
        downloadURL="https://www.titanium-software.fr/download/$osVersion/OnyX.dmg"
    fi
    appNewVersion=$(curl -fs https://www.titanium-software.fr/en/onyx.html | sed -nE "s/.*OnyX ([0-9]+([.][0-9]+)+) for macOS [A-Za-z ]+ ${osVersion}[^0-9].*/\\1/p" | head -1)
    expectedTeamID="T49MRBL8UL"
    ;;
pcoipclient)
    name="PCoIPClient"
    type="dmg"
    pcoipClientInfo=$(curl -fsL "https://dl.anyware.hp.com/ztqM7i47Dt06ETYM/pcoip-client/raw/names/pcoip-client-info/versions/dmg/pcoip-client-dmg-info.json")
    appNewVersion=$(getJSONValue "$pcoipClientInfo" "[0].currentVersion")
    downloadURL="https://dl.anyware.hp.com/pcoip-client/raw/names/pcoip-client-dmg/versions/${appNewVersion}/pcoip-client_${appNewVersion}.dmg"
    expectedTeamID="RU4LW7W32C"
    ;;
pgadmin4)
    name="pgAdmin 4"
    type="dmg"
    downloadParent="https://www.postgresql.org/ftp/pgadmin/pgadmin4/"
    appNewVersion=$(curl -fs "${downloadParent}" | grep -oE 'v[0-9]+.[0-9]+' | sort -V | tail -n 1 | sed 's/v//g')
    if [[ "$(arch)" == "arm64" ]]; then
        downloadURL="https://ftp.postgresql.org/pub/pgadmin/pgadmin4/v$appNewVersion/macos/pgadmin4-$appNewVersion-arm64.dmg"
    else
        downloadURL="https://ftp.postgresql.org/pub/pgadmin/pgadmin4/v$appNewVersion/macos/pgadmin4-$appNewVersion-x86_64.dmg"
    fi
    expectedTeamID="TCHGL2R7C5"
    ;;
postman)
    name="Postman"
    type="zip"
    curlOptions=( -H "accept-encoding: gzip, deflate, br")
    if [[ $(arch) == "arm64" ]]; then
        downloadURL="https://dl.pstmn.io/download/latest/osx_arm64"
    elif [[ $(arch) == "i386" ]]; then
        downloadURL="https://dl.pstmn.io/download/latest/osx_64"
    fi
    appNewVersion=$(getJSONValue "$(curl -fsL 'https://mkt.cdn.postman.com/www-next/release-notes/app-release-notes.json')" 'notes[0].version')
    expectedTeamID="H7H8Q7M5CK"
    ;;
privileges2)
    # credit: Matt Adams (@d3xbot)
    name="Privileges"
    type="pkg"
    packageID="corp.sap.privileges.pkg"
    downloadURL="$(downloadURLFromGit SAP macOS-enterprise-privileges)"
    appNewVersion="$(versionFromGit SAP macOS-enterprise-privileges)"
    expectedTeamID="7R5ZEU67FQ"
    ;;
python)
    name="Python"
    type="pkg"
    pageContent=$(curl -fsL --compressed "https://www.python.org/downloads/macos/")
    appNewVersion=$(echo "$pageContent" | grep -oE 'Latest Python 3 Release - Python [0-9]+\.[0-9]+\.[0-9]+' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1)
    shortVersion=$(echo "$appNewVersion" | cut -d "." -f1,2)
    archiveName="python-${appNewVersion}-macos11.pkg"
    downloadURL="https://www.python.org/ftp/python/$appNewVersion/$archiveName"
    appCustomVersion(){ /usr/bin/defaults read "/Library/Frameworks/Python.framework/Versions/$shortVersion/Resources/Python.app/Contents/Info" CFBundleVersion 2>/dev/null; }
    expectedTeamID="BMM5U3QVKW"
    blockingProcesses=( "IDLE" "Python Launcher" )
    ;;
r)
    name="R"
    type="pkg"
    if [[ $(arch) == "arm64" ]]; then
        downloadURL="https://cloud.r-project.org/bin/macosx/$( curl -fsL https://cloud.r-project.org/bin/macosx/ | grep -m 1 -o '<a href=".*arm64\.pkg">' | sed -E 's/.+"(.+)".+/\1/g' )"
        appNewVersion=$(echo "${downloadURL}" | sed -E 's/.*\/[a-zA-Z]*-([0-9.]*)-.*\..*/\1/g')
    elif [[ $(arch) == "i386" ]]; then
        downloadURL="https://cloud.r-project.org/bin/macosx/$( curl -fsL https://cloud.r-project.org/bin/macosx/ | grep -o '<a href=".*pkg">' | grep -m 1 -v "arm64" | sed -E 's/.+"(.+)".+/\1/g' )"
        appNewVersion=$(echo "${downloadURL}" | sed -E 's/.*\/[a-zA-Z]*-([0-9.]*)\..*/\1/g')
    fi
    expectedTeamID="VZLD955F6P"
    appCustomVersion() { defaults read /Applications/r.app/Contents/Info.plist CFBundleShortVersionString | awk '{print $2}' }
    ;;
rapidapi)
    name="RapidAPI"
    type="zip"
    downloadURL="https://paw.cloud/download"
    appNewVersion="$(curl -fsIL ${downloadURL} | grep -i ^location | cut -d '/' -f5 | awk -F '-' '{ print $2 }')"
    expectedTeamID="84599RL58A"
    ;;
rodecentral)
    name="RODE Central"
    type="pkgInZip"
    downloadURL="https://update.rode.com/central/RODE_Central_MACOS.zip"
    appNewVersion=$(curl -fLs https://rode.com/en/release-notes/rode-central | grep -oE "Version [0-9].[0-9].[0-9.]*" | awk '{print$2}' | sort --version-sort | tail -1)
    expectedTeamID="Z9T72PWTJA"
    ;;
rstudio)
    name="RStudio"
    type="dmg"
    downloadURL="https://rstudio.org/download/latest/stable/desktop/mac/RStudio-latest.dmg"
    finalURL=$(curl -fsLI -o /dev/null -w "%{url_effective}" "$downloadURL")
    appNewVersion=$(echo "$finalURL" | grep -oE '[0-9]{4}\.[0-9]{2}\.[0-9]{1,2}\-[0-9]+' | sed 's/-/+/')
    expectedTeamID="FYF2F5GFX4"
    ;;
signal)
    name="Signal"
    type="dmg"
    downloadURL=https://updates.signal.org/desktop/$(curl -fs https://updates.signal.org/desktop/latest-mac.yml | awk '/url/ && /dmg/ {print $3}' | grep -i universal)
    appNewVersion=$(curl -fs https://updates.signal.org/desktop/latest-mac.yml | grep version | awk '{print $2}')
    expectedTeamID="U68MSDN6DR"
    ;;
slack)
    name="Slack"
    type="pkg"
    downloadURL="https://slack.com/api/desktop.latestRelease?redirect=1&variant=pkg&arch=universal"
    appNewVersion=$( curl -fsIL "${downloadURL}" | grep -i "^location" | cut -d "/" -f7 )
    expectedTeamID="BQR82RBBHL"
    ;;
spotify)
    name="Spotify"
    type="dmg"
    tmpSpotifyDir=$(mktemp -d)
    zipSpotifyPath="$tmpSpotifyDir/SpotifyInstaller.zip"
    curl -fsSL "https://download.scdn.co/SpotifyInstaller.zip" -o "$zipSpotifyPath"
    unzip -q "$zipSpotifyPath" -d "$tmpSpotifyDir"
    appNewVersion=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$tmpSpotifyDir/Install Spotify.app/Contents/Info.plist")
    rm -rf "$tmpSpotifyDir"
    if [[ $(arch) == arm64 ]]; then
        downloadURL="https://download.scdn.co/SpotifyARM64.dmg"
    elif [[ $(arch) == i386 ]]; then
        downloadURL="https://download.scdn.co/Spotify.dmg"
    fi
    expectedTeamID="2FNC3A47ZF"
    ;;
sqldeveloper|\
oraclesqldeveloper)
    name="SQLDeveloper"
    type="zip"
    if [[ "$(arch)" == "arm64" ]]; then
        downloadURL=$(curl -fsL https://www.oracle.com/database/sqldeveloper/technologies/download/ | grep -Eo 'https://download\.oracle\.com/otn_software/java/sqldeveloper/sqldeveloper-[0-9\.]*-macos-aarch64\.app\.zip' | head -1)
    else
        printlog "Oracle SQL Developer is only available for Apple Silicon (arm64) Macs." ERROR
        cleanupAndExit 95 "Oracle SQL Developer requires Apple Silicon" ERROR
    fi
    versionKey="CFBundleVersion"
    appNewVersion=$(echo "$downloadURL" | awk -F - '{print $2}' | cut -d . -f 1-4)
    expectedTeamID="VB5E2TV963"
    ;;
teamviewer)
    name="TeamViewer"
    type="pkg"
    teamViewerFeed=$(curl -fsL "https://download.teamviewer.com/download/update/macupdates.xml?lang=en&version=15.00.0&os=macos&osversion=27.0&type=1&channel=1")
    downloadURL=$(echo "$teamViewerFeed" | xpath 'string((//rss/channel/item/enclosure[@teamviewer:module="full"][@teamviewer:kind="pkg"])[1]/@url)' 2>/dev/null)
    appNewVersion=$(echo "$teamViewerFeed" | xpath 'string((//rss/channel/item/enclosure[@teamviewer:module="full"][@teamviewer:kind="pkg"])[1]/@sparkle:version)' 2>/dev/null)
    expectedTeamID="H7UGFBUGV6"
    ;;teamviewerqsallington)
    name="TeamViewerQS"
    type="zip"
    teamviewerCustomDownloadURL="https://get.teamviewer.com/bp3qnrz"
    teamviewerConfigID=$(curl -fs ${teamviewerCustomDownloadURL} -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36' | grep -o 'var configId = ".*"' | awk -F'"' '{ print $2 }')
    teamviewerVersion=$(curl -fs ${teamviewerCustomDownloadURL} -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36' | grep -o 'var version = ".*"' | awk -F'"' '{ print $2 }')
    downloadURL=$(curl -fs -X POST --url "https://get.teamviewer.com/api/CustomDesign" --header 'Content-Type: application/json; charset=utf-8' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36' --data '{ "ConfigId": "'"$teamviewerConfigID"'", "Version": "'"$teamviewerVersion"'", "IsCustomModule": true, "Subdomain": "1", "ConnectionId": "" }' | tr -d '"')
    appNewVersion=$(curl -fs "https://www.teamviewer.com/en/download/macos/" | grep 'data-json' | grep 'full' | awk -F '"' '{ print $4 }' | sed 's/&quot;/"/g' | plutil -extract "data.0.versionNumber" raw -o - -)
    appName="TeamViewerQS.app"
    expectedTeamID="H7UGFBUGV6"
    ;;
textmate)
    name="TextMate"
    type="tbz"
    #downloadURL="https://api.textmate.org/downloads/release?os=10.12"
    downloadURL=$(downloadURLFromGit "textmate" "textmate")
    appNewVersion=$(versionFromGit "textmate" "textmate")
    expectedTeamID="45TL96F76G"
    ;;
theunarchiver)
    name="The Unarchiver"
    type="dmg"
    downloadURL="https://dl.devmate.com/com.macpaw.site.theunarchiver/TheUnarchiver.dmg"
    appNewVersion="$(curl -fs "https://theunarchiver.com" | grep -i "Latest version" | head -1 | sed -E 's/.*> ([0-9.]*) .*/\1/g')"
    expectedTeamID="S8EX82NJP6"
    ;;
thunderbird)
    name="Thunderbird"
    type="dmg"
    versionKey="CFBundleShortVersionString"
    downloadURL=$(curl -fsIL "https://download.mozilla.org/?product=thunderbird-latest&os=osx&lang=en-US" | grep -i "^location:" | tail -1 | awk '{ print $2 }' | tr -d '\r')
    appNewVersion=$(echo "$downloadURL" | sed -E 's|.*/releases/([^/]+)/mac/.*|\1|')
    expectedTeamID="43AQ936H96"
    ;;
thunderbirdesr)
    name="Thunderbird"
    type="dmg"
    versionKey="CFBundleShortVersionString"
    downloadURL=$(curl -fsIL "https://download.mozilla.org/?product=thunderbird-esr-latest&os=osx&lang=en-US" | grep -i "^location:" | tail -1 | awk '{ print $2 }' | tr -d '\r')
    appNewVersion=$(echo "$downloadURL" | sed -E 's|.*/releases/([^/]+)esr/mac/.*|\1|')
    expectedTeamID="43AQ936H96"
    ;;
ultimakercura)
    name="Ultimaker Cura"
    type="dmg"
    if [[ $(arch) == "arm64" ]]; then
        archiveName="UltiMaker-Cura-[0-9.]*-macos-ARM64.dmg"
    elif [[ $(arch) == "i386" ]]; then
        archiveName="UltiMaker-Cura-[0-9.]*-macos-X64.dmg"
    fi
    downloadURL="$(downloadURLFromGit Ultimaker Cura)"
    appNewVersion=$(versionFromGit Ultimaker Cura )
    expectedTeamID="V4B3JXRRQS"
    ;;
virtualboxlatest)
    name="VirtualBox"
    type="pkgInDmg"
    pkgName="VirtualBox.pkg"
    appNewVersion=$(curl -fs "https://download.virtualbox.org/virtualbox/LATEST.TXT")
    if [[ $(arch) == "arm64" ]]; then
        downloadURL="https://download.virtualbox.org/virtualbox/${appNewVersion}/$(curl -fs "https://download.virtualbox.org/virtualbox/${appNewVersion}/" | grep "macOSArm64" | cut -d\" -f2)"
    elif [[ $(arch) == "i386" ]]; then
        downloadURL="https://download.virtualbox.org/virtualbox/${appNewVersion}/$(curl -fs "https://download.virtualbox.org/virtualbox/${appNewVersion}/" | grep "OSX.dmg" | cut -d\" -f2)"
    fi
    expectedTeamID="VB5E2TV963"
    ;;
vlc)
    # VLC is a versatile, open-source multimedia player that supports a wide range of audio, video, and streaming formats across multiple platforms
    name="VLC"
    type="dmg"
    appNewVersion=$(curl -s https://www.videolan.org/vlc/#download | xmllint --html --xpath "//script[contains(text(),'var PLATFORMS')]" - 2>/dev/null | grep -o '"osx":{"name":"macOS[^}]*' | grep -o '"latestVersion":"[^"]*' | sed 's/"latestVersion":"//')
    downloadURL="https://get.videolan.org/vlc/$appNewVersion/macosx/vlc-$appNewVersion-universal.dmg"
    expectedTeamID="75GAHG3SZQ"
    ;;
wacomdrivers)
    name="Wacom Center"
    type="pkgInDmg"
    downloadURL="$(curl -fs -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36" https://www.wacom.com/en-us/support/product-support/drivers | grep -e "drivers/mac/professional.*dmg" | head -1 | tr '"' "\n" | grep -i http)"
    expectedTeamID="EG27766DY7"
    appNewVersion="$(curl -fs -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36" https://www.wacom.com/en-us/support/product-support/drivers | grep mac/professional/releasenotes | head -1 | tr '"' "\n" | grep -e "Driver [0-9][-0-9.]*" | sed -E 's/Driver ([-0-9.]*).*/\1/g')"
    ;;
whatsapp)
    name="WhatsApp"
    type="dmg"
    downloadURL="https://web.whatsapp.com/desktop/mac_native/release/?configuration=Release"
    appNewVersion=$(curl -fsLIXGET "https://web.whatsapp.com/desktop/mac_native/release/?configuration=Release" | grep -i "^location" | grep -m 1 -o "WhatsApp-.*dmg" | sed 's/.*WhatsApp-2.//g' | sed 's/.dmg//g')
    expectedTeamID="57T9237FN3"
    ;;
zoom)
    name="zoom.us"
    type="pkg"
    downloadURL="https://zoom.us/client/latest/ZoomInstallerIT.pkg"
    appNewVersion="$(curl -fsIL ${downloadURL} | grep -i ^location | cut -d "/" -f5)"
    expectedTeamID="BJ4HAAB9B3"
    versionKey="CFBundleVersion"
    ;;
*)
    # unknown label
    #printlog "unknown label $label"
    cleanupAndExit 1 "EXIT: unknown label $label" ERROR
    ;;
esac

logcode="LOGANALYZER :"

# MARK: reading arguments again
printlog "Reading arguments again: ${argumentsArray[*]}" INFO
for argument in "${argumentsArray[@]}"; do
    printlog "argument: $argument" DEBUG
    eval $argument
done

# verify we have everything we need
if [[ -z $name ]]; then
    printlog "need to provide 'name'" ERROR
    exit 1
fi
if [[ -z $type ]]; then
    printlog "need to provide 'type'" ERROR
    exit 1
fi
if [[ -z $downloadURL ]]; then
    printlog "need to provide 'downloadURL'" ERROR
    exit 1
fi
if [[ -z $expectedTeamID ]]; then
    printlog "need to provide 'expectedTeamID'" ERROR
    exit 1
fi

# Are we only asked to return label name
if [[ $RETURN_LABEL_NAME -eq 1 ]]; then
    printlog "Only returning label name." REQ
    printlog "$name"
    echo "$name"
    exit
fi

# MARK: application download and installation starts here

# Debug output of all variables in a label
printlog "name=${name}" DEBUG
printlog "appName=${appName}" DEBUG
printlog "type=${type}" DEBUG
printlog "archiveName=${archiveName}" DEBUG
printlog "downloadURL=${downloadURL}" DEBUG
printlog "curlOptions=${curlOptions}" DEBUG
printlog "appNewVersion=${appNewVersion}" DEBUG
printlog "appCustomVersion function: $(if type 'appCustomVersion' 2>/dev/null | grep -q 'function'; then echo "Defined. ${appCustomVersion}"; else; echo "Not defined"; fi)" DEBUG
printlog "versionKey=${versionKey}" DEBUG
printlog "packageID=${packageID}" DEBUG
printlog "pkgName=${pkgName}" DEBUG
printlog "choiceChangesXML=${choiceChangesXML}" DEBUG
printlog "expectedTeamID=${expectedTeamID}" DEBUG
printlog "blockingProcesses=${blockingProcesses}" DEBUG
printlog "installerTool=${installerTool}" DEBUG
printlog "CLIInstaller=${CLIInstaller}" DEBUG
printlog "CLIArguments=${CLIArguments}" DEBUG
printlog "updateTool=${updateTool}" DEBUG
printlog "updateToolArguments=${updateToolArguments}" DEBUG
printlog "updateToolRunAsCurrentUser=${updateToolRunAsCurrentUser}" DEBUG
#printlog "Company=${Company}" DEBUG # Not used

# NOTE: Do not disturb active display sleep assertion
if [[ ${INTERRUPT_DND} = "no" ]]; then
    # Check if a fullscreen app is active
    if hasDisplaySleepAssertion; then
        cleanupAndExit 24 "$logcode active display sleep assertion detected, aborting" ERROR
    fi
fi

printlog "BLOCKING_PROCESS_ACTION=${BLOCKING_PROCESS_ACTION}"
printlog "NOTIFY=${NOTIFY}"
printlog "LOGGING=${LOGGING}"

# NOTE: Finding LOGO to use in dialogs
case $LOGO in
    appstore)
        # Apple App Store on Mac
        if [[ $(sw_vers -buildVersion) > "19" ]]; then
            LOGO="/System/Applications/App Store.app/Contents/Resources/AppIcon.icns"
        else
            LOGO="/Applications/App Store.app/Contents/Resources/AppIcon.icns"
        fi
        ;;
    jamf)
        # Jamf Pro
        LOGO="/Library/Application Support/JAMF/Jamf.app/Contents/Resources/AppIcon.icns"
        ;;
    mosyleb)
        # Mosyle Business
        LOGO="/Applications/Self-Service.app/Contents/Resources/AppIcon.icns"
        if [[ -z $MDMProfileName ]]; then; MDMProfileName="Mosyle Corporation MDM"; fi
        ;;
    mosylem)
        # Mosyle Manager (education)
        LOGO="/Applications/Manager.app/Contents/Resources/AppIcon.icns"
        if [[ -z $MDMProfileName ]]; then; MDMProfileName="Mosyle Corporation MDM"; fi
        ;;
    addigy)
        # Addigy
        LOGO="/Library/Addigy/macmanage/MacManage.app/Contents/Resources/atom.icns"
        if [[ -z $MDMProfileName ]]; then; MDMProfileName="MDM Profile"; fi
        ;;
    microsoft)
        # Microsoft Endpoint Manager (Intune)
        if [[ -d "/Library/Intune/Microsoft Intune Agent.app" ]]; then
            LOGO="/Library/Intune/Microsoft Intune Agent.app/Contents/Resources/AppIcon.icns"
        elif [[ -d "/Applications/Company Portal.app" ]]; then
            LOGO="/Applications/Company Portal.app/Contents/Resources/AppIcon.icns"
        fi
        if [[ -z $MDMProfileName ]]; then; MDMProfileName="Management Profile"; fi
        ;;
    ws1)
        # Workspace ONE (AirWatch)
        LOGO="/Applications/Workspace ONE Intelligent Hub.app/Contents/Resources/AppIcon.icns"
        if [[ -z $MDMProfileName ]]; then; MDMProfileName="Device Manager"; fi
        ;;
    kandji)
        # Kandji
        LOGO="/Applications/Kandji Self Service.app/Contents/Resources/AppIcon.icns"
        if [[ -z $MDMProfileName ]]; then; MDMProfileName="MDM Profile"; fi
        ;;
    filewave)
        # FileWave
        LOGO="/usr/local/sbin/FileWave.app/Contents/Resources/fwGUI.app/Contents/Resources/kiosk.icns"
        if [[ -z $MDMProfileName ]]; then; MDMProfileName="FileWave MDM Configuration"; fi
        ;;
esac
if [[ ! -a "${LOGO}" ]]; then
    if [[ $(sw_vers -buildVersion) > "19" ]]; then
        LOGO="/System/Applications/App Store.app/Contents/Resources/AppIcon.icns"
    else
        LOGO="/Applications/App Store.app/Contents/Resources/AppIcon.icns"
    fi
fi
printlog "LOGO=${LOGO}" INFO

printlog "Label type: $type" INFO

# NOTE: extract info from data
if [ -z "$archiveName" ]; then
    case $type in
        dmg|pkg|zip|tbz|bz2)
            archiveName="${name}.$type"
            ;;
        pkgInDmg)
            archiveName="${name}.dmg"
            ;;
        *InZip)
            archiveName="${name}.zip"
            ;;
        updateronly)
            ;;
        *)
            printlog "Cannot handle type $type"
            cleanupAndExit 99
            ;;
    esac
fi
printlog "archiveName: $archiveName" INFO

if [ -z "$appName" ]; then
    # when not given derive from name
    appName="$name.app"
fi

if [ -z "$targetDir" ]; then
    case $type in
        dmg|zip|tbz|bz2|app*)
            targetDir="/Applications"
            ;;
        pkg*)
            targetDir="/"
            ;;
        updateronly)
            ;;
        *)
            cleanupAndExit 99 "$logcode Cannot handle type $type" ERROR
            ;;
    esac
fi

if [[ -z $blockingProcesses ]]; then
    printlog "no blocking processes defined, using $name as default" INFO
    blockingProcesses=( $name )
fi

# MARK: determine tmp dir
if [ "$DEBUG" -eq 1 ]; then
    # for debugging use script dir as working directory
    tmpDir=$(dirname "$0")
else
    # create temporary working directory
    tmpDir=$(mktemp -d )
fi

# NOTE: change directory to temporary working directory
printlog "Changing directory to $tmpDir" DEBUG
if ! cd "$tmpDir"; then
    cleanupAndExit 13 "$logcode error changing directory $tmpDir" ERROR
fi

# MARK: get installed version
getAppVersion
printlog "appversion: $appversion"

# NOTE: Exit if new version is the same or older as installed version (appNewVersion specified)
if [[ "$type" != "updateronly" && ($INSTALL == "force" || $IGNORE_APP_STORE_APPS == "yes") ]]; then
    printlog "Label is not of type “updateronly”, and it’s set to use force to install or ignoring app store apps, so not using updateTool."
    updateTool=""
fi
if [[ -n $appNewVersion ]]; then
    printlog "Latest version of $name is $appNewVersion"

    if [[ -n $appversion ]] && is-at-least $appNewVersion $appversion; then
        if [[ $DEBUG -ne 1 ]]; then
            printlog "There is no newer version available."
            if [[ $INSTALL != "force" ]]; then
                message="$name, version $appNewVersion, is the latest version."
                if [[ $currentUser != "loginwindow" && $NOTIFY == "all" ]]; then
                    printlog "notifying"
                    displaynotification "$message" "No update for $name!"
                fi
                if [[ $DIALOG_CMD_FILE != "" ]]; then
                    updateDialog "complete" "Latest version already installed..."
                    sleep 2
                fi
                if [[ $appNewVersion == $appversion ]]; then
                    cleanupAndExit 0 "$logcode No newer version. $appNewVersion is the same as $appversion." REQ
                else
                    cleanupAndExit 0 "$logcode No newer version. $appNewVersion is older than $appversion" REQ
                fi
            fi
        else
            printlog "DEBUG mode 1 enabled, not exiting, but there is no new version of app." WARN
        fi
    fi
else
    printlog "Latest version not specified."
fi

# MARK: check if this is an Update and we can use updateTool
if [[ (-n $appversion && -n "$updateTool") || "$type" == "updateronly" ]]; then
    printlog "App needs to be updated and uses $updateTool. Ignoring BLOCKING_PROCESS_ACTION and running updateTool now."
    updateDialog "wait" "Updating..."

    if [[ $DEBUG -ne 1 ]]; then
        if runUpdateTool; then
            finishing
            cleanupAndExit 0 "$logcode updateTool has run" REQ
        elif [[ $type == "updateronly" ]];then
            cleanupAndExit 0 "$logcode type is $type so we end here." REQ
        fi # otherwise continue
    else
        printlog "DEBUG mode 1 enabled, not running update tool" WARN
    fi
fi

# MARK: download the archive
if [ -f "$archiveName" ] && [ "$DEBUG" -eq 1 ]; then
    printlog "$archiveName exists and DEBUG mode 1 enabled, skipping download"
else
    # download
    printlog "Downloading $downloadURL to $archiveName" REQ
    if [[ $currentUser != "loginwindow" && $NOTIFY == "all" ]]; then
        printlog "notifying"
        if [[ $updateDetected == "YES" ]]; then
            displaynotification "Downloading $name update" "Download in progress …"
        else
            displaynotification "Downloading new $name" "Download in progress …"
        fi
    fi

    if [[ $DIALOG_CMD_FILE != "" ]]; then
        # pipe
        pipe="$tmpDir/downloadpipe"
        # initialise named pipe for curl output
        initNamedPipe create $pipe

        # run the pipe read in the background
        readDownloadPipe $pipe "$DIALOG_CMD_FILE" & downloadPipePID=$!
        printlog "listening to output of curl with pipe $pipe and command file $DIALOG_CMD_FILE on PID $downloadPipePID" DEBUG

        curlDownload=$(curl -fL -# --show-error ${curlOptions} "$downloadURL" -o "$archiveName" 2>&1 | tee $pipe)
        # because we are tee-ing the output, we want the pipe status of the first command in the chain, not the most recent one
        curlDownloadStatus=$(echo $pipestatus[1])
        killProcess $downloadPipePID

    else
        printlog "No Dialog connection, just download" DEBUG
        curlDownload=$(curl -v -fsL --show-error ${curlOptions} "$downloadURL" -o "$archiveName" 2>&1)
        curlDownloadStatus=$(echo $?)
    fi

    # Trying to detect proxy or web filter on downloaded file
    archiveSHA=$(shasum "$archiveName" | cut -w -f 1)
    archiveSize=$(du -k "$archiveName" | cut -w -f 1)
    archiveType=$(file "$archiveName" | cut -d ':' -f2 )
    printlog "Downloaded $archiveName – Type is $archiveType – SHA is $archiveSHA – Size is $archiveSize kB" INFO

    # Trying to detect download errors, including proxy or web filter blocking on downloaded file
    if [[ $curlDownloadStatus -ne 0 || $archiveType == *ASCII* ]]; then
        printlog "error downloading $downloadURL" ERROR
        message="$name update/installation failed. This will be logged, so IT can follow up."
        if [[ $currentUser != "loginwindow" && $NOTIFY == "all" ]]; then
            printlog "notifying"
            if [[ $updateDetected == "YES" ]]; then
                displaynotification "$message" "Error updating $name"
            else
                displaynotification "$message" "Error installing $name"
            fi
        fi
        if [[ $archiveType == *ASCII* ]]; then
            firstLines=$(head -c 51170 $archiveName)
            deduplicatelogs $firstLines
            cleanupAndExit 2 "$logcode File Downloaded is ASCII, we’re probably being blocked by a proxy or filter.  First 5k of file is:\n$logoutput" ERROR
        else
            deduplicatelogs "$curlDownload"
            cleanupAndExit 2 "$logcode Error downloading $downloadURL error:\n$logoutput" ERROR
        fi
    fi
fi

# MARK: when user is logged in, and app is running, prompt user to quit app
if [[ $BLOCKING_PROCESS_ACTION == "ignore" ]]; then
    printlog "ignoring blocking processes"
else
    if [[ $currentUser != "loginwindow" ]]; then
        if [[ ${#blockingProcesses} -gt 0 ]]; then
            if [[ ${blockingProcesses[1]} != "NONE" ]]; then
                checkRunningProcesses
            fi
        fi
    fi
fi

# MARK: install the download
printlog "Installing $name" REQ
if [[ $currentUser != "loginwindow" && $NOTIFY == "all" ]]; then
    printlog "notifying"
    if [[ $updateDetected == "YES" ]]; then
        displaynotification "Updating $name" "Installation in progress …"
        updateDialog "wait" "Updating..."
    else
        displaynotification "Installing $name" "Installation in progress …"
        updateDialog "wait" "Installing..."
    fi
fi

if [ -n "$installerTool" ]; then
    # installerTool defined, and we use that for installation
    printlog "installerTool used: $installerTool" REQ
    appName="$installerTool"
fi

case $type in
    dmg)
        installFromDMG
        ;;
    pkg)
        installFromPKG
        ;;
    zip)
        installFromZIP
        ;;
    tbz|bz2)
        installFromTBZ
        ;;
    pkgInDmg)
        installPkgInDmg
        ;;
    pkgInZip)
        installPkgInZip
        ;;
    *InDmgInZip)
        installItemInDmgInZip
        ;;
    *)
        cleanupAndExit 99 "$logcode Cannot handle type $type" ERROR
        ;;
esac

updateDialog "wait" "Finishing..."

# MARK: Finishing — print installed application location and version
finishing

# all done!
cleanupAndExit 0 "All done!" REQ
