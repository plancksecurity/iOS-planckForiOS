for lang in de en
do
  # Use -verbose to see more errors/warnings.
  xcodebuild -exportLocalizations -project pEpForiOS.xcodeproj -exportLanguage $lang -localizationPath ../pEp-Translate/original_exports/all/pEpForiOS/
  xcodebuild -exportLocalizations -project ../MessageModel/MessageModel/MessageModel.xcodeproj -exportLanguage $lang -localizationPath ../pEp-Translate/original_exports/all/MessageModel/
done
