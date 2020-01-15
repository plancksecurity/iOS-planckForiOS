#!/bin/bash

translationdir=../pEp-Translate/

# Imports translations, using a temporary directory in order to not change
# original files.
# Param 1: The project (pEpForiOS.xcodeproj or MessageModel/MessageModel.xcodeproj)
# Param 2: The source directory ($translationdir or $translationdir/MessageModel)
function import() {
    echo \*\*\* import $1 $2
    mytmpdir=`mktemp -d 2>/dev/null || mktemp -d -t 'mytmpdir'`

    cp $2/*.xliff $mytmpdir
    sed -i '' 's/<target\/>//' $mytmpdir/*.xliff

    for filename in $mytmpdir/*.xliff; do
        echo \*\*\* xcodebuild -importLocalizations -project $1 -localizationPath $filename
        xcodebuild -importLocalizations -project $1 -localizationPath $filename
    done

    rm -fr $mytmpdir
}

# Imports translations in place, that is, it may change original files.
# Param 1: The project (pEpForiOS.xcodeproj or MessageModel/MessageModel.xcodeproj)
# Param 2: The source directory ($translationdir or $translationdir/MessageModel)
function import_in_place() {
    echo \*\*\* import $1 $2
    for filename in $2/*.xliff; do
        sed -i '' 's/<target\/>//' $filename
        echo \*\*\* xcodebuild -importLocalizations -project $1 -localizationPath $filename
        xcodebuild -importLocalizations -project $1 -localizationPath $filename
    done
}

import pEpForiOS.xcodeproj $translationdir
import ../MessageModel/MessageModel/MessageModel.xcodeproj $translationdir/MessageModel

echo
echo \*\*\* Verify the changes in pEpForiOS and MessageModel and commit \*\*\*
echo