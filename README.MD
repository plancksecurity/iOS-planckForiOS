# How to build

## Prerequisites

Choose homebrew or macports for installing.

* git
* Mercurial

```
mkdir ~/src
cd ~/src

git clone https://github.com/fdik/libetpan

hg clone https://cacert.pep.foundation/dev/repos/pantomime-iOS/
hg clone https://cacert.pep.foundation/dev/repos/netpgp-et
hg clone https://cacert.pep.foundation/dev/repos/pEpEngine
hg clone https://cacert.pep.foundation/dev/repos/pEpiOSAdapter

hg clone https://cacert.pep-security.ch/dev/repos/pEp_for_iOS/

# For testing server access, this is temporary:
cp ./pEpForiOS/Sync/TestData.swift.sample ./pEpForiOS/Sync/TestData.swift
```

Note that netpgp includes a static openssl, and pEpEngine a static libcurl. For
rebuilding see the respective scripts. But you should not have to do that for iOS.
