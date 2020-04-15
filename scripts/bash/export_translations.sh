#!/bin/bash

languages="en de fr es ca tr nl sk"

translationdir=../pEp-Translate/

mytmpdir=`mktemp -d 2>/dev/null || mktemp -d -t 'mytmpdir'`

appdir=$mytmpdir/pEpForiOS
mmdir=$mytmpdir/MessageModel

mkdir $appdir
mkdir $mmdir

for lang in $languages
do
  xcodebuild -exportLocalizations -project pEpForiOS.xcodeproj -exportLanguage $lang -localizationPath $appdir

  if [ $lang = "en" ]
  then
    # Put en.xliff under base.xliff, correcting the language attributes
    cp "$appdir/$lang.xcloc/Localized Contents/$lang.xliff" $translationdir/base.xliff
    sed -i '' 's/source-language="en"/source-language="base"/' $translationdir/base.xliff
    sed -i '' 's/target-language="en"/target-language="base"/' $translationdir/base.xliff
  else
    # Plain copy
    cp "$appdir/$lang.xcloc/Localized Contents/$lang.xliff" $translationdir
  fi
done

rm -fr $mytmpdir

echo
echo ! Verify the changes in $translationdir, and then commit and push !
echo
