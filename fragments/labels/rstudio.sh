rstudio)
    name="RStudio"
    type="dmg"
    downloadURL=$(curl -s -L "https://live-rstudio.pantheonsite.io/download/rstudio-desktop/?posit_iframe=1&initialWidth=1216&childId=rstudio-desktop&parentTitle=Download%20RStudio%20Desktop%20%7C%20Open%20Source%20IDE%20for%20R%20%26%20Python&parentUrl=https%3A%2F%2Fposit.co%2Fdownload%2Frstudio-desktop" | grep -m 1 -Eio 'href="https://download1.rstudio.org/electron/macos/RStudio-(.*).dmg"' | cut -c7- | sed -e 's/"$//')
    appNewVersion=$(curl -sfI "$downloadURL" | grep -i "^location" | grep -oE '[0-9]{4}\.[0-9]{2}\.[0-9]{1,2}\-[0-9]+' | sed 's/-/+/')
    expectedTeamID="FYF2F5GFX4"
    ;;
