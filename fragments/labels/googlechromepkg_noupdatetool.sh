googlechromepkg_noupdatetool)
    name="Google Chrome"
    type="pkg"
    downloadURL="https://dl.google.com/chrome/mac/stable/accept_tos%3Dhttps%253A%252F%252Fwww.google.com%252Fintl%252Fen_ph%252Fchrome%252Fterms%252F%26_and_accept_tos%3Dhttps%253A%252F%252Fpolicies.google.com%252Fterms/googlechrome.pkg"
    appNewVersion=$(curl -s https://omahaproxy.appspot.com/history | awk -F',' '/mac_arm64,stable/{print $3; exit}')
    expectedTeamID="EQHXZ8M8AV"
    ;;
