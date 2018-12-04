#
# Checks out pEp for iOS and dependent projects.
# Will clone from the parent (to save disk-space,
# at least with mercurial),
#
# Usage:
#
# Assuming you want the project as it existed for 0.0.40.
# From the base directory where the original pEp_for_iOS can be found:
#
# mkdir 0.0.40
# cd 0.0.40
# hg clone ../pEp_for_iOS/
# cd pEp_for_iOS/
# hg up v0.0.40
# cd ..
# python3 ../pEp_for_iOS/scripts/python/checkout.py --base-path .. --changeset-path pEp_for_iOS/CHANGESETS
#

import glob
import os
import subprocess
import argparse
import re

def process(base_path, changeset_path):
    current_dir = os.getcwd()

    first_line = True
    with open(changeset_path) as f:
        for line in f:
            if first_line:
                first_line = False
            else:
                process_project(base_path, line)

    os.chdir(current_dir)

def is_git(project):
    projects = {'ldns', 'OpenSSL-for-iPhone', 'libetpan', 'AppAuth-iOS', 'SwipeCellKit'}
    return project in projects

def process_project(base_path, line):
    p = re.compile(r'([^ ]+) ([0-9a-fA-F]+)\n')
    m = p.match(line)
    project = m.group(1)
    the_hash = m.group(2)
    if is_git(project):
        process_git(base_path, project, the_hash)
    else:
        process_hg(base_path, project, the_hash)

def process_hg(base_path, project, the_hash):
    orig_path = os.path.join(base_path, project)
    subprocess.call(['hg', 'clone', orig_path])
    current_dir = os.getcwd()
    os.chdir(project)
    subprocess.call(['hg', 'up', the_hash])
    os.chdir(current_dir)

def process_git(base_path, project, the_hash):
    orig_path = os.path.join(base_path, project)
    subprocess.call(['git', 'clone', orig_path])
    current_dir = os.getcwd()
    os.chdir(project)
    subprocess.call(['git', 'co', the_hash])
    os.chdir(current_dir)

if __name__ == '__main__':
    current_dir = os.getcwd()

    parser = argparse.ArgumentParser(
        description='clone the whole pEp for iOS project at a certain point of time')
    parser.add_argument('--base-path', help='The directory the original project can be found',
        required=True)
    parser.add_argument('--changeset-path', help='The CHANGESET file',
        required=True)
    args = parser.parse_args()

    process(args.base_path, args.changeset_path)

    os.chdir(current_dir)
