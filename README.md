# How to build

## Prerequisites

### Package managers

MacPorts for installing dependencies:

Install [MacPorts](https://www.macports.org/) for your
[version of OS X/macOS](https://www.macports.org/install.php).

### Build-time dependencies

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

Add this to ~/.profile or the _equivalent for your shell_ (create if it doesn't exist, but _please be aware of the consequences_):

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

### Other build-time dependencies

Clone into your home directory:

```
pushd ~
git clone https://git.planck.security/foundation/yml2.git
popd
```

## Setup instructions

```
mkdir src # parent directory of your choice
cd src

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

# internal repo for configuration and test data
git clone https://git.planck.security/iOS/planckForiOS_intern.git

open pep4ios/planckForiOS.xcworkspace
```

### Build

Chose the scheme 'planckForiOS', the simulator/device of your choice, and you are ready to build, run or run the tests.


### Tests

Out of the box, some tests expect a local test server:

```
java -Dgreenmail.setup.test.all -Dgreenmail.users=test001:pwd@localhost,test002:pwd@localhost,test003:pwd@localhost -jar ./testTools/greenmail/greenmail-standalone-1.5.9.jar
```

### Private repo

In order to build the project, you need a repo with internals. In case you don't have access to that, you need to re-create certain files manually. Please follow the errors Xcode gives you. It's mainly about creating configuration files and derived classes.
