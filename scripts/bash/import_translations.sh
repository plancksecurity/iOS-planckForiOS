#!/bin/bash

languages="en de fr es ca tr nl sk"

translationdir=../pEp-Translate/

# Imports translations, using a temporary directory in order to not change
# original files.
# Param 1: The language to import
# Param 2: The project (pEpForiOS.xcodeproj)
# Param 3: The source directory ($translationdir)
function import() {
    echo \*\*\* import $1 $2 $3
    mytmpdir=`mktemp -d 2>/dev/null || mktemp -d -t 'mytmpdir'`

    cp $3/*.xliff $mytmpdir

    import_in_place $1 $2 $mytmpdir

    rm -fr $mytmpdir
}

# Imports translations directly from a given directory, maybe changing the originals.
# Param 1: The language to import
# Param 2: The project (pEpForiOS.xcodeproj)
# Param 3: The source directory ($translationdir)
function import_in_place() {
    filename=$3/$1.xliff
    sed -i '' 's/<target\/>//' $filename
    echo \*\*\* xcodebuild -importLocalizations -project $2 -localizationPath $filename
    xcodebuild -importLocalizations -project $2 -localizationPath $filename
}

for lang in $languages
do
    import $lang pEpForiOS.xcodeproj $translationdir
done

echo
echo \*\*\* Verify the changes in pEpForiOS and commit \*\*\*
echo