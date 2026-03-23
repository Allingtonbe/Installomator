microsoftonedrive)
    name="OneDrive"
    type="pkg"
    downloadURL=$(curl -fsL https://raw.githubusercontent.com/cocopuff2u/MOFA/refs/heads/main/latest_raw_files/macos_standalone_onedrive_all.xml | grep full_update_download | head -1 | grep -o https://oneclient.sfx.ms/Mac/Installers/\[0-9.]\*/universal/OneDrive.pkg)
    appNewVersion=$(print $downloadURL | grep -o '[0-9.]\{5,\}' | cut -d "." -f 1-3)
    expectedTeamID="UBF8T346G9"
    ;;
