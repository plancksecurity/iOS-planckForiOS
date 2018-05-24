git clone https://pep-security.lu/gitlab/misc/ldns/
git clone https://github.com/dirkz/libetpan.git
git clone https://github.com/x2on/OpenSSL-for-iPhone.git
git clone https://github.com/SwipeCellKit/SwipeCellKit.git
git clone https://github.com/openid/AppAuth-iOS

hg clone https://pep.foundation/dev/repos/pantomime-iOS/
hg clone https://pep.foundation/dev/repos/netpgp-et
hg clone https://pep.foundation/dev/repos/pEpEngine
hg clone https://pep.foundation/dev/repos/pEpObjCAdapter
hg clone https://pep.foundation/dev/repos/MessageModel/
hg clone https://pep.foundation/dev/repos/libAccountSettings/

hg clone https://pep-security.ch/dev/repos/pEp_for_iOS/

pushd ldns && git co IOS-749 ; popd
pushd SwipeCellKit && git co 2.0.1 ; popd

pushd pEp_for_iOS && xcodebuild -workspace pEpForiOS.xcworkspace/ -scheme pEp -destination "platform=iOS Simulator,OS=11.3,name=iPhone SE" ; popd

