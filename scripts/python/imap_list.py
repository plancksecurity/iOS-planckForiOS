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
        typ, data = con.search(None, 'ALL')
        for num in data[0].split():
            typ, data = con.fetch(num, '(UID, BODY.PEEK[HEADER.FIELDS (SUBJECT)])')
            print('Message %s\n%s\n' % (num, data[0][1]))

if __name__ == '__main__':
    args = parse_args()
    process(args.credentials, args.account_name)
