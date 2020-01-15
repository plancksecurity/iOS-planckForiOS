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

# Imports translations in place, that is, it may change original files.
# Param 1: The project (pEpForiOS.xcodeproj or MessageModel/MessageModel.xcodeproj)
# Param 2: The source directory ($translationdir or $translationdir/MessageModel)
function import_in_place() {
    for filename in $2/*.xliff; do
        sed -i '' 's/<target\/>//' $filename
        xcodebuild -importLocalizations -verbose -project $1 -localizationPath $filename
    done
}

import_in_place pEpForiOS.xcodeproj $translationdir
import_in_place MessageModel/MessageModel.xcodeproj $translationdir/MessageModel

echo
echo ! Beware of changes in $translationdir. Veryfy !
echo ! Verify the changes in pEpForiOS and MessageModel and commit !
echo