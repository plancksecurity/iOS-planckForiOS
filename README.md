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

git clone https://pep-security.lu/gitlab/misc/ldns/
git clone https://github.com/fdik/libetpan.git
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
```

### Build Project

Open pEpForiOS.xcworkspace and build schema "pEp".

### Unit Tests

The non-existing file referenced in the unit test project, ./pEpForiOSTests/TestUtil/SecretTestData.swift, must be
created, with a class named SecretTestData, derived from TestDataBase. Override populateAccounts().

The tests will not compile without a syntactically correct SecretTestData.swift that inherits from TestDataBase.

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
