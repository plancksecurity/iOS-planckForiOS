# How to build

## Prerequisites

### Package managers

MacPorts for installing all dependencies:

Install [MacPorts](https://www.macports.org/) for your
[version of OS X/macOS](https://www.macports.org/install.php).

### Install CAcert root certificates

Import the root certificates of the community-driven CAcert project
in order to deal with the Mercurial repositories via https; for Mac
OS X follow (the GUI or commandline) instructions provided:

http://wiki.cacert.org/FAQ/ImportRootCert#Mac_OS_X

Before using, please check the authenticity of the certificate(s)
downloaded.

The fingerprints should be:

* Class 1 PKI Key (SHA1): 13:5C:EC:36:F4:9C:B8:E9:3B:1A:B2:70:CD:80:88:46:76:CE:8F:33 
* Class 3 PKI Key (SHA1): AD:7C:3F:64:FC:44:39:FE:F4:E9:0B:E8:F4:7C:6C:FA:8A:AD:FD:CE

(Cf. http://www.cacert.org/index.php?id=3)

### Dependencies of prerequisites

For building the engine, you need a working python2 environment
and all dependencies:

```
sudo port install asn1c
sudo port install py27-lxml

sudo port install python_select
```

### Other dependecies

#### pEpEngine: [yml2](https://fdik.org/yml/toolchain)

Clone into your home directory:

```
pushd ~
hg clone https://cacert.pep.foundation/dev/repos/yml2/
popd
```

## Setup instructions

```
mkdir ~/src
cd ~/src

git clone https://github.com/fdik/libetpan

hg clone https://cacert.pep.foundation/dev/repos/pantomime-iOS/
hg clone https://cacert.pep.foundation/dev/repos/netpgp-et
hg clone https://cacert.pep.foundation/dev/repos/pEpEngine
hg clone https://cacert.pep.foundation/dev/repos/pEpiOSAdapter
hg clone https://cacert.pep.foundation/dev/repos/MailModel/

hg clone https://cacert.pep-security.ch/dev/repos/pEp_for_iOS/
```

Note that netpgp includes a static openssl, and pEpEngine a static libcurl. For
rebuilding see the respective scripts. But you should not have to do that for iOS.

### UI Tests

Set up working account for UI tests. After copying, fill in working account:

```
cp ./pEpForiOSUITests/UITestData.swift.sample ./pEpForiOSUITests/UITestData.swift
```

### Unit Tests

You need to create a copy of TestData.swift.sample as TestData.swift
and populate it with corresponding (valid) settings to run successful tests.

The tests will not compile without a syntactically correct TestData.swift.

```
cp pEpForiOSTests/Util/TestData.swift.sample pEpForiOSTests/Util/TestData.swift
```
