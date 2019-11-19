#!/usr/bin/env python3

#
# Updates the list of (presumably) engine-generated files.
#

import os
import subprocess
from os import listdir, system
from os.path import isfile, join, splitext

ENGINE_BASE_DIR = '../pEpEngine'
SYNC_DIR_GENERATED = join(ENGINE_BASE_DIR, 'sync/generated')
ASN_DIR_GENERATED = join(ENGINE_BASE_DIR, 'asn.1')
DES_DIR = join(ENGINE_BASE_DIR, 'build-mac')
DEST_ASN_LIST = join(DES_DIR, 'generated-files-asn1.txt')


class cd:
    """Context manager for changing the current working directory"""

    def __init__(self, newPath):
        self.newPath = os.path.expanduser(newPath)

    def __enter__(self):
        self.savedPath = os.getcwd()
        os.chdir(self.newPath)

    def __exit__(self, etype, value, traceback):
        os.chdir(self.savedPath)


def cfiles(path):
    """Returns an array of .c and .h files under the given directory"""
    return [f for f in listdir(path)
            if isfile(join(path, f))
            and splitext(f)[1] in ['.c', '.h']]


def clean_engine():
    """Cleans the engine"""
    with cd(ENGINE_BASE_DIR):
        subprocess.run(['gmake', 'clean'], check=True)


def generate_sync_files():
    """Generates the engine's sync files"""
    with cd(ENGINE_BASE_DIR):
        commands = [
            ['gmake', '-C', 'sync'],
            ['gmake', '-C', 'asn.1', 'Sync.c']
        ]
        for cmd in commands:
            subprocess.run(cmd, check=True)


clean_engine()

asnFilesBefore = cfiles(ASN_DIR_GENERATED)
asnFilesBeforeSet = set(asnFilesBefore)

generate_sync_files()

asnFilesAfter = sorted(cfiles(ASN_DIR_GENERATED))
syncFiles = sorted(cfiles(SYNC_DIR_GENERATED))

with open(DEST_ASN_LIST, 'w') as asn_file:
    for asnF in asnFilesAfter:
        if not (asnF in asnFilesBeforeSet):
            item = '$(SRCROOT)/../asn.1/' + asnF
            asn_file.write(item + '\n')
