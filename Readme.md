# How to build

## Prerequisites

* Mercurial
* //Cocoapods

```
mkdir ~/src
cd ~/src

wget https://www.openssl.org/source/openssl-1.0.1p.tar.gz
tar xvfz openssl-1.0.1p.tar.gz

git clone https://github.com/fdik/libetpan

hg clone https://cacert.pep.foundation/dev/repos/netpgp-et
hg clone https://cacert.pep.foundation/dev/repos/pEpEngine
hg clone https://cacert.pep.foundation/dev/repos/pEpiOSAdapter

#pushd netpgp-et/netpgp-xcode
#pod install
#popd
```
