import imaplib
import configparser
import argparse
from pprint import pprint
import re

#
# Account credentials are read from an .ini file:
#
# [account001]
# username = user@example.com
# password = thePassword
# hostname = imap.example.com
# port = 993 # <- this is the default anyways
#

def parse_args():
    parser = argparse.ArgumentParser(description='Erase all emails from IMAP accounts')
    parser.add_argument('--credentials', required=True, help='INI file containing account credentials')
    parser.add_argument('account_names', nargs='+')
    args = parser.parse_args()
    return args

def account_info(ini, account_name):
    config = configparser.ConfigParser()
    config.read(ini)
    return config[account_name]

def match_mailbox_name_from_response(string):
    p1 = re.compile('^.*" "([^"]+)"$')
    p2 = re.compile('^.*" ([a-zA-Z.]+)$')
    return p1.match(string) or p2.match(string)

def parse_mailbox_name(response):
    the_string = str(response, 'utf-8')
    match = match_mailbox_name_from_response(the_string)
    if match != None:
        mb_name = match.group(1)
        return mb_name

def traverse_mailboxes(connection, fn):
    response, data = connection.list()
    if response == 'OK':
        for line in data:
            mailbox_name = parse_mailbox_name(line)
            if mailbox_name != None:
                fn(connection, mailbox_name)

def delete_all_in_current_mailbox(connection):
    r1, uids = connection.uid('search', None, 'ALL')
    if r1 == 'OK':
        for uid in uids[0].split():
            print('deleting message {}'.format(uid))
            r2, _ = connection.uid('store', uid, '+FLAGS', '\\Deleted')
            if r2 != 'OK':
                print('could not remove message {}'.format(uid))
        r3, _ = connection.expunge()
        if r3 != 'OK':
            print('could not expunge')
    else:
        print('Cannot remove all emails')

def rm_all_mailbox_content(connection, mailbox_name):
    status, data = connection.select(mailbox_name)
    if status == 'OK':
        print('mailbox "{}"'.format(mailbox_name))
        delete_all_in_current_mailbox(connection)

def erase_mailboxes(connection):
    traverse_mailboxes(connection, rm_all_mailbox_content)

def process_all(ini, account_names):
    for account_name in account_names:
        print("processing {}".format(account_name))
        data = account_info(ini, account_name)
        hostname = data.get('hostname')
        username = data.get('username')
        password = data.get('password')
        port = data.get('port') or 993
        print('connecting to host: {}, port: {}'.format(hostname, port))
        con = imaplib.IMAP4_SSL(hostname, port=port)
        con.login(username, password)
        erase_mailboxes(con)

if __name__ == '__main__':
    args = parse_args()
    process_all(args.credentials, args.account_names)
