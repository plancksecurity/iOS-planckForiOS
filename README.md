# How to build

## Prerequisites

### Package managers

MacPorts for installing all dependencies:

Install [MacPorts](https://www.macports.org/) for your
[version of OS X/macOS](https://www.macports.org/install.php).

### Dependencies of prerequisites

For building the engine, you need a working python2 environment
and all dependencies:

```
sudo port install python27
sudo port install asn1c
sudo port install py27-lxml

sudo port install python_select

sudo port install autoconf
sudo port install libtool
sudo port install automake

sudo port install gmake

# To run the `greenmail` mailserver for tests
sudo port install openjdk11
```

### Set up Xcode
You need to have an Apple ID configured in Xcode, for code signing. You can add one in the `Accounts` tab of the settings (menu `Xcode > Preferences...`).

For some things (TODO: what exactly?), your Apple ID needs to be part of the pEp team account. Ask `#service`, if you want to be added to the team account. When you are a member of the team, the information on your Apple ID in the Xcode Preferences should have a record `Team: pEp Security SA`, `Role: Member`.

### Other dependencies

#### pEpEngine: [yml2](https://fdik.org/yml/toolchain)

Clone into your home directory:

```
pushd ~
hg clone https://pep.foundation/dev/repos/yml2/
popd
```

## Setup instructions

```
mkdir ~/src
cd ~/src

git clone https://github.com/fdik/libetpan.git
git clone https://pep-security.lu/gitlab/iOS/OpenSSL-for-iPhone.git
git clone https://pep-security.lu/gitlab/iOS/SwipeCellKit.git/
git clone https://pep-security.lu/gitlab/iOS/AppAuth-iOS.git
git clone https://pep-security.lu/gitlab/misc/ldns.git

hg clone https://pep.foundation/dev/repos/pantomime-iOS/
hg clone https://pep.foundation/dev/repos/netpgp-et
hg clone https://pep.foundation/dev/repos/pEpEngine
hg clone https://pep.foundation/dev/repos/pEpObjCAdapter
hg clone https://pep.foundation/dev/repos/MessageModel/
hg clone https://pep.foundation/dev/repos/libAccountSettings/

hg clone https://pep-security.ch/dev/repos/pEp_for_iOS/
```

### Build Project

Open pEpForiOS.xcworkspace and build schema "pEp".

### Unit Tests

Out of the box, most tests expect a local test server:

```
cd ~/Downloads
wget http://central.maven.org/maven2/com/icegreen/greenmail-standalone/1.5.9/greenmail-standalone-1.5.9.jar
shasum -a 256 greenmail-standalone-1.5.9.jar
8301b89007e986e8d5e93e2504aad866a58b07b53ac06abb87e6e43eb7646261  greenmail-standalone-1.5.9.jar
java -Dgreenmail.setup.test.all -Dgreenmail.users=test001:pwd@localhost,test002:pwd@localhost,test003:pwd@localhost -jar ~/Downloads/greenmail-standalone-1.5.9.jar
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

# Misc
For a quick update of all the code repositories cloned in the instructions above, use this shell script snipped:

~~~
cd ~/yml2/
hg pull -u

cd ~/src/libetpan/
git pull

cd ~/src/OpenSSL-for-iPhone/
git pull

cd ~/src/SwipeCellKit/
git pull

cd ~/src/AppAuth-iOS/
git pull

cd ~/src/ldns/
git pull

cd ~/src/pantomime-iOS/
hg pull -u

cd ~/src/netpgp-et/
hg pull -u

cd ~/src/pEpEngine/
hg pull -u

cd ~/src/pEpObjCAdapter/
hg pull -u

cd ~/src/MessageModel/
hg pull -u

cd ~/src/libAccountSettings/
hg pull -u

cd ~/src/pEp_for_iOS/
hg pull -u
~~~
