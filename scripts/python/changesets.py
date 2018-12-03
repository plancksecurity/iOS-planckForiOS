#!/usr/bin/env python3

#
# From pEp_for_iOS, invoke like this:
# python3 scripts/changesets.py
#

import os
import subprocess
import re
import argparse

dirs = ['pEpEngine', 'pEpObjCAdapter', 'netpgp-et', 'MessageModel',
     'pantomime-iOS', 'libAccountSettings', 'ldns',
     'OpenSSL-for-iPhone', 'libetpan', 'AppAuth-iOS', 'SwipeCellKit']

def is_git():
    if os.path.exists('.git/'):
        return True
    else:
        return False

def is_hg():
    if os.path.exists('.hg/'):
        return True
    else:
        return False

def hg_changeset(name):
    p = re.compile(r'parent: \d+:([^\n]+)\n.*')
    process = subprocess.Popen(['hg','sum'], stdout=subprocess.PIPE)
    all = process.stdout.read().decode('utf-8')
    m = p.match(all)
    print(name + ' ' + m.group(1))

def git_changeset(name):
    p = re.compile(r'([^\n]+)\n')
    process = subprocess.Popen(['git','rev-parse', 'HEAD'], stdout=subprocess.PIPE)
    all = process.stdout.read().decode('utf-8')
    m = p.match(all)
    print(name + ' ' + m.group(1))

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Generate current CHANGESETS')
    parser.add_argument('release_name',
        help='The release name, e.g. v0.0.41. Will be the first line.')
    args = parser.parse_args()
    print(args.release_name)

    orig_dir = os.getcwd()
    os.chdir('..')
    base_dir = os.getcwd()
    for d in dirs:
        os.chdir(d)
        if is_git():
            git_changeset(d)
        elif is_hg():
            hg_changeset(d)
        os.chdir(base_dir)
    os.chdir(orig_dir)

