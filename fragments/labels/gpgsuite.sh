gpgsuite)
    name="GPG Suite"
    type="pkgInDmg"
    pkgName="Install.pkg"
    downloadURL=$(curl -fsL "https://gpgtools.org/" | grep -oE 'https://releases\.gpgtools\.com/[^"]*GPG_Suite-[^"]*\.dmg' | head -n 1)
    appNewVersion=$(sed -E 's#^.*/GPG_Suite-([^/]+)\.dmg$#\1#' <<< "$downloadURL")
    appCustomVersion(){ /usr/bin/defaults read "/Library/Application Support/GPGTools/version.plist" CFBundleVersion; }
    blockingProcesses=( NONE )
    expectedTeamID="PKV8ZPD836"
    ;;