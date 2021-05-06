#!/bin/bash

languages="en"

translationdir=../pEp-Translate/

# Imports translations directly from a given directory, maybe changing the originals.
# Param 1: The language to import
# Param 2: The project (pEpForiOS.xcodeproj)
# Param 3: The source directory ($translationdir)
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
    import_in_place $lang pEpForiOS.xcodeproj $translationdir
done

echo
echo \*\*\* Make sure $translationdir doesn not have changes \*\*\*
echo \*\*\* Verify the changes in pEpForiOS and commit \*\*\*
echo