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

# Returns true if the given file name exists.
def check_existence(file_name):
    the_file = Path(file_name)
    return the_file.is_file()

# The build creates artefacts that are tracked. They must be removed
# before being able to check out to another commit.
def clean_repo():
    return call(['git', 'co', '.'])

if __name__ == '__main__':
    clean_xcodebuild() # make the build

    clean_repo() # clean up repo

    # Check what this means for bisect.
    # We want to find out the commit that included mailmime_encode.h in
    # the linkfarm.
    # Old behavior is not having mailmime_encode.h (-> exit code 0),
    # new behavior is having it (-> exit code 1).
    the_file_name = 'include/libetpan/mailmime_encode.h'
    if check_existence(the_file_name):
        print('new: found {filename:s}'.format(filename = the_file_name))
        sys.exit(1)
    else:
        print('old: did not find {filename:s}'.format(filename = the_file_name))
        sys.exit(0)
