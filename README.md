# How to build

## Prerequisites

### Install Revision Control Systems used

Choose homebrew or macports for installing.

* git
* Mercurial

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

* pEpEngine: asn1c
  ```
  brew install asn1c
  ```
* mogenerator
  ```
  brew install mogenerator
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

hg clone https://cacert.pep-security.ch/dev/repos/pEp_for_iOS/

# Set up working account for unit tests. After copying, fill in working account:
cp ./pEpForiOS/Sync/TestData.swift.sample ./pEpForiOS/Sync/TestData.swift

# Set up working account for UI tests. After copying, fill in working account:
cp ./pEpForiOSUITests/UITestData.swift.sample ./pEpForiOSUITests/UITestData.swift
```

Note that netpgp includes a static openssl, and pEpEngine a static libcurl. For
rebuilding see the respective scripts. But you should not have to do that for iOS.

## Auto-generating model files

The core data model files are generated with mogenerator, using modified templates
(for generating protocol definitions as well).

You only need to regenerate them when there were changes in the model.

```
cd pEp_for_iOS

mogenerator --model pEpForiOS/pEpForiOS.xcdatamodeld/pEpForiOS.xcdatamodel --machine-dir pEpForiOS/Models/machine/ --human-dir pEpForiOS/Models/ --swift --base-class BaseManagedObject --template-path ../mogenerator.templates/
```
