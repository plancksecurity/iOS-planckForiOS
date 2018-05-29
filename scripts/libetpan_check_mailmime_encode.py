#!/usr/bin/env python3

from subprocess import call
from pathlib import Path
import sys

# https://git-scm.com/docs/git-bisect

# Cleans up, then invokes a build.
def clean_xcodebuild():
    # This command is bound to fail, but it will generate include files,
    # which is more than sufficient.
    base_command = ['xcodebuild', '-quiet', '-project', 'build-mac/libetpan.xcodeproj/']

    # The command for clean is a variation of the build command.
    clean_command = list(base_command)
    clean_command.append('clean')

    call(clean_command)
    return call(base_command)

# The build creates artefacts that are tracked. They must be removed
# before being able to check out to another commit.
def clean_repo():
    return call(['git', 'co', '.'])

if __name__ == '__main__':
    clean_xcodebuild() # make the build

    clean_repo() # clean up repo

    # Check what this means for bisect.
    include_directory = Path('include/libetpan')
    the_file_name = include_directory.joinpath('mailmime_encode.h')
    if not include_directory.is_dir():
        print('no include directory at all: {dir}'.format(dir = include_directory))
        sys.exit(125)
    elif the_file_name.is_file():
        print('old: found {filename}'.format(filename = the_file_name))
        sys.exit(0)
    else:
        print('new: did not find {filename}'.format(filename = the_file_name))
        sys.exit(1)
