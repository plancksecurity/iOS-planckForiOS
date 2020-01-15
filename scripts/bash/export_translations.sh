#!/bin/bash

translationdir=../pEp-Translate/

languages=(de en)
mytmpdir=`mktemp -d 2>/dev/null || mktemp -d -t 'mytmpdir'`

appdir=$mytmpdir/pEpForiOS
mmdir=$mytmpdir/MessageModel

mkdir $appdir
mkdir $mmdir

for lang in $languages
do
  xcodebuild -exportLocalizations -project pEpForiOS.xcodeproj -exportLanguage $lang -localizationPath $appdir

  cp "$appdir/$lang.xcloc/Localized Contents/$lang.xliff" $translationdir
    xcodebuild -exportLocalizations -project ../MessageModel/MessageModel/MesssageModel.xcodeproj -exportLanguage $lang -localizationPath $mmdir

cp "$mmdir/$lang.xcloc/Localized Contents/$lang.xliff" $translationdir/MessageModel
 done

rm -fr $mytmpdir

echo
echo ! Verify the changes in $translationdir, and then commit and push !
echo