#!/usr/bin/env python3

from subprocess import call
from pathlib import Path
import sys

#
# https://git-scm.com/docs/git-bisect
#
# * `git bisect start`
# * Checkout commit
# * Test commit with: `python3 libetpan_check_mailmime_encode.py`
# * After having marked at least one commit as old/good, and one as new/bad,
#   you can use:
#   `git bisect run python3 libetpan_check_mailmime_encode.py`
#

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

# Marks this run as old (good)
def advertiseOldGood(message):
    print('old/good: {}'.format(message))
    sys.exit(0)

# Marks this run as new (bad)
def advertiseNewBad(message):
    print('new/bad: {}'.format(message))
    sys.exit(1)

def advertiseAsSkip(message):
    print('skip: {}'.format(message))
    sys.exit(125)

if __name__ == '__main__':
    clean_xcodebuild() # make the build

    clean_repo() # clean up repo

    # Check what this means for bisect.
    include_directory = Path('include/libetpan')
    the_file_name = include_directory.joinpath('mailmime_encode.h')
    if not include_directory.is_dir():
        advertiseAsSkip('no include directory at all: {}'.format(include_directory))
    elif the_file_name.is_file():
        advertiseOldGood('found {}'.format(the_file_name))
    else:
        advertiseNewBad('did not find {}'.format(the_file_name))
