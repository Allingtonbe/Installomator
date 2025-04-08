microsoftoutlook)
    name="Microsoft Outlook"
    type="pkg"
    downloadURL="https://go.microsoft.com/fwlink/?linkid=525137"
    versionKey="CFBundleVersion"
    appNewVersion=$(curl -fsIL "$downloadURL" | grep -i location: | grep -o "/Microsoft_.*pkg" | cut -d "_" -f 3)
    expectedTeamID="UBF8T346G9"
    if [[ -x "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" && $INSTALL != "force" && $DEBUG -eq 0 ]]; then
        printlog "Running msupdate --list"
        "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" --list
    fi
    updateTool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
    updateToolArguments=( --install --apps OPIM2019 )
    ;;
