microsoftoutlook)
    name="Microsoft Outlook"
    type="pkg"
    downloadURL=$(curl -fsL "https://learn.microsoft.com/en-us/officeupdates/update-history-office-for-mac" | grep -Eo "https:\/\/officecdn.microsoft.com\/pr\/.*\/MacAutoupdate\/Microsoft_Outlook_.*_Updater.pkg" | head -1)
    versionKey="CFBundleVersion"
    appNewVersion=$(echo $downloadURL | cut -d "/" -f 7 | cut -d "_" -f 3)
    expectedTeamID="UBF8T346G9"
    if [[ -x "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" && $INSTALL != "force" && $DEBUG -eq 0 ]]; then
        printlog "Running msupdate --list"
        "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" --list
    fi
    updateTool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
    updateToolArguments=( --install --apps OPIM2019 )
    ;;