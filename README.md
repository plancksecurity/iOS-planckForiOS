# How to build

## Prerequisites

### Package managers

MacPorts for installing dependencies:

Install [MacPorts](https://www.macports.org/) for your
[version of OS X/macOS](https://www.macports.org/install.php).

### Dependencies of prerequisites

For building the engine, you need a working python3 environment and all dependencies:

```
sudo port install git

sudo port install asn1c

sudo port install python38
sudo port install py38-lxml
sudo port select --set python3 python38

sudo port install gmake
sudo port install autoconf
sudo port install libtool
sudo port install automake

sudo port install wget

sudo port install capnproto

curl https://sh.rustup.rs -sSf | sh

# To run the `greenmail` mailserver for tests
sudo port install openjdk11
```

add this to ~/.profile (create if it doesn't exist):

```
source $HOME/.cargo/env
export PATH="$HOME/.cargo/bin:$PATH"
```

Restart your Console!

```
sudo port install pkgconfig
rustup update
rustup target add aarch64-apple-ios x86_64-apple-ios
sudo port pkgconfig
rustup update nightly
rustup default nightly
rustup component add rust-src
rustup default stable
```

### Set up Xcode
You need to have an Apple ID configured in Xcode, for code signing. You can add one in the `Accounts` tab of the settings (menu `Xcode > Preferences...`).

For some things, your Apple ID needs to be part of the pEp team account. Ask `#service`, if you want to be added to the team account. When you are a member of the team, the information on your Apple ID in the Xcode Preferences should have a record `Team: pEp Security SA`, `Role: Member`.

### Other dependencies

#### pEpEngine: [yml2](https://fdik.org/yml/toolchain)

Clone into your home directory:

```
pushd ~
git clone https://gitea.pep.foundation/fdik/yml2
popd
```

## Setup instructions

In a directory of your choice, do:

```
mkdir src_pEp4iOS
cd src_pEp4iOS

git clone https://pep-security.lu/gitlab/misc/libetpan.git
pushd libetpan
git checkout ios_1.1.200
popd

git clone https://pep-security.lu/gitlab/iOS/OpenSSL-for-iPhone.git
git clone https://pep-security.lu/gitlab/iOS/SwipeCellKit.git/
git clone https://pep-security.lu/gitlab/iOS/CocoaLumberjack
git clone https://pep-security.lu/gitlab/iOS/AppAuth-iOS.git
git clone https://pep-security.lu/gitlab/misc/ldns.git
git clone https://pep-security.lu/gitlab/misc/sqlite.git

git clone http://pep-security.lu/gitlab/iOS/sequoia4ios.git
pushd sequoia4ios
sh build.sh
popd

git clone https://gitea.pep.foundation/pEp.foundation/libAccountSettings

git clone http://pep-security.lu/gitlab/iOS/pep-toolbox.git
git clone https://gitea.pep.foundation/pep.foundation/Pantomime.git
git clone https://gitea.pep.foundation/pEp.foundation/pEpEngine
git clone https://gitea.pep.foundation/pep.foundation/pEpObjCAdapter.git
git clone http://pep-security.lu/gitlab/misc/changesets_script.git

git clone https://pep-security.lu/gitlab/iOS/pep4ios.git
```

### Build Project

Open pEpForiOS.xcworkspace and build schema "pEp".

### Unit Tests

Out of the box, some tests expect a local test server:

```
java -Dgreenmail.setup.test.all -Dgreenmail.users=test001:pwd@localhost,test002:pwd@localhost,test003:pwd@localhost -jar ./testTools/greenmail/greenmail-standalone-1.5.9.jar
```

Note: The following section concerning test data is solved for pEp-internal dev members by checking out a private repo, please ask your colleagues. If you don't have access to that repo, you have to create the needed files yourself.

The non-existing file referenced in the unit test project, pEpForiOSTests/../pEp_for_iOS_intern/SecretTestData.swift, must be
created, with a class named SecretTestData, derived from TestDataBase.

In `SecretTestData.swift`, you must at least override `populateVerifiableAccounts`, adding servers that are either registered in the LAS database or provide DNS SRV for IMAP and SMTP in order to test the "automatic account login".

If you want to run the tests against your own servers, override `populateAccounts` accordingly.

### UI Tests

Note: The following section concerning test data is solved for pEp-internal dev members by checking out a private repo, please ask your colleagues. If you don't have access to that repo, you have to create the needed files yourself.

There is a file referenced in the UI test project, UITestData. You need to create it
(./pEpForiOSUITests/SecretUITestData.swift), and implement it according to the protocol UITestDataProtocol.

The UI tests will not compile without it.

### secret.xcconfig (needed for OAuth2 config secrects and others)

Create secret.xcconfig @ pEpForiOS/../pEp_for_iOS_intern/secret.xcconfig, with those contents:

```
OAUTH2_GMAIL_CLIENT_ID = your_secret_content
OAUTH2_GMAIL_REDIRECT_URL_SCHEME = your_secret_content

OAUTH2_YAHOO_CLIENT_ID = your_secret_content
OAUTH2_YAHOO_CLIENT_SECRET = some_content

```

# Notes on debugging build problems
Depending on whether you use a distribution of bash from macports or Apple, and the contents of your `PATH` variable, the build might fail. Especially the engine makes many assumptions about the environment on the build machine.

If you have any build issues, they may also be fixed by changing some of the variables the engine build system uses in `~/src/pEpEngine/local.conf`. This is an example configuration file:

~~~
YML2_PROC=/opt/local/bin/python2 $(YML2_PATH)/yml2proc

ASN1C=/opt/local/bin/asn1c
ASN1C_INC=/opt/local/share/asn1c/
~~~

Note that some of these variables may be overridden in the build system elsewhere, for example the variable `YML2_PATH`. Check the build steps in `pEpEngine.xcodeproj` for details.
