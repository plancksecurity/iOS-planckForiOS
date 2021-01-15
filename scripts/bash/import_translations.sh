#!/bin/bash

languages="en de fr es ca tr nl sk"

translationdir=../pEp-Translate/

# Imports translations, using a temporary directory in order to not change
# original files.
# Param 1: The language to import
# Param 2: The project (pEpForiOS.xcodeproj or
#          ./SubProjects/MessageModel/MessageModel/MessageModel.xcodeproj
# Param 3: The source directory ($translationdir or $translationdir/MessageModel)
function import() {
    echo \*\*\* import $1 $2 $3
    mytmpdir=`mktemp -d 2>/dev/null || mktemp -d -t 'mytmpdir'`

    cp $3/*.xliff $mytmpdir

    import_in_place $1 $2 $mytmpdir

    rm -fr $mytmpdir
}

# Imports translations directly from a given directory, maybe changing the originals.
# Param 1: The language to import
# Param 2: The project (pEpForiOS.xcodeproj or
#          ./SubProjects/MessageModel/MessageModel/MessageModel.xcodeproj
# Param 3: The source directory
function import_in_place() {
    filename=$3/$1.xliff

    # Eliminate empty translations Part 1
    sed -i '' 's/<target\/>//' $filename

    # Eliminate empty translations Part 2
    sed -i '' 's/<target><\/target>//' $filename

    echo \*\*\* xcodebuild -importLocalizations -project $2 -localizationPath $filename
    xcodebuild -importLocalizations -project $2 -localizationPath $filename
}

for lang in $languages
do
    import $lang pEpForiOS.xcodeproj $translationdir
    import $lang ./SubProjects/MessageModel/MessageModel/MessageModel.xcodeproj $translationdir/MessageModel
done

echo
echo \*\*\* Verify the changes in pEpForiOS and commit \*\*\*
echo