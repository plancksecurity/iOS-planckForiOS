# How to build

## Prerequisites

* Mercurial
* Cocoapods

```
mkdir ~/src
cd ~/src

git clone https://github.com/fdik/libetpan

hg clone https://cacert.pep.foundation/dev/repos/netpgp-et
hg clone https://cacert.pep.foundation/dev/repos/pEpEngine
hg clone https://cacert.pep.foundation/dev/repos/pEpiOSAdapter

pushd netpgp-et/netpgp-xcode
pod install
popd
```
