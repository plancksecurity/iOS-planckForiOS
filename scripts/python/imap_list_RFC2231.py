#
# List all messages from INBOX
#

import imaplib
import argparse
from pprint import pprint

from imap_ini import connect_account

import re

def parse_args():
    parser = argparse.ArgumentParser(description='List INBOX on IMAP accounts')
    parser.add_argument('--credentials', required=True, help='INI file containing account credentials')
    parser.add_argument('account_name', help='The account to list the INBOX for')
    args = parser.parse_args()
    return args

def is_tuple(x):
    return type(x) is tuple

def process(credentials, account_name):
    con = connect_account(credentials, account_name)
    status, _ = con.select()
    if status == 'OK':
        status, data = con.fetch('1:*', 'BODY.PEEK[HEADER]')
        if status == 'OK':
            regex1 = re.compile('=\"[^"]*\"')
            regex3 = re.compile('[^\r]\n')
            regexs = [regex3]
            mail_count = 0
            count_rfc2231 = 0
            data = filter(is_tuple, data)
            for mail in data:
                mail_count += 1
                the_string = mail[1].decode('ascii')
                for regex in regexs:
                    for the_match in regex.findall(the_string):
                        print('match ######')
                        pprint(the_match)
                        count_rfc2231 += 1
            print('counted {} mails, {} of which could be extended format'.format(mail_count, count_rfc2231))

if __name__ == '__main__':
    args = parse_args()
    process(args.credentials, args.account_name)
