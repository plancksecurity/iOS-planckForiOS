import os
import subprocess
import re
import argparse
import shutil
from urllib.parse import urlparse

# python3 scripts/python/checkout-and-build-all.py ~/projects/pEp/pEp_for_iOS ~/tmp/tmp-build/

class Repo:
    def __init__(self, url, branch = 'default'):
        self.url = url
        self.branch = branch

    def dirname(self):
        parsed = urlparse(self.url)
        path = parsed.path
        components = path.split('/')
        name = components[-1]
        if name == '':
            name = components[-2]
        name = re.sub(r'\.git$', '', name)
        return name

class GitRepo(Repo):
    def clone(self):
        completed = subprocess.run(['git','clone',self.url])
        completed.check_returncode()

    def update(self):
        the_dir = self.dirname()
        os.chdir(the_dir)
        completed = subprocess.run(['git','checkout',self.branch])
        completed.check_returncode()

class HgRepo(Repo):
    def clone(self):
        completed = subprocess.run(['hg','clone',self.url])
        completed.check_returncode()

    def update(self):
        the_dir = self.dirname()
        os.chdir(the_dir)
        completed = subprocess.run(['hg','up',self.branch])
        completed.check_returncode()

repos = [
    GitRepo('https://pep-security.lu/gitlab/misc/ldns/', 'IOS-749'),
    GitRepo('https://github.com/fdik/libetpan.git', 'master'),
    GitRepo('https://pep-security.lu/gitlab/iOS/OpenSSL-for-iPhone.git', 'master'),
    GitRepo('https://pep-security.lu/gitlab/iOS/SwipeCellKit.git/', 'master'),
    GitRepo('https://pep-security.lu/gitlab/iOS/AppAuth-iOS.git', 'master'),
    HgRepo('https://pep.foundation/dev/repos/pantomime-iOS/', 'IOS-1480'),
    HgRepo('https://pep.foundation/dev/repos/netpgp-et', 'default'),
    HgRepo('https://pep.foundation/dev/repos/pEpEngine', 'sync'),
    HgRepo('https://pep.foundation/dev/repos/pEpObjCAdapter', 'IOS-1480'),
    HgRepo('https://pep.foundation/dev/repos/MessageModel/', 'IOS-1480'),
    HgRepo('https://pep.foundation/dev/repos/libAccountSettings/', 'default'),
    HgRepo('https://pep-security.ch/dev/repos/pEp_for_iOS/', 'IOS-1480')
    ]

def install_secret_test_data(src_dir, target_dir):
    files = [
        './pEpForiOS/secret.xcconfig',
        'pEpForiOSUITests/SecretUITestData.swift',
        'pEpForiOSTests/TestUtils/SecretTestData.swift']
    for path_part in files:
        src_path = os.path.join(src_dir, path_part)
        target_path = os.path.join(target_dir, 'pEp_for_iOS', path_part)
        shutil.copyfile(src_path, target_path)
        print("copy {} -> {}".format(src_path, target_path))

def run_tests(target_dir):
    os.chdir(target_dir)
    os.chdir('pEp_for_iOS')

    locale_env = os.environ
    locale_env['LC_ALL'] = 'en_US.UTF-8'
    locale_env['LANG'] = 'en_US.UTF-8'

    completed = subprocess.run(
        ['xcodebuild','test','-workspace',
        'pEpForiOS.xcworkspace','-scheme','pEp',
        '-destination "name=iPhone X"'],
        env=locale_env, shell=True
    )
    return completed

def run_tests_multiple(target_dir):
    while True:
        success = run_tests(target_dir)
        if success.returncode == 0:
            break

def rm_sub_dirs(path):
    for dirpath, dirnames, filenames in os.walk(path):
        for dirname in dirnames:
            shutil.rmtree(os.path.join(dirpath, dirname))
        for filename in filenames:
            os.remove(os.path.join(dirpath, filename))

def clone_repos(repos):
    for rep in repos:
        os.chdir(args.target_dir)
        rep.clone()
        rep.update()

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Check out the project and build it.')
    parser.add_argument('src_dir',
        type=os.path.abspath,
        help='The pEp for iOS src directory for getting secret test data')
    parser.add_argument('target_dir',
        type=os.path.abspath,
        help='The target directory to which to checkout everything. WILL BE ERASED!')
    args = parser.parse_args()
    
    rm_sub_dirs(args.target_dir)
    clone_repos(repos)
    install_secret_test_data(args.src_dir, args.target_dir)
    
    #run_tests_multiple(args.target_dir)