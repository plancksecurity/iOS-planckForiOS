#
# Strips arm64e from all *.dylibs of a given archive.
#
# Usage:
#
# python3 scripts/python/rm_arm64e.py <some.xcarchive>
#

import glob
import os
import subprocess
import argparse

official_files = {'libswiftCoreGraphics.dylib', 'libswiftCoreMedia.dylib',
    'libswiftDarwin.dylib', 'libswiftCoreAudio.dylib',
    'libswiftos.dylib', 'libswiftPhotos.dylib',
    'libswiftQuartzCore.dylib', 'libswiftCoreData.dylib',
    'libswiftContacts.dylib', 'libswiftFoundation.dylib',
    'libswiftMetal.dylib', 'libswiftCoreLocation.dylib',
    'libswiftCoreFoundation.dylib', 'libswiftAVFoundation.dylib',
    'libswiftCoreImage.dylib', 'libswiftObjectiveC.dylib',
    'libswiftsimd.dylib', 'libswiftSwiftOnoneSupport.dylib',
    'libswiftUIKit.dylib', 'libswiftDispatch.dylib',
    'libswiftCore.dylib'}

if __name__ == '__main__':
    current_dir = os.getcwd()

    parser = argparse.ArgumentParser(description='Remove arm64e from *.dylib')
    parser.add_argument('archive_path',
        help='SwiftSupport/iphoneos/ of the target archive')
    args = parser.parse_args()

    os.chdir(args.archive_path)

    files = glob.glob('**/*.dylib', recursive=True)
    for file in files:
        base_name = os.path.basename(file)
        if base_name not in official_files:
            print("*** unplanned: " + file)
        subprocess.call(['lipo', file, '-remove', 'arm64e', '-output', file])

    os.chdir(current_dir)
