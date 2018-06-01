#!/usr/bin/env python3

from subprocess import call
from os.path import expanduser

home = expanduser("~")

call(['rm', '-fr', home + '/Library/Developer/Xcode/DerivedData'])
