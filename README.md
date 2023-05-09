# How to build

## Prerequisites

### Package managers

MacPorts for installing dependencies:

Install [MacPorts](https://www.macports.org/) for your
[version of OS X/macOS](https://www.macports.org/install.php).

### Dependencies of prerequisites

For building the engine, you need a working python3 environment and (build|testing) dependencies:

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
sudo port install gsed

curl https://sh.rustup.rs -sSf | sh

# To run the `greenmail` mailserver for tests
sudo port install openjdk11
```

Add this to ~/.profile (create if it doesn't exist):

```
source $HOME/.cargo/env
export PATH="$HOME/.cargo/bin:$PATH"
```

Restart your Console!

```
sudo port install pkgconfig
rustup target add x86_64-apple-darwin
rustup target add x86_64-apple-ios
rustup target add aarch64-apple-darwin
rustup target add aarch64-apple-ios
rustup update
```

### Set up Xcode

You need to have an Apple ID configured in Xcode, for code signing. You can add one in the `Accounts` tab of the settings (menu `Xcode > Preferences...`).

Your Apple ID needs to be part of your development team.

### Other dependencies

Clone into your home directory:

```
pushd ~
git clone https://git.planck.security/foundation/yml2.git
popd
```

## Setup instructions

In a directory of your choice, do:

```
mkdir src_pEp4iOS
cd src_pEp4iOS

git clone https://git.planck.security/iOS/pep4ios.git

git clone https://git.planck.security/foundation/planckCoreV3.git
git clone https://git.planck.security/foundation/libPlanckTransport.git
git clone https://git.planck.security/foundation/planckCoreSequoiaBackend.git
git clone https://git.planck.security/foundation/libetpan.git
git clone https://git.planck.security/foundation/planckObjCWrapper.git
git clone https://git.planck.security/foundation/Pantomime.git
git clone https://git.planck.security/foundation/libAccountsettings.git

git clone https://git.planck.security/misc/ldns.git

git clone https://git.planck.security/iOS/planck-toolbox.git
git clone https://git.planck.security/iOS/Appauth-iOS.git
git clone https://git.planck.security/iOS/common-dependency-build-helpers-4-apple-hardware.git
git clone https://git.planck.security/iOS/CocoaLumberjack.git
git clone https://git.planck.security/iOS/OpenSSL-for-iPhone.git
git clone https://git.planck.security/iOS/SwipeCellKit.git

git clone https://git.planck.security/iOS/planckForiOS_intern.git

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
