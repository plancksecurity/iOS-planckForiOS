#
# List all messages from INBOX
#

import imaplib
import argparse
from pprint import pprint

from imap_ini import connect_account

def parse_args():
    parser = argparse.ArgumentParser(description='List INBOX on IMAP accounts')
    parser.add_argument('--credentials', required=True, help='INI file containing account credentials')
    parser.add_argument('account_name', help='The account to list the INBOX for')
    args = parser.parse_args()
    return args

def process(credentials, account_name):
    con = connect_account(credentials, account_name)
    status, _ = con.select()
    if status == 'OK':
        status, data = con.uid('fetch', '1:*', '(FLAGS)')
        if status == 'OK':
            pprint(data)

if __name__ == '__main__':
    args = parse_args()
    process(args.credentials, args.account_name)
