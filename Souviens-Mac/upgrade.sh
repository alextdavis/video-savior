#!/bin/sh

#  upgrade.sh
#  Souviens-Mac
#
#  Created by Alex Davis on 3/3/18.
#  Copyright © 2018 Alex T. Davis. All rights reserved.

echo 'Souviens is checking for updates...'

brew update
brew upgrade --cleanup youtube-dl ffmpeg

echo 'Souviens is done. Press return to close. '
read
