eidviewer)
    name="eID Viewer"
    type="dmg"
    downloadURL="$(curl -fsL https://eid.belgium.be/en/download/22/license | grep -o 'https:\/\/eid\.belgium\.be\/sites\/default\/files\/software\/eID%20Viewer-[0-9/.]*dmg')"
    appNewVersion="$(echo $downloadURL | grep -o '[0-9/.]*dmg' | sed 's/....$//')"
    expectedTeamID="EU27N85PBZ"
    ;;