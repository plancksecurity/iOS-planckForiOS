#!/bin/bash

languages="en de fr es ca tr nl sk pt cs"

translationdir=../pEp-Translate/

mytmpdir=`mktemp -d 2>/dev/null || mktemp -d -t 'mytmpdir'`

# This is a tmp dir, it does not have to match any real project path at the end.
appdir=$mytmpdir/pep4ios

mkdir $appdir

for lang in $languages
do
  xcodebuild -exportLocalizations -project pEpForiOS.xcodeproj -exportLanguage $lang -localizationPath $appdir

  cp "$appdir/$lang.xcloc/Localized Contents/$lang.xliff" $translationdir
done

rm -fr $mytmpdir

echo
echo ! Verify the changes in $translationdir, and then commit and push !
echo
