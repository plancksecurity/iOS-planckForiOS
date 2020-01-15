#!/bin/bash

translationdir=../pEp-Translate/

# Imports translations, using a temporary directory in order to not change
# original files.
# Param 1: The project (pEpForiOS.xcodeproj or MessageModel/MessageModel.xcodeproj)
# Param 2: The source directory ($translationdir or $translationdir/MessageModel)
function import() {
    mytmpdir=`mktemp -d 2>/dev/null || mktemp -d -t 'mytmpdir'`

    cp $2/*.xliff $mytmpdir
    sed -i '' 's/<target\/>//' $mytmpdir/*.xliff

    for filename in $mytmpdir/*.xliff; do
        xcodebuild -importLocalizations -verbose -project $1 -localizationPath $filename
    done

    rm -fr $mytmpdir
}

import pEpForiOS.xcodeproj $translationdir
import MessageModel/MessageModel.xcodeproj $translationdir/MessageModel

echo
echo ! Verify the changes in pEpForiOS and MessageModel and commit !
echo