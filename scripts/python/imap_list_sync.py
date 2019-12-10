#
# List all sync messages
#

import imaplib
import argparse
from pprint import pprint

from imap_ini import connect_account


def parse_args():
    parser = argparse.ArgumentParser(description='List INBOX on IMAP accounts')
    parser.add_argument('--credentials', required=True,
                        help='INI file containing account credentials')
    parser.add_argument(
        'account_name', help='The account to list the INBOX for')
    args = parser.parse_args()
    return args


def select_folder(con, name=None):
    if name == None:
        return con.select()
    else:
        return con.select(name)


def dump_folder(con, name=None):
    status, _ = select_folder(con, name)
    if status == 'OK':
        typ, data = con.search(None, '(HEADER "pEp-auto-consume" "yes")')
        for num in data[0].split():
            typ, data = con.fetch(
                num, '(UID, BODY.PEEK[HEADER.FIELDS (Message-ID)])')
            pprint(data)


def process(credentials, account_name):
    con = connect_account(credentials, account_name)
    print("INBOX:")
    dump_folder(con)
    print("INBOX.pEpAutoMessages:")
    dump_folder(con, 'INBOX.pEpAutoMessages')


if __name__ == '__main__':
    args = parse_args()
    process(args.credentials, args.account_name)
