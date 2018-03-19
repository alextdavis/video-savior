#!/bin/sh

#  Install.sh
#  Souviens-Mac
#
#  Created by Alex Davis on 3/2/18.
#  Copyright © 2018 Alex T. Davis. All rights reserved.

if command -v brew >/dev/null 2>&1; then
    echo "brew already installed"
else
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

brew update

if command -v youtube-dl >/dev/null 2>&1; then
    brew upgrade --cleanup youtube-dl
else
    brew install youtube-dl ffmpeg
fi

if command -v ffmpeg >/dev/null 2>&1; then
    brew upgrade --cleanup ffmpeg
else
    brew install ffmpeg
fi


if command -v ffmpeg >/dev/null 2>&1; then
    if command -v ffmpeg >/dev/null 2>&1; then
        echo "\n\n\033[32mSuccess:\033[0m Components needed for Souviens are installed and up to date. \nPlease close this window. "
        exit
    fi
fi

echo "\n\n\033[31mError:\033[0m Components needed for Souviens have failed to install. \nPlease read any error messages above. \nIf you need help troubleshooting, visit http://souviens.alextdavis.me/help#brew. \nPress return to close. "
read
