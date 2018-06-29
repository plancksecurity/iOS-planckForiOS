#!/usr/bin/env python3

#
# From pEp_for_iOS, invoke like this:
# python3 scripts/hg_stat.py
# Or:
# ./scripts/hg_stat.py
#

import os
from subprocess import call

base = '../'
dirs = ['pEp_for_iOS', 'MessageModel', 'pEpObjCAdapter', 'pantomime-iOS',
        'pEpEngine', 'netpgp-et', 'libAccountSettings', 'OpenSSL-for-iPhone',
        'libetpan']

if __name__ == '__main__':
    current_dir = os.getcwd()
    for d in dirs:
        path = base + d
        os.chdir(path)
        print("\n*** " + d)
        git_dir = '.git/'
        hg_dir = '.hg/'
        if os.path.exists(git_dir):
            call(['git', 'status'])
        if os.path.exists(hg_dir):
            call(['hg', 'summary', '--remote'])
        os.chdir(current_dir)

