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
sudo port select python python27

sudo port install autoconf
sudo port install libtool
sudo port install automake
```

### Other dependecies

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

//Temp hot fix
cd ~/ldns
git checkout IOS-749
cd ..
cd ~/SwipeCellKit
git checkout master
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

The non-existing file referenced in the unit test project, ./pEpForiOSTests/TestUtil/SecretTestData.swift, must be
created, with a class named SecretTestData, derived from TestDataBase.

In `SecretTestData.swift`, you must override `populateVerifiableAccounts`, adding servers that are either registered in the LAS database or provide DNS SRV for IMAP and SMTP in order to test the "automatic account login".

If you want to run the tests against your own servers, override `populateAccounts` accordingly.

### UI Tests

There is a file referenced in the UI test project, UITestData. You need to create it
(./pEpForiOSUITests/SecretUITestData.swift), and implement it according to the protocol UITestDataProtocol.

The UI tests will not compile without it.

### secret.xcconfig (needed for OAuth2 config secrects and others)

Create secret.xcconfig @ pEpForiOS/secret.xcconfig, with those contents:

```
OAUTH2_GMAIL_CLIENT_ID = some_content
OAUTH2_GMAIL_REDIRECT_URL_SCHEME = some_content

OAUTH2_YAHOO_CLIENT_ID = some_content
OAUTH2_YAHOO_CLIENT_SECRET = some_content

```
